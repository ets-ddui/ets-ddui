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

  //���²��ִ�΢���hash_map�п�������
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
