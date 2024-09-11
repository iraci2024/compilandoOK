unit Servidor_imagens_unit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ScktComp, StdCtrls, Jpeg, ExtCtrls, Buttons, ComCtrls, ImgList, ZLib;

type TSock_Thread_Txt = class(TThread)
private
  Socket: TCustomWinSocket;
public
  constructor Create(aSocket:TCustomWinSocket);
  procedure Execute; override;
end;

type
  TServidorImagens = class( TThread )
      SSocket: TServerSocket;
  protected
      procedure Execute; override;
  public

    procedure ImagensClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ImagensClienaAccept(Sender: TObject; Socket: TCustomWinSocket);
    procedure ImagensClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure ImagensClientError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure pinta;
    procedure DoExpand(inStream: TStream);
end;


implementation

uses UFSessao;


procedure EnviaText(Socket: TCustomWinSocket; MSG : string );
var
  Dados : string;
  Len : Integer;
begin
  Dados := MSG;
  Len := Length(Dados);
  Socket.SendText(Dados);
end;

procedure EnviaComando(SockHandle: Integer; Comando: string);
var
  I: integer;
begin
{  try
    for I:=0 to  HREAD.SSocket.Socket.ActiveConnections - 1 do
     begin
       if HREAD.SSocket.Socket.Connections[I].Handle   =  SockHandle then
        begin
           EnviaText(HREAD.SSocket.Socket.Connections[I] , Comando);

          exit;
        end;
     end;
  finally
    Application.ProcessMessages;
  end;}
end;
procedure TServidorImagens.execute;
begin
  //
  FreeOnTerminate := true;
  SSocket := TServersocket.Create( Application );
  SSOcket.Port :=5052;
  //SSocket.OnClientConnect := ImagensClientConnect;
  SSocket.OnAccept := ImagensClienaAccept;
  SSocket.OnClientRead := ImagensClientRead;
  SSocket.OnClientError := ImagensClientError;
 // SSocket.ServerType := stThreadBlocking;
 Synchronize(SSocket.Open);
  Inicio := 0;
  Segundos := 0;

  while not terminated and SSocket.Socket.Connected do
     begin
  //     Application.ProcessMessages;
       Sleep(1);
     end;
end;



procedure TServidorImagens.ImagensClienaAccept(Sender: TObject;
  Socket: TCustomWinSocket);
var
  TST: TSock_Thread_Txt;
begin
  TST := TSock_Thread_Txt.Create(Socket);
  TST.Resume;
end;

procedure TServidorImagens.ImagensClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
  l: TListItem;
begin
  // Bytes := 0;
//   SSocket.Socket.Connections[0].SendText('p'); // Comando para solicitar imagem nova
end;

