{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi，让漂亮界面做起来更简单。

  本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
  发布此库的目的是希望其有用，但不做任何保证。
  如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

  开源地址: https://github.com/ets-ddui/ets-ddui
  开源协议: The MIT License (MIT)
  作者邮箱: xinghun87@163.com
  官方博客：https://blog.csdn.net/xinghun61
}
unit URtti;

{$i UConfigure.inc}

interface

uses
  Windows, Classes, SysUtils, Types, TypInfo, ObjAuto;

//RTTI
type
  {$IFDEF LAZARUS}
  TMethodNameRec = packed record
    Name : PShortString;
    Addr : CodePointer;
  end;
  PMethodNameTable =  ^TMethodNameTable;
  TMethodNameTable = packed record
    Count : DWORD;
    Entries : packed array[0..0] of TMethodNameRec;
  end;
  PMethodInfo = PMethodNameTable;
  {$ELSE}
  PVmt = ^TVmt;
  TVmt = packed record
    vSelfPtr: Pointer;
    vIntfTable: Pointer;
    vAutoTable: Pointer;
    vInitTable: Pointer;
    vTypeInfo: Pointer;
    vFieldTable: Pointer;
    vMethodTable: Pointer;
    vDynamicTable: Pointer;
    vClassName: PShortString;
    vInstanceSize: Longint;
    vParent: Pointer;
    vSafeCallException: Pointer;
    vAfterConstruction: Pointer;
    vBeforeDestruction: Pointer;
    vDispatch: Pointer;
    vDefaultHandler: Pointer;
    vNewInstance: Pointer;
    vFreeInstance: Pointer;
    vDestroy: Pointer;
    vQueryInterface: Pointer;
    vAddRef: Pointer;
    vRelease: Pointer;
    vCreateObject: Pointer;
  end;
  PMethodInfo = ^TMethodInfo;
  TMethodInfo = packed record
    MethodCount: Word;
    MethodList: array[0..1023] of Char
    {MethodList: array[1..MethodCount] of TMethodInfoHeader};
  end;
  {$ENDIF}
  PPropData = ^TPropData;
  TPointerType = (
    {$IFDEF LAZARUS}
    ptUnknown, ptInteger, ptChar, ptEnumeration, ptFloat,
    ptSet, ptMethod, ptSString, ptLString, ptAString,
    ptWString, ptVariant, ptArray, ptRecord, ptInterface,
    ptClass, ptObject, ptWChar, ptBool, ptInt64, ptQWord,
    ptDynArray, ptInterfaceRaw, ptProcVar, ptUString, ptUChar,
    ptHelper, ptFile, ptClassRef, ptPointer,
    {$ELSE}
    ptUnknown, ptInteger, ptChar, ptEnumeration, ptFloat,
    ptString, ptSet, ptClass, ptMethod, ptWChar, ptLString, ptWString,
    ptVariant, ptArray, ptRecord, ptInterface, ptInt64, ptDynArray,
    {$ENDIF}
    //前面的部分与TTypeKind保持完全兼容，后面针对其他类型做定义
    ptVmt, ptMethodInfo, ptMethodInfoHeader, ptReturnInfo, ptParamInfo,
    ptTypeInfo, ptPropData, ptPropInfo);
  TConfigure = class
  private
    FIndent, FCurClassLevel, FMaxClassLevel: DWORD;
    FList: TList;
    //返回值为True表示已处理，否则，表示未处理
    function DoFilter(APointerType: TPointerType; APointer: Pointer): Boolean;
  public
    constructor Create(AMaxClassLevel: DWORD);
    destructor Destroy; override;
    procedure Inc(AIndent, AClassLevel: DWORD);
    procedure Dec(AIndent, AClassLevel: DWORD);
    procedure PrintTitle(AValue: String);
    procedure PrintContent(AValue: String);
    function Filter(AVmt: PVmt): Boolean; overload;
    function Filter(AMethodInfo: PMethodInfo): Boolean; overload;
    function Filter(AMethodInfoHeader: PMethodInfoHeader): Boolean; overload;
    function Filter(AReturnInfo: PReturnInfo): Boolean; overload;
    function Filter(AParamInfo: PParamInfo): Boolean; overload;
    function Filter(ATypeInfo: PTypeInfo): Boolean; overload;
    function Filter(ATypeKind: TTypeKind; ATypeData: PTypeData): Boolean; overload;
    function Filter(APropData: PPropData): Boolean; overload;
    function Filter(APropInfo: PPropInfo): Boolean; overload;
  end;
  TRtti = class
  private
    class function GetVmt(AObject: TObject): PVmt;
    class procedure DoPrint(AValue: String);
    class procedure PrintTitle(var AConfigure: TConfigure; ATitle: String; AParams: array of const);
    class procedure PrintContent(var AConfigure: TConfigure; AContent: String; AParams: array of const);
    class procedure PrintVmt(var AConfigure: TConfigure; AVmt: PVmt);
    class procedure PrintTypeInfo(var AConfigure: TConfigure; ATypeInfo: PTypeInfo); overload;
    class procedure PrintTypeInfo(var AConfigure: TConfigure; ATypeInfo: PPTypeInfo); overload;
    class procedure PrintTypeData(var AConfigure: TConfigure; ATypeKind: TTypeKind; ATypeData: PTypeData);
    class procedure PrintPropData(var AConfigure: TConfigure; APropData: PPropData);
    class procedure PrintPropInfo(var AConfigure: TConfigure; APropInfo: PPropInfo);
    class procedure PrintMethodInfo(var AConfigure: TConfigure; AMethodInfo: PMethodInfo);
    class procedure PrintMethodInfoHeader(var AConfigure: TConfigure; AMethodInfoHeader: PMethodInfoHeader);
    class procedure PrintReturnInfo(var AConfigure: TConfigure; AReturnInfo: PReturnInfo);
    class procedure PrintParamInfo(var AConfigure: TConfigure; AParamInfo: PParamInfo);
  public
    class procedure PrintRtti(AObject: TObject; AConfigure: TConfigure = nil);
  end;

implementation

uses
  UTool;

{ TConfigure }

constructor TConfigure.Create(AMaxClassLevel: DWORD);
begin
  FList := TList.Create;

  FIndent := 0;
  FCurClassLevel := 1;
  FMaxClassLevel := AMaxClassLevel;
