{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi，让漂亮界面做起来更简单。

  本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
  发布此库的目的是希望其有用，但不做任何保证。
  如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

  开源地址: https://github.com/ets-ddui/ets-ddui
            https://gitee.com/ets-ddui/ets-ddui
  开源协议: The MIT License (MIT)
  作者邮箱: xinghun87@163.com
  官方博客：https://blog.csdn.net/xinghun61
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

//异常处理
procedure CreateDump(AMinidumpType: TMinidumpType; AFileName: PChar);
procedure LoadExceptionDeal(AEnabled, AFullDump: Boolean);
procedure UnLoadExceptionDeal;

//日志管理
procedure WriteView(AMessage: String); overload;
procedure WriteView(AMessage: String; AParams: array of const); overload;
procedure WriteLog(AMessage: String; AFileName: String); overload;
procedure WriteLog(AMessage: String; AParams: array of const; AFileName: String); overload;

//Variant处理加强
function VarToInt(AValue: Variant): Integer;
function VarToIntDef(AValue: Variant; ADefault: Integer): Integer;
function VarToInt64(AValue: Variant): Int64;
function VarToInt64Def(AValue: Variant; ADefault: Int64): Int64;
function VarToFloat(AValue: Variant): Extended;
function VarToFloatDef(AValue: Variant; ADefault: Extended): Extended;
function VarToBoolean(AValue: Variant): Boolean;
function VarToBooleanDef(AValue: Variant; ADefault: Boolean): Boolean;

//BASE64转换
function Base64ToMem(AValue: AnsiString): AnsiString;
function MemToBase64(AValue: AnsiString): AnsiString;
function FileToBase64(AFileName: String): AnsiString;

//杂项
function LoadFile(AFileName: String): String;
procedure SaveDCToBitmap(AControl: TControl; ADC: Cardinal = 0; ADirectory: String = '.\Pic\'; AWaitTime: Int64 = -1);
//FormatEh - 负责将AFormat中的"{Name}"替换成指定的值
//AParameters存放的是"Name1=Value1,Name2=Value2"形式的键值对
//{Name}支持嵌套定义
//"\"可用于对"\{}"进行转译，例如，"\{"被转译为"{"，不会作为"{Name}"的起始字符而被替换
function FormatEh(const AFormat, AParameters: String): String; overload;
function FormatEh(const AFormat: String; AParameters: TStringList): String; overload;
//ExtractNakedFileName - 获取不带路径及后缀名的文件名
function ExtractNakedFileName(AFileName: String): String;
//PosDelimiter - 返回指定分隔符在AValue中出现的位置(可类比LastDelimiter的功能)
//返回值0表示没找到分隔符，否则，为分隔符出现的索引号(从1开始计数)
function PosDelimiter(const ADelimiters, AValue: String; AIndex: Integer = 1): Integer;
//GetProcessImageName/GetProcessImageNameByID - 根据进程句柄或进程ID，获取对应的进程名称
function GetProcessImageName(AHandle: THandle): String;
function GetProcessImageNameByID(APID: Cardinal): String;

implementation

var
  GCreateDump: procedure(AExceptionPointers: PExceptionPointers; AMinidumpType: TMinidumpType; AFileName: PChar); stdcall;
  GEnableException: procedure(AEnabled, AFullDump: Boolean); stdcall;
  GHandle: THandle;
  GWaitTime: Int64;

{
  CreateDump可用于任何生成异常的逻辑中，用于生成dump文件，例如：
  1. try...except...end部分(except中无需指定异常类型)
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
    //Delphi的异常处理入口为_HandleAnyException，在调用except的异常处理代码之前，
    //会将ESP的当前值保存到RaiseListPtr变量中(通过RaiseList获取)，
    //此时ESP与_HandleAnyException入口的偏移量是9 * 4 = 36(做了9次PUSH操作)，
    //而_HandleAnyException入参的含义如下(_HandleAnyException源码中截取)：
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
    //ExtractFilePath不支持对'/'的解析
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
    WriteView('日志输出错误 文件路径：%s 文本内容：%s', [AFileName, AMessage]);
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
    //以下数字16个一排
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62,0, 0, 0, 63, //'+'、'/'
    52,53,54,55,56,57,58,59,60,61,0, 0, 0, 0, 0, 0,  //'0'-'9'
    0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,14, //'A'-'O'
    15,16,17,18,19,20,21,22,23,24,25,0, 0, 0, 0, 0,  //'P'-'Z'
    0, 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40, //'a'-'o'
    41,42,43,44,45,46,47,48,49,50,51);               //'p'-'z'
var
  i, iSrcLen, iSrcIndex, iDestIndex, iEqualCount: Integer;
  bt1, bt2, bt3, bt4: Byte;
begin
  //1.0 对输入数据长度做检查(BASE64字符串长度应该为4的倍数)
  iSrcLen := Length(AValue);
  if (iSrcLen and $3) <> 0 then //不能整除4
    WriteView(Format('Base64ToMem异常，输入数据长度不为4的倍数: %s', [AValue]));
  iSrcLen := iSrcLen and not $3;
  if iSrcLen = 0 then
  begin
    Result := '';
    Exit;
  end;

  //2.0 检查是否有非法字符
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

      WriteView(Format('序号%d存在非法字符%s: %s', [i, AValue[i], AValue]));
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
    //获取文件大小
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
      raise Exception.Create('无效的Variant类型');

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

    Assert(False, Format('%s参数值未指定', [AKeyName]));
  end;
  //getKeyName - 对AFormat中"{Name}"形式的值做处理
  //返回值为"Name"
  //AIndex为要查找的"{Name}"的起始位置(即"{"的索引号)
  //ANextIndex返回的是"}"字符的下一个位置
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
        Assert(False, '格式不正确，没有结尾的"}"字符');

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
//  UnLoadExceptionDeal; //关闭程序时不卸载异常处理的DLL，防止关闭过程中抛出的异常无法捕获到

end.
