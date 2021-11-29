{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi����Ư���������������򵥡�

  ��UI���ǿ�Դ������������������� MIT Э�飬�޸ĺͷ����˳���
  �����˿��Ŀ����ϣ�������ã��������κα�֤��
  ���������������ҵ��Ŀ�����ڱ����е�Bug����������κη��ռ���ʧ�������߲��е��κ����Ρ�

  ��Դ��ַ: https://github.com/ets-ddui/ets-ddui
  ��ԴЭ��: The MIT License (MIT)
  ��������: xinghun87@163.com
  �ٷ����ͣ�https://blog.csdn.net/xinghun61
}
unit UTool;

{$i UConfigure.inc}

interface

uses
  Windows, Classes, SysUtils, StrUtils, Controls, Graphics, Variants, PsAPI;

type
  TMinidumpType = (
    MiniDumpNormal                         = $00000000,
    MiniDumpWithDataSegs                   = $00000001,
    MiniDumpWithFullMemory                 = $00000002,
    MiniDumpWithHandleData                 = $00000004,
    MiniDumpFilterMemory                   = $00000008,
    MiniDumpScanMemory                     = $00000010,
    MiniDumpWithUnloadedModules            = $00000020,
    MiniDumpWithIndirectlyReferencedMemory = $00000040,
    MiniDumpFilterModulePaths              = $00000080,
    MiniDumpWithProcessThreadData          = $00000100,
    MiniDumpWithPrivateReadWriteMemory     = $00000200,
    MiniDumpWithoutOptionalData            = $00000400,
    MiniDumpWithFullMemoryInfo             = $00000800,
    MiniDumpWithThreadInfo                 = $00001000,
    MiniDumpWithCodeSegs                   = $00002000,
    MiniDumpWithoutAuxiliaryState          = $00004000,
    MiniDumpWithFullAuxiliaryState         = $00008000,
    MiniDumpWithPrivateWriteCopyMemory     = $00010000,
    MiniDumpIgnoreInaccessibleMemory       = $00020000,
    MiniDumpWithTokenInformation           = $00040000,
    MiniDumpValidTypeFlags                 = $0007ffff
  );
  PExceptionPointers = ^TExceptionPointers;
  TExceptionPointers = record
    ExceptionRecord: PExceptionRecord;
    ContextRecord: Pointer;
  end;

//�쳣����
procedure CreateDump(AMinidumpType: TMinidumpType; AFileName: PChar);
procedure LoadExceptionDeal(AEnabled, AFullDump: Boolean);
procedure UnLoadExceptionDeal;

//��־����
procedure WriteView(AMessage: String); overload;
procedure WriteView(AMessage: String; AParams: array of const); overload;
procedure WriteLog(AMessage: String; AFileName: String); overload;
procedure WriteLog(AMessage: String; AParams: array of const; AFileName: String); overload;

//Variant�����ǿ
function VarToInt(AValue: Variant): Integer;
function VarToIntDef(AValue: Variant; ADefault: Integer): Integer;
function VarToInt64(AValue: Variant): Int64;
function VarToInt64Def(AValue: Variant; ADefault: Int64): Int64;
function VarToFloat(AValue: Variant): Extended;
function VarToFloatDef(AValue: Variant; ADefault: Extended): Extended;
function VarToBoolean(AValue: Variant): Boolean;
function VarToBooleanDef(AValue: Variant; ADefault: Boolean): Boolean;

//BASE64ת��
function Base64ToMem(AValue: AnsiString): AnsiString;
function MemToBase64(AValue: AnsiString): AnsiString;
function FileToBase64(AFileName: String): AnsiString;

