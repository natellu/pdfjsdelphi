unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.WebView2, Winapi.ActiveX,
  Vcl.Edge, Vcl.StdCtrls, System.NetEncoding, Vcl.ExtCtrls;

type
  TpdfForm = class(TForm)
    EdgeBrowser1: TEdgeBrowser;
    btnOpen: TButton;
    FlowPanel1: TFlowPanel;
    btnSave: TButton;
    Memo1: TMemo;
    btnShowAnnotations: TButton;
    btnAddAnno: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure EdgeBrowser1CreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure EdgeBrowser1WebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    procedure btnShowAnnotationsClick(Sender: TObject);
    procedure btnAddAnnoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure SavePdfRequest(Browser: TEdgeBrowser);
    procedure LoadPdfToBrowser(Browser: TEdgeBrowser; const PdfFilePath: string);
    procedure RequestPdfAnnotations(Browser: TEdgeBrowser);
    procedure AddStickyNote(Browser: TEdgeBrowser; X, Y: Integer; Text, Author: string);
    procedure SetUIEnabled(AEnabled: Boolean);
  public
  end;

var
  pdfForm: TpdfForm;

const
  MSG_SAVE_PDF = 'SAVE_PDF:';
  MSG_ANNOTATIONS = 'ANNOTATIONS:';

implementation

{$R *.dfm}

procedure TpdfForm.FormCreate(Sender: TObject);
begin
  SetUIEnabled(False);
end;

procedure TpdfForm.FormShow(Sender: TObject);
begin
  EdgeBrowser1.CreateWebView
end;

procedure TpdfForm.SetUIEnabled(AEnabled: Boolean);
begin
  btnOpen.Enabled := AEnabled;
  btnSave.Enabled := AEnabled;
  btnShowAnnotations.Enabled := AEnabled;
  btnAddAnno.Enabled := AEnabled;
end;

procedure TpdfForm.EdgeBrowser1CreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  WebView3: ICoreWebView2_3;
  AppPath, WebAssetsPath: string;
begin
  if Succeeded(AResult) then
  begin
    if Succeeded(Sender.DefaultInterface.QueryInterface(IID_ICoreWebView2_3, WebView3)) then
    begin
      AppPath := ExtractFilePath(ParamStr(0));
      WebAssetsPath := AppPath + 'web_assets';

      //maps folder to host to prevent cors errors
      WebView3.SetVirtualHostNameToFolderMapping(
        'pdfviewer.local',
        PWideChar(WebAssetsPath),
        1
      );

      SetUIEnabled(True);

       EdgeBrowser1.Navigate('https://pdfviewer.local/web/viewer.html?file=');  //?file= empty loads no pdf, can add pdf so that it gets loaded by default
    end;
  end;
end;

procedure TpdfForm.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    LoadPdfToBrowser(EdgeBrowser1, OpenDialog1.FileName);
end;

procedure TpdfForm.btnSaveClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    SavePdfRequest(EdgeBrowser1);
end;

procedure TpdfForm.btnShowAnnotationsClick(Sender: TObject);
begin
  RequestPdfAnnotations(EdgeBrowser1);
end;

procedure TpdfForm.btnAddAnnoClick(Sender: TObject);
begin
  AddStickyNote(EdgeBrowser1, 10, 10, 'Text', 'Author');
end;

procedure TpdfForm.LoadPdfToBrowser(Browser: TEdgeBrowser; const PdfFilePath: string);
var
  FileStream: TMemoryStream;
  Base64Str: string;
  Base64Encoder: TBase64Encoding;
  JS: string;
begin
  FileStream := TMemoryStream.Create;
  Base64Encoder := TBase64Encoding.Create(0);
  try
    FileStream.LoadFromFile(PdfFilePath);
    FileStream.Position := 0;
    Base64Str := Base64Encoder.EncodeBytesToString(FileStream.Memory, FileStream.Size);

    JS :=
      'var bytes = new Uint8Array(atob("' + Base64Str + '").split("").map(function(c) { return c.charCodeAt(0); }));' +
      'PDFViewerApplication.open({ data: bytes });';

    Browser.ExecuteScript(JS);
  finally
    Base64Encoder.Free;
    FileStream.Free;
  end;
end;

procedure TpdfForm.SavePdfRequest(Browser: TEdgeBrowser);
var
  JS: string;
begin
  JS :=
    'PDFViewerApplication.pdfDocument.saveDocument().then(function(data) {' +
    '  var binary = "";' +
    '  var bytes = new Uint8Array(data);' +
    '  for (var i = 0; i < bytes.byteLength; i++) { binary += String.fromCharCode(bytes[i]); }' +
    '  window.chrome.webview.postMessage("' + MSG_SAVE_PDF + '" + btoa(binary));' +
    '});';

  Browser.ExecuteScript(JS);
end;

procedure TpdfForm.EdgeBrowser1WebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
var
  MessageStr: string;
  Base64Data: string;
  Bytes: TBytes;
  PdfStream: TMemoryStream;
  WebMessage: PWideChar;
  SavePath: string;
  AnnotationData: string;
