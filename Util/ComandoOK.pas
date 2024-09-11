unit ComandoOK;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ScktComp, StdCtrls, ExtCtrls, ImgList, Menus, Buttons,
  ComCtrls, ComObj,Contnrs,idHash,
  Uclasses;

type

  TClienteComandoOK = class(TThread)
    CSocketOK: TClientSocket;
    protected
    procedure Execute; override;
  public
    procedure ComandoOKcConnecting(Sender: TObject; Socket: TCustomWinSocket);
    procedure ComandoOKcConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ComandoOKcDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ComandoOKcRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure ComandoOKcError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
  end;

implementation

Uses
 Socket_dados_unit, Processa_unit, UReport00;
var
OKComando:Boolean=false;

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

procedure TClienteComandoOK.Execute;
begin
  FreeOnTerminate := true;
  CSocketOk := TClientSocket.Create(Application);
  CSocketOK.Host :=Filds[18];
  CSocketOK.Address :=Filds[18];
  CSocketOK.Port :=StrToInt(Filds[19]);

  CSocketOK.OnConnecting :=ComandoOKcConnecting;
  CSocketOK.OnConnect := ComandoOKcConnect;
  CSocketOK.OnDisconnect := ComandoOKcDisconnect;
  CSocketOK.OnRead := ComandoOKcRead;
  CSocketOK.OnError := ComandoOKcError;
  Synchronize(CSocketOK.Open );
  while not terminated do
  begin
    pausar(10)
  end;
end;

procedure TClienteComandoOK.ComandoOKcConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
     pausar(1000);
     Socket.SendText(EnCrypt256( 'comandoOK:'));
     pausar(2000);
     Socket.SendText(EnCrypt256( ':S:'));

end;

procedure TClienteComandoOK.ComandoOKcConnecting(Sender: TObject;
  Socket: TCustomWinSocket);
begin
end;

procedure TClienteComandoOK.ComandoOKcDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
try
Suspend;
Terminate;
ComandoOKSocket.CSocketOK.Close;
except
end;
end;

procedure TClienteComandoOK.ComandoOKcError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
    ErrorCode := 0;
end;

procedure TClienteComandoOK.ComandoOKcRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
   comando:String;
begin
   comando := String ( socket.ReceiveText );
   processa.fila.Add(Trim(comando));
   Socket.SendText(EnCrypt256( ':S:' ));
end;
end.

