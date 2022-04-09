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
unit UDUIGridHashMap;

interface

uses
  SysUtils, UDUIGrid;

{$I DGLCfg.inc_h}

//{$define __DGL_KeyType_Is_ValueType}
type
  _KeyType = TDUIGridCoord;
  _ValueType = String;

const
  _NULL_Value: Pointer = nil;

//{$define _DGL_NotHashFunction}
function _HashValue(const AKey: _KeyType): Cardinal;

{$define _DGL_Compare_Key}
function _IsEqual_Key(const ALeft, ARight: _KeyType): Boolean;
function _IsLess_Key(const ALeft, ARight: _KeyType): Boolean;

{$I HashMap.inc_h}

implementation

function _HashValue(const AKey: _KeyType): Cardinal;
begin
  Result := Cardinal(AKey.FCol.FIndex);
  Result := Result shl 16 + Result shr 16;
  Result := Result xor Cardinal(AKey.FRow.FIndex);

  //以下部分从微软的hash_map中拷贝而来
  Result := (Result xor $DEADBEEF) and $7FFFFFFF;
  Result := 16807 * (Result mod 127773) - 2836 * (Result div 127773);
  if Result > $7FFFFFFF then
    Result := Result - $7FFFFFFF;
end;

function _IsEqual_Key(const ALeft, ARight: _KeyType): Boolean;
begin
  Result := (ALeft.FCol.FIndex = ARight.FCol.FIndex) and (ALeft.FRow.FIndex = ARight.FRow.FIndex);
end;

function _IsLess_Key(const ALeft, ARight: _KeyType): Boolean;
begin
  if Cardinal(ALeft.FCol.FIndex) < Cardinal(ARight.FCol.FIndex) then
    Result := True
  else if (Cardinal(ALeft.FCol.FIndex) = Cardinal(ARight.FCol.FIndex))
    and (Cardinal(ALeft.FRow.FIndex) < Cardinal(ARight.FRow.FIndex)) then
    Result := True
  else
    Result := False;
end;

{$I HashMap.inc_pas}

end.
