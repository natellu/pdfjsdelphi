program PDFJSDELPHI;

uses
  Vcl.Forms,
  main in 'main.pas' {pdfForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TpdfForm, pdfForm);
  Application.Run;
end.
