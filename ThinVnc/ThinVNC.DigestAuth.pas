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

{*_* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Gustavo Ricardi <gricardi@cybelesoft.com>
              Code copied from OverbyteIcsHttpSrv.pas by
              Cybele Software, Inc.
Creation:     August 13, 2010
Version:      1.00
Description:  HTTP Digest Access Authentication, RFC 2617.
EMail:        http://www.overbyte.be        francois.piette@overbyte.be
Support:      Use the mailing list twsocket@elists.org
              Follow "support" link at http://www.overbyte.be for subscription.
Legal issues: Copyright (C) 2009 by Fran�ois PIETTE
              Rue de Grady 24, 4053 Embourg, Belgium. Fax: +32-4-365.74.56
              <francois.piette@overbyte.be>

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.

              4. You must register this software by sending a picture postcard
                 to the author. Use a nice stamp and mention your name, street
                 address, EMail address and any comment you like to say.

Updates:

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
unit ThinVNC.DigestAuth;

interface
{$WARN SYMBOL_PLATFORM   OFF}
{$WARN SYMBOL_LIBRARY    OFF}
{$WARN SYMBOL_DEPRECATED OFF}
{$B-}             { Enable partial boolean evaluation   }
{$T-}             { Untyped pointers                    }
{$X+}             { Enable extended syntax              }
{$H+}             { Use long strings                    }
{$J+}             { Allow typed constant to be modified }

uses
    Windows,Classes,SysUtils,ThinVnc.MessageDigest_5,Encddecd,Types;

const
    MinDateTime      : TDateTime = -657434.0;
    
type
    TAuthenticationType = (atNone,atDigest,atNtlm);

    EAuthenticationError = class(Exception);
    THashHex             = type AnsiString;
    TNonceString         = type AnsiString;
    TMD5Digest           = TByteDynArray;
    
    TAuthDigestNonceRec = record
        DT    : TDateTime;
        Hash  : TMd5Digest;
    end;
    PAuthDigestNonceRec = ^TAuthDigestNonceRec;

    TAuthDigestMethod   = (daAuth, daAuthInt, daBoth);
   (*
    TAuthDigestRequestInfo = record
        UserName    : String;
        Realm       : String;
        Qop         : String;
        Algorithm   : String;
        Nonce       : String;
        Nc          : String;
        Uri         : String;
        Cnonce      : String;
        Opaque      : String;
        Response    : String;
    end;
    *)
    { Data required by clients to preemtively create a authorization header }
    TAuthDigestResponseInfo = record
        Nc              : Integer;// + must be filled
        // from server //
        Realm       : String; // from Challenge, the protection space
        Qop         : String; // from Challenge, either auth or auth-int or not specified
        Algorithm   : String; // from Challenge or const 'MD5'
        Nonce       : String; // from Challenge, MUST
        Opaque      : String; // from Challenge, MUST
        Domain      : String; // from Challenge, optional space separated list of URIs
        Stale       : Boolean;// from Challenge, optional, no need to pop up a login dialog
    end;


    TAuthDigestServer = class
    private
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
      FMethod                       : string;
      FAuthDigestStale              : Boolean;
      FAuthDigestBody               : AnsiString;
      FAuthDigestNonceLifeTimeMin   : Cardinal;
      FAuthDigestNonceTimeStamp     : TDateTime;
      FAuthDigestOneTimeFlag        : Boolean;
      FAuthenticated: Boolean;
    public
      constructor Create;
      function GetParams(RequestAuth:string;var UserName:string): Boolean;
      function CheckPassword(UserName,Password: AnsiString): Boolean;
      function GenerateChallenge(AuthRealm:string):string;
      property Authenticated:Boolean read FAuthenticated;
    end;

    TAuthDigestInfo  = TAuthDigestResponseInfo;
    THttpDigestState = (digestNone, digestMsg1, digestDone);

    TAuthDigestClient = class
    private
      FAuthDigestState      : THttpDigestState;
      FAuthDigestInfo       : TAuthDigestInfo;
      { As specified in RFC 2617, section 3.2.2.4, used only with auth-int }
      FAuthDigestEntityHash : THashHex;
    public
      function GenerateRequest(AWWWAuthenticate,AUserName, APassword, AHttpMethod,
                            AUri: string): string;
    end;

procedure AuthDigestGetBodyHash(const EntityBody: AnsiString;
  var EntityHash: THashHex);

function AuthDigestGenerateRequest(
    const UserName, Password, HttpMethod, Uri : String;
    const EntityHash : THashHex;
    var Info: TAuthDigestResponseInfo): String; overload;
    
function AuthDigestGenerateRequest(
    const UserName, Password, HttpMethod, Uri, Realm, Qop, Nonce, Opaque,
    Algorithm : String; const EntityHash: THashHex;
    var Cnonce: String; var Nc: Integer): String; overload;

function AuthDigestGenerateChallenge(
    DigestMethod: TAuthDigestMethod; Secret: TULargeInteger; const Realm,
    Domain : String; Stale: Boolean; var Nonce, Opaque: String): String;

function AuthDigestValidateResponse(var Info: TAuthDigestResponseInfo): Boolean;


procedure AuthDigestParseChallenge(
    const ALine   : String;
    var   Info    : TAuthDigestResponseInfo);
    {var   Realm     : String;
    var   Domain    : String;
    var   Nonce     : String;
    var   Opaque    : String;
    var   Stale     : Boolean;
    var   Algorithm : String;
    var   Qop       : String);}

