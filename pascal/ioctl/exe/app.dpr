program main;

{$APPTYPE CONSOLE}

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  DIALOGS;

const
  METHOD_BUFFERED = 0;
  FILE_ANY_ACCESS = 0;
  FILE_DEVICE_UNKNOWN = $22;

var
  fd: DWORD;
  code: DWORD;
  dwRet: DWORD;
begin
  fd:= CreateFile('\\.\MyDriver', GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, Nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (fd <> INVALID_HANDLE_VALUE) then
  begin
    code:= (FILE_DEVICE_UNKNOWN shl 16) or (FILE_ANY_ACCESS Shl 14) or ($800 shl 2) or (METHOD_BUFFERED);
    DeviceIoControl(fd, code, Nil, 0, Nil, 0, dwRet, Nil);
    CloseHandle(fd);
  end else
  begin
    WriteLn(Output, 'failed to open mydriver');
  end;
end.