//����
function LoadFile(AFileName: String): String;
procedure SaveDCToBitmap(AControl: TControl; ADC: Cardinal = 0; ADirectory: String = '.\Pic\'; AWaitTime: Int64 = -1);
//FormatEh - ����AFormat�е�"{Name}"�滻��ָ����ֵ
//AParameters��ŵ���"Name1=Value1,Name2=Value2"��ʽ�ļ�ֵ��
//{Name}֧��Ƕ�׶���
//"\"�����ڶ�"\{}"����ת�룬���磬"\{"��ת��Ϊ"{"��������Ϊ"{Name}"����ʼ�ַ������滻
function FormatEh(const AFormat, AParameters: String): String; overload;
function FormatEh(const AFormat: String; AParameters: TStringList): String; overload;
//ExtractNakedFileName - ��ȡ����·������׺�����ļ���
function ExtractNakedFileName(AFileName: String): String;
//PosDelimiter - ����ָ���ָ�����AValue�г��ֵ�λ��(�����LastDelimiter�Ĺ���)
//����ֵ0��ʾû�ҵ��ָ���������Ϊ�ָ������ֵ�������(��1��ʼ����)
function PosDelimiter(const ADelimiters, AValue: String; AIndex: Integer = 1): Integer;
//GetProcessImageName/GetProcessImageNameByID - ���ݽ��̾�������ID����ȡ��Ӧ�Ľ�������
function GetProcessImageName(AHandle: THandle): String;
function GetProcessImageNameByID(APID: Cardinal): String;

implementation

var
  GCreateDump: procedure(AExceptionPointers: PExceptionPointers; AMinidumpType: TMinidumpType; AFileName: PChar); stdcall;
  GEnableException: procedure(AEnabled, AFullDump: Boolean); stdcall;
  GHandle: THandle;
  GWaitTime: Int64;

{
  CreateDump�������κ������쳣���߼��У���������dump�ļ������磺
  1. try...except...end����(except������ָ���쳣����)
  2. Application.OnException
}
{$WARN SYMBOL_DEPRECATED OFF}
procedure CreateDump(AMinidumpType: TMinidumpType; AFileName: PChar);
var
  ep: TExceptionPointers;
begin
  if not Assigned(GCreateDump) then
    LoadExceptionDeal(False, False);

  if Assigned(GCreateDump) then
  begin
    //Delphi���쳣�������Ϊ_HandleAnyException���ڵ���except���쳣�������֮ǰ��
    //�ὫESP�ĵ�ǰֵ���浽RaiseListPtr������(ͨ��RaiseList��ȡ)��
    //��ʱESP��_HandleAnyException��ڵ�ƫ������9 * 4 = 36(����9��PUSH����)��
    //��_HandleAnyException��εĺ�������(_HandleAnyExceptionԴ���н�ȡ)��
    { ->    [ESP+ 4] excPtr: PExceptionRecord       }
    {       [ESP+ 8] errPtr: PExcFrame              }
    {       [ESP+12] ctxPtr: Pointer                }
    {       [ESP+16] dspPtr: Pointer                }
    { <-    EAX return value - always one   }
    ep.ExceptionRecord := PPointer(Integer(RaiseList) + 4 + 9 * 4)^;
    ep.ContextRecord := PPointer(Integer(RaiseList) + 12 + 9 * 4)^;

    GCreateDump(@ep, AMinidumpType, AFileName);
  end;
end;
{$WARN SYMBOL_DEPRECATED ON}

procedure LoadExceptionDeal(AEnabled, AFullDump: Boolean);
begin
  if not FileExists('ExceptionDeal.dll') then
    Exit;

  if GHandle = 0 then
    GHandle := LoadLibrary('ExceptionDeal.dll');

  if GHandle <> 0 then
  begin
    GCreateDump := GetProcAddress(GHandle, 'Dump');
    GEnableException := GetProcAddress(GHandle, 'EnableException');
  end;

  if AEnabled and Assigned(GEnableException) then
    GEnableException(AEnabled, AFullDump);
end;

procedure UnLoadExceptionDeal;
var
  hHandle: THandle;
begin
  if GHandle <> 0 then
  begin
    hHandle := GHandle;
    GHandle := 0;
    GCreateDump := nil;
    GEnableException := nil;

    FreeLibrary(hHandle);
  end;
end;

procedure WriteView(AMessage: String);
begin
  if AMessage = '' then
    Exit;
  OutputDebugString(@AMessage[1]);
end;

procedure WriteView(AMessage: String; AParams: array of const);
begin
  WriteView(Format(AMessage, AParams));
end;

procedure WriteLog(AMessage: String; AFileName: String);
  function getPath(AFilePath: String): String;
  begin
    //ExtractFilePath��֧�ֶ�'/'�Ľ���
    Result := LeftStr(AFilePath, LastDelimiter('\/:', AFilePath));
  end;
  function createDirectory(AFilePath: String): Boolean;
  begin
    Result := True;

    if (AFilePath = '') or DirectoryExists(AFilePath) then
      Exit;

    if AFilePath[Length(AFilePath)] in ['\', '/'] then
      SetLength(AFilePath, Length(AFilePath) - 1);

    Result := createDirectory(getPath(AFilePath)) and CreateDir(AFilePath);
  end;
var
  iFileHandle: Integer;
begin
  if AMessage = '' then
    Exit;

  if FileExists(AFileName) then
    iFileHandle := FileOpen(AFileName, fmOpenWrite or fmShareDenyNone)
  else
  begin
    createDirectory(getPath(AFileName));

    iFileHandle := FileCreate(AFileName);
  end;

  if iFileHandle <= 0 then
  begin
    WriteView('��־������� �ļ�·����%s �ı����ݣ�%s', [AFileName, AMessage]);
    Exit;
  end;

  try
    FileSeek(iFileHandle, 0, FILE_END);
    FileWrite(iFileHandle, AMessage[1], Length(AMessage));
  finally
    if iFileHandle > 0 then
    begin
      FileClose(iFileHandle);
    end;
  end;
end;

procedure WriteLog(AMessage: String; AParams: array of const; AFileName: String);
begin
  WriteLog(Format(AMessage, AParams), AFileName);
end;

function Base64ToMem(AValue: AnsiString): AnsiString;
const
  cBase64Dict: array[#0..#122] of Byte = (
    //��������16��һ��
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62,0, 0, 0, 63, //'+'��'/'
    52,53,54,55,56,57,58,59,60,61,0, 0, 0, 0, 0, 0,  //'0'-'9'
    0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,14, //'A'-'O'
    15,16,17,18,19,20,21,22,23,24,25,0, 0, 0, 0, 0,  //'P'-'Z'
    0, 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40, //'a'-'o'
    41,42,43,44,45,46,47,48,49,50,51);               //'p'-'z'
var
  i, iSrcLen, iSrcIndex, iDestIndex, iEqualCount: Integer;
  bt1, bt2, bt3, bt4: Byte;
begin
  //1.0 ���������ݳ��������(BASE64�ַ�������Ӧ��Ϊ4�ı���)
  iSrcLen := Length(AValue);
  if (iSrcLen and $3) <> 0 then //��������4
    WriteView(Format('Base64ToMem�쳣���������ݳ��Ȳ�Ϊ4�ı���: %s', [AValue]));
  iSrcLen := iSrcLen and not $3;
  if iSrcLen = 0 then
  begin
    Result := '';
    Exit;
  end;

  //2.0 ����Ƿ��зǷ��ַ�
  for i := 1 to Length(AValue) do
    if not (AValue[i] in ['A'..'Z', 'a'..'z', '0'..'9', '+', '/']) then
    begin
      if i = Length(AValue) - 1 then
      begin
        if (AValue[i] = '=') and (AValue[i + 1] = '=') then
          Break;
      end
      else if i = Length(AValue) then
      begin
        if AValue[i] = '=' then
          Break;
      end;

      WriteView(Format('���%d���ڷǷ��ַ�%s: %s', [i, AValue[i], AValue]));
      Result := '';
      Exit;
    end;

  iEqualCount := 0;
  if AValue[iSrcLen] = '=' then
    Inc(iEqualCount);
  if AValue[iSrcLen - 1] = '=' then
    Inc(iEqualCount);

  if iEqualCount > 0 then
  begin
    Dec(iSrcLen, 4);
    SetLength(Result, iSrcLen div 4 * 3 + 3 - iEqualCount);
  end
  else
    SetLength(Result, iSrcLen div 4 * 3);

  iSrcIndex := 1;
  iDestIndex := 1;
  while (iSrcIndex + 3) <= iSrcLen do
  begin
    bt1 := cBase64Dict[AValue[iSrcIndex]];
    bt2 := cBase64Dict[AValue[iSrcIndex + 1]];
    bt3 := cBase64Dict[AValue[iSrcIndex + 2]];
    bt4 := cBase64Dict[AValue[iSrcIndex + 3]];

    Result[iDestIndex] := Chr((bt1 shl 2) or (bt2 shr 4));
    Result[iDestIndex + 1] := Chr((bt2 shl 4) or (bt3 shr 2));
    Result[iDestIndex + 2] := Chr((bt3 shl 6) or bt4);

    Inc(iSrcIndex, 4);
    Inc(iDestIndex, 3);
  end;

  case iEqualCount of
    1:
    begin
      bt1 := cBase64Dict[AValue[iSrcIndex]];
      bt2 := cBase64Dict[AValue[iSrcIndex + 1]];
      bt3 := cBase64Dict[AValue[iSrcIndex + 2]];

      Result[iDestIndex] := Chr((bt1 shl 2) or (bt2 shr 4));
      Result[iDestIndex + 1] := Chr((bt2 shl 4) or (bt3 shr 2));
    end;
    2:
    begin
      bt1 := cBase64Dict[AValue[iSrcIndex]];
      bt2 := cBase64Dict[AValue[iSrcIndex + 1]];

      Result[iDestIndex] := Chr((bt1 shl 2) or (bt2 shr 4));
    end;
  end;
end;

function MemToBase64(AValue: AnsiString): AnsiString;
const
  cBase64Dict: array[0..63] of AnsiChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  iSrcLen, iSrcIndex, iDestIndex: Integer;
  bt1, bt2, bt3: Byte;
begin
  if AValue = '' then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, (Length(AValue) + 2) div 3 * 4);

  iSrcLen := Length(AValue);
  iSrcIndex := 1;
  iDestIndex := 1;
  while (iSrcIndex + 2) <= iSrcLen do
  begin
    bt1 := Ord(AValue[iSrcIndex]);
    bt2 := Ord(AValue[iSrcIndex + 1]);
    bt3 := Ord(AValue[iSrcIndex + 2]);

    Result[iDestIndex] := cBase64Dict[bt1 shr 2];
    Result[iDestIndex + 1] := cBase64Dict[((bt1 and $03) shl 4) or (bt2 shr 4)];
    Result[iDestIndex + 2] := cBase64Dict[((bt2 and $0f) shl 2) or (bt3 shr 6)];
    Result[iDestIndex + 3] := cBase64Dict[bt3 and $3f];

    Inc(iSrcIndex, 3);
    Inc(iDestIndex, 4);
  end;

  case iSrcLen mod 3 of
    1:
    begin
      bt1 := Ord(AValue[iSrcIndex]);

      Result[iDestIndex] := cBase64Dict[bt1 shr 2];
      Result[iDestIndex + 1] := cBase64Dict[(bt1 and $03) shl 4];
      Result[iDestIndex + 2] := '=';
      Result[iDestIndex + 3] := '=';
    end;
    2:
    begin
      bt1 := Ord(AValue[iSrcIndex]);
      bt2 := Ord(AValue[iSrcIndex + 1]);

      Result[iDestIndex] := cBase64Dict[bt1 shr 2];
      Result[iDestIndex + 1] := cBase64Dict[((bt1 and $03) shl 4) or (bt2 shr 4)];
      Result[iDestIndex + 2] := cBase64Dict[(bt2 and $0f) shl 2];
      Result[iDestIndex + 3] := '=';
    end;
  end;
end;

function ReadFileToMemory(AFileName: String): AnsiString;
var
  iFile, iLen: Integer;
begin
  Result := '';
  if not FileExists(AFileName) then
    Exit;

  iFile := FileOpen(AFileName, fmOpenRead);
  if iFile < 0 then
    Exit;
  try
    //��ȡ�ļ���С
    iLen := FileSeek(iFile, 0, FILE_END);
    if iLen < 0 then
      Exit;

    FileSeek(iFile, 0, FILE_BEGIN);
    SetLength(Result, iLen);
    FileRead(iFile, Result[1], iLen);
  finally
    if iFile >= 0 then
      FileClose(iFile);
  end;
end;

function FileToBase64(AFileName: String): AnsiString;
begin
  Result := MemToBase64(ReadFileToMemory(AFileName));
end;

function VarToInt(AValue: Variant): Integer;
begin
  Result := AValue;
end;

function VarToIntDef(AValue: Variant; ADefault: Integer): Integer;
begin
  if VarIsNull(AValue) then
    Result := ADefault
  else
    Result := AValue;
end;

function VarToInt64(AValue: Variant): Int64;
begin
  Result := AValue;
end;

function VarToInt64Def(AValue: Variant; ADefault: Int64): Int64;
begin
  if VarIsNull(AValue) then
    Result := ADefault
  else
    Result := AValue;
end;

function VarToFloat(AValue: Variant): Extended;
begin
  Result := AValue;
end;

function VarToFloatDef(AValue: Variant; ADefault: Extended): Extended;
begin
  if VarIsNull(AValue) then
    Result := ADefault
  else
    Result := AValue;
end;

function VarToBoolean(AValue: Variant): Boolean;
var
  str: String;
begin
  if VarIsStr(AValue) then
  begin
    str := VarToStr(AValue);
    if CompareText(str, 'true') = 0 then
      Result := True
    else if CompareText(str, 'false') = 0 then
      Result := False
    else
      raise Exception.Create('��Ч��Variant����');

    Exit;
  end;

  Result := AValue;
end;

function VarToBooleanDef(AValue: Variant; ADefault: Boolean): Boolean;
var
  str: String;
begin
  if VarIsStr(AValue) then
  begin
    str := VarToStr(AValue);
    if CompareText(str, 'true') = 0 then
      Result := True
    else if CompareText(str, 'false') = 0 then
      Result := False
    else
      Result := ADefault;

    Exit;
  end;

  if VarIsNull(AValue) then
    Result := ADefault
  else
    Result := AValue;
end;

function LoadFile(AFileName: String): String;
begin
  Result := '';

  if not FileExists(AFileName) then
    Exit;

  with TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone) do
    try
      if Size = 0 then
        Exit;

      SetLength(Result, Size);
      Read(Result[1], Size);
    finally
      Free;
    end;
