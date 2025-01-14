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

unit ThinVnc.TcpCommon;
{$I ThinVnc.DelphiVersion.inc}
{$I ThinVnc.inc}
interface

uses Windows,Classes,SysUtils,zlib,SyncObjs,math,
  IdGlobal,
  ThinVnc.Log;

type
  TCallbackSendEvent = procedure (Text:AnsiString;APacketNumber:Cardinal) of object;
  TCallbackTextEvent = procedure (Text:AnsiString) of object;
  TCallbackObject = class
  private
    FText : Ansistring;
    FCallback : TCallbackSendEvent;
    FPAcketNumber : Cardinal;
  public
    constructor Create(Atext:Ansistring;ACallback:TCallbackSendEvent;APacketNumber:Cardinal);
  end;

  TSendThread = class(TThread)
  private
    FCs : TCriticalSection;
    FList : TList;
    FEvent : TEvent;
    FLastPacketNumber : Cardinal;
    FOnEmptyQueue: TNotifyevent;
  public
    constructor create;
    destructor Destroy;override;
    procedure SendCmd(ACallback:TCallbackSendEvent;AText:AnsiString);
    procedure Execute;override;
    procedure Continue;
    function  LastPacketNumber:Cardinal;
    property  OnEmptyQueue: TNotifyevent read FOnEmptyQueue write FOnEmptyQueue;
  end;

  TAckEvent = procedure (APacketNumber:Cardinal) of object;
  TMsgHeader = packed record
    Version : byte;
    Type_ : byte;
    Compressed : byte;
    Reserved : byte;
    PacketNumber : Cardinal;
  end;
  TFormatBufferType = (fbJson,fbBinary);

function EndianLong(L : longint) : longint;
function FormatSendBuffer(Text:AnsiString;fbType:TFormatBufferType;APacketNumber:Cardinal):TIdBytes;
procedure DataAvailable(Stream:TStream;var ARcvBuff:ansistring;var APacketLen,APacketIdx:Integer;Callback,CallbackBuf:TCallbackTextEvent;AAckEvent:TAckEvent=nil);

function ZDecompressStr(const s: Ansistring): Ansistring;
function ZCompressStr(const s: Ansistring
  {$IFDEF DELPHI2010}; level: TZCompressionLevel=zcDefault{$ENDIF}): Ansistring;

implementation

function ZCompressStr(const s: Ansistring
  {$IFDEF DELPHI2010}; level: TZCompressionLevel{$ENDIF}): Ansistring;
var
  buffer: Pointer;
  size: Integer;
begin
  buffer := nil;
  size := 0;
  {$IFDEF DELPHI2010}
  ZCompress(PAnsiChar(@s[1]), Length(s), buffer, size, level);
  {$ELSE}
  ////CompressBuf(PAnsiChar(@s[1]), Length(s), buffer, size);
  {$ENDIF}
  SetLength(result, size);
  Move(buffer^, pointer(result)^, size);
  FreeMem(buffer);
end;

function ZDecompressStr(const s: Ansistring): Ansistring;
var
  buffer: Pointer;
  size, Len: Integer;
begin
  buffer := nil;
  size := 0;
  Len := Length(s);
  try
    {$IFDEF DELPHI2010}
    ZDecompress(PAnsiChar(@s[1]), Len, buffer, size);
    {$ELSE}
    ////DecompressBuf(PAnsiChar(@s[1]), Len, 0, buffer, size);
    {$ENDIF}
    SetLength(result, size);
    Move(buffer^, pointer(result)^, size);
    FreeMem(buffer);
  except
    on E: Exception do
    begin
      LogException(E.Message);
      LogDump(Format('Invalid ZCompressed Data: %d bytes', [Len]),
        PAnsiChar(s), Len);
      raise;
    end;
  end;
end;

{$DEFINE COMPRESS_BINARY}
function EndianLong(L : longint) : longint;
begin
  result := swap(L shr 16) or
  (longint(swap(L and $ffff)) shl 16);
end;

function FormatSendBuffer(Text:AnsiString;fbType:TFormatBufferType;APacketNumber:Cardinal):TIdBytes;
var
  Size,sizebe,OldSize : LongInt;
  Header : TMsgHeader;
  Start : TDatetime;
begin
  OldSize:=Length(Text);
  Start:=Now;
  if (fbType=fbJson) then
    LogInfo(Format('FormatSendBuffer Json:%s',[Text]));
  {$IFDEF DELPHI2010}
  Text:=ZCompressStr(Text,zcMax);
  {$ELSE}
  Text:=ZCompressStr(Text);
  {$ENDIF}
  Size:=Length(Text)+SizeOf(Header);
  LogInfo(Format('FormatSendBuffer PacketNumber:%d OldSize:%d NewSize:%d Compress time:%.3d ms.',[APacketNumber,OldSize,Size,
      DateTimeToTimeStamp(Now-Start).Time]));
  Header.Version:=1;
  Header.Type_:=Byte(fbType);
  Header.PacketNumber:=APacketNumber;
  Header.Compressed:=1;
  SetLength(result,SizeOf(LongInt)+size+1);
  sizebe:=EndianLong(Size);
  result[0]:=$80;
  Move(sizebe,result[1],SizeOf(LongInt));
  Move(Header,result[SizeOf(LongInt)+1],SizeOf(Header));
  Move(Text[1],result[SizeOf(LongInt)+SizeOf(Header)+1],Size-SizeOf(Header));
