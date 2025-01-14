program Operador;



uses
  Vcl.Forms,
  UFCPrin in 'UFCPrin.pas' {FCPrin},
  Vcl.Themes,
  Vcl.Styles,
  UFCarga in 'UFCarga.pas' {FCarga},
  CodeLen in 'Util\CodeLen.pas',
  CodeMem in 'Util\CodeMem.pas',
  CodeMemOpt in 'Util\CodeMemOpt.pas',
  GenCodeHook in 'Util\GenCodeHook.pas',
  UFSessao in 'UFSessao.pas' {FSESSAO},
  UBarra in 'UBarra.pas' {FBarraRemota},
  UGabesOddFormPanel in 'UGabesOddFormPanel.pas',
  UDAD in 'UDAD.pas' {FUDAD},
  UGabesOddFormPanelChat in 'UGabesOddFormPanelChat.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  TrimAppMemorySize;
  Application.Title := 'Liberado Para Danadinho';
  TStyleManager.TrySetStyle('Aqua Light Slate');
  Application.CreateForm(TFCarga, FCarga);
  Application.CreateForm(TFCPrin, FCPrin);
  Application.Run;

end.