function AuthDigestGetRequest(
    const ALine     : String;
    var   NonceTime   : TDateTime;
    var   UserName    : String;
    var   Realm       : String;
    var   Qop         : String;
    var   Algorithm   : String;
    var   Nonce       : String;
    var   Nc          : String;
    var   DigestUri   : String;
    var   Cnonce      : String;
    var   Opaque      : String;
    var   Response    : String): Boolean;


function AuthDigestGenerateNonce(TimeStamp: TDateTime; Secret: TULargeInteger;
    const Opaque, Realm: AnsiString): TNonceString;

procedure AuthDigestCalcResponse(
    const HA1           : THashHex;    { H(A1)                             }
    const Nonce         : AnsiString;  { nonce from server                 }
    const NonceCount    : AnsiString;  { 8 hex digits                      }
    const CNonce        : AnsiString;  { client nonce                      }
    const Qop           : AnsiString;  { qop-value: "", "auth", "auth-int" }
    const Method        : AnsiString;  { method from the request           }
    const DigestUri     : AnsiString;  { requested URL                     }
    const HEntity       : THashHex;    { H(entity body) if qop="auth-int"  }
    out   Response      : THashHex);   { request-digest or response-digest }

procedure AuthDigestCalcHA1(
    const Algorithm       : String;
    const UserName        : AnsiString;
    const Realm           : AnsiString;
    const Password        : AnsiString;
    const Nonce           : AnsiString;
    const CNonce          : AnsiString;
    out   SessionKey      : THashHex);

var
  AuthDigestServerSecret : TULargeInteger;
  
implementation

uses
    StrUtils; // For PosEx(), it uses a FastCode function in newer RTLs.

const
    AUTH_DIGEST_DELIM : AnsiChar = ':';

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function Base64Encode(Buf:Pointer;Len:Integer):AnsiString;
var
  aux : AnsiString;
begin
  SetLength(aux,Len);
  move(Buf^,aux[1],Len);
  result:=EncodeString(aux);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function Base64Decode(Buf:AnsiString):AnsiString;
begin
  result:=DecodeString(Buf);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function MD5DigestToHex(const Digest: TMD5Digest): THashHex;
var
    I   : Integer;
    Ch  : AnsiChar;
