//
// TTTTTTTTTTTT  HH                            VV          VV  NN     NN  CCCCCCCCCC
//      TT       HH           II                VV        VV   NNN    NN  CC
//      TT       HH                              VV      VV    NNNN   NN  CC
//      TT       HHHHHHHHHHH  II   NNNNNNNNN      VV    VV     NN NN  NN  CC
//      TT       HH       HH  II  NN       NN      VV  VV      NN  NN NN  CC
//      TT       HH       HH  II  NN       NN       VVVV       NN   NNNN  CC
//      TT       HH       HH  II  NN       NN        VV        NN    NNN  CCCCCCCCCC
//
// Copyright 2010 Cybele Software, Inc.
//
//
//
// This file is part of ThinVNC.
//
// ThinVNC is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     ThinVNC is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with ThinVNC. If not, see <http://www.gnu.org/licenses/>
//
// For additional information, please refer to our Licensing FAQ or contact us via e-mail.
//
// See also:
// http://en.wikipedia.org/wiki/GPL
//

unit ThinVnc.WebSockets;
{$I ThinVnc.DelphiVersion.inc}
{$I ThinVnc.inc}
interface

{.$DEFINE USE_INDY}
uses
  Windows,
  Contnrs,Types,Math,StrUtils,Classes,Sysutils,SyncObjs,
  IdTCPServer,
  IdIOHandlerSocket,
  IdContext,
  IdIOHandler,
  IdTCPConnection,
  IdGlobal,
  zLib,
  IdZLibCompressorBase,
  {$IFNDEF UNICODE}
  IdCompressorZLibEx,
  {$ENDIF}
  ThinVNC.LkJSON,
  ThinVnc.MessageDigest_5,
  ThinVnc.DigestAuth,
  ThinVnc.InputQueue,
  ThinVnc.TcpCommon,
  ThinVnc.ClientSession,
  ThinVnc.Capture,
  ThinVnc.Log,
  dialogs,
  ThinVnc.Utils;

const
  policy_response = '<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>\n';

