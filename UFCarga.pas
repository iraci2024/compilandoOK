unit UFCarga;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms,
  Vcl.Imaging.jpeg,
  Vcl.ExtCtrls, Vcl.MPlayer,
  Thend, bass, dialogs,
  Vcl.Imaging.pngimage,
  Wcrypt2, DCPcrypt2,
  DCPripemd160, DCPrijndael, Vcl.StdCtrls, TFlatMemoUnit, TFlatButtonUnit,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.ADS, FireDAC.Phys.ADSDef, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client, Vcl.Menus, Vcl.Imaging.GIFImg, comobj;

type
  TrataErros = class(TThread)
  protected
    procedure Execute; override;
  public
  end;

type
  TFCarga = class(TForm)
    PopUpSh: TTimer;
    MediaPlayer: TMediaPlayer;
    trm: TThreadComponent;
    DCP_ripemd1601: TDCP_ripemd160;
    Timer1: TTimer;
    Image1: TImage;
    Panel1: TPanel;
    procedure PopUpShTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure trmExecute(Sender: TObject);
    procedure UserControl1LoginSucess(Sender: TObject; IdUser: Integer;
      Usuario, Nome, Senha, Email: string; Privileged: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }

  protected
    procedure WMShowWindow(var Message: TWMShowWindow); message WM_SHOWWINDOW;
  public
    { Public declarations }

    procedure CapturaErro(Sender: TObject; E: Exception);
    function vDc_vCri(Action, Src: String): String;

  end;

var
  FCarga: TFCarga;
  TELAPOP: TForm;
  Trata: TrataErros;
  Channel: DWORD;

  // function Ofuscador_Rmt(Action, Src: String): String;
  // #-----------------------------------------------------------------------------
implementation

{$R *.dfm}

uses UFCPrin;

procedure TFCarga.CapturaErro(Sender: TObject; E: Exception);
var
  erros: TStringList;
begin
  erros := TStringList.Create;
  erros.Add(E.Message);
  erros.SaveToFile('Diagnóstico.log');
  erros.Free;
  Screen.Cursor := crDefault;
  Application.ProcessMessages;

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

function MostraPopUp(Tela: TForm; Tempo: Integer): Boolean;
begin
  if not(Tela = nil) then
    if not Tela.Showing then
    begin
      TELAPOP := Tela;
      Tela.Left := Screen.Width - Tela.Width;
      Tela.Top := (Screen.Height - AlturaBarraTarefas);
      Tela.Hide;
      FCarga.PopUpSh.Interval := Tempo;
      FCarga.PopUpSh.Enabled := True;
      Result := True;
      Sleep(5000);
      BASS_ChannelPause(Channel);
      Tela.Show;

    end
    else
    begin
      Result := False;
      Tela.BringToFront;
    end;
end;


procedure TFCarga.FormCreate(Sender: TObject);
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

begin
 // Trv();
  Trata := TrataErros.Create(True);
  Trata.FreeOnTerminate := True;
  Trata.Start;
  (Image1.Picture.Graphic as TGIFImage).Animate := True;
  BASS_Init(-1, 44100, 0, Application.Handle, nil);
  Channel := BASS_StreamCreateFile(False,
    PChar(ExtractFilePath(Application.ExeName) + 'PlayList\start.mp3'), 0, 0, 0

{$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
  BASS_ChannelPlay(Channel, False);
  Application.onexception := FCarga.CapturaErro;
end;

procedure TFCarga.PopUpShTimer(Sender: TObject);
begin
  TELAPOP.Top := TELAPOP.Top - 10;
  if TELAPOP.Top <= ((Screen.Height - AlturaBarraTarefas) - TELAPOP.Height) then
    PopUpSh.Enabled := False;
end;

procedure TFCarga.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  trm.Active := False;
  MostraPopUp(FCPrin, 5);
  FCarga.Hide;

end;

procedure TFCarga.trmExecute(Sender: TObject);
begin
  trm.Active := False;
  MostraPopUp(FCPrin, 5);
  FCarga.Hide;
end;

procedure TFCarga.UserControl1LoginSucess(Sender: TObject; IdUser: Integer;
  Usuario, Nome, Senha, Email: string; Privileged: Boolean);
begin
  Application.ShowMainForm := True;
end;

function TFCarga.vDc_vCri(Action, Src: String): String;
var
  Key: String;
  Cipher: TDCP_rijndael;

begin
  Key := 'BAUdGYGlgX3wUY4XrGGt9z6CrGnnlmpgCaEIjtVSM2U7lYOwieLiZxs8v5df4YMnVY273VQ5jA4wdJvTR0P5r3y28crWsXscOWSW6IPkjwCg7WWUH1mCyA3Dhh8A0123456789';
  if (Action = UpperCase('C')) then
  begin
    Cipher := TDCP_rijndael.Create(nil);
    Cipher.InitStr(Key, TDCP_ripemd160);
    Result := Cipher.EncryptString(Src);
    Cipher.Burn;
    Cipher.Free;
  end;
  if (Action = UpperCase('D')) then
  begin
    Cipher := TDCP_rijndael.Create(nil);
    Cipher.InitStr(Key, TDCP_ripemd160);
    Result := Cipher.DecryptString(Src);
    Cipher.Burn;
    Cipher.Free;
  end;

end;

procedure TFCarga.WMShowWindow(var Message: TWMShowWindow);
begin
  // Put the "hat" out of the screen center
  if Message.Show then
    Top := (Screen.WorkAreaHeight - Height - 150) div 2;
  inherited;
end;

{ TrataErros }

procedure TrataErros.Execute;
begin
  inherited;
end;

end.