end;

destructor TConfigure.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

procedure TConfigure.Inc(AIndent, AClassLevel: DWORD);
begin
  FIndent := FIndent + AIndent;
  FCurClassLevel := FCurClassLevel + AClassLevel;
end;

procedure TConfigure.Dec(AIndent, AClassLevel: DWORD);
begin
  FIndent := FIndent - AIndent;
  FCurClassLevel := FCurClassLevel - AClassLevel;
end;

procedure TConfigure.PrintTitle(AValue: String);
begin
  if FCurClassLevel > FMaxClassLevel then
    TRtti.DoPrint(Format('%*s+ ', [2 * FIndent, '']) + AValue)
  else
    TRtti.DoPrint(Format('%*s- ', [2 * FIndent, '']) + AValue);
end;

procedure TConfigure.PrintContent(AValue: String);
begin
  TRtti.DoPrint(Format('%*s| ', [2 * FIndent, '']) + AValue);
end;

function TConfigure.DoFilter(APointerType: TPointerType; APointer: Pointer): Boolean;
begin
  Result := True;
  if FList.IndexOf(APointer) >= 0 then
    Exit;

  FList.Add(APointer);
  Result := False;
end;

function TConfigure.Filter(AVmt: PVmt): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(AVmt) then
    Exit;

  if DoFilter(ptVmt, AVmt) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(AMethodInfo: PMethodInfo): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(AMethodInfo) then
    Exit;

  if DoFilter(ptMethodInfo, AMethodInfo) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(AMethodInfoHeader: PMethodInfoHeader): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(AMethodInfoHeader) then
    Exit;

  if DoFilter(ptMethodInfoHeader, AMethodInfoHeader) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(AReturnInfo: PReturnInfo): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(AReturnInfo) then
    Exit;

  if DoFilter(ptReturnInfo, AReturnInfo) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(AParamInfo: PParamInfo): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(AParamInfo) then
    Exit;

  if DoFilter(ptParamInfo, AParamInfo) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(ATypeInfo: PTypeInfo): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(ATypeInfo) then
    Exit;

  if DoFilter(ptTypeInfo, ATypeInfo) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(ATypeKind: TTypeKind; ATypeData: PTypeData): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(ATypeData) then
    Exit;

  //TPointerType开头部分的定义与TTypeKind完全兼容
  if DoFilter(TPointerType(ATypeKind), ATypeData) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(APropData: PPropData): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(APropData) then
    Exit;

  if DoFilter(ptPropData, APropData) then
    Exit;

  Result := False;
end;

function TConfigure.Filter(APropInfo: PPropInfo): Boolean;
begin
  Result := True;
  if (FCurClassLevel > FMaxClassLevel) or not Assigned(APropInfo) then
    Exit;

  if DoFilter(ptPropInfo, APropInfo) then
    Exit;

  Result := False;
end;

{ TRtti }

const
  {$IFDEF LAZARUS}
  cCallConv: array[TCallConv] of String = (
    'ccReg', 'ccCdecl', 'ccPascal', 'ccStdCall', 'ccSafeCall',
    'ccCppdecl', 'ccFar16', 'ccOldFPCCall', 'ccInternProc',
    'ccSysCall', 'ccSoftFloat', 'ccMWPascal');
  {$ENDIF}
  CCallingConvention: array[TCallingConvention] of String = (
    'ccRegister', 'ccCdecl', 'ccPascal', 'ccStdCall', 'ccSafeCall');
  CFloatType: array[TFloatType] of String = (
    'ftSingle', 'ftDouble', 'ftExtended', 'ftComp', 'ftCurr');
  CIntfFlag: array[TIntfFlag] of String = (
    'ifHasGuid', 'ifDispInterface', 'ifDispatch'{$IFDEF LAZARUS}, 'ifHasStrGUID'{$ENDIF});
  cMethodKind: array[TMethodKind] of String = (
    {$IFDEF LAZARUS}
    'mkProcedure', 'mkFunction', 'mkConstructor', 'mkDestructor',
    'mkClassProcedure', 'mkClassFunction', 'mkClassConstructor',
    'mkClassDestructor', 'mkOperatorOverload');
    {$ELSE}
    'mkProcedure', 'mkFunction', 'mkConstructor', 'mkDestructor',
    'mkClassProcedure', 'mkClassFunction', 'mkClassConstructor',
    'mkOperatorOverload', 'mkSafeProcedure', 'mkSafeFunction');
    {$ENDIF}
  COrdType: array[TOrdType] of String = (
    'otSByte', 'otUByte', 'otSWord', 'otUWord', 'otSLong', 'otULong');
  CParamFlag: array[TParamFlag] of String = (
    'pfVar', 'pfConst', 'pfArray', 'pfAddress', 'pfReference', 'pfOut');
  CTypeKind: array[TTypeKind] of String = (
    {$IFDEF LAZARUS}
    'tkUnknown', 'tkInteger', 'tkChar', 'tkEnumeration', 'tkFloat',
    'tkSet', 'tkMethod', 'tkSString', 'tkLString', 'tkAString',
    'tkWString', 'tkVariant', 'tkArray', 'tkRecord', 'tkInterface',
    'tkClass', 'tkObject', 'tkWChar', 'tkBool', 'tkInt64', 'tkQWord',
    'tkDynArray', 'tkInterfaceRaw', 'tkProcVar', 'tkUString', 'tkUChar',
    'tkHelper', 'tkFile', 'tkClassRef', 'tkPointer');
    {$ELSE}
    'tkUnknown', 'tkInteger', 'tkChar', 'tkEnumeration', 'tkFloat',
    'tkString', 'tkSet', 'tkClass', 'tkMethod', 'tkWChar', 'tkLString', 'tkWString',
    'tkVariant', 'tkArray', 'tkRecord', 'tkInterface', 'tkInt64', 'tkDynArray');
    {$ENDIF}
type
  PParamFlags = ^TypInfo.TParamFlags;
  {$IFDEF LAZARUS}
  PCallConv = ^TCallConv;
  {$ENDIF}

function TranslateIntfFlagsBase(AIntfFlags: TIntfFlagsBase): String;
var
  inf: TIntfFlag;