end;

procedure DataAvailable(Stream:TStream;var ARcvBuff:ansistring;var APacketLen,APacketIdx:Integer;Callback,CallbackBuf:TCallbackTextEvent;AAckEvent:TAckEvent);
var
  lCount,read,pl : LongInt;
  Header : TMsgHeader;
  Log : ILogger;
begin
  Log := TLogger.Create('DataAvailable','DataAvailable');
  Stream.Seek(0,0);
  lCount := Stream.Size;
  if lCount>0 then
  repeat
    if APacketLen=0 then begin
      read := Stream.Read(pl, SizeOf(LongInt));
      Assert(read = SizeOf(LongInt));
      if read=-1 then exit;
      { Max 512 KB ? }
      if (pl < 0) or (pl > 512*1024) then begin
        pl:=0;
        break;
      end;

      Assert((pl > 0) and (pl <= 512*1024));
      APacketLen:=EndianLong(pl);

      SetLength(ARcvBuff, APacketLen);
      LogInfo(Format('Start New Packet. Size=%d',[APacketLen]));
      APacketIdx := 0;
    end else begin
      read := Stream.Read(ARcvBuff[APacketIdx+1], min((APacketLen-APacketIdx),lCount));
      if read >= 0 then APacketIdx:=APacketIdx+read
      else begin
        APacketLen:=0;
        break;
      end;

      if (APacketIdx>=SizeOf(Header)) then
        Move(ARcvBuff[1],Header,SizeOf(Header));

      if (APacketIdx>=(APacketLen div 2)) and Assigned(AAckEvent) then
        AAckEvent(Header.PacketNumber);

      if (APacketIdx>APacketLen) then
        break;
      if (APacketIdx=APacketLen) then begin
        APacketLen:=0;
        ARcvBuff:=Copy(ARcvBuff,SizeOf(Header)+1,Length(ARcvBuff));
        if Header.Compressed>0 then
           ARcvBuff:=ZDecompressStr(ARcvBuff);
        try
          if Header.Type_=Byte(fbJSON) then begin
              Callback(ARcvBuff);
          end else CallbackBuf(ARcvBuff);
        except
          On E:Exception do
            LogException(E.Message);
        end;
      end;
    end;
    lCount:=lCount-read;
  until lCount<=0;
end;

{ TSendThread }

constructor TSendThread.create;
begin
  inherited Create(true);
  FCs:=TCriticalSection.Create;
  FList := TList.Create;
  FEvent := TEvent.Create(nil,true,false,'');
  FreeOnTerminate:=true;
  resume;
end;

destructor TSendThread.Destroy;
begin
  FList.Free;
  FEvent.Free;
  FCs.Free;
  inherited;
end;

function TSendThread.LastPacketNumber: Cardinal;
begin
  FCs.Enter;
  try
    result:=FLastPacketNumber
  finally
    FCs.Leave;
  end;
end;

procedure TSendThread.Continue;
begin
  FEvent.SetEvent;
end;

procedure TSendThread.Execute;
var
  co : TCallbackObject;
begin
  while not Terminated do begin
    FEvent.WaitFor(INFINITE);
    if Terminated then exit;

    LogInfo('TSendThread.Execute WaitFor Exit');
    co:=nil;
    FCs.Enter;
    try
      if FList.Count>0 then begin
        co:=FList[0];
        FList.Delete(0);
      end else begin
        if Assigned(FOnEmptyQueue) then
          FOnEmptyQueue(self);
        FEvent.ResetEvent;
      end;
    finally
      FCs.Leave;
    end;
    if assigned(co) then
    try
      try
        if Assigned(co.FCallback) then
          co.FCallback(co.FText,co.FPacketNumber);
      finally
        co.Free;
      end;
    except
      On E:Exception do
        LogException(E.Message);
    end;
  end;
end;

procedure TSendThread.SendCmd(ACallback: TCallbackSendEvent; AText: AnsiString);
var
  Log : Ilogger;
begin
  Log := TLogger.Create(Self,'SendCmd');
  FCs.Enter;
  try
    Inc(FLastPacketNumber);
    FList.Add(TCallbackObject.Create(AText,ACallback,FLastPacketNumber));
    FEvent.SetEvent;
  finally
    FCs.Leave;
  end;
end;

{ TCallbackObject }

constructor TCallbackObject.Create(Atext: Ansistring;
  ACallback: TCallbackSendEvent;APacketNumber:Cardinal);
begin
  FText:=AText;
  FCallback:=ACallback;
  FPacketNumber:=APacketNumber;
end;

end.
