unit main;

interface
  uses 
    DDDK;
    
  const 
    DEV_NAME = '\Device\MyDriver';
    SYM_NAME = '\DosDevices\MyDriver';
    
  function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;

implementation
var
  dwLen: ULONG;
  szBuf: array[0..255] of char;
  
function IrpOpen(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IRP_MJ_CREATE', []);
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function IrpRead(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
var
  i: ULONG;
  src: PChar;
  dst: PChar;
begin
  DbgPrint('IRP_MJ_READ', []);
  
  src:= szBuf;
  dst:= MmGetMdlVirtualAddress(pIrp^.MdlAddress);
  for i:= 0 to dwLen do
  begin
    dst[i]:= src[i];
  end;
  
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= dwLen;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function IrpWrite(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
var
  i: ULONG;
  src: PChar;
  dst: PChar;

begin
  DbgPrint('IRP_MJ_WRITE', []);
  
  dst:= szBuf;
  src:= MmGetMdlVirtualAddress(pIrp^.MdlAddress);
  dwLen:= MmGetMdlByteCount(pIrp^.MdlAddress);
  DbgPrint('Buffer: %s, Length: %d', [src, dwLen]);
 
  for i:= 0 to dwLen do
  begin
    dst[i]:= src[i];
  end;
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= dwLen;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function IrpClose(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IRP_MJ_CLOSE', []);
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

procedure Unload(pOurDriver:PDriverObject); stdcall;
var
  szSymName: TUnicodeString;

begin
  RtlInitUnicodeString(@szSymName, SYM_NAME);
  IoDeleteSymbolicLink(@szSymName);
  IoDeleteDevice(pOurDriver^.DeviceObject);
end;

function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;
var
  suDevName: TUnicodeString;
  szSymName: TUnicodeString;
  pOurDevice: PDeviceObject;
  
begin
  RtlInitUnicodeString(@suDevName, DEV_NAME);
  RtlInitUnicodeString(@szSymName, SYM_NAME);
  Result:= IoCreateDevice(pOurDriver, 0, @suDevName, FILE_DEVICE_UNKNOWN, 0, FALSE, pOurDevice);

  if NT_SUCCESS(Result) then
  begin
    pOurDriver^.MajorFunction[IRP_MJ_CREATE]:= @IrpOpen;
    pOurDriver^.MajorFunction[IRP_MJ_READ]  := @IrpRead;
    pOurDriver^.MajorFunction[IRP_MJ_WRITE] := @IrpWrite;
    pOurDriver^.MajorFunction[IRP_MJ_CLOSE] := @IrpClose;
    pOurDriver^.DriverUnload := @Unload;
    pOurDevice^.Flags:= pOurDevice^.Flags or DO_DIRECT_IO;
    pOurDevice^.Flags:= pOurDevice^.Flags and not DO_DEVICE_INITIALIZING;
    Result:= IoCreateSymbolicLink(@szSymName, @suDevName);
  end;
end;
end.