begin
  Result := '';

  for inf := Low(TIntfFlag) to High(TIntfFlag) do
    if inf in AIntfFlags then
      Result := Result + CIntfFlag[inf] + ',';

  if Length(Result) > 0 then
    SetLength(Result, Length(Result) - 1);
end;

class procedure TRtti.PrintRtti(AObject: TObject; AConfigure: TConfigure);
var
  conf: TConfigure;
begin
  if not Assigned(AObject) then
    Exit;

  DoPrint('[Base Info]');
  DoPrint(Format('ClassName:          %s',     [AObject.ClassName]));
  DoPrint(Format('Size:               %d',     [AObject.InstanceSize]));
  DoPrint(Format('Address:            0x%.8x', [DWORD(AObject)]));

  conf := AConfigure;
  try
    if not Assigned(AConfigure) then
      conf := TConfigure.Create(1);

    PrintTitle(conf, 'VMT:                0x%.8x', [PDWORD(AObject)^]);
    PrintVmt(conf, GetVmt(AObject));
  finally
    if not Assigned(AConfigure) then
      FreeAndNil(conf);
  end;
end;

class procedure TRtti.PrintVmt(var AConfigure: TConfigure;
  AVmt: PVmt);
begin
  if AConfigure.Filter(AVmt) then
    Exit;

  PrintContent(AConfigure, '[VMT]',                      []);
  {$IFDEF LAZARUS}
  PrintContent(AConfigure, 'vInstanceSize:      %d',     [AVmt^.vInstanceSize]);
  PrintContent(AConfigure, 'vInstanceSize2:     0x%.8x', [AVmt^.vInstanceSize2]);

  AConfigure.Inc(0, 1);
  PrintTitle(AConfigure,   'vParent:            0x%.8x', [DWORD(AVmt^.vParent)]);
  AConfigure.Inc(1, 0);
  PrintVmt(AConfigure, PVmt(AVmt^.vParent));
  AConfigure.Dec(1, 1);

  PrintContent(AConfigure, 'vClassName:         0x%.8x(%s)', [DWORD(AVmt^.vClassName), AVmt^.vClassName^]);
  PrintContent(AConfigure, 'vDynamicTable:      0x%.8x', [DWORD(AVmt^.vDynamicTable)]);

  PrintTitle(AConfigure,   'vMethodTable:       0x%.8x', [DWORD(AVmt^.vMethodTable)]);
  AConfigure.Inc(1, 0);
  PrintMethodInfo(AConfigure, PMethodInfo(AVmt^.vMethodTable));
  AConfigure.Dec(1, 0);

  PrintContent(AConfigure, 'vFieldTable:        0x%.8x', [DWORD(AVmt^.vFieldTable)]);

  PrintTitle(AConfigure,   'vTypeInfo:          0x%.8x', [DWORD(AVmt^.vTypeInfo)]);
  AConfigure.Inc(1, 0);
  PrintTypeInfo(AConfigure, PTypeInfo(AVmt^.vTypeInfo));
  AConfigure.Dec(1, 0);

  PrintContent(AConfigure, 'vInitTable:         0x%.8x', [DWORD(AVmt^.vInitTable)]);
  PrintContent(AConfigure, 'vAutoTable:         0x%.8x', [DWORD(AVmt^.vAutoTable)]);
  PrintContent(AConfigure, 'vIntfTable:         0x%.8x', [DWORD(AVmt^.vIntfTable)]);
  PrintContent(AConfigure, 'vMsgStrPtr:         0x%.8x', [DWORD(AVmt^.vMsgStrPtr)]);
  PrintContent(AConfigure, 'vDestroy:           0x%.8x', [DWORD(AVmt^.vDestroy)]);
  PrintContent(AConfigure, 'vNewInstance:       0x%.8x', [DWORD(AVmt^.vNewInstance)]);
  PrintContent(AConfigure, 'vFreeInstance:      0x%.8x', [DWORD(AVmt^.vFreeInstance)]);
  PrintContent(AConfigure, 'vSafeCallException: 0x%.8x', [DWORD(AVmt^.vSafeCallException)]);
  PrintContent(AConfigure, 'vDefaultHandler:    0x%.8x', [DWORD(AVmt^.vDefaultHandler)]);
  PrintContent(AConfigure, 'vAfterConstruction: 0x%.8x', [DWORD(AVmt^.vAfterConstruction)]);
  PrintContent(AConfigure, 'vBeforeDestruction: 0x%.8x', [DWORD(AVmt^.vBeforeDestruction)]);
  PrintContent(AConfigure, 'vDefaultHandlerStr: 0x%.8x', [DWORD(AVmt^.vDefaultHandlerStr)]);
  PrintContent(AConfigure, 'vDispatch:          0x%.8x', [DWORD(AVmt^.vDispatch)]);
  PrintContent(AConfigure, 'vDispatchStr:       0x%.8x', [DWORD(AVmt^.vDispatchStr)]);
  PrintContent(AConfigure, 'vEquals:            0x%.8x', [DWORD(AVmt^.vEquals)]);
  PrintContent(AConfigure, 'vGetHashCode:       0x%.8x', [DWORD(AVmt^.vGetHashCode)]);
  PrintContent(AConfigure, 'vToString:          0x%.8x', [DWORD(AVmt^.vToString)]);
  {$ELSE}
  PrintContent(AConfigure, 'vSelfPtr:           0x%.8x', [DWORD(AVmt^.vSelfPtr)]);
  PrintContent(AConfigure, 'vIntfTable:         0x%.8x', [DWORD(AVmt^.vIntfTable)]);
  PrintContent(AConfigure, 'vAutoTable:         0x%.8x', [DWORD(AVmt^.vAutoTable)]);
  PrintContent(AConfigure, 'vInitTable:         0x%.8x', [DWORD(AVmt^.vInitTable)]);

  PrintTitle(AConfigure,   'vTypeInfo:          0x%.8x', [DWORD(AVmt^.vTypeInfo)]);
  AConfigure.Inc(1, 0);
  PrintTypeInfo(AConfigure, PTypeInfo(AVmt^.vTypeInfo));
  AConfigure.Dec(1, 0);

  PrintContent(AConfigure, 'vFieldTable:        0x%.8x', [DWORD(AVmt^.vFieldTable)]);

  PrintTitle(AConfigure,   'vMethodTable:       0x%.8x', [DWORD(AVmt^.vMethodTable)]);
  AConfigure.Inc(1, 0);
  PrintMethodInfo(AConfigure, PMethodInfo(AVmt^.vMethodTable));
  AConfigure.Dec(1, 0);

  PrintContent(AConfigure, 'vDynamicTable:      0x%.8x', [DWORD(AVmt^.vDynamicTable)]);
  PrintContent(AConfigure, 'vClassName:         0x%.8x(%s)', [DWORD(AVmt^.vClassName), AVmt^.vClassName^]);
  PrintContent(AConfigure, 'vInstanceSize:      %d',     [AVmt^.vInstanceSize]);

  AConfigure.Inc(0, 1);
  PrintTitle(AConfigure,   'vParent:            0x%.8x', [DWORD(AVmt^.vParent)]);
  if Assigned(AVmt^.vParent) then
  begin
    AConfigure.Inc(1, 0);
    PrintVmt(AConfigure, PVmt(PInteger(AVmt^.vParent)^ + vmtSelfPtr));
    AConfigure.Dec(1, 0);
  end;
  AConfigure.Dec(0, 1);

  PrintContent(AConfigure, 'vSafeCallException: 0x%.8x', [DWORD(AVmt^.vSafeCallException)]);
  PrintContent(AConfigure, 'vAfterConstruction: 0x%.8x', [DWORD(AVmt^.vAfterConstruction)]);
  PrintContent(AConfigure, 'vBeforeDestruction: 0x%.8x', [DWORD(AVmt^.vBeforeDestruction)]);
  PrintContent(AConfigure, 'vDispatch:          0x%.8x', [DWORD(AVmt^.vDispatch)]);
  PrintContent(AConfigure, 'vDefaultHandler:    0x%.8x', [DWORD(AVmt^.vDefaultHandler)]);
  PrintContent(AConfigure, 'vNewInstance:       0x%.8x', [DWORD(AVmt^.vNewInstance)]);
  PrintContent(AConfigure, 'vFreeInstance:      0x%.8x', [DWORD(AVmt^.vFreeInstance)]);
  PrintContent(AConfigure, 'vDestroy:           0x%.8x', [DWORD(AVmt^.vDestroy)]);
  PrintContent(AConfigure, 'vQueryInterface:    0x%.8x', [DWORD(AVmt^.vQueryInterface)]);
  PrintContent(AConfigure, 'vAddRef:            0x%.8x', [DWORD(AVmt^.vAddRef)]);
  PrintContent(AConfigure, 'vRelease:           0x%.8x', [DWORD(AVmt^.vRelease)]);
  PrintContent(AConfigure, 'vCreateObject:      0x%.8x', [DWORD(AVmt^.vCreateObject)]);
  {$ENDIF}