begin
  if Succeeded(Args.ArgsInterface.TryGetWebMessageAsString(WebMessage)) then
  begin
    MessageStr := WebMessage;
    CoTaskMemFree(WebMessage);

    if MessageStr.StartsWith(MSG_SAVE_PDF) then
    begin
      SavePath := SaveDialog1.FileName;
      Base64Data := MessageStr.Substring(Length(MSG_SAVE_PDF));
      Bytes := TNetEncoding.Base64.DecodeStringToBytes(Base64Data);

      PdfStream := TMemoryStream.Create;
      try
        PdfStream.WriteBuffer(Bytes[0], Length(Bytes));
        PdfStream.SaveToFile(SavePath);
        ShowMessage('PDF saved successfully to: ' + SavePath);
      finally
        PdfStream.Free;
      end;
    end
    else if MessageStr.StartsWith(MSG_ANNOTATIONS) then
    begin
      AnnotationData := MessageStr.Substring(Length(MSG_ANNOTATIONS));
      AnnotationData := StringReplace(AnnotationData, '\n', sLineBreak, [rfReplaceAll]);
      AnnotationData := StringReplace(AnnotationData, 'Type: /', 'Type: ', [rfReplaceAll]);
      Memo1.Lines.Text := AnnotationData;
    end;
  end;
end;

// uses pdf-lib.js instead of pdf.js
procedure TpdfForm.RequestPdfAnnotations(Browser: TEdgeBrowser);
var
  JS: string;
begin
JS :=
    '(async function() {' +
    '  try {' +
    '    var data = await PDFViewerApplication.pdfDocument.saveDocument();' +
    '    var pdfDoc = await PDFLib.PDFDocument.load(data);' +
    '    var pages = pdfDoc.getPages();' +
    '    var result = [];' +
    '    ' +
    '    for (var i = 0; i < pages.length; i++) {' +
    '      var page = pages[i];' +
    '      var annots = page.node.Annots();' +
    '      if (!annots) continue;' +
    '      ' +
    '      for (var j = 0; j < annots.size(); j++) {' +
    '        var annotRef = annots.get(j);' +
    '        if (!annotRef) continue;' +
    '        ' +
    '        var annot = pdfDoc.context.lookup(annotRef);' +
    '        if (!annot || typeof annot.lookup !== "function") continue;' +
    '        ' +
    '        var subtype = annot.lookup(PDFLib.PDFName.of("Subtype"));' +
    '        var typeStr = (subtype && typeof subtype.value === "function") ? subtype.value() : "Unknown";' +
    '        var info = "Page " + (i + 1) + " - Type: " + typeStr;' +
    '        ' +
    '        var contentsObj = annot.lookup(PDFLib.PDFName.of("Contents"));' +
    '        if (contentsObj && typeof contentsObj.decodeText === "function") {' +
    '           var text = contentsObj.decodeText();' +
    '           if (text) info += " | Content: " + text;' +
    '        }' +
    '        ' +
    '        var authorObj = annot.lookup(PDFLib.PDFName.of("T"));' +
    '        if (authorObj && typeof authorObj.decodeText === "function") {' +
    '           var authorText = authorObj.decodeText();' +
    '           if (authorText) info += " | Author: " + authorText;' +
    '        }' +
    '        ' +
    '        info = info.replace(/\\r\\n|\\r|\\n/g, " ");' +
    '        result.push(info);' +
    '      }' +
    '    }' +
    '    ' +
    '    var finalStr = result.length > 0 ? result.join("\\n") : "No annotations found.";' +
    '    window.chrome.webview.postMessage("ANNOTATIONS:" + finalStr);' +
    '  } catch(e) {' +
    '    window.chrome.webview.postMessage("ANNOTATIONS:Error: " + e.stack);' +
    '  }' +
    '})();';

  Browser.ExecuteScript(JS);
end;


// uses pdf-lib.js instead of pdf.js
procedure TpdfForm.AddStickyNote(Browser: TEdgeBrowser; X, Y: Integer; Text, Author: string);
var
  JS: string;
begin
 JS :=
    '(async function() {' +
    '  try {' +
    '    var data = await PDFViewerApplication.pdfDocument.saveDocument();' +
    '    var pdfDoc = await PDFLib.PDFDocument.load(data);' +
    '    var pages = pdfDoc.getPages();' +
    '    var page = pages[0];' +
    '    var height = page.getHeight();' +
    '    ' +
    '    var annotation = pdfDoc.context.obj({' +
    '      Type: "Annot",' +
    '      Subtype: "Text",' +
    '      Open: true,' +
    '      Name: "Note",' +
    '      Rect: [' + IntToStr(X) + ', height - ' + IntToStr(Y) + ' - 20, ' +
                     IntToStr(X + 20) + ', height - ' + IntToStr(Y) + '],' +
    '      Contents: PDFLib.PDFString.of("' + Text + '"),' +
    '      T: PDFLib.PDFString.of("' + Author + '"),' +
    '      C: [0, 1, 0]' +
    '    });' +
    '    ' +
    '    var annotationRef = pdfDoc.context.register(annotation);' +
    '    ' +
    '    var annots = page.node.lookup(PDFLib.PDFName.of("Annots"), PDFLib.PDFArray);' +
    '    if (!annots) {' +
    '      annots = pdfDoc.context.obj([]);' +
    '      page.node.set(PDFLib.PDFName.of("Annots"), annots);' +
    '    }' +
    '    ' +
    '    annots.push(annotationRef);' +
    '    ' +
    '    var pdfBytes = await pdfDoc.save();' +
    '    PDFViewerApplication.open({ data: pdfBytes });' +
    '  } catch(e) { console.error(e); }' +
    '})();';

  Browser.ExecuteScript(JS);
end;

end.
