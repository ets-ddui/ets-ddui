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
unit UDUIRcStream;

interface

uses
  Windows, Classes, SysUtils, StrUtils, Variants, UTool;

type
  TDfmPrefix = record
    FFlags: TFilerFlags;
    FChildPos: Integer;
  end;

  TDfmStream = class(TResourceStream)
  public
    constructor Create(AClass: TClass); overload;
    constructor Create(AObject: TObject); overload;
    procedure Debug(AStrings: TStrings);
    function NextType: TValueType;
    function ReadType: TValueType;
    function ReadSignature: String;
    function ReadPrefix: TDfmPrefix;
    function ReadStr: String;
    function ReadValue(var AType: TValueType): Variant;
  end;

implementation

{ TDfmStream }

constructor TDfmStream.Create(AClass: TClass);
begin
  inherited Create(FindResourceHInstance(FindHInstance(AClass)), AClass.ClassName, RT_RCDATA);
end;

constructor TDfmStream.Create(AObject: TObject);
begin
  Create(AObject.ClassType);
end;

procedure TDfmStream.Debug(AStrings: TStrings);
  function readList: String;
  var
    vt: TValueType;
    v: Variant;
  begin
    Result := '';

    while True do
    begin
      v := ReadValue(vt);
      if vt = vaNull then
        Break;

      if Result <> '' then
        Result := Result + ', ';
      Result := Result + VarToStr(v);
    end;
  end;
  procedure readPropertys(ALevel: Integer);
  var
    vt: TValueType;
    sBlank, sPropertyName: String;
    v: Variant;
    i: Integer;
  begin
    sBlank := DupeString(' ', ALevel * 2);

    while True do
    begin
      sPropertyName := ReadStr;
      if sPropertyName = '' then
        Break;

      v := ReadValue(vt);
      case vt of
        vaSet: AStrings.Append(Format('%s%s = [%s]', [sBlank, sPropertyName, VarToStr(v)]));
        vaList: AStrings.Append(Format('%s%s = (%s)', [sBlank, sPropertyName, readList]));
        vaCollection:
        begin
          if NextType = vaNull then
            AStrings.Append(Format('%s%s = <>', [sBlank, sPropertyName]))
          else
          begin
            AStrings.Append(Format('%s%s = <', [sBlank, sPropertyName]));
            while True do
            begin
              v := ReadValue(vt);
              if vt = vaNull then
                Break;

              i := -1;
              if vt in [vaInt8, vaInt16, vaInt32] then
              begin
                i := VarToInt(v);
                ReadValue(vt);
              end;

              if vt <> vaList then
              begin
                WriteView('Collection格式不正确');
                Break;
              end;

              AStrings.Append(Format('%sitem(%d)', [DupeString(' ', (ALevel + 1) * 2), i]));
              readPropertys(ALevel + 2);
              AStrings.Append(Format('%send', [DupeString(' ', (ALevel + 1) * 2)]));
            end;
            AStrings.Append(Format('%s>', [sBlank]));
          end;
        end
      else
        AStrings.Append(Format('%s%s = %s', [sBlank, sPropertyName, VarToStr(v)]));
      end;
    end;
  end;
  procedure readComponent(ALevel: Integer);
  var
    sTemp, sBlank: String;
  begin
    sBlank := DupeString(' ', ALevel * 2);

    with ReadPrefix do
    begin
      sTemp := ReadStr;
      AStrings.Append(Format('%sobject %s: %s [%d] [%d]',
        [sBlank, ReadStr, sTemp, Byte(FFlags), FChildPos]));
    end;
    readPropertys(ALevel + 1);
    while NextType <> vaNull do
      readComponent(ALevel + 1);
    ReadType;
    AStrings.Append(Format('%send', [sBlank]));
  end;
var
  iPosition: Integer;
begin
  iPosition := Seek(0, soFromCurrent);
  try
    Seek(0, soFromBeginning);
    AStrings.Clear;

    AStrings.Append(ReadSignature);
    readComponent(0);
    if Position < Size then
      WriteView('还有剩余数据未读取(%d/%d)', [Position, Size]);
  finally
    Seek(iPosition, soFromBeginning);
  end;
end;

function TDfmStream.NextType: TValueType;
begin
  Read(Result, SizeOf(TValueType));
  Seek(-1 * SizeOf(TValueType), soFromCurrent);
end;

function TDfmStream.ReadType: TValueType;
begin
  Read(Result, SizeOf(TValueType));
end;

function TDfmStream.ReadSignature: String;
begin
  SetLength(Result, SizeOf(Longint));
  Read(Result[1], SizeOf(Longint));
end;

function TDfmStream.ReadPrefix: TDfmPrefix;
var
  vt: TValueType;
begin
  Result.FFlags := [];
  Result.FChildPos := -1;

  if Byte(NextType) and $F0 = $F0 then
  begin
    Byte(Result.FFlags) := Byte(ReadType) and $0F;
    if ffChildPos in Result.FFlags then
    begin
      Result.FChildPos := VarToInt(ReadValue(vt));
      if not (vt in [vaInt8, vaInt16, vaInt32]) then
        WriteView('资源文件格式不正确');
    end;
  end;
end;

function TDfmStream.ReadStr: String;
var
  iLen: Byte;
begin
  Read(iLen, SizeOf(Byte));
  SetLength(Result, iLen);
  Read(Result[1], iLen);
end;

function TDfmStream.ReadValue(var AType: TValueType): Variant;
  function readShort: ShortInt;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readSmall: SmallInt;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readInteger: LongInt;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readInt64: Int64;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readFloat: Extended;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readDouble: Double;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readSingle: Single;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readCurrency: Currency;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readDate: TDateTime;
  begin
    Read(Result, SizeOf(Result));
  end;
  function readString: String;
  var
    iLen: Byte;
  begin
    Read(iLen, SizeOf(iLen));
    SetLength(Result, iLen);
    Read(Result[1], iLen);
  end;
  function readLString: String;
  var
    iLen: Integer;
  begin
    Read(iLen, SizeOf(iLen));
    SetLength(Result, iLen);
    Read(Result[1], iLen);
  end;
  function readWString: WideString;
  var
    iLen: Integer;
  begin
    Read(iLen, SizeOf(iLen));
    SetLength(Result, iLen);
    Read(Result[1], iLen * 2);
  end;
  function readUTF8String: WideString;
  begin
    Result := Utf8Decode(readLString);
  end;
  function readSet: String;
  var
    sTemp: String;
  begin
    Result := '';

    while True do
    begin
      sTemp := ReadStr;
      if sTemp = '' then
        Break;

      if Result <> '' then
        Result := Result + ', ';
      Result := Result + sTemp;
    end;
  end;
begin
  AType := ReadType;

  case AType of
    vaNil, vaNull: ; //什么都不做
    vaInt8: Result := readShort;
    vaInt16: Result := readSmall;
    vaInt32: Result := readInteger;
    vaInt64: Result := readInt64;
    vaExtended: Result := readFloat;
    vaDouble: Result := readDouble;
    vaSingle: Result := readSingle;
    vaCurrency: Result := readCurrency;
    vaDate: Result := readDate;
    vaString: Result := readString;
    vaLString: Result := readLString;
    vaWString: Result := readWString;
    vaUTF8String: Result := readUTF8String;
    vaIdent: Result := readString;
    vaFalse: Result := False;
    vaTrue: Result := True;
    vaBinary: Result := readLString;
    vaSet: Result := readSet;
    vaList: ; //什么都不做
    vaCollection: ; //什么都不做
  end;
end;

end.