end;

procedure SaveDCToBitmap(AControl: TControl; ADC: Cardinal; ADirectory: String; AWaitTime: Int64);
var
  bmp: TBitmap;
  iCurrTime: Int64;
  iWidth, iHeight: Integer;
  strName: String;
begin
  iCurrTime := GetTickCount;
  if iCurrTime - GWaitTime <= AWaitTime then
    Exit;

  if not Assigned(AControl) then
  begin
    iWidth := 1024;
    iHeight := 1024;
    strName := 'Unknown';
  end
  else
  begin
    iWidth := AControl.Width;
    iHeight := AControl.Height;
    if AControl.Name = '' then
      strName := AControl.ClassName
    else
      strName := AControl.Name;
  end;

  GWaitTime := iCurrTime;
  ADirectory := StringReplace(ADirectory, '/', '\', [rfReplaceAll]);
  if ADirectory[Length(ADirectory)] <> '\' then
    ADirectory := ADirectory + '\';

  bmp := TBitmap.Create;
  try
    bmp.SetSize(iWidth, iHeight);
    bmp.Canvas.Brush.Color := clBlue;
    bmp.Canvas.FillRect(Rect(0, 0, iWidth, iHeight));

    BitBlt(bmp.Canvas.Handle, 0, 0, iWidth, iHeight, ADC, 0, 0, SRCCOPY);
    ForceDirectories(Format('%s%s\', [ADirectory, strName]));
    bmp.SaveToFile(Format('%s%s\%d.bmp', [ADirectory, strName, GWaitTime]));
  finally
    FreeAndNil(bmp);
  end;
end;

function FormatEh(const AFormat, AParameters: String): String;
var
  slst: TStringList;
begin
  slst := TStringList.Create;
  try
    slst.StrictDelimiter := True;
    slst.DelimitedText := AParameters;

    Result := FormatEh(AFormat, slst);
  finally
    FreeAndNil(slst);
  end;
end;

function FormatEh(const AFormat: String; AParameters: TStringList): String;
  function getValue(AKeyName: String; AKeyValue: TStringList): String;
  var
    i: Integer;
  begin
    Result := '';

    if Assigned(AKeyValue) then
      for i := 0 to AKeyValue.Count - 1 do
        if CompareText(AKeyName, AKeyValue.Names[i]) = 0 then
        begin
          Result := AKeyValue.ValueFromIndex[i];
          Exit;
        end;

    Assert(False, Format('%s����ֵδָ��', [AKeyName]));
  end;
  //getKeyName - ��AFormat��"{Name}"��ʽ��ֵ������
  //����ֵΪ"Name"
  //AIndexΪҪ���ҵ�"{Name}"����ʼλ��(��"{"��������)
  //ANextIndex���ص���"}"�ַ�����һ��λ��
  function getKeyName(var ANextIndex: Integer; AFormat: String; AIndex: Integer; AKeyValue: TStringList): String;
  var
    iLastPos, iLen: Integer;
  begin
    Result := '';
    iLastPos := AIndex + 1;
    iLen := Length(AFormat);

    while iLastPos <= iLen do
    begin
      ANextIndex := PosDelimiter('\{}', AFormat, iLastPos);
      if ANextIndex <= 0 then
      begin
        Assert(False, '��ʽ����ȷ��û�н�β��"}"�ַ�');

        ANextIndex := Length(AFormat) + 1;
        Result := Result + MidStr(AFormat, iLastPos, ANextIndex - iLastPos);
        Exit;
      end;

      Result := Result + MidStr(AFormat, iLastPos, ANextIndex - iLastPos);
      if AFormat[ANextIndex] = '\' then
      begin
        if ANextIndex < iLen then
          Result := Result + AFormat[ANextIndex + 1];

        iLastPos := ANextIndex + 2;
      end
      else if AFormat[ANextIndex] = '{' then
      begin
        Result := Result + getValue(getKeyName(iLastPos, AFormat, ANextIndex, AKeyValue), AKeyValue);
      end
      else //AFormat[ANextIndex] = '}'
      begin
        Inc(ANextIndex);
        Exit;
      end;
    end;

    ANextIndex := iLen + 1;
  end;
var
  iBeg, iLastPos, iLen: Integer;
begin
  iLastPos := 1;
  iBeg := PosDelimiter('\{', AFormat, iLastPos);
  if iBeg <= 0 then
  begin
    Result := AFormat;
    Exit;
  end;

  Result := '';

  iLen := Length(AFormat);
  while iBeg > 0 do
  begin
    Result := Result + MidStr(AFormat, iLastPos, iBeg - iLastPos);
    if AFormat[iBeg] = '\' then
    begin
      if iBeg < iLen then
        Result := Result + AFormat[iBeg + 1];

      iLastPos := iBeg + 2;
    end
    else //AFormat[iBeg] = '{'
    begin
      Result := Result + getValue(getKeyName(iLastPos, AFormat, iBeg, AParameters), AParameters);
    end;

    if iLastPos > iLen then
      Exit;

    iBeg := PosDelimiter('\{', AFormat, iLastPos);
  end;

  Result := Result + MidStr(AFormat, iLastPos, iLen + 1 - iLastPos);
end;

function ExtractNakedFileName(AFileName: String): String;
var
  iBegin, iEnd: Integer;
begin
  iBegin := LastDelimiter(PathDelim + DriveDelim, AFileName);
  iEnd := LastDelimiter('.' + PathDelim + DriveDelim, AFileName);
  if iBegin = iEnd then
    iEnd := iBegin + 1;
  Result := Copy(AFileName, iBegin + 1, iEnd - iBegin - 1);
end;

function PosDelimiter(const ADelimiters, AValue: String; AIndex: Integer): Integer;
var
  iLen: Integer;
begin
  Result := 0;
  iLen := Length(AValue);
  if (AIndex <= 0) or (AIndex > iLen) then
    Exit;

  if '' = ADelimiters then
  begin
    Result := AIndex;
    Exit;
  end;

  Result := AIndex;
  if ByteType(AValue, Result) = mbTrailByte then
    Inc(Result);

  while Result <= iLen do
  begin
    if 0 < AnsiPos(AValue[Result], ADelimiters) then
      Exit;

    if AValue[Result] in LeadBytes then
      Inc(Result, 2)
    else
      Inc(Result);
  end;

  Result := 0;
end;

function GetProcessImageName(AHandle: THandle): String;
var
  iLen: Integer;
begin
  iLen := 1024;
  SetLength(Result, iLen);
  iLen := GetModuleFileNameEx(AHandle, 0, @Result[1], iLen);
  SetLength(Result, iLen);
end;

function GetProcessImageNameByID(APID: Cardinal): String;
var
  h: THandle;
begin
  Result := '';
  h := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, APID);
  if h = 0 then
    Exit;

  try
    Result := GetProcessImageName(h);
  finally
    CloseHandle(h);
  end;
end;

initialization
  GHandle := 0;
  GCreateDump := nil;
  GEnableException := nil;
  GWaitTime := 0;

finalization
//  UnLoadExceptionDeal; //�رճ���ʱ��ж���쳣�����DLL����ֹ�رչ������׳����쳣�޷�����

end.
