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

unit ThinVnc.Unicode;
{$I ThinVnc.DelphiVersion.inc}
{$I ThinVnc.inc}
interface
uses
  Classes,SysUtils;

const
  UNICODE_INVALID=63; //Invalid unicode utf-8 sequence char '?'

function UTF8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PChar; SourceBytes: Cardinal): Cardinal;
function Utf8Decode(const S: UTF8String): WideString;

implementation


function UTF8ToUnicode(Dest: PWideChar; MaxDestChars: Cardinal; Source: PChar; SourceBytes: Cardinal): Cardinal;
var
  InputUTF8: Cardinal;
  IBYTE: BYTE;
  OutputUnicode: Cardinal;
  PRECHAR: Cardinal;
  TempBYTE: BYTE;
  CharLen: Cardinal;
  LookAhead: Cardinal;
  UC: Cardinal;
begin
  if not assigned(Source) then begin
    result:=0;
    exit;
  end;
  result:=Cardinal(-1);
  InputUTF8:=0;
  OutputUnicode:=0;
  PreChar:=0;
  if Assigned(Dest) Then begin
    while (OutputUnicode<MaxDestChars) and (InputUTF8<SourceBytes) do begin
      IBYTE:=byte(Source[InputUTF8]);
      if (IBYTE and $80) = 0 then begin
        //One character US-ASCII, convert it to unicode
        if IBYTE = 10 then begin
          If (PreChar<>13) and FALSE Then begin
            //Expand to crlf, conform UTF-8.
            //This procedure will break the memory alocation by
            //FPC for the widestring, so never use it. Condition never true due the "and FALSE".
            if OutputUnicode+1<MaxDestChars Then begin
              Dest[OutputUnicode]:=WideChar(13);
              inc(OutputUnicode);
              Dest[OutputUnicode]:=WideChar(10);
              inc(OutputUnicode);
              PreChar:=10;
            end else begin
              Dest[OutputUnicode]:=WideChar(13);
              inc(OutputUnicode);
            end;
          end else begin
            Dest[OutputUnicode]:=WideChar(IBYTE);
            inc(OutputUnicode);
            PreChar:=IBYTE;
          end;
        end else begin
          Dest[OutputUnicode]:=WideChar(IBYTE);
          inc(OutputUnicode);
          PreChar:=IBYTE;
        end;
        inc(InputUTF8);
      end else begin
        TempByte:=IBYTE;
        CharLen:=0;
        while (TempBYTE and $80)<>0 do begin
          TempBYTE:=(TempBYTE shl 1) and $FE;
          inc(CharLen);
        end;
        //Test for the "CharLen" conforms UTF-8 string
        //This means the 10xxxxxx pattern.
{$HINTS OFF} //-HINT about converting to int64
        if (InputUTF8+CharLen-1)>SourceBytes Then begin
{$HINTS ON}
          //Insuficient chars in string to decode
          //UTF-8 array. Fallback to single char.
          CharLen:= 1;
        end;
        for LookAhead := 1 to CharLen-1 do begin
          if ((byte(Source[InputUTF8+LookAhead]) and $80)<>$80) or
             ((byte(Source[InputUTF8+LookAhead]) and $40)<>$00) then begin
              //Invalid UTF-8 sequence, fallback.
              CharLen:= LookAhead;
              break;
          end;
        end;
        UC:=$FFFF;
        Case CharLen of
          1:  begin
                //Not valid UTF-8 sequence
                UC:=UNICODE_INVALID;
              end;
          2:  begin
                //Two bytes UTF, convert it
                UC:=(byte(Source[InputUTF8]) and $1F) shl 6;
                UC:=UC or (byte(Source[InputUTF8+1]) and $3F);
                if UC <= $7F then begin
                    //Invalid UTF sequence.
                    UC:=UNICODE_INVALID;
                end;
              end;
          3:  begin
                //Three bytes, convert it to unicode
                UC:= (byte(Source[InputUTF8]) and $0F) shl 12;
                UC:= UC or ((byte(Source[InputUTF8+1]) and $3F) shl 6);
                UC:= UC or ((byte(Source[InputUTF8+2]) and $3F));
                If (UC <= $7FF) or (UC >= $FFFE) or ((UC >= $D800) and (UC <= $DFFF)) Then begin
                    //Invalid UTF-8 sequence
                    UC:= UNICODE_INVALID;
                End;
              end;
          4,5,6,7:  begin
                      //Invalid UTF8 to unicode conversion,
                      //mask it as invalid UNICODE too.
                      UC:=UNICODE_INVALID;
                    end;
        end;
        If CharLen > 0 Then begin
            PreChar:=UC;
            Dest[OutputUnicode]:=WideChar(UC);
            inc(OutputUnicode);
        End;
        InputUTF8:= InputUTF8 + CharLen;
      end;
    end;
    Result:=OutputUnicode+1;
  end else begin
    while (InputUTF8<SourceBytes) do begin
      IBYTE:=byte(Source[InputUTF8]);
      if (IBYTE and $80) = 0 then begin
        //One character US-ASCII, convert it to unicode
        if IBYTE = 10 then begin
          If (PreChar<>13) and FALSE Then begin
            //Expand to crlf, conform UTF-8.
            //This procedure will break the memory alocation by
            //FPC for the widestring, so never use it. Condition never true due the "and FALSE".
            inc(OutputUnicode,2);
            PreChar:=10;
          end else begin
            inc(OutputUnicode);
            PreChar:=IBYTE;
          end;
        end else begin
          inc(OutputUnicode);
          PreChar:=IBYTE;
        end;
        inc(InputUTF8);
      end else begin
        TempByte:=IBYTE;
        CharLen:=0;
        while (TempBYTE and $80)<>0 do begin
          TempBYTE:=(TempBYTE shl 1) and $FE;
          inc(CharLen);
        end;
        //Test for the "CharLen" conforms UTF-8 string
        //This means the 10xxxxxx pattern.
{$HINTS OFF} //-HINT about converting to int64
        if (InputUTF8+CharLen-1)>SourceBytes Then begin
{$HINTS ON}
          //Insuficient chars in string to decode
          //UTF-8 array. Fallback to single char.
          CharLen:= 1;
        end;
        for LookAhead := 1 to CharLen-1 do begin
          if ((byte(Source[InputUTF8+LookAhead]) and $80)<>$80) or
             ((byte(Source[InputUTF8+LookAhead]) and $40)<>$00) then begin
              //Invalid UTF-8 sequence, fallback.
              CharLen:= LookAhead;
              break;
          end;
        end;
        UC:=$FFFF;
        Case CharLen of
          1:  begin
                //Not valid UTF-8 sequence
                UC:=UNICODE_INVALID;
              end;
          2:  begin
                //Two bytes UTF, convert it
                UC:=(byte(Source[InputUTF8]) and $1F) shl 6;
                UC:=UC or (byte(Source[InputUTF8+1]) and $3F);
                if UC <= $7F then begin
                    //Invalid UTF sequence.
                    UC:=UNICODE_INVALID;
                end;
              end;
          3:  begin
                //Three bytes, convert it to unicode
                UC:= (byte(Source[InputUTF8]) and $0F) shl 12;
                UC:= UC or ((byte(Source[InputUTF8+1]) and $3F) shl 6);
                UC:= UC or ((byte(Source[InputUTF8+2]) and $3F));
                If (UC <= $7FF) or (UC >= $FFFE) or ((UC >= $D800) and (UC <= $DFFF)) Then begin
                    //Invalid UTF-8 sequence
                    UC:= UNICODE_INVALID;
                End;
              end;
          4,5,6,7:  begin
                      //Invalid UTF8 to unicode conversion,
                      //mask it as invalid UNICODE too.
                      UC:=UNICODE_INVALID;
                    end;
        end;
        If CharLen > 0 Then begin
            PreChar:=UC;
            inc(OutputUnicode);
        End;
        InputUTF8:= InputUTF8 + CharLen;
      end;
    end;
    Result:=OutputUnicode+1;
  end;
end;

function Utf8Decode(const S: UTF8String): WideString;
var
  L: Integer;
  Temp: WideString;
begin
  Result := '';
  if S = '' then Exit;
  SetLength(Temp, Length(S));

  L := UTF8ToUnicode(PWideChar(Temp), Length(Temp)+1, PChar(S), Length(S));
  if L > 0 then
    SetLength(Temp, L-1)
  else
    Temp := '';
  Result := Temp;
end;
end.