type
  TWebConnection = class;

  TWebSocketMessageEvent = procedure(AConnection: TWebConnection; const AMessage: string) of object;
  TWebSocketConnectEvent = procedure(AConnection: TWebConnection) of object;
  TWebSocketDisconnectEvent = procedure(AConnection: TWebConnection) of object;
  TWebSocketException = class(Exception);
  TWebSocketHandshakeException = class(TWebSocketException);

  TWebSocketVersion = (wsVer75,wsVer76);
  TWebSocketVersions = set of TWebSocketVersion;

  TWebRequestHeader = class
  private
    FName     : string;
    FValue    : string;
  public
    constructor Create(AHeader:string);overload;
    constructor Create(AName,AValue:string);overload;
  end;

  TWebSocketHeader = class(TWebRequestHeader)
  private
    FExists   : boolean;
    FVersions : TWebSocketVersions;
  public
    constructor Create(AName,AValue:string;AVersions:TWebSocketVersions);overload;
    function MatchAndFill(Msg:string):Boolean;
  end;

  TWebDataFields = class
  private
    FList: TStringList;
    function GetCount: Integer;
    function GetName(const Index: Integer): string;
    function GetValue(const Name: string): string;
    function GetValueFromIndex(const Index: Integer): string;
  public
    constructor Create(const Query: string);
    property Count: Integer read GetCount;
    property Names[const Index: Integer]: string read GetName;
    property Values[const Name: string]: string read GetValue;
    property ValueFromIndex[const Index: Integer]: string read GetValueFromIndex;
  end;

  TWebMethod = (wmNone, wmGet, wmPost);

  TWebRequest = class
  private
    FVersion : TWebSocketVersion;
    FResource: string;
    FScheme : string;
    FQuery  : string;
    FPath   : string;
    FPostData: string;
    FQueryFields : TWebDataFields;
    FPostFields : TWebDataFields;
    FCookieFields : TStrings;
    FWebRequestHeaders : TObjectList;
    FWebSocketHeaders : TObjectList;
    FIsWebSocketRequest : Boolean;
    FConnection : TIdTCPConnection;
    FWebMethod: TWebMethod;
    FWebConnection: TWebConnection;
    function  GenMd5: TIdBytes;
    procedure SetHeaderValue(Header, Value: string);
    procedure GetHttpRequest;
    function  GetQueryFields: TWebDataFields;
    function GetPostFields: TWebDataFields;
    function GetCookieFields: TStrings;
    function GetBinaryData: string;
    function GetIsBinaryPost: Boolean;
  public
    constructor Create(AWebConnection: TWebConnection);
    destructor Destroy;override;

    function GetHeaderValue(Header: string): string;
    property Query:string read FQuery;
    property QueryFields:TWebDataFields read GetQueryFields;
    property PostFields:TWebDataFields read GetPostFields;
    property CookieFields:TStrings read GetCookieFields;
    property Resource: string read FResource;
    property Path: string read FPath;
    property IsBinaryPost: Boolean read GetIsBinaryPost;
    property BinaryData: string read GetBinaryData;
    property WebMethod: TWebMethod read FWebMethod;
  end;

  TProcessScriptEvent = procedure (AConnection:TWebConnection) of object;

  TWebSocketServer = class;
  TWebConnection = class
  private
    FContext: TIdContext;
    FRequest: TWebRequest;
    FHandshakeResponseSent: Boolean;
    FOnMessageReceived: TWebSocketMessageEvent;
    FServer:TWebSocketServer;
    FContentType : string;
    FCustomResponseHeaders : TStringList;
    FMethod : string;
    FSession : TClientSession;
  
    FAuthRealm: string;
    FAuthUserName: string;
    FAuthType: TAuthenticationType;

    FAuthDigestRealm              : String; 
    FAuthDigestUri                : String;
    FAuthDigestNonce              : String;
    FAuthDigestQop                : String;
    FAuthDigestNc                 : String;
    FAuthDigestCnonce             : String;
    FAuthDigestResponse           : String;
    FAuthDigestOpaque             : String;
    FAuthDigestServerNonce        : String;
    FAuthDigestServerOpaque       : String;
    FAuthDigestAlg                : String;
    FAuthDigestStale              : Boolean;
    FAuthDigestBody               : AnsiString;
    FAuthDigestNonceLifeTimeMin   : Cardinal;
    FAuthDigestNonceTimeStamp     : TDateTime;
    FAuthDigestOneTimeFlag        : Boolean;


    FQueue      : TThinBufferQueueThread;
    FRcvBuff    : AnsiString;
    FPacketLen  : LongInt;
    FPacketIdx  : LongInt;
    FBinary     : boolean;

    function GetHandshakeCompleted: Boolean;
    function GetServerIOHandler: TIdIOHandler;
    function GetPeerIP: string;
    procedure FinishWebSocketHandshake;
    procedure ProcessHttpRequest;
    procedure ProcessScript;
    procedure ReceiveFrame;
  {$IFNDEF UNICODE}
    function Compress(Data: AnsiString; Method: byte): AnsiString;
  {$ENDIF}
    procedure ProcessLocalAuthentication(Sender:TObject;var AuthStatus:TAuthStatus;var Error:string);
    function AuthDigestGetParams: Boolean;
    function AuthDigestCheckPassword(const Password: String): Boolean;
    procedure ProcessPacket(JsonText: Ansistring);
    procedure SendBuffer(Text: AnsiString; APacketNumber: Cardinal);
    procedure SendMessage(Text: AnsiString; APacketNumber: Cardinal);
    procedure SetHandshakeResponseSent(const Value: Boolean);
    procedure AuthGetType(ASession:TClientSession; var AuthType:TAuthenticationType;var AuthRealm:string);
    procedure AuthGetPassword(ASession:TClientSession;
                               AUser:string;var Password : String);
    procedure SendBytes(Bytes: TIdBytes);
    procedure SendScreen(Text: AnsiString; APacketNumber: Cardinal);
    procedure ResolveSession(JsonText: Ansistring);
    procedure ProcessAuthentication(Sender: TObject;var Username:string;
      var AuthStatus: TAuthStatus;var Error:string);
    function QueryStringToJson(query: string): string;
    function BinaryToJson(Buffer: AnsiString): AnsiString;
  protected
    const
      FRAME_START = $00;
      FRAME_SIZE_START = $80;
      FRAME_END = $FF;

    procedure ProcessRequest;
    procedure SendFrame(const AData: string);

    property Context:TIdContext read FContext write FContext;
    property ServerIOHandler: TIdIoHandler read GetServerIOHandler;
    property HandshakeCompleted: Boolean read GetHandshakeCompleted;
    property HandshakeResponseSent: Boolean read FHandshakeResponseSent write SetHandshakeResponseSent;
    procedure HandleBinaryIncomingData(Sender: TObject; Item: TThinQueueItem);
    procedure HandleTextIncomingData(Sender: TObject; Item: TThinQueueItem);
  public
    constructor Create(AServer:TWebSocketServer;AContext:TIdContext);
    destructor Destroy;override;
    procedure AssignSession(ASession: TClientSession);
    function  CreateSession(APolled:Boolean):TClientSession;
    procedure SendHttpResponseHeader(Size: Integer;HttpCode:string='');
    procedure SendHttpResponse(value,HttpCode: string);
    procedure ProcessFile(AFilename:string);
    procedure AnswerString(AHttpStatus, AContentType,AHeaders,AContent:AnsiString);
    procedure AnswerPage(AHttpStatus, AHeaders, APage: AnsiString);
    procedure Answer401;
    procedure Answer404;
    procedure Receive;
    property  Session:TClientSession read FSession write FSession;
    property  Request: TWebRequest read FRequest write FRequest;
    property AuthUserName:string read FAuthUserName;
    property AuthRealm:string read FAuthRealm write FAuthRealm;
    property AuthType:TAuthenticationType read FAuthType write FAuthType;

    property OnMessageReceived: TWebSocketMessageEvent read FOnMessageReceived write FOnMessageReceived;
    property PeerIP: string read GetPeerIP;
  end;

  TAuthGetPasswordEvent   = procedure (AConnection:TWebConnection;
                                         var Password : String) of object;
  TAuthGetTypeEvent       = procedure (AConnection:TWebConnection;
                                         var AuthType:TAuthenticationType;
                                         var AuthRealm:string) of object;
  TWebSocketServer = class
  private
    FPort: Integer;
    FTCPServer: TIdTCPServer;
    FProtectedPages : TStrings;
    FConnections: TObjectList;
    FConnLocker: TCriticalSection;
    FOnConnect: TWebSocketConnectEvent;
    FOnMessageReceived: TWebSocketMessageEvent;
    FOnDisconnect: TWebSocketDisconnectEvent;
    FKeyFile: string;
    FRootCertFile: string;
    FCertFile: string;
    FRootPath: string;
    FOnProcessScript: TProcessScriptEvent;
    FOnServerStopped: TNotifyEvent;
    FOnServerStarted: TNotifyEvent;
    FOnAuthGetPassword: TAuthGetPasswordEvent;
    FOnAuthGetType: TAuthGetTypeEvent;
    FAuthDigestServerSecret : TULargeInteger;
    FDefaultPage: string;
    FAuthenticationType: TAuthenticationType;
    FWebSocketsEnabled: Boolean;
    function GetTCPServer: TIdTCPServer;
    function GetConnections: TObjectList;
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);

    procedure AuthGetType(AConnection:TWebConnection);
    procedure AuthGetPassword(AConnection:TWebConnection;
                                         var Password : String);
    function CreateServerSecret: TULargeInteger;
  protected
    procedure TCPServerConnect(AContext:TIdContext);
    procedure TCPServerDisconnect(AContext:TIdContext);
    procedure TCPServerExecute(AContext:TIdContext);
    procedure MessageReceived(AConnection: TWebConnection; const AMessage: string);

    property TCPServer: TIdTCPServer read GetTCPServer;
    property Connections: TObjectList read GetConnections;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Broadcast(AMessage: string);
    property ProtectedPages:TStrings read FProtectedPages;
    property WebSocketsEnabled:Boolean read FWebSocketsEnabled write FWebSocketsEnabled;
    property OnAuthGetPassword:TAuthGetPasswordEvent read FOnAuthGetPassword write FOnAuthGetPassword;
    property OnAuthGetType:TAuthGetTypeEvent read FOnAuthGetType write FOnAuthGetType;
    property OnProcessScript:TProcessScriptEvent read FOnProcessScript write FOnProcessScript;
    property Port:Integer read FPort write FPort;
    property RootPath:string read FRootPath write FRootPath;
    property DefaultPage:string read FDefaultPage write FDefaultPage;
    property RootCertFile : string read FRootCertFile write FRootCertFile;
    property CertFile : string read FCertFile write FCertFile;
    property KeyFile : string read FKeyFile write FKeyFile;
    property Active: Boolean read GetActive write SetActive;
    property AuthenticationType:TAuthenticationType read FAuthenticationType write FAuthenticationType;
    property OnConnect: TWebSocketConnectEvent read FOnConnect write FOnConnect;
    property OnMessageReceived: TWebSocketMessageEvent read FOnMessageReceived write FOnMessageReceived;
    property OnDisconnect: TWebSocketDisconnectEvent read FOnDisconnect write FOnDisconnect;
    property OnServerStarted: TNotifyEvent read FOnServerStarted  write FOnServerStarted;
    property OnServerStopped: TNotifyEvent read FOnServerStopped  write FOnServerStopped;
  end;

