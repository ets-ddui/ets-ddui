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
unit UDUICoordinateTransform;

interface

uses
  Windows, IGDIPlus;

type
  TDUIMatrix = record
    F00, F10: Extended;
    F01, F11: Extended;
  end;

  TDUICoord = record
    class operator Implicit(APoint: TPoint): TDUICoord;
    class operator Multiply(ALeft: TDUICoord; ARight: TDUIMatrix): TDUICoord;
    class operator Add(ALeft: TDUICoord; ARight: TDUICoord): TDUICoord;
    class operator Subtract(ALeft: TDUICoord; ARight: TDUICoord): TDUICoord;
    case Integer of
      0: (FLeft, FTop: Integer);
      1: (FWidth, FHeight: Integer);
  end;

  TDUICoords = record
    FCoords: array of TDUICoord;
    class operator Multiply(ALeft: TDUICoords; ARight: TDUIMatrix): TDUICoords;
    class operator Add(ALeft: TDUICoords; ARight: TDUICoord): TDUICoords;
    class operator Add(ALeft, ARight: TDUICoords): TDUICoords;
  end;

  TPoints = array of TPoint;

function MakeDUIMatrix(A00, A10, A01, A11: Extended): TDUIMatrix;
function MakeDUICoord(ALeft, ATop: Integer): TDUICoord;
function MakeDUICoords(APoints: array of Integer): TDUICoords;
function MakePoint(AValue: TDUICoord): TPoint;
function MakePoints(AValue: TDUICoords): TPoints;
function MakeGPRect(AValue: TDUICoords): TGPRect;

implementation

function MakeDUIMatrix(A00, A10, A01, A11: Extended): TDUIMatrix;
begin
  Result.F00 := A00;
  Result.F01 := A01;
  Result.F10 := A10;
  Result.F11 := A11;
end;

function MakeDUICoord(ALeft, ATop: Integer): TDUICoord;
begin
  Result.FLeft := ALeft;
  Result.FTop := ATop;
end;

function MakeDUICoords(APoints: array of Integer): TDUICoords;
var
  i, iCount: Integer;
begin
  iCount := Length(APoints) div 2;
  SetLength(Result.FCoords, iCount);
  for i := 0 to iCount - 1 do
    Result.FCoords[i] := MakeDUICoord(APoints[2 * i], APoints[2 * i + 1]);
end;

function MakePoint(AValue: TDUICoord): TPoint;
begin
  Result.X := AValue.FLeft;
  Result.Y := AValue.FTop;
end;

function MakePoints(AValue: TDUICoords): TPoints;
var
  i, iCount: Integer;
begin
  iCount := Length(AValue.FCoords);
  SetLength(Result, iCount);
  for i := 0 to iCount - 1 do
  begin
    Result[i].X := AValue.FCoords[i].FLeft;
    Result[i].Y := AValue.FCoords[i].FTop;
  end;
end;

function MakeGPRect(AValue: TDUICoords): TGPRect;
begin
  case Length(AValue.FCoords) of
    0: Result := MakeRect(0, 0, 0, 0);
    1: Result := MakeRect(AValue.FCoords[0].FLeft, AValue.FCoords[0].FTop, 0, 0);
  else
    Result := MakeRect(AValue.FCoords[0].FLeft, AValue.FCoords[0].FTop,
      AValue.FCoords[1].FWidth, AValue.FCoords[1].FHeight);
  end;
end;

class operator TDUICoord.Implicit(APoint: TPoint): TDUICoord;
begin
  Result.FLeft := APoint.X;
  Result.FTop := APoint.Y;
end;

class operator TDUICoord.Multiply(ALeft: TDUICoord; ARight: TDUIMatrix): TDUICoord;
  function toInteger(AValue: Extended): Integer;
  begin
    if AValue > 0 then
      Result := Trunc(AValue + 0.5)
    else if AValue < 0 then
      Result := Trunc(AValue - 0.5)
    else
      Result := 0;
  end;
begin
  Result.FLeft := toInteger(ALeft.FLeft * ARight.F00 + ALeft.FTop * ARight.F01);
  Result.FTop := toInteger(ALeft.FLeft * ARight.F10 + ALeft.FTop * ARight.F11);
end;

class operator TDUICoord.Add(ALeft: TDUICoord; ARight: TDUICoord): TDUICoord;
begin
  Result.FLeft := ALeft.FLeft + ARight.FLeft;
  Result.FTop := ALeft.FTop + ARight.FTop;
end;

class operator TDUICoord.Subtract(ALeft: TDUICoord; ARight: TDUICoord): TDUICoord;
begin
  Result.FLeft := ALeft.FLeft - ARight.FLeft;
  Result.FTop := ALeft.FTop - ARight.FTop;
end;

class operator TDUICoords.Multiply(ALeft: TDUICoords; ARight: TDUIMatrix): TDUICoords;
var
  i, iCount: Integer;
begin
  iCount := Length(ALeft.FCoords);
  SetLength(Result.FCoords, iCount);
  for i := 0 to iCount - 1 do
    Result.FCoords[i] := ALeft.FCoords[i] * ARight;
end;

class operator TDUICoords.Add(ALeft: TDUICoords; ARight: TDUICoord): TDUICoords;
var
  i, iCount: Integer;
begin
  iCount := Length(ALeft.FCoords);
  SetLength(Result.FCoords, iCount);
  for i := 0 to iCount - 1 do
    Result.FCoords[i] := ALeft.FCoords[i] + ARight;
end;

class operator TDUICoords.Add(ALeft, ARight: TDUICoords): TDUICoords;
var
  iLeftLen, iRightLen: Integer;
begin
  iLeftLen := Length(ALeft.FCoords);
  iRightLen := Length(ARight.FCoords);

  SetLength(Result.FCoords, iLeftLen + iRightLen);
  if iLeftLen > 0 then
    Move(ALeft.FCoords[0], Result.FCoords[0], iLeftLen * SizeOf(TDUICoord));
  if iRightLen > 0 then
    Move(ARight.FCoords[0], Result.FCoords[iLeftLen], iRightLen * SizeOf(TDUICoord));
end;

end.
