object pdfForm: TpdfForm
  Left = 0
  Top = 0
  Caption = 'pdfForm'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 15
  object EdgeBrowser1: TEdgeBrowser
    Left = 0
    Top = 0
    Width = 624
    Height = 311
    Align = alClient
    TabOrder = 0
    AllowSingleSignOnUsingOSPrimaryAccount = False
    TargetCompatibleBrowserVersion = '117.0.2045.28'
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
    OnCreateWebViewCompleted = EdgeBrowser1CreateWebViewCompleted
    OnWebMessageReceived = EdgeBrowser1WebMessageReceived
    ExplicitLeft = 304
    ExplicitTop = 232
    ExplicitWidth = 100
    ExplicitHeight = 41
  end
  object FlowPanel1: TFlowPanel
    Left = 0
    Top = 311
    Width = 624
    Height = 41
    Align = alBottom
    Caption = 'FlowPanel1'
    ShowCaption = False
    TabOrder = 1
    ExplicitLeft = 248
    ExplicitTop = 392
    ExplicitWidth = 185
    object btnOpen: TButton
      Left = 1
      Top = 1
      Width = 75
      Height = 25
      Caption = #214'ffnen'
      TabOrder = 0
      OnClick = btnOpenClick
    end
    object btnSave: TButton
      Left = 76
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Speichern'
      TabOrder = 1
      OnClick = btnSaveClick
    end
    object btnShowAnnotations: TButton
      Left = 151
      Top = 1
      Width = 114
      Height = 25
      Caption = 'Zeig Annotations'
      TabOrder = 2
      OnClick = btnShowAnnotationsClick
    end
    object btnAddAnno: TButton
      Left = 265
      Top = 1
      Width = 144
      Height = 25
      Caption = 'Bemerkung hinzuf'#252'gen'
      TabOrder = 3
      OnClick = btnAddAnnoClick
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 352
    Width = 624
    Height = 89
    Align = alBottom
    Lines.Strings = (
      'Annotations:')
    TabOrder = 2
    ExplicitLeft = 232
    ExplicitTop = 440
    ExplicitWidth = 185
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'pdf'
    Filter = 'pdf|*.pdf'
    Left = 440
    Top = 311
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'pdf'
    Filter = 'pdf|*.pdf'
    Left = 504
    Top = 311
  end
end
