unit Servidor_dados_unit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ScktComp, StdCtrls, Jpeg, ExtCtrls, Buttons, ComCtrls, ImgList, ZLib,
  Clipbrd;

type TSock_Thread = class(TThread)
private
  Socket: TCustomWinSocket;
public
  constructor Create(aSocket:TCustomWinSocket);
  procedure Execute; override;
end;

type
   TServidorDados = class( TThread )
       Dados: TServerSocket;
        procedure dadosClientRead(Sender: TObject; Socket: TCustomWinSocket);
        procedure dadosClientAccept(Sender: TObject; Socket: TCustomWinSocket);
        procedure dadosClientConnect(Sender: TObject; Socket: TCustomWinSocket);
        procedure dadosClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
        procedure dadosClientError(Sender: TObject; Socket: TCustomWinSocket;
                  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
        procedure MudaImagem;
        procedure Chat(Comando: string);
    protected
        procedure Execute; override;


   end;


implementation

uses
  uConfiguracao, UFSessao, UFCPrin;

procedure TServidorDados.MudaImagem;
begin
   //
   FSESSAO.Panel1.Width := ( XTela * frmConfiguracoes.Zoom.Value ) div 100;
   FSESSAO.Panel1.Height := ( YTela * frmConfiguracoes.Zoom.Value ) div 100;
   FSESSAO.Panel1.Top := (FSESSAO.ClientHeight - FSESSAO.Panel1.Height ) div 2;
   FSESSAO.Panel1.Left := (FSESSAO.ClientWidth - FSESSAO.Panel1.Width ) div 2;
   if FSESSAO.Panel1.Width >=FSESSAO.ClientWidth then
      FSESSAO.Panel1.Left := 0;
   if FSESSAO.Panel1.Height >= FSESSAO.ClientHeight then
      FSESSAO.Panel1.Top := 0;

end;


function SplitString(S,Delimitador: string): TStringList;
var
  p: integer;
begin
  Result := TStringList.Create;

  p := Pos(Delimitador, S);
  while (p > 0) do
  begin
    Result.Add(Copy(S, 1, p - 1));
    Delete(S, 1, p + Length(Delimitador) - 1);
    p := Pos(Delimitador, S);
  end;

  if (S <> '') then
    Result.Add(S);
end;

Function Split(texto: string; delimitador:string): TStringList;
var
  retorno : TStringList;
begin
  Result := TStringList.Create;
  Result.LineBreak := delimitador;
  Result.Text := texto;
end;

procedure TServidorDados.Execute;
begin
  FreeOnTerminate := true;
  Dados := TServersocket.Create( Application );
  Dados.Port :=5051;
  Dados.OnClientConnect := dadosClientConnect;
  Dados.OnAccept := dadosClientAccept;
  Dados.OnClientDisconnect := dadosClientDisconnect;
//  Dados.OnClientRead := dadosClientRead;
//  Dados.ServerType := stThreadBlocking;
  Synchronize( Dados.Open );
  while not terminated and Dados.Socket.Connected do
     begin
//       Application.ProcessMessages;
       Sleep(1);
     end;

end;




procedure TServidorDados.dadosClientError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
   case ErrorCode of
   10061: Application.MessageBox('Não foi possivel conectar ao servidor', Pchar(Application.Title),16);
   10060: Application.MessageBox('Não foi possivel conectar ao servidor', Pchar(Application.Title),16);
   else begin
         ErrorCode := 0;
         Exit;
         end;
   end;
    ErrorCode := 0;

end;

procedure TServidorDados.dadosClientAccept(Sender: TObject;
  Socket: TCustomWinSocket);
begin

end;

procedure TServidorDados.dadosClientConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
end;

procedure TServidorDados.dadosClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin

end;

procedure TServidorDados.dadosClientRead(Sender: TObject; Socket: TCustomWinSocket);
function PosSocket(fField : String): String;
var
  I : Byte;
begin
   Result := '';
   for I := 1 To Length(fField) do
       if fField [I] In ['0'..'9'] Then
            Result := Result + fField [I];
end;

var
  comando: String;
  proc: String;

  POSX: Integer;
  Inicio: Integer;
  Aux: String;
  LstComando: TStringList;
  NSocket:String;
begin
 {
   comando := String( socket.ReceiveText );
   if Pos( ':S:', comando ) > 0  then
   begin
      Processa.CamandoOK := True;
   end;
   if Pos( 'chat:', comando ) > 0 then
      Chat( comando );
   if Pos( 'clb:', comando ) > 0 then
      begin
         RecebeuClipboard := True;
         Aux := Copy( comando, Pos( 'clb:', comando ) + 4, Length( Comando ) - (Pos( 'clb:', comando ) + 3) );
         Clipboard.AsText := Aux;
      end;
   if pos( 'qualidade:', comando ) > 0 then
      begin
         Qualidade := StrToInt( copy( comando, pos( 'qualidade:', comando ) + 10, 4) );
      end;
   if pos( ';semfoto:', comando ) > 0 then
      Hread.SSocket.Socket.Connections[0].SendText('ping'); //ENVIA UM COMANDO AO SERVIDOR AVISANDO Q JÁ RECEBEU A IMAGEM E Q ESTA PRONTO PARA RECEBER OUTRA
   if pos( 'desconectar:', comando ) > 0 then
      begin
         Vista.Desconectar1.Click;
      end;
   if Pos('resolucao:', comando ) > 0 then
      begin
         ShowMessage(comando);
         Inicio := pos( 'resolucao:', comando ) + 10;
         POSX := Pos( 'x', comando );
         proc := Copy( comando, inicio, POSX - 11 );
         XTela := StrToInt( proc );
         proc := Copy( comando, POSX + 1, ( Length( comando ) - Posx ) );
         YTela := StrToInt( Trim( proc ) );
         Synchronize( MudaImagem );

         with Processa.Fila2.New do
            begin
               Comando := 'nv:' + IntToStr( frmConfiguracoes.Compressao.ItemIndex );
            end;
         with Processa.Fila2.New do
            begin
               Comando := 'nl:' + IntToStr( frmConfiguracoes.Linhas.Value );
            end;
         with Processa.Fila2.New do
            begin
               Comando := 'nc:' + IntToStr( frmConfiguracoes.Colunas.Value );
            end;
         with Processa.Fila2.New do
            begin
               Comando :=  'ql:' + IntToStr( frmConfiguracoes.Qualidade.Position );
            end;
         with Processa.Fila2.New do
            begin
               Comando :=  'zm:' + IntToStr( frmConfiguracoes.Zoom.Value );
            end;

         with Processa.Fila2.New do
         begin
             case frmConfiguracoes.MandaLinha.Checked of
                false:Comando :=  'ml:0' ;
                true: Comando :=  'ml:1' ;
         end;
         end;
         with Processa.Fila2.New do
         begin
             case frmConfiguracoes.MandaQuadro.Checked of
                false:Comando :=  'mq:0' ;
                true: Comando :=  'mq:1' ;
         end;
         end;

         with Processa.Fila2.New do
            begin
               Comando :=  'dadosrec';
            end;
      end;
  }
end;

procedure TServidorDados.Chat(Comando: string);
begin
end;



{ TSock_Thread }

constructor TSock_Thread.Create(aSocket: TCustomWinSocket);
begin
    inherited Create(true);
    Socket := aSocket;
    FreeOnTerminate := true;

end;

procedure TSock_Thread.Execute;

var
  comando: String;
  proc: String;

  POSX: Integer;
  Inicio: Integer;
  Aux: String;
  LstComando: TStringList;

begin
  inherited;
  while not Terminated and Socket.Connected do
  begin
  if Socket.ReceiveLength > 0 then
  begin
      comando := String( socket.ReceiveText );
      if Pos( ':S:', comando ) > 0  then
      begin
      fsessao.Processa.CamandoOK := True;
      end;
      if Pos( 'clb:', comando ) > 0 then
      begin
         RecebeuClipboard := True;
         Aux := Copy( comando, Pos( 'clb:', comando ) + 4, Length( Comando ) - (Pos( 'clb:', comando ) + 3) );
         Clipboard.AsText := Aux;
      end;
      if pos( 'qualidade:', comando ) > 0 then
      begin
         Qualidade := StrToInt( copy( comando, pos( 'qualidade:', comando ) + 10, 4) );
      end;


      if Pos('resolucao:', comando ) > 0 then
      begin
         Inicio := pos( 'resolucao:', comando ) + 10;
         POSX := Pos( 'x', comando );
         proc := Copy( comando, inicio, POSX - 11 );
         XTela := StrToInt( proc );
         proc := Copy( comando, POSX + 1, ( Length( comando ) - Posx ) );
         YTela := StrToInt( Trim( proc ) );
         //Synchronize(FTCONEXCOES.ServidorDados.MudaImagem);
         with  fsessao.Processa.Fila2.New do
         begin
               Comando := 'nv:' + IntToStr( frmConfiguracoes.Compressao.ItemIndex );
         end;
         with fsessao.Processa.Fila2.New do
         begin
               Comando := 'nl:' + IntToStr( frmConfiguracoes.Linhas.Value );
         end;
         with fsessao.Processa.Fila2.New do
         begin
               Comando := 'nc:' + IntToStr( frmConfiguracoes.Colunas.Value );
         end;
         with fsessao.Processa.Fila2.New do
         begin
               Comando :=  'ql:' + IntToStr( frmConfiguracoes.Qualidade.Position );
         end;
         with fsessao.Processa.Fila2.New do
         begin
               Comando :=  'zm:' + IntToStr( frmConfiguracoes.Zoom.Value );
         end;
         with fsessao.Processa.Fila2.New do
         begin
             case frmConfiguracoes.MandaLinha.Checked of
                false:Comando :=  'ml:0' ;
                true: Comando :=  'ml:1' ;
         end;
         end;
         with fsessao.Processa.Fila2.New do
         begin
             case frmConfiguracoes.MandaQuadro.Checked of
                false:Comando :=  'mq:0' ;
                true: Comando :=  'mq:1' ;
         end;
         end;
         with fsessao.Processa.Fila2.New do
            begin
            Comando :=  'dadosrec';
            end;
      end;

  end;
  end;

end;


end.