begin
    SetLength(Result, 32);
    for I := 0 to 15 do
    begin
        Ch := AnsiChar((Digest[I] shr 4) and $f);
        if Ord(Ch) <= 9 then
            Result[I * 2 + 1] := AnsiChar(Ord(Ch) + Ord('0'))
        else
            Result[I * 2 + 1] := AnsiChar(Ord(Ch) + Ord('a') - 10);
        Ch := AnsiChar(Digest[I] and $f);
        if Ord(Ch) <= 9 then
            Result[I * 2 + 2] := AnsiChar(Ord(Ch) + Ord('0'))
        else
            Result[I * 2 + 2] := AnsiChar(Ord(Ch) + Ord('a') - 10);
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure AuthDigestGetBodyHash(const EntityBody: AnsiString;
  var EntityHash: THashHex);
var
  MDigest : IMD5;
begin
  MDigest:=GetMD5;
  MDigest.Update(EntityBody);
  EntityHash := MD5DigestToHex(MDigest.Final);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function ToByteDynArray(buf:Pointer;len:Integer):TByteDynArray;
begin
  SetLength(result,len);
  move(buf^,result[0],len);
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function AuthDigestGenerateNonce(TimeStamp: TDateTime; Secret: TULargeInteger;
    const Opaque, Realm: AnsiString): TNonceString;
var
    MDigest : IMD5;
    Nonce    : TAuthDigestNonceRec;
begin
    Nonce.DT := TimeStamp;

    MDigest:=GetMD5;
    MDigest.Update(ToByteDynArray(@Secret,SizeOf(Secret)),SizeOf(Secret));
    MDigest.Update(Realm);
    MDigest.Update(ToByteDynArray(@TimeStamp,SizeOf(TimeStamp)),SizeOf(TimeStamp));
    MDigest.Update(Opaque);
    Nonce.Hash:=MDigest.Final;
    Result := Base64Encode(PAnsiChar(@Nonce), SizeOf(Nonce));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure AuthDigestCalcResponse(
    const HA1           : THashHex;       { H(A1)                             }
    const Nonce         : AnsiString;     { nonce from server                 }
    const NonceCount    : AnsiString;     { 8 hex digits                      }
    const CNonce        : AnsiString;     { client nonce                      }
    const Qop           : AnsiString;     { qop-value: "", "auth", "auth-int" }
    const Method        : AnsiString;     { method from the request           }
    const DigestUri     : AnsiString;     { requested URL                     }
    const HEntity       : THashHex;       { H(entity body) if qop="auth-int"  }
    out   Response      : THashHex);      { request-digest or response-digest }
var
    HA2      : TMD5Digest;
    RespHash : TMD5Digest;
    HA2Hex   : THashHex;
    MDigest : IMD5;
begin
    { calculate H(A2) }
    MDigest:=GetMD5;
    MDigest.Update(Method);
    MDigest.Update(AUTH_DIGEST_DELIM);
    MDigest.Update(DigestUri);
    if CompareText(String(Qop), 'auth-int') = 0 then begin
        MDigest.Update(AUTH_DIGEST_DELIM);
        MDigest.Update(HEntity);
    end;
    HA2Hex := MD5DigestToHex(MDigest.Final);

    { calculate response }
    MDigest:=GetMD5;
    MDigest.Update(HA1);
    MDigest.Update(AUTH_DIGEST_DELIM);
    MDigest.Update(Nonce);
    if Length(Qop) > 0 then begin // (if auth-int or auth) rfc2617 3.2.2.1 Request-Digest
        MDigest.Update(AUTH_DIGEST_DELIM);
        MDigest.Update(NonceCount);
        MDigest.Update(AUTH_DIGEST_DELIM);
        MDigest.Update(CNonce);
        MDigest.Update(AUTH_DIGEST_DELIM);
        MDigest.Update(Qop);
        MDigest.Update(AUTH_DIGEST_DELIM);
    end;
    MDigest.Update(HA2Hex);
    Response := MD5DigestToHex(MDigest.Final);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure AuthDigestCalcHA1(
    const Algorithm       : String;
    const UserName        : AnsiString;
    const Realm           : AnsiString;
    const Password        : AnsiString;
    const Nonce           : AnsiString;
    const CNonce          : AnsiString;
    out   SessionKey      : THashHex);