implementation

uses
  Masks;

{ TWebSocketServer }

constructor TWebSocketServer.Create;
begin
  FPort := 80;
  FRootPath := GetModulePath;
  FDefaultPage := 'index.html';
  FAuthDigestServerSecret := CreateServerSecret;
  FConnLocker := TCriticalSection.Create;
  FWebSocketsEnabled := true;
  FProtectedPages := TStringList.Create;
end;

destructor TWebSocketServer.Destroy;
begin
  // Cleanup
  try
    TCPServer.Active := False;
  except
  end;
  TCPServer.Free;
  FreeAndNil(FConnLocker);
  FreeAndNil(FConnections);  
  FreeAndNil(FProtectedPages);
  inherited;
end;

procedure TWebSocketServer.MessageReceived(AConnection: TWebConnection; const AMessage: string);
begin
  if Assigned(OnMessageReceived) and (AConnection.HandshakeCompleted) then
  begin
    OnMessageReceived(AConnection, AMessage);
  end;
end;

procedure TWebSocketServer.AuthGetPassword(AConnection: TWebConnection;
  var Password: String);
begin
  if Assigned(OnAuthGetPassword) then
    OnAuthGetPassword(AConnection,Password); 
end;

function TWebSocketServer.CreateServerSecret: TULargeInteger;
begin
  Result.LowPart  := Random(MaxInt);
  Result.HighPart := Random(MaxInt);
end;

procedure TWebSocketServer.AuthGetType(AConnection: TWebConnection);
begin
  if AConnection.FAuthType=atNone then
    AConnection.FAuthType:=FAuthenticationType;
  AConnection.FAuthRealm:='ThinVNC';
  if Assigned(OnAuthGetType) then
    OnAuthGetType(AConnection,AConnection.FAuthType,AConnection.FAuthRealm);
end;

procedure TWebSocketServer.Broadcast(AMessage: string);
var
  ConnectionPtr: Pointer;
  Connection: TWebConnection;
begin
  for ConnectionPtr in Connections do
  begin
    Connection := ConnectionPtr;
    if Connection.HandshakeCompleted then
    begin
      Connection.SendFrame(AMessage);
    end;
  end;
end;

function TWebSocketServer.GetActive: Boolean;
begin
  Result := TCPServer.Active;
end;

function TWebSocketServer.GetConnections: TObjectList;
begin
  FConnLocker.Enter;
  try
    if not Assigned(FConnections) then
    begin
      FConnections := TObjectList.Create(False);
    end;
  finally
    FConnLocker.Leave;
  end;
  Result := FConnections;
end;


function TWebSocketServer.GetTCPServer: TIdTCPServer;
begin
  if not Assigned(FTCPServer) then
  begin
    FTCPServer := TIdTCPServer.Create(nil);

    // Events
    FTCPServer.OnConnect := TCPServerConnect;
    FTCPServer.OnDisconnect := TCPServerDisconnect;
    FTCPServer.OnExecute := TCPServerExecute;
  end;

  Result := FTCPServer;
end;

procedure TWebSocketServer.SetActive(const Value: Boolean);
var
  Log: ILogger;
begin
  Log := TLogger.Create(Self, Format('SetActive(Value=%s)', [BoolToStr(Value, True)]));
  if TCPServer.Active <> Value then
  try
    if Value then
    begin
      Log.LogDebug('Deleting TCPServer.Bindings...');
      TCPServer.Bindings.Clear;
      FTCPServer.DefaultPort := Port;
    end;
    TCPServer.TerminateWaitTime:=100;
    Log.LogDebug('Changing TCPServer.Active...');
    try
      TCPServer.Active := Value;
    except
    end;
    Log.LogDebug('TCPServer.Active has changed.');
    if TCPServer.Active and Assigned(OnServerStarted) then
      OnServerStarted(self)
    else if not TCPServer.Active and Assigned(OnServerStopped) then
      OnServerStopped(self);
    if not value then Cleanup;
  except
  end;
end;

procedure TWebSocketServer.TCPServerConnect(AContext:TIdContext);
var
  Connection: TWebConnection;
begin
  Connection := TWebConnection.Create(Self,AContext);
  Connection.OnMessageReceived := MessageReceived;
  //frm_principal.memo2.Lines.Add(inttostr(FTCPServer.DefaultPort));

  FConnLocker.Enter;
  try
    Connections.Add(Connection);
  finally
    FConnLocker.Leave;
  end;
  AContext.Data := Connection;

  if Assigned(OnConnect) then
  begin
    OnConnect(Connection);

  end;

end;

procedure TWebSocketServer.TCPServerDisconnect(AContext:TIdContext);
var
  Connection: TWebConnection;
begin
  Connection := AContext.Data as TWebConnection;
  if AContext.Data=nil then exit;

  if Assigned(OnDisconnect) then
  begin
    OnDisconnect(Connection);
  end;

  AContext.Data := nil;
  FConnLocker.Enter;
  try
    Connections.Remove(Connection);
  finally
    FConnLocker.Leave;
  end;
  Connection.Free;
end;

procedure TWebSocketServer.TCPServerExecute(AContext:TIdContext);
var
  Client: TWebConnection;
  msg:string;
begin
  Client := AContext.Data as TWebConnection;
  Client.Receive;

end;

{ TWebConnection }

constructor TWebConnection.Create(AServer:TWebSocketServer;AContext:TIdContext);
begin
  HandshakeResponseSent := False;
  Context := AContext;
  FServer := AServer;
  TIdIOHandlerSocket(ServerIOHandler).UseNagle:=false;
  ServerIOHandler.ReadTimeout:=IdTimeoutInfinite;
  FCustomResponseHeaders := TStringList.Create;
  FAuthDigestStale := False;
  FAuthDigestNonceLifeTimeMin := 1;
  FMethod:='GET';
  FQueue := TThinBufferQueueThread.Create;
  FQueue.OnProcess := HandleBinaryIncomingData;
end;

destructor TWebConnection.Destroy;
var
  Log : ILogger;
begin
  Log := TLogger.Create(Self,'Destroy');
  Log.LogInfo(Format('Session:$%.4x',[Integer(FSession)]));

  if Assigned(FSession) and HandshakeCompleted then
    FSession.SetGarbage;

  
  if FQueue <> nil then
  begin
    FQueue.Terminate;
    FQueue := nil;
  end;
  FreeAndNil(FCustomResponseHeaders);
  FRequest.Free;
  inherited;
end;


function TWebConnection.AuthDigestGetParams: Boolean;
var
  RequestAuth : string;
begin
  RequestAuth := Request.GetHeaderValue('Authorization');
  Result := AuthDigestGetRequest(RequestAuth, FAuthDigestNonceTimeStamp,
                   FAuthUserName, FAuthDigestRealm, FAuthDigestQop,
                   FAuthDigestAlg, FAuthDigestNonce, FAuthDigestNc,
                   FAuthDigestUri, FAuthDigestCnonce, FAuthDigestOpaque,
                   FAuthDigestResponse);