end;

class procedure TRtti.PrintMethodInfo(var AConfigure: TConfigure;
  AMethodInfo: PMethodInfo);
var
  i: Integer;
  pmih: PMethodInfoHeader;
begin
  if AConfigure.Filter(AMethodInfo) then
    Exit;

  PrintContent(AConfigure, '[AMethodInfo]',              []);
  {$IFDEF LAZARUS}
  PrintContent(AConfigure, 'Count:              %d',     [AMethodInfo^.Count]);
  PrintTitle(AConfigure,   'Entries:            0x%.8x', [DWORD(@AMethodInfo^.Entries)]);
  AConfigure.Inc(1, 0);
  for i := 0 to AMethodInfo^.Count - 1 do
  begin
    PrintTitle(AConfigure,   'Entries[%d]', [i + 1]);
    AConfigure.Inc(1, 0);
    PrintContent(AConfigure, 'Name:               %s',     [AMethodInfo^.Entries[i].Name^]);
    PrintContent(AConfigure, 'Addr:               0x%.8x', [DWORD(AMethodInfo^.Entries[i].Addr)]);
    AConfigure.Dec(1, 0);
  end;
  AConfigure.Dec(1, 0);
  {$ELSE}
  PrintContent(AConfigure, 'MethodCount:        %d',     [AMethodInfo^.MethodCount]);

  pmih := Pointer(@AMethodInfo^.MethodList);
  PrintTitle(AConfigure,   'MethodList:         0x%.8x', [DWORD(pmih)]);
  for i := 1 to AMethodInfo^.MethodCount do
  begin
    AConfigure.Inc(1, 0);
    PrintTitle(AConfigure, 'MethodList[%d]', [i]);
    AConfigure.Inc(1, 0);
    PrintMethodInfoHeader(AConfigure, pmih);
    AConfigure.Dec(2, 0);

    pmih := Pointer(DWORD(pmih) + pmih^.Len);
  end;
  {$ENDIF}
end;

class procedure TRtti.PrintMethodInfoHeader(var AConfigure: TConfigure;
  AMethodInfoHeader: PMethodInfoHeader);
var
  i: Integer;
  pri: PReturnInfo;
  ppi, ppiEnd: PParamInfo;
begin
  if AConfigure.Filter(AMethodInfoHeader) then
    Exit;

  PrintContent(AConfigure, '[AMethodInfoHeader]',        []);
  PrintContent(AConfigure, 'Len:                %d',     [AMethodInfoHeader^.Len]);
  PrintContent(AConfigure, 'Addr:               0x%.8x', [DWORD(AMethodInfoHeader^.Addr)]);
  PrintContent(AConfigure, 'Name:               %s',     [AMethodInfoHeader^.Name]);

  ppiEnd := Pointer(DWORD(AMethodInfoHeader) + AMethodInfoHeader.Len);
  pri := Pointer(DWORD(@AMethodInfoHeader^.Name) + 1 + Length(AMethodInfoHeader^.Name));
  if DWORD(pri) >= DWORD(ppiEnd) then
    Exit;

  PrintTitle(AConfigure,   'ReturnInfo:         0x%.8x', [DWORD(pri)]);
  AConfigure.Inc(1, 0);
  PrintReturnInfo(AConfigure, pri);
  AConfigure.Dec(1, 0);

  i := 0;
  ppi := Pointer(DWORD(pri) + SizeOf(TReturnInfo));
  PrintTitle(AConfigure,   'ParamInfo:          0x%.8x', [DWORD(ppi)]);
  while DWORD(ppi) < DWORD(ppiEnd) do
  begin
    Inc(i);

    AConfigure.Inc(1, 0);
    PrintTitle(AConfigure, 'ParamInfo[%d]', [i]);
    AConfigure.Inc(1, 0);
    PrintParamInfo(AConfigure, ppi);
    AConfigure.Dec(2, 0);

    ppi := Pointer(DWORD(@ppi^.Name) + 1 + Length(ppi^.Name));
  end;