procedure TServidorImagens.ImagensClientError(Sender: TObject; Socket: TCustomWinSocket;
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


procedure TServidorImagens.ImagensClientRead(Sender: TObject; Socket: TCustomWinSocket);
Var

TamBuffer : integer;
Paux : pointer;
DeZip: TDecompressionStream;
FileIni,FileOut: TFileStream;
i: Integer;
Buf: array[0..1023]of Byte;
Entrada: AnsiString;
Tracos: Integer;
AuxTamanho: string;
AuxLinha: String;
AuxColuna: String;
Dados: AnsiString;

begin
{
 begin
 //*****************************************************************************

  if not RecebendoArquivo then //VERIFICA SE NÃO ESTÁ RECEBENDO O ARQ
   Begin

     ENTRADA :=Socket.ReceiveText;
     if Entrada = 's' then
        begin
           Vista.RemotoPhoto.Socket.SendText('p');
           Exit;
        end;
     Tracos := 0;
      AuxTamanho:= '';
      AuxLinha:='';
      AuxColuna:='';
     for I := 1 to Length( Entrada ) do
         begin
            if Entrada[I]='|' then
              Tracos := Tracos + 1
            else
                begin
                    if Tracos = 0 then
                       AuxTamanho := AuxTamanho + Entrada[I];
                    if Tracos = 1 then
                       AuxLinha := AuxLinha + Entrada[I];
                    if Tracos = 2 then
                       AuxColuna := AuxColuna + Entrada[I];
                end;
         end;
         TamanhoArquivo := StrToInt64( AuxTamanho );
         Linha := StrToInt64( AuxLinha );
         Coluna := StrToInt64( AuxColuna );
     vista.Bytes :=vista.Bytes+ TamanhoArquivo;
     //Vista.Caption := 'Kadoshi Viewer - Transferência '+ inttostr( Bytes );
     RecebendoArquivo := True;  //SETA PARA RECEBENDO
     if Arquivo = nil then //LIMPA O ARQUIVO DE MEMÓRIA
       Arquivo := TMemoryStream.Create //CRIA O ARQUIVO MEM
     else
        begin
           Arquivo.Free;
           Arquivo := TMemoryStream.Create;
        end;
           Vista.RemotoPhoto.Socket.SendText('d');

   end
  else
   Begin //CASO RECEBENDO
     TamBuffer := Socket.ReceiveLength;  //PEGA O TAM DO BUFFER
     GetMem(PAux,TamBuffer); //JOGA NA MEMÓRIA
     Socket.ReceiveBuf(PAux^,TamBuffer);//RECEBE O  BUFFER ACUMULATIVO
     Arquivo.Write(PAux^,TamBuffer);  //GRAVA NO ARQ DE MEMORIA
     Dispose(PAux); //PREPARA PARA SER ACUMULATIVO
     transferido := transferido + ( Arquivo.Size / 1024 );
     if TamanhoArquivo = Arquivo.Size then //VERIFICA SE JÁ RECEBEU TODO
      Begin //CASO JÁ RECEBEU TODO
        RecebendoArquivo := False;//SETA Q NÃO ESTÁ MAIS RECEBENDO
//        Arquivo.SaveToFile( 'recebido.pre');//SALVA IMAGEM NO HD compactada
  //      Arquivo := Nil;
       Arquivo.Position := 0;
//       Arquivo.SaveToFile( 'teste.pre' );
       DoExpand( Arquivo );
       Arquivo.Position := 0;
       jpegi:=tjpegimage.create; //CRIA COMPONENTE JPEG
       jpegi.LoadFromStream( Arquivo );

        Synchronize(pinta );

       jpegi.Free;//LIMPA O JPEG

       Vista.RemotoPhoto.Socket.SendText('p'); //ENVIA UM COMANDO AO SERVIDOR AVISANDO Q JÁ RECEBEU A IMAGEM E Q ESTA PRONTO PARA RECEBER OUTRA
      end;
  end;

 end;  }

end;

procedure TServidorImagens.pinta;
begin
{   if StopScree=true then
   exit else
   if not vista.Panel1.Visible then
   vista.Panel1.Visible := True;
   SetBkMode( vista.Image1.Canvas.Handle, TRANSPARENT );
   vista.Image1.Canvas.Draw(Coluna, Linha, jpegi);
  // jpegi.SaveToFile( IntToStr( Linha ) + IntToStr( Coluna )+ '.jpg' );}
end;

procedure TServidorImagens.DoExpand(inStream: TStream);
const
  BufferSize = 4096;
var
  Count: Integer;
  outMS: TMemoryStream;
  ZStream: TCustomZLibStream;
  Buffer: array[0..BufferSize - 1] of Byte;
begin
  outMS := TMemoryStream.Create;
  try
    InStream.Seek(0, soFromBeginning);
    outMS.Size := 0;

    ZStream := TDecompressionStream.Create(InStream);
    try
      while True do
      begin
        Count := ZStream.Read(Buffer, BufferSize);
        if Count <> 0 then
          outMS.WriteBuffer(Buffer, Count)
        else
          Break;
      end;
    finally
      ZStream.Free;
    end;

    InStream.Size := outMS.Size;
    InStream.Position := 0;
    InStream.CopyFrom(outMs, 0);
  finally
    outMS.Free;
  end;
end;


constructor TSock_Thread_Txt.Create(aSocket: TCustomWinSocket);
begin
    inherited Create(true);
    Socket := aSocket;
    FreeOnTerminate := true;
end;

procedure TSock_Thread_Txt.Execute;
var
L:TListItem;
comando:String;
begin
{  inherited;
  while not Terminated and Socket.Connected do
  begin
          L :=FTCONEXCOES.lv1.FindCaption(0, Socket.RemoteAddress, False, True, False);
          if L <> nil then
          begin
          if L.SubItems.Objects[2] = nil then
          begin
          L.SubItems.Objects[2] := TObject(Socket);
          L.SubItems[0] :='CASA-PC';
          L.SubItems[1] :='COMENDADOR';
          L.SubItems[2] :='WIN7';
          L.SubItems[3] :='1.0.0';
          L.SubItems[5] :=IntToStr(Socket.Handle);
          end;
          end;
          Destroy;

  end;}
end;

end.