end;

procedure TWebConnection.AuthGetPassword(ASession: TClientSession;
  AUser: string; var Password: String);
begin
  FAuthUserName:=AUser;
  if Assigned(FServer.OnAuthGetPassword) then
    FServer.OnAuthGetPassword(Self,Password);
end;

procedure TWebConnection.AuthGetType(ASession: TClientSession;
  var AuthType: TAuthenticationType; var AuthRealm: string);
begin
  if Assigned(FServer.OnAuthGetType) then
    FServer.OnAuthGetType(Self,AuthType,AuthRealm);
end;

function TWebConnection.AuthDigestCheckPassword(const Password: String): Boolean;
var
    SessKey      : THashHex;
    MyResponse   : THashHex;
    HEntity      : THashHex;
    NonceLifeTime: Cardinal;
begin
    if Password = '' then begin
        Result := FALSE;
        Exit;
    end;
    AuthDigestCalcHA1(FAuthDigestAlg, AnsiString(FAuthUserName),
                      AnsiString(FAuthDigestRealm), AnsiString(Password),
                      AnsiString(FAuthDigestNonce), AnsiString(FAuthDigestCnonce),
                      SessKey);

    AuthDigestGetBodyHash(FAuthDigestBody, HEntity);
    AuthDigestCalcResponse(SessKey, AnsiString(FAuthDigestNonce),
                           AnsiString(FAuthDigestNc),
                           AnsiString(FAuthDigestCnonce),
                           AnsiString(FAuthDigestQop), AnsiString(FMethod),
                           AnsiString(FAuthDigestUri), HEntity, MyResponse);
    Result := SameText(AnsiString(FAuthDigestResponse), MyResponse);

    if Result then begin
        { Check whether we have to force a new nonce in which case we set    }
        { FAuthDigestStale to TRUE which avoids popping up a login dialog at }
        { the client side. }
        if FAuthDigestOneTimeFlag then
            NonceLifeTime := 2
            { Grant the user two minutes to be able to enter login manually  }
            { if FAuthDigestNonceLifeTimeMin equals zero = one-timer nonce. }
        else
            NonceLifeTime := FAuthDigestNonceLifeTimeMin;

        if (((FAuthDigestNonceTimeStamp * 1440) + NonceLifeTime) / 1440) < Now then
        begin
            { The nonce is stale, respond a 401 }
            FAuthDigestStale := TRUE;
            Result := FALSE;
        end;
     end;
end;

procedure TWebConnection.ProcessAuthentication(Sender:TObject;var Username:string;var AuthStatus:TAuthStatus;var Error:string);
begin
  if TClientSession(Sender).IsLocal then
    ProcessLocalAuthentication(Sender,AuthStatus,Error)
  ;
  Username:=AuthUserName;
end;


procedure TWebConnection.ProcessLocalAuthentication(Sender:TObject;var AuthStatus:TAuthStatus;var Error:string);
var
  Body,Header : string;
  PasswdBuf : string;
  Authenticated : Boolean;
  RequestAuth : string;
begin
  FServer.AuthGetType(Self);

  Error:='';

  Authenticated:=False;
  AuthStatus:=asAuthRequired;
  if (FAuthType = atNone) then AuthStatus:=asAuthNotRequired
  else if Authenticated then AuthStatus:=asAuthenticated;

  if AuthStatus<>asAuthRequired then exit;

  if AuthType = atDigest then begin
    FAuthDigestBody := '';
    Authenticated := AuthDigestGetParams;
    if Authenticated then begin
      PasswdBuf := '';
      FServer.AuthGetPassword(Self,PasswdBuf);
      Authenticated := AuthDigestCheckPassword(PasswdBuf);
      if Authenticated then
        AuthStatus:=asAuthenticated;
    end;
    FAuthDigestOneTimeFlag := FALSE;
  end;

  if AuthStatus=asAuthRequired then begin
    Body := '<HTML><HEAD><TITLE>401 Access Denied</TITLE></HEAD>' +
          '<BODY><H1>401 Access Denied</H1>The requested URL ' + Request.FPath +
          ' requires authorization.<P></BODY></HTML>' + #13#10;
    if AuthType = atDigest then begin
      FAuthDigestServerNonce  := '';
      FAuthDigestServerOpaque := '';
      Header := Header + 'WWW-Authenticate: Digest ' +
                AuthDigestGenerateChallenge(
                                  daAuth,
                                  FServer.FAuthDigestServerSecret,
                                  FAuthRealm, '', FAuthDigestStale,
                                  FAuthDigestServerNonce,
                                  FAuthDigestServerOpaque) + #13#10;
    end;

    Error:='401 Access Denied';
    AnswerString('401 Access Denied','',Header,Body);
  end else Error:='';
end;


procedure TWebConnection.Receive;
begin
    try
      if HandshakeCompleted then ReceiveFrame
      else ProcessRequest
    Except
      Context.Connection.Disconnect;
      ServerIOHandler.InputBuffer.Clear;
    end;
end;

procedure TWebConnection.SendBuffer(Text: AnsiString; APacketNumber: Cardinal);
var
  Log : Ilogger;
begin
  Log := TLogger.Create(Self,'SendBuffer');
  ServerIOHandler.Write(FormatSendBuffer(Text,fbBinary,APacketNumber));
end;

procedure TWebConnection.SendMessage(Text: AnsiString; APacketNumber: Cardinal);
var
  Log : Ilogger;
begin
  Log := TLogger.Create(Self,'SendMessage');
  ServerIOHandler.Write(FormatSendBuffer(Text,fbJson,APacketNumber));
end;

procedure TWebConnection.SetHandshakeResponseSent(const Value: Boolean);
begin
  if FHandshakeResponseSent = Value then exit;
  
  FHandshakeResponseSent := Value;
end;

function TWebConnection.GetServerIOHandler: TIdIoHandler;
begin
  Result := Context.Connection.IOHandler;
end;

function TWebConnection.BinaryToJson(Buffer:AnsiString):AnsiString;
var
  Header : TMsgHeader;
begin
  result:='';
  if Length(Buffer) = 0 then Exit;
  Move(Buffer[1],Header,SizeOf(Header));
  SetLength(result,Length(Buffer)-SizeOf(Header));
  Move(Buffer[SizeOf(Header)+1],result[1],Length(Buffer)-SizeOf(Header));
  if Header.Compressed>0 then
    result:=ZDecompressStr(result);
end;

procedure TWebConnection.HandleBinaryIncomingData(Sender: TObject;
  Item: TThinQueueItem);
var
  Header : TMsgHeader;