end;

class procedure TRtti.PrintReturnInfo(var AConfigure: TConfigure;
  AReturnInfo: PReturnInfo);
begin
  if AConfigure.Filter(AReturnInfo) then
    Exit;

  PrintContent(AConfigure, '[AReturnInfo]',              []);
  PrintContent(AConfigure, 'Version:            %d',     [AReturnInfo^.Version]);
  PrintContent(AConfigure, 'CallingConvention:  %s',     [CCallingConvention[AReturnInfo^.CallingConvention]]);
  PrintTitle(AConfigure,   'ReturnType:         0x%.8x', [DWORD(AReturnInfo^.ReturnType)]);

  AConfigure.Inc(1, 0);
  {$IFDEF LAZARUS}
  PrintTypeInfo(AConfigure, AReturnInfo^.ReturnType);
  {$ELSE}
  PrintTypeInfo(AConfigure, PPTypeInfo(AReturnInfo^.ReturnType));
  {$ENDIF}
  AConfigure.Dec(1, 0);

  PrintContent(AConfigure, 'ParamSize:          %d',     [AReturnInfo^.ParamSize]);
end;

class procedure TRtti.PrintParamInfo(var AConfigure: TConfigure;
  AParamInfo: PParamInfo);
  function translateParamFlags(AParamFlags: TParamFlags): String;
  begin
    Result := '';

    if pfVar in AParamFlags then Result := Result + 'pfVar,';
    if pfConst in AParamFlags then Result := Result + 'pfConst,';
    if pfArray in AParamFlags then Result := Result + 'pfArray,';
    if pfAddress in AParamFlags then Result := Result + 'pfAddress,';
    if pfReference in AParamFlags then Result := Result + 'pfReference,';
    if pfOut in AParamFlags then Result := Result + 'pfOut,';
    if pfResult in AParamFlags then Result := Result + 'pfResult,';

    if Length(Result) > 0 then
      SetLength(Result, Length(Result) - 1);
  end;
begin
  if AConfigure.Filter(AParamInfo) then
    Exit;

  PrintContent(AConfigure, '[AParamInfo]',               []);
  PrintContent(AConfigure, 'Flags:              %s',     [translateParamFlags(AParamInfo^.Flags)]);
  PrintContent(AConfigure, 'Access:             %d',     [AParamInfo^.Access]);
  PrintContent(AConfigure, 'Name:               %s',     [AParamInfo^.Name]);

  PrintTitle(AConfigure,   'ParamType:          0x%.8x', [DWORD(AParamInfo^.ParamType)]);

  AConfigure.Inc(1, 0);
  {$IFDEF LAZARUS}
  PrintTypeInfo(AConfigure, AParamInfo^.ParamType);
  {$ELSE}
  PrintTypeInfo(AConfigure, PPTypeInfo(AParamInfo^.ParamType));
  {$ENDIF}
  AConfigure.Dec(1, 0);
end;

class procedure TRtti.PrintTypeInfo(var AConfigure: TConfigure;
  ATypeInfo: PTypeInfo);
var
  ptd: PTypeData;
begin
  if AConfigure.Filter(ATypeInfo) then
    Exit;

  PrintContent(AConfigure, '[TypeInfo]',                 []);
  PrintContent(AConfigure, 'Kind:               %s',     [CTypeKind[ATypeInfo^.Kind]]);
  PrintContent(AConfigure, 'Name:               %s',     [ATypeInfo^.Name]);

  ptd := GetTypeData(ATypeInfo);
  PrintTitle(AConfigure,   'TypeData:           0x%.8x', [DWORD(ptd)]);
  AConfigure.Inc(1, 0);
  PrintTypeData(AConfigure, ATypeInfo^.Kind, ptd);
  AConfigure.Dec(1, 0);
end;

class procedure TRtti.PrintTypeInfo(var AConfigure: TConfigure;
  ATypeInfo: PPTypeInfo);
begin
  if not Assigned(ATypeInfo) then
    Exit;

  PrintTypeInfo(AConfigure, ATypeInfo^);
end;

procedure PrintDefault(var AConfigure: TConfigure; ATypeData: PTypeData);
begin

end;

procedure PrintOrdType(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'OrdType:            %s', [COrdType[ATypeData^.OrdType]]);
  TRtti.PrintContent(AConfigure, 'MinValue:           %d', [ATypeData^.MinValue]);
  TRtti.PrintContent(AConfigure, 'MaxValue:           %d', [ATypeData^.MaxValue]);
end;

procedure PrintEnum(var AConfigure: TConfigure; ATypeData: PTypeData);
var
  i: Integer;
  pss: PShortString;
begin
  PrintOrdType(AConfigure, ATypeData);
  TRtti.PrintTitle(AConfigure,   'BaseType:           0x%.8x', [DWORD(ATypeData^.BaseType)]);

  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.BaseType);
  AConfigure.Dec(1, 0);

  pss := @ATypeData^.NameList;
  TRtti.PrintTitle(AConfigure,   'NameList:           0x%.8x', [DWORD(pss)]);
  AConfigure.Inc(1, 0);
  for i := ATypeData^.MinValue to ATypeData^.MaxValue do
  begin
    TRtti.PrintContent(AConfigure, 'NameList:           (%d)%s', [i, pss^]);
    pss := Pointer(DWORD(pss) + 1 + Length(pss^));
  end;
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'EnumUnitName:       %s', [pss^]);
end;

