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
unit UDUIGridEx;

interface

uses
  SysUtils, UDUICore, UDUIGrid;

type
  TDUIFixedProperty = record
    FSize: Integer;
    FVisible: Boolean;
  end;

  TDUIFixedPropertys = array of TDUIFixedProperty;

  TDUIDrawGrid = class(TDUIGridBase)
  private
    FCount: array[TDUIRowColType] of Longint;
    FFixedCount: array[TDUIRowColType] of Longint;
    FPropertys: array[TDUIRowColType] of TDUIFixedPropertys;
    function GetCount(const AType: TDUIRowColType): Longint;
    procedure SetCount(const AType: TDUIRowColType; const AValue: Longint);
    function GetFixedCount(const AType: TDUIRowColType): Longint;
    procedure SetFixedCount(const AType: TDUIRowColType; const AValue: Longint);
    procedure AdjustPropertys(AType: TDUIRowColType; ANewLength: Cardinal);
    function GetCells(ACol, ARow: Integer): String;
    procedure SetCells(ACol, ARow: Integer; const AValue: String);
    function GetCellWidth(ACol: Integer): Integer;
    procedure SetCellWidth(ACol: Integer; const AValue: Integer);
    function GetCellHeight(ARow: Integer): Integer;
    procedure SetCellHeight(ARow: Integer; const AValue: Integer);
  protected
    function CalcMovedID(const AIndex: TDUIRowColID;
      ACount: Integer; AMoveModes: TDUIMoveModes): TDUIRowColID; override;
    function DoCompare(const ALeft, ARight: TDUIRowColID): Integer; override;
    function IsFirst(AIndex: TDUIRowColID): Boolean; override;
    function IsEof(AIndex: TDUIRowColID): Boolean; override;
    function First(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID; override;
    function Last(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID; override;
    function Eof(AType: TDUIRowColType): TDUIRowColID; override;
    function GetMinTopLeft(AType: TDUIRowColType): TDUIRowColID; override;
    function PosToID(AType: TDUIRowColType; APosition: Integer): TDUIRowColID; override;
    procedure IDsToPos(var AResMin, AResMax, AResPos: Integer;
      const AMin, AMax, APos: TDUIRowColID); override;
    function GetEditClass(const ACol, ARow: TDUIRowColID): TDUIKeyboardBaseClass; override;
    procedure InitEditor(AEditor: TDUIKeyboardBase); override;
    function GetEditText(const ACol, ARow: TDUIRowColID): String; override;
    function GetCellSize(const AIndex: TDUIRowColID): Integer; override;
    procedure SetCellSize(const AIndex: TDUIRowColID; const AValue: Integer); override;
    function GetCellVisible(const AIndex: TDUIRowColID): Boolean; override;
    procedure SetCellVisible(const AIndex: TDUIRowColID; const AValue: Boolean); override;
  public
    property Cells[ACol: Integer; ARow: Integer]: String read GetCells write SetCells;
    property CellHeight[ARow: Integer]: Integer read GetCellHeight write SetCellHeight;
    property CellWidth[ACol: Integer]: Integer read GetCellWidth write SetCellWidth;
  published
    //ColCount、RowCount必须放在FixedCols、FixedRows的前面
    property ColCount: Longint index rctCol read GetCount write SetCount default 0;
    property RowCount: Longint index rctRow read GetCount write SetCount default 0;
    property FixedCols: Longint index rctCol read GetFixedCount write SetFixedCount default 0;
    property FixedRows: Longint index rctRow read GetFixedCount write SetFixedCount default 0;
    property DefaultColWidth;
    property DefaultRowHeight;
    property GridLineWidth;
    property Options;
    property TitleHeight;
    property TitleWidth;
  end;

implementation

uses
  UDUIEdit;

{ TDUIDrawGrid }

function TDUIDrawGrid.CalcMovedID(const AIndex: TDUIRowColID;
  ACount: Integer; AMoveModes: TDUIMoveModes): TDUIRowColID;
var
  iIndex, iStep: Integer;
begin
  Result := AIndex;
  if (ACount = 0) or IsEof(AIndex) then
    Exit;

  iIndex := Integer(Result.FIndex);
  iStep := IfThen(ACount > 0, 1, -1);
  while ACount <> 0 do
  begin
    iIndex := iIndex + iStep;
    if iIndex < 0 then
    begin
      Result := First(AIndex.FType);
      Exit;
    end
    else if iIndex > GetCount(AIndex.FType) then
    begin
      Result := Eof(AIndex.FType);
      Exit;
    end;

    Result.FIndex := Pointer(iIndex);
    if not Conform(Result, AMoveModes) then
      Continue;

    ACount := ACount - iStep;
  end;
end;

function TDUIDrawGrid.DoCompare(const ALeft, ARight: TDUIRowColID): Integer;
begin
  Result := Integer(ALeft.FIndex) - Integer(ARight.FIndex);
end;

function TDUIDrawGrid.IsFirst(AIndex: TDUIRowColID): Boolean;
begin
  Result := Integer(AIndex.FIndex) = 0;
end;

function TDUIDrawGrid.IsEof(AIndex: TDUIRowColID): Boolean;
begin
  Result := (Integer(AIndex.FIndex) < 0)
    or (Integer(AIndex.FIndex) > GetCount(AIndex.FType));
end;

function TDUIDrawGrid.First(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := AType;
  Result.FIndex := Pointer(0);
  if Conform(Result, AMoveModes) then
    Exit;

  Result := CalcMovedID(Result, 1, AMoveModes);
end;

function TDUIDrawGrid.Last(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := AType;
  Result.FIndex := Pointer(GetCount(AType));
  if Conform(Result, AMoveModes) then
    Exit;

  Result := CalcMovedID(Result, -1, AMoveModes);
end;

function TDUIDrawGrid.Eof(AType: TDUIRowColType): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := AType;
  Result.FIndex := Pointer(-1);
end;

function TDUIDrawGrid.GetMinTopLeft(AType: TDUIRowColType): TDUIRowColID;
var
  iIndex: Integer;
begin
  if GetCount(AType) = GetFixedCount(AType) then
  begin
    Result := Eof(AType);
    Exit;
  end;

  Result.FParent := Self;
  Result.FType := AType;
  for iIndex := FFixedCount[AType] + 1 to FCount[AType] do
  begin
    Result.FIndex := Pointer(iIndex);
    if GetCellVisible(Result) then
      Exit;
  end;

  Result := Eof(AType);
end;

function TDUIDrawGrid.PosToID(AType: TDUIRowColType; APosition: Integer): TDUIRowColID;
begin
  if APosition <= GetFixedCount(AType) then
    Result := First(AType, [mmHide, mmFroze])
  else if APosition > GetCount(AType) then
    Result := Last(AType, [mmHide, mmFroze])
  else
  begin
    Result.FParent := Self;
    Result.FType := AType;
    Result.FIndex := Pointer(APosition);

    if Conform(Result, [mmHide, mmFroze]) then //Result = TopLeft
      Exit
    else if Result < GetTopLeft(AType) then //Result < TopLeft
      Result := Result + 1 //往TopLeft的方向调整(相当于进度条移动距离不够，则界面不作调整)
    else //Result > TopLeft
      Result := Result - 1;
  end;
end;

procedure TDUIDrawGrid.IDsToPos(var AResMin, AResMax, AResPos: Integer;
  const AMin, AMax, APos: TDUIRowColID);
begin
  AResMin := Integer(AMin.FIndex);
  AResMax := Integer(AMax.FIndex);
  AResPos := Integer(APos.FIndex);
end;

procedure TDUIDrawGrid.AdjustPropertys(AType: TDUIRowColType; ANewLength: Cardinal);
var
  i, iOldLen: Cardinal;
begin
  iOldLen := Length(FPropertys[AType]);

  if ANewLength < iOldLen then
    SetLength(FPropertys[AType], ANewLength)
  else if ANewLength > iOldLen then
  begin
    SetLength(FPropertys[AType], ANewLength);
    for i := iOldLen to ANewLength - 1 do
    begin
      FPropertys[AType][i].FSize := -1;
      FPropertys[AType][i].FVisible := True;
    end;
  end;
end;

function TDUIDrawGrid.GetEditClass(const ACol, ARow: TDUIRowColID): TDUIKeyboardBaseClass;
begin
  if IsFirst(ACol) and IsFirst(ARow) then
    Result := nil
  else
    Result := TDUIEdit;
end;

procedure TDUIDrawGrid.InitEditor(AEditor: TDUIKeyboardBase);
begin
  with TDUIEdit(AEditor) do
  begin
    ArcBorder := False;
    WinControl.Visible := True;
    Text := GetEditText(Col, Row);
  end;
end;

function TDUIDrawGrid.GetEditText(const ACol, ARow: TDUIRowColID): String;
  function intToAscii(AValue: Integer): String;
  var
    iMod: Integer;
  begin
    repeat
      iMod := AValue mod 26;
      AValue := AValue div 26 - 1;

      Result := Char(Ord('A') + iMod) + Result;
    until AValue < 0;
  end;
begin
  if IsFirst(ACol) and IsFirst(ARow) then
    Result := ''
  else if IsFirst(ACol) then
    Result := IntToStr(Integer(ARow.FIndex))
  else if IsFirst(ARow) then
    Result := intToAscii(Integer(ACol.FIndex) - 1)
  else
    Result := inherited GetEditText(ACol, ARow);
end;

function TDUIDrawGrid.GetCells(ACol, ARow: Integer): String;
begin
  Result := GetEditText(MakeCol(Pointer(ACol)), MakeRow(Pointer(ARow)));
end;

function TDUIDrawGrid.GetCellHeight(ARow: Integer): Integer;
begin
  Result := GetCellSize(MakeRow(Pointer(ARow)));
end;

procedure TDUIDrawGrid.SetCellHeight(ARow: Integer; const AValue: Integer);
begin
  SetCellSize(MakeRow(Pointer(ARow)), AValue);
end;

procedure TDUIDrawGrid.SetCells(ACol, ARow: Integer; const AValue: String);
begin
  SetEditText(MakeCol(Pointer(ACol)), MakeRow(Pointer(ARow)), AValue);
end;

function TDUIDrawGrid.GetCellSize(const AIndex: TDUIRowColID): Integer;
begin
  if IsEof(AIndex) then
    raise Exception.Create('索引越界');

  if IsFirst(AIndex) then
    Result := IfThen(AIndex.FType = rctCol, TitleWidth, TitleHeight)
  else if Integer(AIndex.FIndex) > Length(FPropertys[AIndex.FType]) then
    Result := IfThen(AIndex.FType = rctCol, DefaultColWidth, DefaultRowHeight)
  else if FPropertys[AIndex.FType][Integer(AIndex.FIndex) - 1].FSize < 0 then
    Result := IfThen(AIndex.FType = rctCol, DefaultColWidth, DefaultRowHeight)
  else
    Result := FPropertys[AIndex.FType][Integer(AIndex.FIndex) - 1].FSize;
end;

procedure TDUIDrawGrid.SetCellSize(const AIndex: TDUIRowColID; const AValue: Integer);
begin
  if GetCellSize(AIndex) = AValue then
    Exit;

  if IsFirst(AIndex) then
  begin
    if AIndex.FType = rctCol then
      TitleWidth := AValue
    else
      TitleHeight := AValue;
  end
  else
  begin
    if Integer(AIndex.FIndex) > Length(FPropertys[AIndex.FType]) then
      AdjustPropertys(AIndex.FType, Integer(AIndex.FIndex));

    FPropertys[AIndex.FType][Integer(AIndex.FIndex) - 1].FSize := AValue;
  end;

  SizeChanged(AIndex);
end;

function TDUIDrawGrid.GetCellVisible(const AIndex: TDUIRowColID): Boolean;
begin
  if IsEof(AIndex) then
    raise Exception.Create('索引越界');

  if IsFirst(AIndex) then
    Result := CTitle[AIndex.FType] in Options
  else if Integer(AIndex.FIndex) > Length(FPropertys[AIndex.FType]) then
    Result := True
  else
    Result := FPropertys[AIndex.FType][Integer(AIndex.FIndex) - 1].FVisible;
end;

procedure TDUIDrawGrid.SetCellVisible(const AIndex: TDUIRowColID; const AValue: Boolean);
begin
  if GetCellVisible(AIndex) = AValue then
    Exit;

  if IsFirst(AIndex) then
  begin
    if AValue then
      Options := Options + [CTitle[AIndex.FType]]
    else
      Options := Options - [CTitle[AIndex.FType]];
  end
  else
  begin
    if Integer(AIndex.FIndex) > Length(FPropertys[AIndex.FType]) then
      AdjustPropertys(AIndex.FType, Integer(AIndex.FIndex));

    FPropertys[AIndex.FType][Integer(AIndex.FIndex) - 1].FVisible := AValue;
    if not AValue then
    begin
      if AIndex = IfThen(AIndex.FType = rctCol, Col, Row) then
        MoveCurrent(Col, Row, False);
      if AIndex = GetTopLeft(AIndex.FType) then
        MoveTopLeft(GetTopLeft(rctCol), GetTopLeft(rctRow));
    end;
  end;

  SizeChanged(AIndex);
end;

function TDUIDrawGrid.GetCount(const AType: TDUIRowColType): Longint;
begin
  Result := FCount[AType];
end;

procedure TDUIDrawGrid.SetCount(const AType: TDUIRowColType; const AValue: Longint);
var
  iOldValue: LongInt;
  idCurrent, idTopLeft: TDUIRowColID;
begin
  if FCount[AType] = AValue then
    Exit;

  iOldValue := FCount[AType];
  FCount[AType] := AValue;

  if FFixedCount[AType] > AValue then
    FFixedCount[AType] := AValue;

  if AType = rctCol then
  begin
    idCurrent := Col;
    if IsEof(idCurrent) then
      idCurrent.FIndex := Pointer(iOldValue);

    idTopLeft := GetTopLeft(AType);
    if IsEof(idTopLeft) then
      idTopLeft.FIndex := Pointer(iOldValue);

    MoveCurrent(idCurrent, Row, True);
    MoveTopLeft(idTopLeft, GetTopLeft(rctRow));
  end
  else
  begin
    idCurrent := Row;
    if IsEof(idCurrent) then
      idCurrent.FIndex := Pointer(iOldValue);

    idTopLeft := GetTopLeft(AType);
    if IsEof(idTopLeft) then
      idTopLeft.FIndex := Pointer(iOldValue);

    MoveCurrent(Col, idCurrent, True);
    MoveTopLeft(GetTopLeft(rctCol), idTopLeft);
  end;

  Invalidate;
end;

function TDUIDrawGrid.GetFixedCount(const AType: TDUIRowColType): Longint;
begin
  Result := FFixedCount[AType];
end;

procedure TDUIDrawGrid.SetFixedCount(const AType: TDUIRowColType; const AValue: Longint);
begin
  if FFixedCount[AType] = AValue then
    Exit;

  if (AValue < 0) or (AValue > FCount[AType]) then
    raise Exception.Create('索引越界');

  FFixedCount[AType] := AValue;

  MoveCurrent(Col, Row, True);
  MoveTopLeft(GetTopLeft(rctCol), GetTopLeft(rctRow));
  Invalidate;
end;

function TDUIDrawGrid.GetCellWidth(ACol: Integer): Integer;
begin
  Result := GetCellSize(MakeCol(Pointer(ACol)));
end;

procedure TDUIDrawGrid.SetCellWidth(ACol: Integer; const AValue: Integer);
begin
  SetCellSize(MakeCol(Pointer(ACol)), AValue);
end;

end.