begin
  if Item.Length = 0 then Exit;
  ProcessPacket(BinaryToJson(Item.Buffer));
end;

procedure TWebConnection.HandleTextIncomingData(Sender: TObject;
  Item: TThinQueueItem);
begin
  ProcessPacket(QueryStringToJson(Item.Buffer));
end;


procedure TWebConnection.ProcessPacket(JsonText: Ansistring);
begin
  if not assigned(FSession) then
    ResolveSession(JsonText)
  else if not TClientSession.IsValid(FSession) then
    FSession:=nil;

  if not Assigned(FSession) {or (FSession.AuthenticationStatus=asAuthRequired) }then begin
    Context.Connection.Disconnect;
    exit;
  end;

  FSession.ProcessPacket(JsonText);
end;

function TWebConnection.CreateSession(APolled:Boolean): TClientSession;
begin
  AssignSession(ClientSessionClass.Create(APolled));
  FSession.OnAuthGetType:=AuthGetType;
  FSession.OnAuthGetPassword:=AuthGetPassword;
  FSession.OnProcessAuthentication:=ProcessAuthentication;
  result:=FSession;
end;

procedure TWebConnection.AssignSession(ASession:TClientSession);
begin
  FSession := ASession;
  FSession.OnAuthGetType:=AuthGetType;
  FSession.OnAuthGetPassword:=AuthGetPassword;
  FSession.OnProcessAuthentication:=ProcessAuthentication;
end;

procedure TWebConnection.ResolveSession(JsonText: Ansistring);
var
  jsObj:TlkJSONobject;
  id : Integer;
  Log : ILogger;
begin
  Log := TLogger.Create(Self,'ResolveSession');

  jsObj:=TlkJSON.ParseText(JsonText) as TlkJSONobject;
  if not Assigned(jsObj) then exit;
  try
    if jsObj.IndexOfName('id') < 0 then exit;
    FSession:=GetClientSession(jsObj.Field['id'].Value);
    if FSession=nil then Exit;//FSession := ClientSessionClass.Create;
    if HandshakeCompleted then begin
      FSession.Polled:=false;
      if FBinary then begin
        FQueue.OnProcess := HandleBinaryIncomingData;
        FSession.OnSendCmd:=SendMessage;
        FSession.OnSendScreen:=SendMessage;
        FSession.OnSendBuf:=SendBuffer;
      end else begin
        FQueue.OnProcess := HandleTextIncomingData;
        FSession.OnSendCmd:=SendScreen;
        FSession.OnSendScreen:=SendScreen;
        FSession.OnSendBuf:=SendScreen;
      end;
        end;
  finally
    FreeAndNil(jsObj);
  end;
end;

function TWebConnection.GetHandshakeCompleted: Boolean;
begin
  Result := HandshakeResponseSent;
end;

function TWebConnection.GetPeerIP: string;
begin
  Result := Context.Connection.Socket.Binding.PeerIP;
end;

procedure TWebConnection.ProcessRequest;
begin
  // Read request headers
  if Request=nil then
    Request := TWebRequest.Create(Self);
  Request.GetHttpRequest;

  if Request.FIsWebSocketRequest then FinishWebSocketHandshake
  else ProcessHttpRequest;
end;

procedure TWebConnection.ProcessHttpRequest;
var
  Body,Header,Error,Path : string;
  AuthStatus : TAuthStatus;
  n: Integer;
begin
  FContentType := 'text/html';

  path:=Request.Path;
  if path='' then path:=FServer.DefaultPage;

  for n := 0 to FServer.FProtectedPages.Count - 1 do
    if SameText(Path,FServer.FProtectedPages[n]) then begin
      ProcessLocalAuthentication(nil,AuthStatus,Error);
      if AuthStatus=asAuthRequired then exit
      else break;
    end;

  if (((Request.Path='') and (FServer.DefaultPage<>'')) or (ExtractFileExt(Request.Path)<>'')) then ProcessFile(FServer.RootPath+FRequest.Path)
  else ProcessScript;
end;

procedure TWebConnection.ProcessScript;
begin
  if assigned(FServer.OnProcessScript) then
    FServer.OnProcessScript(Self);
end;

procedure TWebConnection.Answer404;
var
  Body : String;
begin
  Body := '<HTML><HEAD><TITLE>404 Not Found</TITLE></HEAD>' +
          '<BODY><H1>404 Not Found</H1>The requested URL ' +
          Request.FResource +
          ' was not found on this server.<P></BODY></HTML>' + #13#10;
  SendHttpResponse(Body,'404 Not Found');
end;

procedure TWebConnection.Answer401;
var
  Body : String;
begin
  Body := '<HTML><HEAD><TITLE>401 Access Denied</TITLE></HEAD>' +
          '<BODY><H1>401 Access Denied</H1>The requested URL ' + Request.FPath +
          ' requires authorization.<P></BODY></HTML>' + #13#10;
  SendHttpResponse(Body,'404 Not Found');
end;

{$IFNDEF UNICODE}
function TWebConnection.Compress(Data:AnsiString;Method:byte):AnsiString;
var
  Compressor : TIdCompressorZLibEx;
  MsIn,MsOut : TMemoryStream;
begin
  Compressor := TIdCompressorZLibEx.Create;
  try
    MsIn:=TMemoryStream.Create;
    try
      MsOut:=TMemoryStream.Create;
      try
        MsIn.Write(Data[1],Length(Data));
        MsIn.Seek(0,0);
        if Method=0 then
          Compressor.CompressHTTPDeflate(MsIn,MsOut,9)
        else Compressor.DecompressGZipStream(MsIn,MsOut);
        SetLength(result,MsOut.Size);
        MsOut.Seek(0,0);
        MsOut.Read(result[1],MsOut.Size);
      finally
        MsOut.Free;
      end;
    finally
      MsIn.Free;
    end;
  finally
    Compressor.Free;
  end;
end;
{$ENDIF}

procedure TWebConnection.AnswerString(AHttpStatus, AContentType,AHeaders,
  AContent: AnsiString);
var
  ContentEncoding : string;
begin
  FContentType:=AContentType;
  if AContentType='' then FContentType:='text/html';
  
  FCustomResponseHeaders.Text := AHeaders;
  if (Length(AContent)>200) then begin
    ContentEncoding:=Request.GetHeaderValue('Accept-Encoding');
    {$IFNDEF UNICODE}
    if Pos('deflate',ContentEncoding)>0 then begin
      FCustomResponseHeaders.Add('Content-Encoding: deflate');
      AContent:=Compress(AContent,0);
    end else if Pos('gzip',ContentEncoding)>0 then begin
      FCustomResponseHeaders.Add('Content-Encoding: gzip');
      AContent:=Compress(AContent,1);
    end;
    {$ENDIF}
  end;

  SendHttpResponse(AContent,AHttpStatus);