procedure PrintSet(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'OrdType:            %s', [COrdType[ATypeData^.OrdType]]);

  TRtti.PrintTitle(AConfigure,   'CompType:           %s', [DWORD(ATypeData^.CompType)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.CompType);
  AConfigure.Dec(1, 0);
end;

procedure PrintFloat(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'FloatType:          %s', [CFloatType[ATypeData^.FloatType]]);
end;

procedure PrintString(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'MaxLength:          %d', [ATypeData^.MaxLength]);
end;

procedure PrintClass(var AConfigure: TConfigure; ATypeData: PTypeData);
var
  ppd: PPropData;
begin
  TRtti.PrintContent(AConfigure, 'ClassType:          0x%.8x', [DWORD(ATypeData^.ClassType)]);
  TRtti.PrintContent(AConfigure, 'ParentInfo:         0x%.8x', [DWORD(ATypeData^.ParentInfo)]);
  TRtti.PrintContent(AConfigure, 'PropCount:          %d',     [ATypeData^.PropCount]);
  TRtti.PrintContent(AConfigure, 'UnitName:           %s',     [ATypeData^.UnitName]);

  ppd := Pointer(DWORD(@ATypeData^.UnitName) + Length(ATypeData^.UnitName) + 1);
  TRtti.PrintTitle(AConfigure,   'PropData:           0x%.8x', [DWORD(ppd)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintPropData(AConfigure, ppd);
  AConfigure.Dec(1, 0);
end;

procedure PrintMethod(var AConfigure: TConfigure; ATypeData: PTypeData);
  function translateParamFlag(AFlags: TypInfo.TParamFlags): String;
  var
    pf: TParamFlag;
  begin
    Result := '';

    for pf := Low(TParamFlag) to High(TParamFlag) do
      if pf in AFlags then
        Result := Result + CParamFlag[pf] + ',';

    if Length(Result) > 0 then
      SetLength(Result, Length(Result) - 1);
  end;
var
  i: Integer;
  ppfs: Pointer;
begin
  TRtti.PrintContent(AConfigure, 'MethodKind:         %s',     [CMethodKind[ATypeData^.MethodKind]]);
  TRtti.PrintContent(AConfigure, 'ParamCount:         %d',     [ATypeData^.ParamCount]);

  ppfs := @ATypeData^.ParamList;
  TRtti.PrintTitle(AConfigure,   'ParamList:          0x%.8x', [DWORD(ppfs)]);
  AConfigure.Inc(1, 0);
  for i := 1 to ATypeData^.ParamCount do
  begin
    TRtti.PrintTitle(AConfigure, 'ParamList[%d]', [i]);
    AConfigure.Inc(1, 0);
    TRtti.PrintContent(AConfigure, '[ParamList]',                []);
    TRtti.PrintContent(AConfigure, 'Flags:              0x%.8x(%s)',     [DWORD(ppfs), translateParamFlag(PParamFlags(ppfs)^)]);
    ppfs := Pointer(DWORD(ppfs) + SizeOf(TParamFlags));
    TRtti.PrintContent(AConfigure, 'ParamName:          0x%.8x(%s)',     [DWORD(ppfs), PShortString(ppfs)^]);
    ppfs := Pointer(DWORD(ppfs) + PByte(ppfs)^ + 1);
    TRtti.PrintContent(AConfigure, 'TypeName:           0x%.8x(%s)',     [DWORD(ppfs), PShortString(ppfs)^]);
    AConfigure.Dec(1, 0);

    ppfs := Pointer(DWORD(ppfs) + PByte(ppfs)^ + 1);
  end;
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'ResultType:         0x%.8x(%s)', [DWORD(ppfs), PShortString(ppfs)^]);
  {$IFDEF LAZARUS}
  ppfs := Pointer(DWORD(ppfs) + PByte(ppfs)^ + 1);
  TRtti.PrintTitle(AConfigure,   'ResultTypeRef:      0x%.8x', [DWORD(ppfs)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, PPTypeInfo(ppfs)^);
  AConfigure.Dec(1, 0);

  ppfs := Pointer(DWORD(ppfs) + SizeOf(PTypeInfo));
  TRtti.PrintContent(AConfigure, 'CC:                 %s', [CCallConv[PCallConv(ppfs)^]]);
  ppfs := Pointer(DWORD(ppfs) + SizeOf(TCallConv));
  TRtti.PrintTitle(AConfigure,   'ParamTypeRefs:      0x%.8x', [DWORD(ppfs)]);
  AConfigure.Inc(1, 0);
  for i := 1 to ATypeData^.ParamCount do
  begin
    TRtti.PrintTypeInfo(AConfigure, PPTypeInfo(ppfs)^);
    ppfs := Pointer(DWORD(ppfs) + SizeOf(PTypeInfo));
  end;
  AConfigure.Dec(1, 0);
  {$ENDIF}
end;

procedure PrintInterface(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintTitle(AConfigure,   'IntfParent:         0x%.8x', [DWORD(ATypeData^.IntfParent)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.IntfParent);
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'IntfFlags:          %s',     [TranslateIntfFlagsBase(ATypeData^.IntfFlags)]);
  TRtti.PrintContent(AConfigure, 'Guid:               %s',     [GUIDToString(ATypeData^.Guid)]);
  TRtti.PrintContent(AConfigure, 'IntfUnit:           %s',     [ATypeData^.IntfUnit]);
end;

procedure PrintInt64(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'MinInt64Value:      %I64d',  [ATypeData^.MinInt64Value]);
  TRtti.PrintContent(AConfigure, 'MaxInt64Value:      %I64d',  [ATypeData^.MaxInt64Value]);
end;

procedure PrintDynArray(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'elSize:             %d',     [ATypeData^.elSize]);
  TRtti.PrintContent(AConfigure, 'elType:             0x%.8x', [DWORD(ATypeData^.elType)]);
  TRtti.PrintContent(AConfigure, 'varType:            %d',     [ATypeData^.varType]);
  TRtti.PrintContent(AConfigure, 'elType2:            0x%.8x', [DWORD(ATypeData^.elType2)]);
  TRtti.PrintContent(AConfigure, 'DynUnitName:        %s',     [ATypeData^.DynUnitName]);
end;

{$IFDEF LAZARUS}
procedure PrintArray(var AConfigure: TConfigure; ATypeData: PTypeData);
var
  i: Integer;
begin
  TRtti.PrintTitle(AConfigure,   'ArrayData:          0x%.8x', [DWORD(@ATypeData^.ArrayData)]);

  AConfigure.Inc(1, 0);
  TRtti.PrintContent(AConfigure, '[TArrayTypeData]',           []);
  TRtti.PrintContent(AConfigure, 'Size:               %d',     [ATypeData^.ArrayData.Size]);
  TRtti.PrintContent(AConfigure, 'ElCount:            %d',     [ATypeData^.ArrayData.ElCount]);

  TRtti.PrintTitle(AConfigure,   'ElType:             0x%.8x', [DWORD(ATypeData^.ArrayData.ElType)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.ArrayData.ElType);
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'DimCount:           %d',     [ATypeData^.ArrayData.DimCount]);

  TRtti.PrintTitle(AConfigure,   'Dims:               0x%.8x', [DWORD(@ATypeData^.ArrayData.Dims)]);
  AConfigure.Inc(1, 0);
  for i := 0 to ATypeData^.ArrayData.DimCount - 1 do
  begin
    TRtti.PrintTitle(AConfigure, 'Dims[%d]', [i + 1]);
    AConfigure.Inc(1, 0);
    TRtti.PrintTypeInfo(AConfigure, ATypeData^.ArrayData.Dims[i]);
    AConfigure.Dec(1, 0);
  end;
  AConfigure.Dec(1, 0);
end;

procedure PrintAString(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintContent(AConfigure, 'CodePage:           %d', [ATypeData^.CodePage]);
end;

procedure PrintClassRef(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintTitle(AConfigure,   'InstanceType:       0x%.8x', [DWORD(ATypeData^.InstanceType)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.InstanceType);
  AConfigure.Dec(1, 0);
end;

procedure PrintHelper(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintTitle(AConfigure,   'HelperParent:       0x%.8x', [DWORD(ATypeData^.HelperParent)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.HelperParent);
  AConfigure.Dec(1, 0);

  TRtti.PrintTitle(AConfigure,   'ExtendedInfo:       0x%.8x', [DWORD(ATypeData^.ExtendedInfo)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.ExtendedInfo);
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'HelperProps:        %d',     [ATypeData^.HelperProps]);
  TRtti.PrintContent(AConfigure, 'HelperUnit:         %s',     [ATypeData^.HelperUnit]);
end;

procedure PrintInterfaceRaw(var AConfigure: TConfigure; ATypeData: PTypeData);
var
  pss: PShortString;
begin
  TRtti.PrintTitle(AConfigure,   'RawIntfParent:      0x%.8x', [DWORD(ATypeData^.RawIntfParent)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.RawIntfParent);
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'RawIntfFlags:       %s',     [TranslateIntfFlagsBase(ATypeData^.RawIntfFlags)]);
  TRtti.PrintContent(AConfigure, 'IID:                %s',     [GUIDToString(ATypeData^.IID)]);
  pss := @ATypeData^.RawIntfUnit;
  TRtti.PrintContent(AConfigure, 'RawIntfUnit:        %s',     [pss^]);
  pss := Pointer(DWORD(pss) + 1 + Length(pss^));
  TRtti.PrintContent(AConfigure, 'IIDStr:             %s',     [pss^]);
end;

procedure PrintPointer(var AConfigure: TConfigure; ATypeData: PTypeData);
begin
  TRtti.PrintTitle(AConfigure,   'RefType:            0x%.8x', [DWORD(ATypeData^.RefType)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.RefType);
  AConfigure.Dec(1, 0);
end;

procedure PrintProcVar(var AConfigure: TConfigure; ATypeData: PTypeData);
var
  i: Integer;
  ppp: PProcedureParam;
begin
  TRtti.PrintTitle(AConfigure,   'ProcSig:            0x%.8x', [DWORD(@ATypeData^.ProcSig)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintContent(AConfigure, 'Flags:              %d',     [ATypeData^.ProcSig.Flags]);
  TRtti.PrintContent(AConfigure, 'CC:                 %s',     [CCallConv[ATypeData^.ProcSig.CC]]);

  TRtti.PrintTitle(AConfigure,   'ResultType:         0x%.8x', [DWORD(ATypeData^.ProcSig.ResultType)]);
  AConfigure.Inc(1, 0);
  TRtti.PrintTypeInfo(AConfigure, ATypeData^.ProcSig.ResultType);
  AConfigure.Dec(1, 0);

  TRtti.PrintContent(AConfigure, 'ParamCount:         %d',     [ATypeData^.ProcSig.ParamCount]);
  ppp := Pointer(DWORD(ATypeData) + SizeOf(TProcedureSignature));
  TRtti.PrintTitle(AConfigure,   'Params:             0x%.8x', [DWORD(ppp)]);
  AConfigure.Inc(1, 0);
  for i := 0 to ATypeData^.ParamCount - 1 do
  begin
    TRtti.PrintTitle(AConfigure,   'Params[%d]', [i + 1]);
    AConfigure.Inc(1, 0);
    TRtti.PrintContent(AConfigure, 'Flags:              %d',     [ppp^.Flags]);

    TRtti.PrintTitle(AConfigure,   'ParamType:          0x%.8x', [DWORD(ppp^.ParamType)]);
    AConfigure.Inc(1, 0);
    TRtti.PrintTypeInfo(AConfigure, ppp^.ParamType);
    AConfigure.Dec(1, 0);

    TRtti.PrintContent(AConfigure, 'Name:               %s',     [ppp^.Name]);
    AConfigure.Dec(1, 0);

    ppp := Pointer(DWORD(ppp) + 1 + Length(ppp^.Name));
  end;
  AConfigure.Dec(2, 0);
end;

procedure PrintRecord(var AConfigure: TConfigure; ATypeData: PTypeData);
var
  i: Integer;
  pmf: PManagedField;
begin
  TRtti.PrintContent(AConfigure, 'RecSize:            %d',     [ATypeData^.RecSize]);
  TRtti.PrintContent(AConfigure, 'ManagedFldCount:    %d',     [ATypeData^.ManagedFldCount]);

  pmf := Pointer(DWORD(ATypeData) + SizeOf(Integer) * 2);
  TRtti.PrintTitle(AConfigure,   'ManagedFields:      0x%.8x', [DWORD(pmf)]);
  AConfigure.Inc(1, 0);
  for i := 0 to ATypeData^.ManagedFldCount - 1 do
  begin
    TRtti.PrintTitle(AConfigure, 'ManagedFields[%d]', [i + 1]);
    AConfigure.Inc(1, 0);
    TRtti.PrintTitle(AConfigure, 'TypeRef             0x%.8x', [DWORD(pmf[i].TypeRef)]);
    AConfigure.Inc(1, 0);
    TRtti.PrintTypeInfo(AConfigure, pmf[i].TypeRef);
    AConfigure.Dec(1, 0);
    TRtti.PrintContent(AConfigure, 'FldOffset:          %d',     [pmf[i].FldOffset]);
    AConfigure.Dec(1, 0);
  end;
  AConfigure.Dec(1, 0);
end;
{$ENDIF}

class procedure TRtti.PrintTypeData(var AConfigure: TConfigure;
  ATypeKind: TTypeKind; ATypeData: PTypeData);
type
  TPrintProc = procedure(var AConfigure: TConfigure; ATypeData: PTypeData);
const
  cPrintProc: array[TTypeKind] of TPrintProc = (
    {$IFDEF LAZARUS}
    {tkUnknown}PrintDefault, {tkInteger}PrintOrdType, {tkChar}PrintOrdType,
    {tkEnumeration}PrintEnum, {tkFloat}PrintFloat, {tkSet}PrintSet,
    {tkMethod}PrintMethod, {tkSString}PrintString, {tkLString}PrintDefault,
    {tkAString}PrintAString, {tkWString}PrintDefault, {tkVariant}PrintDefault,
    {tkArray}PrintArray, {tkRecord}PrintRecord, {tkInterface}PrintInterface,
    {tkClass}PrintClass, {tkObject}PrintDefault, {tkWChar}PrintOrdType,
    {tkBool}PrintOrdType, {tkInt64}PrintInt64, {tkQWord}PrintInt64,
    {tkDynArray}PrintDynArray, {tkInterfaceRaw}PrintInterfaceRaw, {tkProcVar}PrintProcVar,
    {tkUString}PrintDefault, {tkUChar}PrintDefault, {tkHelper}PrintHelper,
    {tkFile}PrintDefault, {tkClassRef}PrintClassRef, {tkPointer}PrintPointer);
    {$ELSE}
    {tkUnknown}PrintDefault, {tkInteger}PrintOrdType, {tkChar}PrintOrdType,
    {tkEnumeration}PrintEnum, {tkFloat}PrintFloat, {tkString}PrintString,
    {tkSet}PrintSet, {tkClass}PrintClass, {tkMethod}PrintMethod,
    {tkWChar}PrintOrdType, {tkLString}PrintDefault, {tkWString}PrintDefault,
    {tkVariant}PrintDefault, {tkArray}PrintDefault, {tkRecord}PrintDefault,
    {tkInterface}PrintInterface, {tkInt64}PrintInt64, {tkDynArray}PrintDynArray);
    {$ENDIF}
begin
  if AConfigure.Filter(ATypeKind, ATypeData) then
    Exit;

  PrintContent(AConfigure, '[TypeData]',                 []);
  cPrintProc[ATypeKind](AConfigure, ATypeData);
end;

class procedure TRtti.PrintPropData(var AConfigure: TConfigure;
  APropData: PPropData);
var
  i: Integer;
  ppi: PPropInfo;
begin
  if AConfigure.Filter(APropData) then
    Exit;

  PrintContent(AConfigure, '[PropData]',                 []);
  PrintContent(AConfigure, 'PropCount:          %d',     [APropData^.PropCount]);

  ppi := PPropInfo(@APropData^.PropList);
  PrintTitle(AConfigure,   'PropList:           0x%.8x', [DWORD(ppi)]);
  for i := 1 to APropData^.PropCount do
  begin
    AConfigure.Inc(1, 0);
    PrintTitle(AConfigure, 'PropList[%d]', [i]);
    AConfigure.Inc(1, 0);
    PrintPropInfo(AConfigure, ppi);
    AConfigure.Dec(2, 0);

    ppi := Pointer(DWORD(@ppi^.Name) + Length(ppi^.Name) + 1);
  end;
end;

class procedure TRtti.PrintPropInfo(var AConfigure: TConfigure;
  APropInfo: PPropInfo);
begin
  if AConfigure.Filter(APropInfo) then
    Exit;

  PrintContent(AConfigure, '[PropInfo]',                 []);
  PrintContent(AConfigure, 'GetProc:            0x%.8x', [DWORD(APropInfo^.GetProc)]);
  PrintContent(AConfigure, 'SetProc:            0x%.8x', [DWORD(APropInfo^.SetProc)]);
  PrintContent(AConfigure, 'StoredProc:         0x%.8x', [DWORD(APropInfo^.StoredProc)]);
  PrintContent(AConfigure, 'Index:              %d',     [APropInfo^.Index]);
  PrintContent(AConfigure, 'Default:            %d',     [APropInfo^.Default]);
  PrintContent(AConfigure, 'NameIndex:          %d',     [APropInfo^.NameIndex]);
  PrintContent(AConfigure, 'Name:               %s',     [APropInfo^.Name]);

  PrintTitle(AConfigure,   'PropType:           0x%.8x', [DWORD(APropInfo^.PropType)]);
  AConfigure.Inc(1, 0);
  PrintTypeInfo(AConfigure, APropInfo^.PropType);
  AConfigure.Dec(1, 0);
end;

class function TRtti.GetVmt(AObject: TObject): PVmt;
begin
  {$IFDEF LAZARUS}
  Result := PVmt(Pointer(AObject)^);
  {$ELSE}
  Result := PVmt(PInteger(AObject)^ + vmtSelfPtr);
  {$ENDIF}
end;

class procedure TRtti.PrintTitle(var AConfigure: TConfigure;
  ATitle: String; AParams: array of const);
begin
  AConfigure.PrintTitle(Format(ATitle, AParams));
end;

class procedure TRtti.PrintContent(var AConfigure: TConfigure;
  AContent: String; AParams: array of const);
begin
  AConfigure.PrintContent(Format(AContent, AParams));
end;

class procedure TRtti.DoPrint(AValue: String);
begin
  WriteView(AValue);
  //WriteLog(AValue + #$D#$A, './Test.log');
end;

end.