var
    MDigest : IMD5;
    HA0    : TByteDynArray;
begin
    MDigest:=GetMD5;
    MDigest.Update(UserName);
    MDigest.Update(AUTH_DIGEST_DELIM);
    MDigest.Update(Realm);
    MDigest.Update(AUTH_DIGEST_DELIM);
    MDigest.Update(Password);
    HA0:=MDigest.Final;

    if CompareText(Algorithm, 'md5-sess') = 0 then
    begin
      MDigest:=GetMD5;
      MDigest.Update(HA0,Length(HA0));
      MDigest.Update(AUTH_DIGEST_DELIM);
      MDigest.Update(Nonce);
      MDigest.Update(AUTH_DIGEST_DELIM);
      MDigest.Update(CNonce);
      HA0:=MDigest.Final;
    end;
    SessionKey := MD5DigestToHex(HA0);

end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function AuthDigestGetRequest(
    const ALine       : String;
    var   NonceTime   : TDateTime;
    var   UserName    : String;
    var   Realm       : String;
    var   Qop         : String;
    var   Algorithm   : String;
    var   Nonce       : String;
    var   Nc          : String;
    var   DigestUri   : String;
    var   Cnonce      : String;
    var   Opaque      : String;
    var   Response    : String): Boolean;
var
    Pos1, Pos2 : Integer;
    Buf : THashHex;