end;

procedure TWebConnection.AnswerPage(AHttpStatus, AHeaders, APage: AnsiString);
begin
  FCustomResponseHeaders.Text := AHeaders;
  ProcessFile(FServer.RootPath+APage);
end;

procedure TWebConnection.ProcessFile(AFilename:string);
  function GetContentType(AFilename:string):string;
  var
    Ext : String;
  begin
    { We probably should use the registry to find MIME type for file types }
    Ext := LowerCase(ExtractFileExt(AFilename));
    if Length(Ext) > 1 then
        Ext := Copy(Ext, 2, Length(Ext));
    if (Ext = 'htm') or (Ext = 'html') then
        Result := 'text/html'
    else if Ext = 'gif' then
        Result := 'image/gif'
    else if Ext = 'bmp' then
        Result := 'image/bmp'
    else if (Ext = 'jpg') or (Ext = 'jpeg') then
        Result := 'image/jpeg'
    else if Ext = 'txt' then
        Result := 'text/plain'
    else if Ext = 'css' then
        Result := 'text/css'
    else if Ext = 'ico' then
        Result := 'image/x-icon'
    else if Ext = 'js' then
        Result := 'text/javascript'
    else if Ext = 'pdf' then
        Result := 'application/pdf'
    else if Ext = 'png' then
        Result := 'image/png'
    else if Ext = 'xml' then
        Result := 'application/xml'
    else
        Result := 'application/binary';
  end;

var
  ms : TMemoryStream;
  LStream : TFileStream;
  ext : string;
begin
  try
    ext:=ExtractFileExt(AFilename);
    if ext='' then begin
      if AFilename<>'' then AFilename:=IncludeTrailingBackSlash(AFilename);
      AFilename:=AFilename+FServer.FDefaultPage;
    end;

    if (AFilename<>'') and (Pos(':',AFilename)=0) and (AFilename[1]<>'\') then
      AFilename:=GetMOdulePath+AFilename;
    LStream := TFileStream.Create(AFilename,fmOpenRead);
    try
      FContentType := GetContentType(AFilename);
      SendHttpResponseHeader(LStream.Size);
      ServerIOHandler.Write(LStream);
    finally
      FreeAndNil(LStream);
    end;
  except
    Answer404;
  end;
end;

procedure TWebConnection.SendHttpResponseHeader(Size:Integer;HttpCode:string);
var
  Header : string;
begin
  if HttpCode='' then HttpCode:='200';
  
  Header := 'HTTP/1.1' + ' '+HttpCode + #13#10;
  Header := Header + 'Content-Type: ' +FContentType+ #13#10 +
            'Content-Length: ' + IntToStr(Size) + #13#10;
  Header := Header + 'Connection: Keep-Alive' + #13#10;
  if FCustomResponseHeaders.Count>0 then
    Header := Header+FCustomResponseHeaders.Text;
  Header := Header + #13#10;
  ServerIOHandler.Write(Header);
  FCustomResponseHeaders.Clear;
end;

procedure TWebConnection.SendBytes(Bytes:TIdBytes);
begin
  ServerIOHandler.Write(Bytes);
end;

procedure TWebConnection.SendHttpResponse(value,HttpCode:string);
begin
  SendHttpResponseHeader(Length(Value),HttpCode);
  ServerIOHandler.Write(value);

  if Request.GetHeaderValue('Connection')='close' then
    Context.Connection.Disconnect;
end;

// WebSockets

procedure TWebConnection.SendScreen(Text:AnsiString;APacketNumber:Cardinal);
begin
  SendFrame(Text);
end;

function TWebConnection.QueryStringToJson(query:string):string;
  function StringForJson(Value: string): string;
  var I: Integer;
  begin
    Result := '';
    for I := 1 to Length(Value) do
    begin
      case Value[I] of
        '/', '\', '"': Result := Result + '\' + Value[I];
         #8: Result := Result + '\b';
         #9: Result := Result + '\t';
        #10: Result := Result + '\n';
        #13: Result := Result + '\r';
        #12: Result := Result + '\f';
        #00..#07,#11,#14..#19: Result := Result + '\u' + IntToHex(Ord(Value[I]), 4);
        else Result := Result + Value[I];
      end;
    end;
  end;
var
  n : Integer;
  ParamName, ParamValue: string;
  QueryFields : TWebDataFields;
begin
  QueryFields:=TWebDataFields.Create(Query);
  try
    result:='';
    for n := 0 to QueryFields.Count - 1 do begin
      ParamName := StringForJson(QueryFields.Names[n]);
      ParamValue := StringForJson(QueryFields.ValueFromIndex[n]);
      if result<>'' then result:=result+', ';
      result:=result+Format('"%s":"%s"',[ParamName, ParamValue]);
    end;
  finally
    QueryFields.Free;
  end;
  result:='{'+result+'}';
end;

procedure TWebConnection.ReceiveFrame;

var
  FirstChar: Byte;
  Msg: string;
  NumBytes : Integer;
  buf : TIdBytes;
  sbuf : AnsiString;
  ms : TMemoryStream;
  Log : ILogger;
begin
  Log := TLogger.Create(Self,'ReceiveFrame');
  Msg := '';



  while true do begin
    // Read new frame
    {$IFDEF UNICODE}
    FirstChar := ServerIOHandler.ReadByte;
    {$ELSE}
    FirstChar := Byte(ServerIOHandler.ReadChar);
    {$ENDIF}
    case FirstChar of
      FRAME_START: begin
    {$IFDEF UNICODE}
        Msg := ServerIOHandler.ReadLn(AnsiChar(FRAME_END),Indy8BitEncoding);
    {$ELSE}
        Msg := ServerIOHandler.ReadLn(AnsiChar(FRAME_END));
    {$ENDIF}
        FBinary:=False;
        if FSession=nil then
          ResolveSession(QueryStringToJson(Msg));

        if FSession=nil then begin
          Context.Connection.Disconnect;
          exit;
        end;

        FQueue.AddBuffer(Msg);
//        FSession.ProcessPacket(QueryStringToJson(Msg));
      end;
      FRAME_SIZE_START: begin
        FBinary:=True;
        ms := TMemoryStream.Create;
        try
          ServerIOHandler.ReadStream(ms);
          SetLength(sbuf,ms.Size);
          move(ms.Memory^,sbuf[1],ms.Size);

          if FSession=nil then
            ResolveSession(BinaryToJson(sbuf));

          if FSession=nil then begin
            Context.Connection.Disconnect;
            exit;
          end;

          FQueue.AddBuffer(sbuf);
        finally
          ms.free;
        end;
      end;
    else
      raise Exception.Create('Invalid frame start!');
    end;
  end;
  FQueue.Clear;
end;

procedure TWebConnection.FinishWebSocketHandshake;
var
  Sec : string;
begin
  try
    Sec:='';
    if Request.FVersion=wsVer76 then Sec:='Sec-';

    // Send response headers
    if not FServer.FWebSocketsEnabled then begin
      ServerIOHandler.WriteLn('HTTP/1.1 403');
      exit;
    end;

    ServerIOHandler.WriteLn('HTTP/1.1 101 Web Socket Protocol Handshake');
    ServerIOHandler.WriteLn('Upgrade: WebSocket');
    ServerIOHandler.WriteLn('Connection: Upgrade');
    ServerIOHandler.WriteLn(Sec+'WebSocket-Origin: ' + Request.GetHeaderValue('Origin'));
    ServerIOHandler.WriteLn(Sec+'WebSocket-Location: ' + Request.FScheme+'://' + Request.GetHeaderValue('Host') + '/');
    ServerIOHandler.WriteLn(Sec+'WebSocket-Protocol: ' + Request.GetHeaderValue(Sec+'WebSocket-Protocol'));

    // End handshake
    ServerIOHandler.WriteLn;
    if Request.FVersion=wsVer76 then
      ServerIOHandler.Write(Request.GenMD5)
    else ServerIOHandler.WriteLn;

    HandshakeResponseSent := True;
  except
    on E: TWebSocketHandshakeException do
    begin
      // Close the connection if the handshake failed
      Context.Connection.Disconnect;
    end;
  end;
end;

procedure TWebConnection.SendFrame(const AData: string);
begin
  if AData <> '' then
  begin
    if Assigned(Context) and Assigned(Context.Connection) and
      Assigned(Context.Connection.IOHandler) and
      not (csDestroying in Context.Connection.IOHandler.ComponentState) then
    {$IFDEF UNICODE}
    ServerIOHandler.Write(Char(FRAME_START) + AData + Char(FRAME_END),Indy8BitEncoding);
    {$ELSE}
    ServerIOHandler.Write(Char(FRAME_START) + AData + Char(FRAME_END));
    {$ENDIF}
  end;
end;

{ TWebRequest }

constructor TWebRequest.Create(AWebConnection: TWebConnection);
begin
  FWebConnection:=AWebConnection;
  FConnection:=AWebConnection.Context.Connection;

  FWebRequestHeaders := TObjectList.Create;
  FWebSocketHeaders := TObjectList.Create;
end;

destructor TWebRequest.Destroy;
begin
  FreeAndNil(FCookieFields);
  FreeAndNil(FQueryFields);
  FreeAndNil(FPostFields);
  FreeAndnil(FWebRequestHeaders);
  FreeAndnil(FWebSocketHeaders);
  inherited;
end;

procedure TWebRequest.GetHttpRequest;
var
  Msg: string;
  WebSocketHeaderFound : boolean;
  n,idx : Integer;
  ContentLength: string;
  aux : ansistring;
  buf : TIdBytes;
begin
  FWebRequestHeaders.Clear;
  FWebSocketHeaders.Clear;
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Upgrade','WebSocket',[wsVer75,wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Connection','Upgrade',[wsVer75,wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Host','*',[wsVer75,wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Origin','*',[wsVer75,wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Sec-WebSocket-Key1','*',[wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Sec-WebSocket-Key2','*',[wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Sec-WebSocket-Key3','*',[wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('Sec-WebSocket-Protocol','*',[wsVer76]));
  FWebSocketHeaders.Add(TWebSocketHeader.Create('WebSocket-Protocol','*',[wsVer75]));

  FWebMethod := wmNone;
  //    GET /demo HTTP/1.1
  Msg := FConnection.IOHandler.ReadLn();
  if MatchesMask(Msg, 'GET /* HTTP/1.*') then
    FWebMethod := wmGet
  else if MatchesMask(Msg, 'POST /* HTTP/1.*') then
    FWebMethod := wmPost
  else if (Msg='<policy-file-request/>') then begin
    FConnection.IOHandler.Write(policy_response);
    exit;
  end;
  if FWebMethod = wmNone then
    LogError('Unknown method for requested URL: ' + Msg);
  Assert(FWebMethod <> wmNone);

  FreeAndNil(FQueryFields);
  FreeAndNil(FPostFields);
  FreeAndNil(FCookieFields);

  if FWebMethod = wmGet then
    FResource := Copy(Msg, 6, Length(Msg) - 14) else
    FResource := Copy(Msg, 7, Length(Msg) - 15);
  FPath:=FResource;
  FQuery:='';
  FPostData := '';
  Idx:=Pos('?',FResource);
  if Idx>0 then begin
    FQuery:=Copy(FResource,idx+1,Length(FResource));
    FPath :=Copy(FResource,1,idx-1);
  end;

  Msg:='*';
  while Msg<>'' do begin
    WebSocketHeaderFound := true;
    //    Upgrade: WebSocket
    Msg := FConnection.IOHandler.ReadLn();
    if Msg<>'' then begin
      for n := 0 to FWebSocketHeaders.Count - 1 do begin
        WebSocketHeaderFound:=TWebSocketHeader(FWebSocketHeaders[n]).MatchAndFill(Msg);
        if WebSocketHeaderFound then break;
      end;

      if not WebSocketHeaderFound then
        FWebRequestHeaders.Add(TWebRequestHeader.Create(Msg));
    end;
  end;

  if FWebMethod = wmPost then
  begin
    ContentLength := GetHeaderValue('Content-Length');
    Assert(ContentLength <> '');
    FPostData := FConnection.IOHandler.ReadString(StrToInt(ContentLength));
  end;

  FIsWebSocketRequest:=TWebSocketHeader(FWebSocketHeaders[0]).FExists;
  if FIsWebSocketRequest then begin
    FVersion:=wsVer75;
    if GetHeaderValue('Sec-WebSocket-Key1')<>'*' then FVersion:=wsVer76;

    if FVersion=wsVer76 then begin
{$IFDEF UNICODE}
      FConnection.IOHandler.ReadBytes(buf,8);
      SetLength(aux,8);
      move(buf[0],aux[1],8);
{$ELSE}
      aux:=FConnection.IOHandler.ReadString(FConnection.IOHandler.InputBuffer.Size);
{$ENDIF}
      SetHeaderValue('Sec-WebSocket-Key3',aux);
      if GetHeaderValue('Sec-WebSocket-Protocol')='*' then
        SetHeaderValue('Sec-WebSocket-Protocol','Sample');
    end else
      if GetHeaderValue('WebSocket-Protocol')='*' then
        SetHeaderValue('WebSocket-Protocol','Sample');

    for n := 0 to FWebSocketHeaders.Count - 1 do begin
      if (FVersion in TWebSocketHeader(FWebSocketHeaders[n]).FVersions) and
        not TWebSocketHeader(FWebSocketHeaders[n]).FExists then
        raise TWebSocketHandshakeException.Create('');
    end;
  end;

  FScheme:=IfThen(FIsWebSocketRequest,'ws','http');
end;

function TWebRequest.GetIsBinaryPost: Boolean;
var
  ContentType: string;
begin
  ContentType := GetHeaderValue('Content-Type');
  Result := (FWebMethod = wmPost) and (Pos('application/x-www-form-urlencoded', ContentType) <= 0);
end;

function TWebRequest.GetPostFields: TWebDataFields;
var
  n : Integer;
begin
  if not Assigned(FPostFields) then
  begin
    if IsBinaryPost then
      FPostFields:=TWebDataFields.Create('') else
      FPostFields:=TWebDataFields.Create(FPostData);
  end;
  result:=FPostFields;
end;

function TWebRequest.GetQueryFields: TWebDataFields;
var
  n : Integer;
begin
  if not Assigned(FQueryFields) then
    FQueryFields:=TWebDataFields.Create(FQuery);
  result:=FQueryFields;
end;

function TWebRequest.GetBinaryData: string;
begin
  if IsBinaryPost then
    Result := FPostData else
    Result := '';
end;

function TWebRequest.GetCookieFields: TStrings;
begin
  if not Assigned(FCookieFields) then begin
    FCookieFields:=TStringList.Create;
    FCookieFields.Text:=StringReplace(GetHeaderValue('Cookie'),';',#13#10,[rfReplaceAll]);
  end;
  result:=FCookieFields;
end;

function TWebRequest.GetHeaderValue(Header:string):string;
var
  n : Integer;
begin
  result:='';
  for n := 0 to FWebRequestHeaders.Count - 1 do
    if SameText(TWebRequestHeader(FWebRequestHeaders[n]).FName,Header) then begin
      result:= TWebRequestHeader(FWebRequestHeaders[n]).FValue;
      exit;
    end;
  for n := 0 to FWebSocketHeaders.Count - 1 do
    if SameText(TWebSocketHeader(FWebSocketHeaders[n]).FName,Header) then begin
      result:= TWebSocketHeader(FWebSocketHeaders[n]).FValue;
      exit;
    end;
end;

procedure TWebRequest.SetHeaderValue(Header,Value:string);
var
  n : Integer;
begin
  for n := 0 to FWebSocketHeaders.Count - 1 do
    if TWebSocketHeader(FWebSocketHeaders[n]).FName=Header then begin
      TWebSocketHeader(FWebSocketHeaders[n]).FValue:=Value;
      TWebSocketHeader(FWebSocketHeaders[n]).FExists:=true;
      exit;
    end;
  for n := 0 to FWebRequestHeaders.Count - 1 do
    if TWebRequestHeader(FWebRequestHeaders[n]).FName=Header then begin
      TWebRequestHeader(FWebRequestHeaders[n]).FValue:=Value;
      exit;
    end;
end;

function TWebRequest.GenMd5:TIdBytes;
var
  i, spaces1,spaces2 : Integer;
  num1,num2 : cardinal;
  buf : TByteDynArray;
  MDigest: IMD5;
  SecWebSocketKey1,SecWebSocketKey2,SecWebSocketKey3 : AnsiString;
begin
  SecWebSocketKey1:=GetHeaderValue('Sec-WebSocket-Key1');
  SecWebSocketKey2:=GetHeaderValue('Sec-WebSocket-Key2');
  SecWebSocketKey3:=GetHeaderValue('Sec-WebSocket-Key3');

  spaces1:=0;
  num1:=0;
  for i:=1 to Length(SecWebSocketKey1) do begin
    if (SecWebSocketKey1[i] = ' ') then Inc(spaces1,1);
    if (SecWebSocketKey1[i] >= #48) and (SecWebSocketKey1[i] <= #57) then
      num1 := num1 * 10 + (Ord(SecWebSocketKey1[i]) - 48);
  end;
  num1 := num1 div spaces1;

  spaces2:=0;
  num2:=0;
  for i:=1 to Length(SecWebSocketKey2) do begin
    if (SecWebSocketKey2[i] = ' ') then Inc(spaces2,1);
    if (SecWebSocketKey2[i] >= #48) and (SecWebSocketKey2[i] <= #57) then
      num2 := num2 * 10 + (Ord(SecWebSocketKey2[i]) - 48);
  end;
  num2 := num2 div spaces2;

  SetLength(buf,17);
  // Pack it big-endian
  buf[0] := ((num1 and $ff000000) shr 24);
  buf[1] := ((num1 and $ff0000) shr 16);
  buf[2] := ((num1 and $ff00) shr 8);
  buf[3] := (num1 and $ff);

  buf[4] := ((num2 and $ff000000) shr 24);
  buf[5] := ((num2 and $ff0000) shr 16);
  buf[6] := ((num2 and $ff00) shr 8);
  buf[7] := (num2 and $ff);

  move(SecWebSocketKey3[1],buf[8],8);
  buf[16] := 0;

  MDigest:=GetMD5;
  MDigest.Update(buf,16);
  result := TIdBytes(MDigest.Final);
end;


{ TWebRequestHeader }

constructor TWebRequestHeader.Create(AName, AValue: string);
begin
  FName:=AName;
  FValue:=AValue;
end;

constructor TWebRequestHeader.Create(AHeader: string);
var
  idx : Integer;
begin
  idx:=Pos(':',AHeader);
  FName:=Copy(AHeader,1,idx-1);
  FValue:=Trim(Copy(AHeader,idx+1,Length(AHeader)));
end;

{ TWebSocketHeader }

constructor TWebSocketHeader.Create(AName, AValue: string;
  AVersions: TWebSocketVersions);
begin
  inherited Create(AName,AValue);
  FVersions := AVersions;
end;

function TWebSocketHeader.MatchAndFill(Msg: string): Boolean;
begin
  if FValue='*' then begin
    result:=MatchesMask(Msg, FName+': *');
    if result then
      FValue := Trim(Copy(Msg, Length(FName)+2, Length(Msg)));
  end else
    result:=SameText(Msg,FName+': '+FValue);
  FExists:=FExists or result;
end;

{ TWebDataFields }

constructor TWebDataFields.Create(const Query: string);
begin
  inherited Create;
  FList := TStringList.Create;
  FList.Delimiter := '&';
  FList.DelimitedText := Query;
end;

function TWebDataFields.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TWebDataFields.GetName(const Index: Integer): string;
begin
  Result := FList.Names[Index];
end;

function TWebDataFields.GetValue(const Name: string): string;
begin
  Result := ValueFromIndex[FList.IndexOfName(Name)];
end;

function TWebDataFields.GetValueFromIndex(const Index: Integer): string;
begin
  Result := ThinVNC.Utils.HttpDecode(FList.ValueFromIndex[Index]);
end;

end.