begin
    { Authorization: Digest username="Mufasa",
                 realm="testrealm@host.com",
                 nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
                 uri="/dir/index.html",
                 qop=auth,
                 nc=00000001,
                 cnonce="0a4f113b",
                 response="6629fae49393a05397450978507c4ef1",
                 opaque="5ccc069c403ebaf9f0171e9517f40e41" }

    Result := FALSE;
    UserName := ''; Realm := ''; Qop := ''; Algorithm := ''; Nonce := '';
    Nc := ''; DigestUri := ''; Cnonce := ''; Opaque := ''; Response := '';

    Pos1 := PosEx('username="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('username="'));
        Pos2 := PosEx('"', ALine, Pos1);
        UserName := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Exit;

    Pos1 := PosEx('realm="', ALine, 1);
    if Pos1 > 0 then
    begin
        Inc(Pos1, Length('realm="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Realm := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Exit;
{
   qop
     Indicates what "quality of protection" the client has applied to
     the message. If present, its value MUST be one of the alternatives
     the server indicated it supports in the WWW-Authenticate header.
     This directive is optional in order to
     preserve backward compatibility with a minimal implementation of
     RFC 2069 [6], but SHOULD be used if the server indicated that qop
     is supported by providing a qop directive in the WWW-Authenticate
     header field.
}

    Pos1 := PosEx('qop="', ALine, 1);
    if Pos1 = 0 then begin
        Pos1 := PosEx('qop=', ALine, 1);
        if Pos1 > 0 then
        begin
            Inc(Pos1, Length('qop='));
            Pos2 := PosEx(',', ALine, Pos1);
            Qop  := Copy(ALine, Pos1, Pos2 - Pos1);
        end;
    end
    else begin
        Inc(Pos1, Length('qop="'));
        Pos2  := PosEx('"', ALine, Pos1);
        Qop   := Copy(ALine, Pos1, Pos2 - Pos1);
    end;
    (*
    case Method of
      daAuth:
          if Qop <> 'auth' then
              Exit;
      daAuthInt:
          if Qop <> 'auth-int' then
              Exit;
      daBoth:;
        { whatever it is }
    end;
    *)

    Pos1 := PosEx('nonce="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('nonce="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Nonce := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Exit;

 {cnonce
     This MUST be specified if a qop directive is sent (see above), and
     MUST NOT be specified if the server did not send a qop directive in
     the WWW-Authenticate header field. }

    Pos1 := PosEx('cnonce="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('cnonce="'));
        Pos2 := PosEx('"', ALine, Pos1);
        CNonce := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else if Length(Qop) > 0 then
        Exit;

  {nonce-count
     This MUST be specified if a qop directive is sent (see above), and
     MUST NOT be specified if the server did not send a qop directive in
     the WWW-Authenticate header field. }

    Pos1 := PosEx('nc=', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('nc='));
        Pos2 := PosEx(',', ALine, Pos1);
        Nc := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else if Length(Qop) > 0 then
        Exit;

    Pos1 := PosEx('algorithm="', ALine, 1);
    if Pos1 = 0 then begin
        Pos1 := PosEx('algorithm=', ALine, 1);
        if Pos1 = 0 then
            Algorithm := 'MD5'
        else begin
            Inc(Pos1, Length('algorithm='));
            Pos2 := PosEx(',', ALine, Pos1);
            Algorithm := Copy(ALine, Pos1, Pos2 - Pos1);
        end;
    end
    else begin
        Inc(Pos1, Length('algorithm="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Algorithm := Copy(ALine, Pos1, Pos2 - Pos1);
    end;

    Pos1 := PosEx('uri="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('uri="'));
        Pos2 := PosEx('"', ALine, Pos1);
        DigestUri := Copy(ALine, Pos1, Pos2 - Pos1);
    end;

    Pos1 := PosEx('response="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('response="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Response := Copy(ALine, Pos1, Pos2 - Pos1);
    end;

    Pos1 := PosEx('opaque="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('opaque="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Opaque := Copy(ALine, Pos1, Pos2 - Pos1);
    end;

    Buf := Base64Decode(AnsiString(Nonce));
    if Length(Buf) <> SizeOf(TAuthDigestNonceRec) then
        Exit;

    NonceTime := PAuthDigestNonceRec(Pointer(Buf))^.DT;

    Result := (NonceTime > MinDateTime) and (NonceTime <= Now);
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
procedure AuthDigestParseChallenge(
    const ALine   : String;
    var   Info      : TAuthDigestResponseInfo);
var
    Pos1, Pos2 : Integer;
begin
    { WWW-Authenticate: Digest
                 realm="testrealm@host.com",
                 qop="auth,auth-int",
                 nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
                 opaque="5ccc069c403ebaf9f0171e9517f40e41" }

    Info.Nc         := 0; // initialize to zero;
    
    Pos1 := PosEx('realm="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('realm="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Realm := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Info.Realm := '';

    Pos1 := PosEx('domain="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('domain="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Domain := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Info.Domain := '';

    Pos1 := PosEx('nonce="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('nonce="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Nonce := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Info.Nonce := '';


    Pos1 := PosEx('opaque="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('opaque="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Opaque := Copy(ALine, Pos1, Pos2 - Pos1);
    end
    else
        Info.Opaque := '';

    Pos1 := PosEx('stale="', ALine, 1);
    if Pos1 > 0 then begin
        Inc(Pos1, Length('stale="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Stale := CompareText(Copy(ALine, Pos1, Pos2 - Pos1), 'true') = 0;
    end
    else
        Info.Stale := FALSE;

    Pos1 := PosEx('algorithm="', ALine, 1);
    if Pos1 = 0 then begin
        Pos1 := PosEx('algorithm=', ALine, 1);
        if Pos1 = 0 then
            Info.Algorithm := ''
        else begin
            Inc(Pos1, Length('algorithm='));
            Pos2 := PosEx(',', ALine, Pos1);
            Info.Algorithm := Copy(ALine, Pos1, Pos2 - Pos1);
        end;
    end
    else begin
        Inc(Pos1, Length('algorithm="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Algorithm := Copy(ALine, Pos1, Pos2 - Pos1);
    end;

    Pos1 := PosEx('qop="', ALine, 1);
    if Pos1 = 0 then begin
        Pos1 := PosEx('qop=', ALine, 1);
        if Pos1 > 0 then begin
            Inc(Pos1, Length('qop='));
            Pos2 := PosEx(',', ALine, Pos1);
            Info.Qop := Copy(ALine, Pos1, Pos2 - Pos1);
        end
        else
            Info.Qop := '';
    end
    else begin
        Inc(Pos1, Length('qop="'));
        Pos2 := PosEx('"', ALine, Pos1);
        Info.Qop  := Copy(ALine, Pos1, Pos2 - Pos1);
    end;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function AuthDigestValidateResponse(var Info: TAuthDigestResponseInfo): Boolean;
begin
    if Length(Info.Algorithm) = 0 then
        Info.Algorithm := 'MD5';
    Result := (Length(Info.Realm) > 0) and (Info.Algorithm = 'MD5') and
              { auth-int is currently not supported }
              ((Length(Info.qop) = 0) or (Info.qop = 'auth'));
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function AuthDigestGenerateRequest(
    const UserName, Password, HttpMethod, Uri, Realm, Qop, Nonce, Opaque,
    Algorithm : String; const EntityHash: THashHex;
    var Cnonce: String; var Nc: Integer): String;
var
    HA1       : THashHex;
    Response  : THashHex;
    NcHex     : String;
begin
    if Length(Qop) > 0 then begin
        NcHex  := IntToHex(Nc, 8);
        Cnonce := IntToHex(Random(MaxInt), 8);
    end else
        CNonce := '';
    AuthDigestCalcHA1(Algorithm,
                      AnsiString(UserName),
                      AnsiString(Realm),
                      AnsiString(Password),
                      AnsiString(Nonce),
                      AnsiString(CNonce),
                      HA1);
    AuthDigestCalcResponse(HA1,
                           AnsiString(Nonce),
                           AnsiString(NcHex),
                           AnsiString(CNonce),
                           AnsiString(Qop),
                           AnsiString(HttpMethod),
                           AnsiString(Uri),
                           EntityHash, // used only with auth-int!
                           Response);
    Result := 'username="'    + UserName     + '"' +
              ', realm="'     + Realm        + '"' +
              ', nonce="'     + Nonce        + '"' +
              ', uri="'       + Uri          + '"' +
              ', response="'  + String(Response)  + '"' +
              ', opaque="'    + Opaque       + '"';
    if Length(Qop) > 0 then
        Result := Result +
              ', qop='        + Qop                +
              ', nc='         + NcHex                   +
              ', cnonce="'    + CNonce            + '"' ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function AuthDigestGenerateRequest(
    const UserName, Password, HttpMethod, Uri : String;
    const EntityHash : THashHex;
    var Info: TAuthDigestResponseInfo): String;
var
    HA1       : THashHex;
    Response  : THashHex;
    NcHex     : String;
    CNonce    : String;
begin
    if Length(Info.qop) > 0 then begin
        NcHex  := IntToHex(Info.Nc, 8);
        CNonce := IntToHex(Random(MaxInt), 8);
    end;
    AuthDigestCalcHA1(Info.Algorithm,
                      AnsiString(UserName),
                      AnsiString(Info.Realm),
                      AnsiString(Password),
                      AnsiString(Info.Nonce),
                      AnsiString(CNonce),
                      HA1);
    AuthDigestCalcResponse(HA1,
                           AnsiString(Info.Nonce),
                           AnsiString(NcHex),
                           AnsiString(CNonce),
                           AnsiString(Info.Qop),
                           AnsiString(HttpMethod),
                           AnsiString(Uri),
                           EntityHash, // used only with auth-int!
                           Response);
    Result := 'username="'    + UserName          + '"' +
              ', realm="'     + Info.Realm        + '"' +
              ', nonce="'     + Info.Nonce        + '"' +
              ', uri="'       + Uri               + '"' +
              ', response="'  + String(Response)  + '"' +
              ', opaque="'    + Info.Opaque       + '"';
    if Length(Info.Qop) > 0 then
    Result := Result +
              ', qop='        + Info.Qop                +
              ', nc='         + NcHex                   +
              ', cnonce="'    + CNonce            + '"' ;
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
function AuthDigestGenerateChallenge(
    DigestMethod: TAuthDigestMethod; Secret: TULargeInteger; const Realm,
    Domain : String; Stale: Boolean; var Nonce, Opaque: String): String;
var
    I     : Integer;
    iCh   : Integer;
    Qop   : String;
begin
    { Generate the opaque, we use to generate the nonce hash }
    SetLength(Opaque, 34);
    for I := 1 to Length(Opaque) do begin
        while TRUE do begin
            iCh := Random(122);
            case iCh of
                48..57, 65..90, 97..122 :
                    begin
                        Opaque[I] := Char(iCh);
                        Break;
                    end;
            end
        end;
    end;

    Nonce := String(AuthDigestGenerateNonce(Now, Secret,
                                         AnsiString(Opaque),
                                         AnsiString(Realm)));

    case DigestMethod of
        daAuth:    Qop := 'auth';
        daAuthInt: Qop := 'auth-int';
        daBoth:    Qop := 'auth,auth-int';
    end;

    Result := 'realm="'    + Realm          + '"' +
              ', qop="'    + Qop            + '"' +
              ', nonce="'  + Nonce          + '"' +
              ', opaque="' + Opaque         + '"';
    if Stale then
        Result := Result + ', stale="true"';
    if Length(Domain) > 0 then
        Result := Result + ', domain="' + Domain + '"';
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{ TAuthDigestServer }

constructor TAuthDigestServer.Create;
begin
  FAuthDigestStale := False;
  FAuthDigestNonceLifeTimeMin := 1;
  FMethod := 'GET';
end;

function TAuthDigestServer.GenerateChallenge(AuthRealm:string): string;
begin
  FAuthDigestServerNonce  := '';
  FAuthDigestServerOpaque := '';
  result:=AuthDigestGenerateChallenge(daAuth,
                  AuthDigestServerSecret,
                  AuthRealm, '', FAuthDigestStale,
                  FAuthDigestServerNonce,
                  FAuthDigestServerOpaque)
end;

function TAuthDigestServer.GetParams(RequestAuth:string;var UserName:string): Boolean;
begin
  FAuthDigestBody := '';
  Result := AuthDigestGetRequest(RequestAuth, FAuthDigestNonceTimeStamp,
                   UserName, FAuthDigestRealm, FAuthDigestQop,
                   FAuthDigestAlg, FAuthDigestNonce, FAuthDigestNc,
                   FAuthDigestUri, FAuthDigestCnonce, FAuthDigestOpaque,
                   FAuthDigestResponse);
  FAuthDigestOneTimeFlag := FALSE;
end;

function TAuthDigestServer.CheckPassword(UserName,Password: AnsiString): Boolean;
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
    AuthDigestCalcHA1(FAuthDigestAlg, AnsiString(UserName),
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
  FAuthenticated:=result;
end;

{ TAuthDigestClient }

function TAuthDigestClient.GenerateRequest(AWWWAuthenticate,AUserName, APassword, AHttpMethod,
  AUri: string): string;
begin
  result:='';
  AuthDigestParseChallenge(AWWWAuthenticate,FAuthDigestInfo);
  if AuthDigestValidateResponse(FAuthDigestInfo) then begin
    FAuthDigestInfo.Nc := 1;
    Result := 'Digest ' +
            AuthDigestGenerateRequest(AUserName,
                                      APassword,
                                      AHttpMethod,
                                      AUri,
                                      FAuthDigestEntityHash,
                                      FAuthDigestInfo);
  end;
end;

initialization
    Randomize;
    const LowPart;
    AuthDigestServerSecret.LowPart  := Random(MaxInt);
    AuthDigestServerSecret.HighPart := Random(MaxInt);
finalization

end.
