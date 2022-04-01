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
unit UDUIGrid;

interface

uses
  Messages, Windows, SysUtils, Classes, Variants, Graphics, Menus, Controls,
  Forms, StdCtrls, Types, IGDIPlus, UDUICore, UDUIForm, UDUIScrollBar,
  UDUIGraphics, UDUIUtils;

type
  TDUIRowColType = (rctCol, rctRow);
  TDUIGridOption = (goVertTitleLine, goHorzTitleLine, goVertLine, goHorzLine,
    goRangeSelect, goEditing, goRowSelect, goVertTitle, goHorzTitle);
  TDUIGridOptions = set of TDUIGridOption;
  TDUICellType = (ctTitle, ctFroze, ctCell);
  TDUICellState = set of (gdSelected, gdFocused, gdMerged);
  TDUIGridState = (gsNormal, gsSelecting);

  TDUIGridBase = class;
  TDUIRowColID = record //行列ID，用于唯一标识行、列位置
    FParent: TDUIGridBase;
    FType: TDUIRowColType;
    FIndex: Pointer;
    class operator Equal(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
    class operator GreaterThan(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
    class operator GreaterThanOrEqual(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
    class operator LessThan(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
    class operator LessThanOrEqual(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
    //加减运算符仅操作可见单元格
    class operator Add(AValue: TDUIRowColID; ADelta: Integer): TDUIRowColID;
    class operator Subtract(AValue: TDUIRowColID; ADelta: Integer): TDUIRowColID;
  end;

  TDUIMoveMode = (mmHide, mmFroze); //排除隐藏单元格、排除冻结单元格
  TDUIMoveModes = set of TDUIMoveMode;
  TDUIGridCoord = record
    FCol: TDUIRowColID;
    FRow: TDUIRowColID;
  end;
  TDUIGridRect = record
    case Integer of
      0: (Left, Top, Right, Bottom: TDUIRowColID);
      1: (TopLeft, BottomRight: TDUIGridCoord);
  end;
  TDUIGridSize = record
    FColSize: Cardinal;
    FRowSize: Cardinal;
  end;

  TDUIGridData = class(TComponent)
  private
    FDisableCount: Integer;
    FGrid: TDUIGridBase;
  public
    procedure DisableControl;
    procedure EnableControl;
    function GetEditText(const ACol, ARow: TDUIRowColID): String; virtual; abstract;
    procedure SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String); virtual;
  end;

  TDUIGridBase = class(TDUIKeyboardBase)
  {$IFDEF DESIGNTIME}
  private
    function DoGetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList;
  {$ELSE}
  private
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    function DoGetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList;
  {$ENDIF}
  private
    FTitleLinePen, FLinePen: TDUIPen;
    FFont: TDUIFont;
    FBackground, FFocusBackground, FTitleBackground: TDUIBrush;
    FTextBrush: TDUIBrush;
    FStringFormat: IGPStringFormat;
    FAnchor: TDUIGridCoord;
    FCurrent: TDUIGridCoord;
    FDefaultSize: array[TDUIRowColType] of Integer;
    FEditor: TDUIKeyboardBase;
    FGridLineWidth: Integer;
    FGridState: TDUIGridState;
    FOldEditWndProc: TWndMethod;
    FOptions: TDUIGridOptions;
    FScrollBars: array[TDUIRowColType] of TDUIScrollBar;
    FTimerAnchor, FTimerScrollBar: Pointer;
    FTitleSize: array[TDUIRowColType] of Integer;
    FTopLeft: TDUIGridCoord;
    FOwnData: Boolean;
    FData: TDUIGridData;
    procedure DoScrollBarChange(ASender: TObject);
    procedure EditWndProc(var AMessage: TMessage);
    procedure UpdateScrollPos;
    procedure AdjustEditorPosition;
    procedure ShowEditor;
    procedure HideEditor(ASaveData: Boolean);
    function GetTitleSize(const AType: TDUIRowColType): Integer;
    procedure SetTitleSize(const AType: TDUIRowColType; const AValue: Integer);
    function GetDefaultCellSize(const AType: TDUIRowColType): Integer;
    procedure SetDefaultCellSize(const AType: TDUIRowColType; const AValue: Integer);
    procedure SetGridLineWidth(AValue: Integer);
    procedure SetOptions(AValue: TDUIGridOptions);
    function GetSelection: TDUIGridRect;
    procedure SetSelection(AValue: TDUIGridRect);
    procedure WMChar(var AMessage: TWMChar); message WM_CHAR;
    procedure WMGetDlgCode(var AMessage: TMessage); message WM_GETDLGCODE;
    procedure WMTimer(var AMessage: TWMTimer); message WM_TIMER;
  protected
    function CoordBeginPoint(const ACoord: TDUIGridCoord): TPoint;
    //CalcDiagonal负责从AStart开始，计算当前界面最大可容纳的单元格的坐标
    //ADirection为True，则向右下角查找，为False，则向左上角查找
    function CalcDiagonal(const AStart: TDUIGridCoord; ADirection: Boolean): TDUIGridCoord; overload;
    function CalcDiagonal(var ASize: TDUIGridSize; const AStart: TDUIGridCoord; ADirection: Boolean): TDUIGridCoord; overload;
    procedure ClampInView(const ACoord: TDUIGridCoord);
    function Compare(const ALeft, ARight: TDUIRowColID): Integer;
    function Conform(const AIndex: TDUIRowColID; AMoveModes: TDUIMoveModes): Boolean;
    function GetEditText(const ACol, ARow: TDUIRowColID): String; virtual;
    procedure SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String); virtual;
    function GetAnchor(AType: TDUIRowColType): TDUIRowColID;
    function GetCalcCellSize(const AIndex: TDUIRowColID): Integer; virtual;
    function GetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList; virtual;
    function GetTopLeft(AType: TDUIRowColType): TDUIRowColID;
    function MakeCol(AIndex: Pointer): TDUIRowColID;
    function MakeRow(AIndex: Pointer): TDUIRowColID;
    procedure MoveAnchor(ANewAnchor: TDUIGridCoord);
    procedure MoveCurrent(ACol, ARow: TDUIRowColID; AMoveAnchor: Boolean);
    procedure MoveTopLeft(ACol, ARow: TDUIRowColID);
    function PointToCoord(const APoint: TPoint): TDUIGridCoord;
    procedure TopLeftChanged; dynamic;
    procedure SizeChanged(const AIndex: TDUIRowColID); dynamic;
    function DoMouseWheelDown(AShift: TShiftState; AMousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(AShift: TShiftState; AMousePos: TPoint): Boolean; override;
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    function DrawCellLine(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
      const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState): TRect; virtual;
    procedure DrawCell(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
      const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState); virtual;
    procedure DrawClientCellBackground(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
      const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState); virtual;
    procedure DrawClientCell(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
      const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState); virtual;
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyUp(var AKey: Word; AShift: TShiftState); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseMove(AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure Resize; override;
    property Row: TDUIRowColID index rctRow read FCurrent.FRow;
    property Col: TDUIRowColID index rctCol read FCurrent.FCol;
    property TitleHeight: Integer index rctRow read GetTitleSize write SetTitleSize default 24;
    property TitleWidth: Integer index rctCol read GetTitleSize write SetTitleSize default 32;
    property DefaultRowHeight: Integer index rctRow read GetDefaultCellSize write SetDefaultCellSize default 24;
    property DefaultColWidth: Integer index rctCol read GetDefaultCellSize write SetDefaultCellSize default 64;
    property GridLineWidth: Integer read FGridLineWidth write SetGridLineWidth default 1;
    property Options: TDUIGridOptions read FOptions write SetOptions
      default [goVertTitleLine, goHorzTitleLine, goVertLine, goHorzLine, goRangeSelect, goVertTitle, goHorzTitle];
    property Selection: TDUIGridRect read GetSelection write SetSelection;
  protected
    //CalcMovedID计算将AIndex行/列，移动ACount次后，所到达的行/列
    //ACount为正表示向右/下移动，否则，向左/上移动
    //AMoveModes默认计算所有单元格，但可以指定排除隐藏或冻结单元格
    function CalcMovedID(const AIndex: TDUIRowColID;
      ACount: Integer; AMoveModes: TDUIMoveModes): TDUIRowColID; virtual; abstract;
    function IsFirst(AIndex: TDUIRowColID): Boolean; virtual; abstract;
    function IsEof(AIndex: TDUIRowColID): Boolean; virtual; abstract;
    function First(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID; virtual; abstract;
    function Last(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID; virtual; abstract;
    function Eof(AType: TDUIRowColType): TDUIRowColID; virtual; abstract;
    function DoCompare(const ALeft, ARight: TDUIRowColID): Integer; virtual; abstract;
    function GetEditClass(const ACol, ARow: TDUIRowColID): TDUIKeyboardBaseClass; virtual; abstract;
    procedure InitEditor(AEditor: TDUIKeyboardBase); virtual; abstract;
    function GetMinTopLeft(AType: TDUIRowColType): TDUIRowColID; virtual; abstract;
    //PosToID、IDToPos将行列坐标TDUIRowColID与滚动条坐标Position进行相互转换
    function PosToID(AType: TDUIRowColType; APosition: Integer): TDUIRowColID; virtual; abstract;
    procedure IDsToPos(var AResMin, AResMax, AResPos: Integer;
      const AMin, AMax, APos: TDUIRowColID); virtual; abstract;

    function GetCellSize(const AIndex: TDUIRowColID): Integer; virtual; abstract;
    procedure SetCellSize(const AIndex: TDUIRowColID; const AValue: Integer); virtual; abstract;
    property CellSize[const AIndex: TDUIRowColID]: Integer read GetCellSize write SetCellSize;

    function GetCellVisible(const AIndex: TDUIRowColID): Boolean; virtual; abstract;
    procedure SetCellVisible(const AIndex: TDUIRowColID; const AValue: Boolean); virtual; abstract;
    property CellVisible[const AIndex: TDUIRowColID]: Boolean read GetCellVisible write SetCellVisible;

    procedure SetData(const AValue: TDUIGridData); virtual;
    property Data: TDUIGridData read FData write SetData;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
  end;

function GridCoord(ACol, ARow: TDUIRowColID): TDUIGridCoord;
function IfThen(ACondition: Boolean; AValue1, AValue2: Integer): Integer; overload;
function IfThen(ACondition: Boolean; AValue1, AValue2: TDUIRowColID): TDUIRowColID; overload;

const
  CTitle: array[TDUIRowColType] of TDUIGridOption = (goHorzTitle, goVertTitle);

implementation

uses
  Consts, Clipbrd, UDUIGridData;

function GridCoord(ACol, ARow: TDUIRowColID): TDUIGridCoord;
begin
  Result.FCol := ACol;
  Result.FRow := ARow;
end;

function IfThen(ACondition: Boolean; AValue1, AValue2: Integer): Integer; overload;
begin
  if ACondition then
    Result := AValue1
  else
    Result := AValue2;
end;

function IfThen(ACondition: Boolean; AValue1, AValue2: TDUIRowColID): TDUIRowColID; overload;
begin
  if ACondition then
    Result := AValue1
  else
    Result := AValue2;
end;

{ TDUIRowColID }

class operator TDUIRowColID.Equal(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
begin
  Result := ALeft.FParent.Compare(ALeft, ARight) = 0;
end;

class operator TDUIRowColID.GreaterThan(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
begin
  Result := ALeft.FParent.Compare(ALeft, ARight) > 0;
end;

class operator TDUIRowColID.GreaterThanOrEqual(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
begin
  Result := (ALeft = ARight) or (ALeft > ARight);
end;

class operator TDUIRowColID.LessThan(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
begin
  Result := not (ALeft >= ARight);
end;

class operator TDUIRowColID.LessThanOrEqual(ALeft: TDUIRowColID; ARight: TDUIRowColID): Boolean;
begin
  Result := not (ALeft > ARight);
end;

class operator TDUIRowColID.Add(AValue: TDUIRowColID; ADelta: Integer): TDUIRowColID;
begin
  Result := AValue.FParent.CalcMovedID(AValue, ADelta, [mmHide]);
end;

class operator TDUIRowColID.Subtract(AValue: TDUIRowColID; ADelta: Integer): TDUIRowColID;
begin
  ADelta := -ADelta;
  Result := AValue + ADelta;
end;

{ TDUIGridData }

procedure TDUIGridData.DisableControl;
begin
  Inc(FDisableCount);
end;

procedure TDUIGridData.EnableControl;
begin
  Dec(FDisableCount);
  if (FDisableCount = 0) and Assigned(FGrid) then
    FGrid.Invalidate;
end;

procedure TDUIGridData.SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String);
var
  ptLeftTop: TGPPoint;
  siCell: TGPSize;
begin
  if (FDisableCount <> 0) or not Assigned(FGrid) then
    Exit;

  ptLeftTop := FGrid.CoordBeginPoint(GridCoord(ACol, ARow));
  siCell := MakeSize(FGrid.GetCalcCellSize(ACol), FGrid.GetCalcCellSize(ARow));
  FGrid.InvalidateRect(MakeRect(ptLeftTop, siCell));
end;

{ TDUIGridBase }

{$IFDEF DESIGNTIME}

function TDUIGridBase.DoGetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList;
begin
  Result := nil;
end;

{$ELSE}

procedure TDUIGridBase.WMNCHitTest(var AMessage: TWMNCHitTest);
var
  gc: TDUIGridCoord;
begin
  if IsTransparent then
    AMessage.Result := HTTRANSPARENT
  else
  begin
    gc := PointToCoord(ScreenToClient(SmallPointToPoint(AMessage.Pos)));
    if IsEof(gc.FCol) or IsEof(gc.FRow) then
      AMessage.Result := HTTRANSPARENT
    else
      AMessage.Result := HTCLIENT;
  end;
end;

function TDUIGridBase.DoGetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList;
begin
  Result := GetPaintControls(ACol, ARow);
end;

{$ENDIF}

constructor TDUIGridBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FLinePen := TDUIPen.Create(Self, 'GRID.LINE');
  FTitleLinePen := TDUIPen.Create(Self, 'GRID.LINE.TITLE');
  FFont := TDUIFont.Create(Self, 'GRID.TEXT');
  FBackground := TDUIBrush.Create(Self, 'GRID.BACKGROUND');
  FFocusBackground := TDUIBrush.Create(Self, 'GRID.BACKGROUND.FOCUS');
  FTitleBackground := TDUIBrush.Create(Self, 'GRID.BACKGROUND.TITLE');
  FTextBrush := TDUIBrush.Create(Self, 'GRID.TEXT');

  FStringFormat := TGPStringFormat.Create;
  FStringFormat.SetAlignment(StringAlignmentNear);
  FStringFormat.SetLineAlignment(StringAlignmentCenter);
  FStringFormat.SetFormatFlags(StringFormatFlagsNoWrap);

  //滚动条是反着创建的
  FScrollBars[rctCol] := TDUIScrollBar.Create(Self); //行滚动条
  with FScrollBars[rctCol] do
  begin
    DUIParent := Self;
    Kind := sbHorizontal;
    Align := alBottom;
    Visible := False;
    OnChange := DoScrollBarChange;
  end;
  FScrollBars[rctRow] := TDUIScrollBar.Create(Self); //列滚动条
  with FScrollBars[rctRow] do
  begin
    DUIParent := Self;
    Kind := sbVertical;
    Align := alRight;
    Visible := False;
    OnChange := DoScrollBarChange;
  end;

  ControlStyle := ControlStyle + [csDoubleClicks, csCaptureMouse];
  FGridLineWidth := 1;
  FOptions := [goVertTitleLine, goHorzTitleLine, goVertLine, goHorzLine, goRangeSelect, goVertTitle, goHorzTitle];
  FTitleSize[rctCol] := 32;
  FTitleSize[rctRow] := 24;
  FDefaultSize[rctCol] := 64;
  FDefaultSize[rctRow] := 24;
  SetBounds(Left, Top, 5 * FDefaultSize[rctCol], 5 * FDefaultSize[rctRow]);

  FOwnData := False;
end;

destructor TDUIGridBase.Destroy;
begin
  FreeAndNil(FEditor);
  FreeAndNil(FScrollBars[rctCol]);
  FreeAndNil(FScrollBars[rctRow]);

  SetData(nil);

  inherited Destroy;
end;

procedure TDUIGridBase.AfterConstruction;
begin
  FTopLeft.FCol := GetMinTopLeft(rctCol);
  FTopLeft.FRow := GetMinTopLeft(rctRow);
  FAnchor := FTopLeft;
  FCurrent := FTopLeft;

  inherited;
end;

function TDUIGridBase.DoMouseWheelDown(AShift: TShiftState; AMousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelDown(AShift, AMousePos);
  if not Result then
  begin
    MoveTopLeft(FTopLeft.FCol, FTopLeft.FRow + 3);
    Result := True;
  end;
end;

function TDUIGridBase.DoMouseWheelUp(AShift: TShiftState; AMousePos: TPoint): Boolean;
var
  idNew: TDUIRowColID;
begin
  Result := inherited DoMouseWheelUp(AShift, AMousePos);
  if not Result then
  begin
    idNew := FTopLeft.FRow - 3;
    if IsEof(idNew) then
      idNew := First(rctRow, [mmHide, mmFroze]);

    MoveTopLeft(FTopLeft.FCol, idNew);
    Result := True;
  end;
end;

procedure TDUIGridBase.DoPaint(AGPCanvas: IGPGraphics);
  function getCellType(ACol, ARow: TDUIRowColID): TDUICellType;
  begin
    if (ACol = First(rctCol)) or (ARow = First(rctRow)) then
      Result := ctTitle
    else if (ACol < GetMinTopLeft(rctCol)) or (ARow < GetMinTopLeft(rctRow)) then
      Result := ctFroze
    else
      Result := ctCell;
  end;
var
  idCol, idRow: TDUIRowColID;
  ptLeftTop: TGPPoint;
  siCell: TGPSize;
  iLineSize: array[TDUIRowColType] of Integer;
begin
  AGPCanvas.FillRectangle(FBackground, MakeRect(0, 0, Width, Height));

  iLineSize[rctRow] := IfThen([goVertTitleLine, goVertLine] * Options <> [], FGridLineWidth, 0);
  iLineSize[rctCol] := IfThen([goHorzTitleLine, goHorzLine] * Options <> [], FGridLineWidth, 0);

  ptLeftTop := MakePoint(0, 0);
  idCol := First(rctCol, [mmHide]);
  while True do //按列循环
  begin
    if (idCol >= GetMinTopLeft(rctCol)) and (idCol < FTopLeft.FCol) then
      idCol := FTopLeft.FCol;

    if IsEof(idCol) then
      Break;

    siCell := MakeSize(iLineSize[rctCol], iLineSize[rctRow]);

    idRow := First(rctRow, [mmHide]);
    while True do //按行循环
    begin
      if (idRow >= GetMinTopLeft(rctRow)) and (idRow < FTopLeft.FRow) then
        idRow := FTopLeft.FRow;

      if IsEof(idRow) then
        Break;

      siCell := MakeSize(2 * iLineSize[rctCol] + GetCalcCellSize(idCol),
        2 * iLineSize[rctRow] + GetCalcCellSize(idRow));

      DrawCell(AGPCanvas, idCol, idRow,
        MakeRect(ptLeftTop, siCell),
        getCellType(idCol, idRow),
        []);

      idRow := idRow + 1;
      Inc(ptLeftTop.Y, siCell.Height - iLineSize[rctRow]);

      if ptLeftTop.Y > Height then
        Break;
    end;

    idCol := idCol + 1;
    ptLeftTop := MakePoint(ptLeftTop.X + siCell.Width - iLineSize[rctCol], 0);

    if ptLeftTop.X > Width then
      Break;
  end;
end;

procedure TDUIGridBase.DoScrollBarChange(ASender: TObject);
begin
  if ASender = FScrollBars[rctCol] then
    MoveTopLeft(PosToID(rctCol, TDUIScrollBar(ASender).Position), FTopLeft.FRow)
  else if ASender = FScrollBars[rctRow] then
    MoveTopLeft(FTopLeft.FCol, PosToID(rctRow, TDUIScrollBar(ASender).Position));
end;

function TDUIGridBase.DrawCellLine(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
  const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState): TRect;
var
  penLine: TDUIPen;
begin
  Result := Rect(0, 0, 0, 0);
  penLine := nil;

  //1.1 左边线
  repeat
    if (ACellType = ctTitle) and (goVertTitleLine in Options) then
    begin
      penLine := FTitleLinePen;
      Result.Left := FGridLineWidth;
    end
    else if (ACellType <> ctTitle) and (goVertLine in Options) then
    begin
      penLine := FLinePen;
      Result.Left := FGridLineWidth;
    end
    else
      Break;

    if ARect.X <> 0 then
      Break;

    penLine.Pen.Width := FGridLineWidth;
    AGPCanvas.DrawLine(penLine,
      ARect.X, ARect.Y,
      ARect.X, ARect.Y + ARect.Height - 1);
  until True;

  //1.2 右边线
  repeat
    if (ACellType = ctTitle) and (goVertTitleLine in Options) then
    begin
      penLine := FTitleLinePen;
      Result.Right := FGridLineWidth;
    end
    else if (ACellType <> ctTitle) and (goVertLine in Options) then
    begin
      penLine := FLinePen;
      Result.Right := FGridLineWidth;
    end
    else
      Break;

    penLine.Pen.Width := FGridLineWidth;
    AGPCanvas.DrawLine(penLine,
      ARect.X + ARect.Width - FGridLineWidth, ARect.Y,
      ARect.X + ARect.Width - FGridLineWidth, ARect.Y + ARect.Height - 1);
  until True;

  //1.3 上边线
  repeat
    if (ACellType = ctTitle) and (goHorzTitleLine in Options) then
    begin
      penLine := FTitleLinePen;
      Result.Top := FGridLineWidth;
    end
    else if (ACellType <> ctTitle) and (goHorzLine in Options) then
    begin
      penLine := FLinePen;
      Result.Top := FGridLineWidth;
    end
    else
      Break;

    if ARect.Y <> 0 then
      Break;

    penLine.Pen.Width := FGridLineWidth;
    AGPCanvas.DrawLine(penLine,
      ARect.X, ARect.Y,
      ARect.X + ARect.Width - 1, ARect.Y);
  until True;

  //1.4 下边线
  repeat
    if (ACellType = ctTitle) and (goHorzTitleLine in Options) then
    begin
      penLine := FTitleLinePen;
      Result.Bottom := FGridLineWidth;
    end
    else if (ACellType <> ctTitle) and (goHorzLine in Options) then
    begin
      penLine := FLinePen;
      Result.Bottom := FGridLineWidth;
    end
    else
      Break;

    penLine.Pen.Width := FGridLineWidth;
    AGPCanvas.DrawLine(penLine,
      ARect.X, ARect.Y + ARect.Height - FGridLineWidth,
      ARect.X + ARect.Width - 1, ARect.Y + ARect.Height - FGridLineWidth);
  until True;
end;

procedure TDUIGridBase.DrawCell(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
  const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState);
var
  rctAdjust: TRect;
begin
  //1.0 绘制边线
  rctAdjust := DrawCellLine(AGPCanvas, ACol, ARow, ARect, ACellType, ACellState);

  //2.0 绘制单元格(排除边线)
  DrawClientCell(AGPCanvas, ACol, ARow,
    MakeRect(ARect.X + rctAdjust.Left,
      ARect.Y + rctAdjust.Top,
      ARect.Width - rctAdjust.Left - rctAdjust.Right,
      ARect.Height - rctAdjust.Top - rctAdjust.Bottom),
    ACellType, ACellState);
end;

procedure TDUIGridBase.DrawClientCellBackground(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
  const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState);
begin
  if IsFirst(ACol) or IsFirst(ARow) then
    AGPCanvas.FillRectangle(FTitleBackground, ARect)
  else if (goRowSelect in Options) and (ARow = Row) then
    AGPCanvas.FillRectangle(FFocusBackground, ARect)
  else if not (goRowSelect in Options) and (ARow = Row) and (ACol = Col) then
    AGPCanvas.FillRectangle(FFocusBackground, ARect)
  else
    AGPCanvas.FillRectangle(FBackground, ARect);
end;

procedure TDUIGridBase.DrawClientCell(AGPCanvas: IGPGraphics; const ACol, ARow: TDUIRowColID;
  const ARect: TGPRect; ACellType: TDUICellType; ACellState: TDUICellState);
var
  i: Integer;
  lst: TControlsList;
  rct: TRect;
  dui: TDUIBase;
  gc: TGPGraphicsContainer;
begin
  DrawClientCellBackground(AGPCanvas, ACol, ARow, ARect, ACellType, ACellState);

  lst := DoGetPaintControls(ACol, ARow);
  if not Assigned(lst) then
  begin
    AGPCanvas.DrawString(GetEditText(ACol, ARow), FFont, ARect, FStringFormat, FTextBrush);
    Exit;
  end;

  rct.Left := ARect.X;
  rct.Top := ARect.Y;
  rct.Right := ARect.X + ARect.Width - 1;
  rct.Bottom := ARect.Y + ARect.Height - 1;
  ArrangeControls(lst, nil, rct);

  for i := 0 to lst.Count - 1 do
  begin
    dui := TDUIBase(lst[i]);

    gc := AGPCanvas.BeginContainer;
    try
      AGPCanvas.TranslateTransform(dui.Left, dui.Top);
      dui.Perform(WM_PAINT, 0, Integer(AGPCanvas));
    finally
      AGPCanvas.EndContainer(gc);
    end;
  end;
end;

procedure TDUIGridBase.EditWndProc(var AMessage: TMessage);
begin
  case AMessage.Msg of
    CM_MOUSEWHEEL, WM_KEYUP, WM_SYSKEYUP:
    begin
      Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
      Exit;
    end;
    WM_KEYDOWN, WM_SYSKEYDOWN:
    begin
      case TWMKeyDown(AMessage).CharCode of
        VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_ESCAPE:
          Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
        VK_INSERT:
          if KeyDataToShiftState(TWMKeyDown(AMessage).KeyData) = [] then
            Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
        VK_TAB:
          if not (ssAlt in KeyDataToShiftState(TWMKeyDown(AMessage).KeyData)) then
            Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
        VK_DELETE:
          if ssCtrl in KeyDataToShiftState(TWMKeyDown(AMessage).KeyData) then
            Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
      else
        if Assigned(FEditor) then
          FOldEditWndProc(AMessage);
      end;

      Exit;
    end;
    WM_CHAR:
    begin
      case TWMKey(AMessage).CharCode of
        VK_ESCAPE:
        begin
          Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
          Exit;
        end;
        VK_RETURN:
        begin
          //ALT + RETURN由控件本身处理
          if not (ssAlt in KeyDataToShiftState(TWMKeyDown(AMessage).KeyData)) then
          begin
            Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
            Exit;
          end;
        end;
      end;
    end;
    WM_GETDLGCODE:
    begin
      AMessage.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS;
      Exit;
    end;
  end;

  if Assigned(FEditor) then
    FOldEditWndProc(AMessage);
end;

procedure TDUIGridBase.KeyDown(var AKey: Word; AShift: TShiftState);
  function getPageSize: Integer;
  var
    gs: TDUIGridSize;
  begin
    CalcDiagonal(gs, FTopLeft, True);
    Result := gs.FRowSize;
  end;
begin
  inherited KeyDown(AKey, AShift);

  case AKey of
    VK_F2:
    begin
      ShowEditor;
      Exit;
    end;
    VK_UP: MoveCurrent(Col, Row - 1, not (ssShift in AShift));
    VK_DOWN: MoveCurrent(Col, Row + 1, not (ssShift in AShift));
    VK_LEFT: MoveCurrent(Col - 1, Row, not (ssShift in AShift));
    VK_RIGHT: MoveCurrent(Col + 1, Row, not (ssShift in AShift));
    VK_NEXT: MoveCurrent(Col, Row + getPageSize, not (ssShift in AShift));
    VK_PRIOR: MoveCurrent(Col, Row - getPageSize, not (ssShift in AShift));
    VK_HOME:
    begin
      if goRowSelect in Options then
        MoveCurrent(Col, GetMinTopLeft(rctRow), not (ssShift in AShift))
      else
        MoveCurrent(GetMinTopLeft(rctCol), Row, not (ssShift in AShift));
    end;
    VK_END:
    begin
      if goRowSelect in Options then
        MoveCurrent(Col, Last(rctRow, [mmHide]), not (ssShift in AShift))
      else
        MoveCurrent(Last(rctCol, [mmHide]), Row, not (ssShift in AShift));
    end;
    VK_TAB:
    begin
      //ALT + TAB是屏幕切换
      if ssAlt in AShift then
        Exit;

      if ssShift in AShift then
        MoveCurrent(Col - 1, Row, True)
      else
        MoveCurrent(Col + 1, Row, True);
    end;
  else
    Exit;
  end;

  ClampInView(FCurrent);
end;

procedure TDUIGridBase.KeyUp(var AKey: Word; AShift: TShiftState);
  procedure clipCopy(ADelete: Boolean);
  var
    idLeft, idTop, idRight, idBottom: TDUIRowColID;
    strResult, strLine: String;
  begin
    with GetSelection do
    begin
      idLeft := Left;
      idTop := Top;
      idRight := Right;
      idBottom := Bottom;
    end;

    strResult := '';
    while idTop <= idBottom do
    begin
      strLine := '';
      while idLeft <= idRight do
      begin
        if strLine <> '' then
          strLine := strLine + #$9 + GetEditText(idLeft, idTop)
        else
          strLine := strLine + GetEditText(idLeft, idTop);

        if ADelete then
          SetEditText(idLeft, idTop, '');

        idLeft := idLeft + 1;
      end;

      if strResult <> '' then
        strResult := strResult + #$D#$A + strLine
      else
        strResult := strResult + strLine;

      idTop := idTop + 1;
    end;

    Clipboard.AsText := strResult;
  end;
  procedure clipPaste;
  begin
    {TODO: 添加剪贴板粘贴功能}
  end;
begin
  inherited KeyUp(AKey, AShift);

  if ssCtrl in AShift then
  begin
    case Char(AKey) of
      'C': clipCopy(False);
      'V': clipPaste;
      'X': clipCopy(True);  
    end;
  end;
end;

function ShiftStateToKeys(AShift: TShiftState): Word;
begin
  Result := 0;
  if ssShift in AShift then Result := Result or MK_SHIFT;
  if ssCtrl in AShift then Result := Result or MK_CONTROL;
  if ssLeft in AShift then Result := Result or MK_LBUTTON;
  if ssRight in AShift then Result := Result or MK_RBUTTON;
  if ssMiddle in AShift then Result := Result or MK_MBUTTON;
end;

procedure TDUIGridBase.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  i: Integer;
  lst: TControlsList;
  pt: TPoint;
  dui: TDUIBase;
  rct: TRect;
  gcCurr: TDUIGridCoord;
begin
  gcCurr := PointToCoord(Point(AX, AY));

  lst := DoGetPaintControls(gcCurr.FCol, gcCurr.FRow);
  if Assigned(lst) then
  begin
    rct.TopLeft := CoordBeginPoint(gcCurr);
    rct.Right := rct.Left + GetCellSize(gcCurr.FCol) - 1;
    rct.Bottom := rct.Top + GetCellSize(gcCurr.FRow) - 1;
    ArrangeControls(lst, nil, rct);

    for i := lst.Count - 1 downto 0 do
    begin
      dui := TDUIBase(lst[i]);

      pt := Point(AX - dui.Left, AY - dui.Top);
      if PtInRect(dui.ClientRect, pt) then
      begin
        //WM_NCHITTEST消息的LParam应该是屏幕坐标，但因为dui没有设置父窗口，因此，这里特殊处理，传入控件相对坐标
        if dui.Perform(WM_NCHITTEST, 0, Longint(PointToSmallPoint(pt))) = HTTRANSPARENT then
          Break;

        dui.Perform(WM_LBUTTONDOWN, ShiftStateToKeys(AShift), Longint(PointToSmallPoint(pt)));
        Exit;
      end;
    end;
  end;

  if AButton = mbLeft then
  begin
    FGridState := gsNormal;
    if (gcCurr.FCol >= GetMinTopLeft(rctCol)) and not IsEof(gcCurr.FCol)
      and (gcCurr.FRow >= GetMinTopLeft(rctRow)) and not IsEof(gcCurr.FRow) then
    begin
      FGridState := gsSelecting;
      FTimerAnchor := TDUIForm(RootParent).SetDUITimer(Self, 60, True);

      if ssShift in AShift then
        MoveAnchor(gcCurr)
      else
        MoveCurrent(gcCurr.FCol, gcCurr.FRow, True);
    end;
  end;

  inherited MouseDown(AButton, AShift, AX, AY);
end;

procedure TDUIGridBase.MouseMove(AShift: TShiftState; AX, AY: Integer);
begin
  if FGridState = gsSelecting then
    Perform(WM_TIMER, Integer(FTimerAnchor), 0);

  if not Assigned(FTimerScrollBar) then
  begin
    FTimerScrollBar := TDUIForm(RootParent).SetDUITimer(Self, 60, True);
    UpdateScrollPos;
  end;

  inherited MouseMove(AShift, AX, AY);
end;

procedure TDUIGridBase.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  try
    if FGridState = gsSelecting then
      Perform(WM_TIMER, Integer(FTimerAnchor), 0);

    inherited MouseUp(AButton, AShift, AX, AY);
  finally
    FGridState := gsNormal;
    if Assigned(FTimerAnchor) then
    begin
      TDUIForm(RootParent).KillDUITimer(FTimerAnchor);
      FTimerAnchor := nil;
    end;
  end;
end;

procedure TDUIGridBase.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if AOperation = opRemove then
  begin
    if FData = AComponent then
      FData := nil;
  end;
end;

procedure TDUIGridBase.Resize;
begin
  inherited;

  SizeChanged(Eof(rctRow));
end;

procedure TDUIGridBase.WMChar(var AMessage: TWMChar);
begin
  inherited;

  if not (goEditing in Options) then
    Exit;

  case AMessage.CharCode of
    VK_BACK, 32..255:
    begin
      ShowEditor;
      if Assigned(FEditor) then
        FEditor.Perform(AMessage.Msg, AMessage.CharCode, AMessage.KeyData);
    end;
    VK_ESCAPE:
    begin
      HideEditor(False);
    end;
    VK_RETURN:
    begin
      //ALT + RETURN不处理(仿造Excel的实现)
      if ssAlt in KeyDataToShiftState(TWMKeyDown(AMessage).KeyData) then
        Exit;

      HideEditor(True);
    end;
  end;
end;

procedure TDUIGridBase.WMGetDlgCode(var AMessage: TMessage);
begin
  AMessage.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS;
end;

procedure TDUIGridBase.WMTimer(var AMessage: TWMTimer);
var
  ptCursor: TPoint;
  gcCurr: TDUIGridCoord;
begin
  if AMessage.TimerID = Integer(FTimerAnchor) then
  begin
    if not (FGridState in [gsSelecting]) then
      Exit;

    ptCursor := ScreenToClient(Mouse.CursorPos);
    gcCurr := PointToCoord(ptCursor);

    if (ptCursor.X < 0) or (gcCurr.FCol < GetMinTopLeft(rctCol)) then
    begin
      gcCurr.FCol := FAnchor.FCol - 1;
      if IsEof(gcCurr.FCol) then
        gcCurr.FCol := FAnchor.FCol;
    end
    else if ptCursor.X > Width then
      gcCurr.FCol := FAnchor.FCol + 1;

    if (ptCursor.Y < 0) or (gcCurr.FRow <= GetMinTopLeft(rctRow)) then
    begin
      gcCurr.FRow := FAnchor.FRow - 1;
      if IsEof(gcCurr.FRow) then
        gcCurr.FRow := FAnchor.FRow;
    end
    else if ptCursor.Y > Height then
      gcCurr.FRow := FAnchor.FRow + 1;

    MoveAnchor(gcCurr);
    ClampInView(FAnchor);
  end
  else if AMessage.TimerID = Integer(FTimerScrollBar) then
  begin
    UpdateScrollPos;

    if not PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos)) and (FGridState = gsNormal) then
    begin
      TDUIForm(RootParent).KillDUITimer(FTimerScrollBar);
      FTimerScrollBar := nil;
    end;
  end;
end;

procedure TDUIGridBase.AdjustEditorPosition;
var
  gcMax: TDUIGridCoord;
begin
  if not Assigned(FEditor) then
    Exit;

  gcMax := CalcDiagonal(FTopLeft, True);
  if IsEof(Col) or (Col < FTopLeft.FCol) or (Col > gcMax.FCol)
    or IsEof(Row) or (Row < FTopLeft.FRow) or (Row > gcMax.FRow) then
    FEditor.SetBounds(0, 0, 0, 0)
  else
    with CoordBeginPoint(GridCoord(Col, Row)) do
      FEditor.SetBounds(X, Y, GetCalcCellSize(Col), GetCalcCellSize(Row));
end;

function TDUIGridBase.CalcDiagonal(const AStart: TDUIGridCoord; ADirection: Boolean): TDUIGridCoord;
var
  gs: TDUIGridSize;
begin
  Result := CalcDiagonal(gs, AStart, ADirection);
end;

function TDUIGridBase.CalcDiagonal(var ASize: TDUIGridSize;
  const AStart: TDUIGridCoord; ADirection: Boolean): TDUIGridCoord;
  function innerCalcDiagonal(var ACount: Cardinal; ATotalSize, ALineSize: Integer;
    AStartPoint: TDUIRowColID; AStep: Integer): TDUIRowColID;
  var
    id, idNextPoint: TDUIRowColID;
  begin
    ACount := 0;
    if IsEof(AStartPoint) then
    begin
      Result := AStartPoint;
      Exit;
    end;

    id := First(AStartPoint.FType, [mmHide]);
    while id < GetMinTopLeft(AStartPoint.FType) do
    begin
      Dec(ATotalSize, GetCalcCellSize(id) + ALineSize);
      id := id + 1;
    end;

    Result := AStartPoint;
    Dec(ATotalSize, GetCalcCellSize(Result) + {2 * }ALineSize); //不计算最后一个单元格的边界线
    while ATotalSize >= 0 do
    begin
      Inc(ACount);

      idNextPoint := Result + AStep;
      if IsEof(idNextPoint) or (idNextPoint < GetMinTopLeft(AStartPoint.FType)) then
        Exit;

      Dec(ATotalSize, GetCalcCellSize(idNextPoint) + ALineSize);
      if ATotalSize < 0 then
        Exit;

      Result := idNextPoint;
    end;
  end;
begin
  Result.FCol := innerCalcDiagonal(ASize.FColSize,
    Width, IfThen([goVertTitleLine, goVertLine] * Options <> [], FGridLineWidth, 0),
    AStart.FCol, IfThen(ADirection, 1, -1));
  Result.FRow := innerCalcDiagonal(ASize.FRowSize,
    Height, IfThen([goHorzTitleLine, goHorzLine] * Options <> [], FGridLineWidth, 0),
    AStart.FRow, IfThen(ADirection, 1, -1));
end;

procedure TDUIGridBase.ClampInView(const ACoord: TDUIGridCoord);
var
  gcMin, gcMax, gcNew: TDUIGridCoord;
begin
  gcNew := FTopLeft;
  gcMin := CalcDiagonal(ACoord, False);
  gcMax := CalcDiagonal(FTopLeft, True);

  if ACoord.FCol < FTopLeft.FCol then
    gcNew.FCol := ACoord.FCol
  else if ACoord.FCol > gcMax.FCol then
    gcNew.FCol := gcMin.FCol;

  if ACoord.FRow < FTopLeft.FRow then
    gcNew.FRow := ACoord.FRow
  else if ACoord.FRow > gcMax.FRow then
    gcNew.FRow := gcMin.FRow;

  MoveTopLeft(gcNew.FCol, gcNew.FRow);
end;

function TDUIGridBase.Compare(const ALeft, ARight: TDUIRowColID): Integer;
begin
  if ALeft.FType <> ARight.FType then
  begin
    raise Exception.Create('行列类型不匹配');
    Exit;
  end;

  if (ALeft.FParent <> Self) or (ARight.FParent <> Self) then
  begin
    raise Exception.Create('非当前表格的单元格');
    Exit;
  end;

  if IsFirst(ALeft) and IsFirst(ARight) then
    Result := 0
  else if IsFirst(ALeft) then
    Result := -1
  else if IsFirst(ARight) then
    Result := 1
  else if IsEof(ALeft) and IsEof(ARight) then
    Result := 0
  else if IsEof(ALeft) then
    Result := 1
  else if IsEof(ARight) then
    Result := -1
  else
    Result := DoCompare(ALeft, ARight);
end;

function TDUIGridBase.Conform(const AIndex: TDUIRowColID; AMoveModes: TDUIMoveModes): Boolean;
var
  mm: TDUIMoveModes;
begin
  if IsEof(AIndex) then
  begin
    Result := False;
    Exit;
  end;

  mm := [];
  if not CellVisible[AIndex] then
    mm := mm + [mmHide];
  if AIndex < GetMinTopLeft(AIndex.FType) then
    mm := mm + [mmFroze];

  Result := mm * AMoveModes = [];
end;

function TDUIGridBase.CoordBeginPoint(const ACoord: TDUIGridCoord): TPoint;
  function innerCoordBeginPoint(APoint: TDUIRowColID; ALineSize: Integer): Integer;
  var
    idIndex, idMinTopLeft, idTopLeft: TDUIRowColID;
  begin
    Result := 0;
    if IsEof(APoint) then
      Exit;

    Result := ALineSize;
    idIndex := First(APoint.FType, [mmHide]);
    idMinTopLeft := GetMinTopLeft(APoint.FType);
    idTopLeft := GetTopLeft(APoint.FType);
    while True do
    begin
      if (idIndex >= idMinTopLeft) and (idIndex < idTopLeft) then
        idIndex := idTopLeft;

      if (idIndex >= APoint) or IsEof(idIndex) then
        Break;

      Inc(Result, GetCalcCellSize(idIndex) + ALineSize);
      idIndex := idIndex + 1;
    end;
  end;
begin
  Result.X := innerCoordBeginPoint(ACoord.FCol,
    IfThen([goVertTitleLine, goVertLine] * Options <> [], FGridLineWidth, 0));
  Result.Y := innerCoordBeginPoint(ACoord.FRow,
    IfThen([goHorzTitleLine, goHorzLine] * Options <> [], FGridLineWidth, 0));
end;

procedure TDUIGridBase.HideEditor(ASaveData: Boolean);
begin
  if not Assigned(FEditor) then
    Exit;

  if ASaveData then
    SetEditText(Col, Row, FEditor.Text);

  FreeAndNil(FEditor);
end;

function TDUIGridBase.MakeCol(AIndex: Pointer): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := rctCol;
  Result.FIndex := AIndex;
end;

function TDUIGridBase.MakeRow(AIndex: Pointer): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := rctRow;
  Result.FIndex := AIndex;
end;  

procedure TDUIGridBase.MoveAnchor(ANewAnchor: TDUIGridCoord);
begin
  if IsEof(ANewAnchor.FCol) then
    ANewAnchor.FCol := Last(rctCol, [mmHide]);
  if ANewAnchor.FCol < GetMinTopLeft(rctCol) then
    ANewAnchor.FCol := GetMinTopLeft(rctCol);

  if IsEof(ANewAnchor.FRow) then
    ANewAnchor.FRow := Last(rctRow, [mmHide]);
  if ANewAnchor.FRow < GetMinTopLeft(rctRow) then
    ANewAnchor.FRow := GetMinTopLeft(rctRow);

  if (FAnchor.FCol = ANewAnchor.FCol) and (FAnchor.FRow = ANewAnchor.FRow) then
    Exit;

  if goRangeSelect in Options then
  begin
    FAnchor := ANewAnchor;
    Invalidate;
  end
  else
    MoveCurrent(ANewAnchor.FCol, ANewAnchor.FRow, True);
end;

procedure TDUIGridBase.MoveCurrent(ACol, ARow: TDUIRowColID; AMoveAnchor: Boolean);
begin
  if not Conform(ACol, [mmHide, mmFroze]) then
    ACol := ACol + 1;
  if IsEof(ACol) then
    ACol := Last(rctCol, [mmHide, mmFroze]);
  if ACol < GetMinTopLeft(rctCol) then
    ACol := GetMinTopLeft(rctCol);

  if not Conform(ARow, [mmHide, mmFroze]) then
    ARow := ARow + 1;
  if IsEof(ARow) then
    ARow := Last(rctRow, [mmHide, mmFroze]);
  if ARow < GetMinTopLeft(rctRow) then
    ARow := GetMinTopLeft(rctRow);

  if (ACol = Col) and (ARow = Row) then
    Exit;

  HideEditor(True);

  FCurrent.FCol := ACol;
  FCurrent.FRow := ARow;
  if AMoveAnchor or not (goRangeSelect in Options) then
  begin
    FAnchor := FCurrent;
    if goRowSelect in Options then
      FAnchor.FCol := Last(rctCol, [mmHide]);
  end;
  if goRowSelect in Options then
    FCurrent.FCol := GetMinTopLeft(rctCol);

  Invalidate;
end;

procedure TDUIGridBase.TopLeftChanged;
begin
  UpdateScrollPos;
  AdjustEditorPosition;
  Invalidate;
end;

procedure TDUIGridBase.MoveTopLeft(ACol, ARow: TDUIRowColID);
var
  gcMaxTopLeft: TDUIGridCoord;
begin
  gcMaxTopLeft.FCol := Last(rctCol, [mmHide, mmFroze]);
  gcMaxTopLeft.FRow := Last(rctRow, [mmHide, mmFroze]);
  gcMaxTopLeft := CalcDiagonal(gcMaxTopLeft, False);

  if not Conform(ACol, [mmHide, mmFroze]) then
    ACol := ACol + 1;
  if ACol > gcMaxTopLeft.FCol then
    ACol := gcMaxTopLeft.FCol;
  if ACol < GetMinTopLeft(rctCol) then
    ACol := GetMinTopLeft(rctCol);

  if not Conform(ARow, [mmHide, mmFroze]) then
    ARow := ARow + 1;
  if ARow > gcMaxTopLeft.FRow then
    ARow := gcMaxTopLeft.FRow;
  if ARow < GetMinTopLeft(rctRow) then
    ARow := GetMinTopLeft(rctRow);

  if (ACol = FTopLeft.FCol) and (ARow = FTopLeft.FRow) then
    Exit;

  FTopLeft.FCol := ACol;
  FTopLeft.FRow := ARow;

  TopLeftChanged;
end;

function TDUIGridBase.PointToCoord(const APoint: TPoint): TDUIGridCoord;
  function innerPointToCoord(AType: TDUIRowColType; AStartPoint, ALineSize: Integer): TDUIRowColID;
  var
    iBegin, iEnd: Integer;
    id: TDUIRowColID;
  begin
    if AStartPoint < 0 then
    begin
      Result := Eof(AType);
      Exit;
    end;

    iBegin := 0;
    Result := First(AType, [mmHide]);
    id := GetMinTopLeft(AType);
    while Result < id do
    begin
      iEnd := iBegin + 2 * ALineSize + GetCalcCellSize(Result);
      if (AStartPoint >= iBegin) and (AStartPoint < iEnd) then
        Exit;

      iBegin := iEnd - ALineSize;
      Result := Result + 1;
    end;

    Result := GetTopLeft(AType);
    while Result < Eof(AType) do
    begin
      iEnd := iBegin + 2 * ALineSize + GetCalcCellSize(Result);
      if (AStartPoint >= iBegin) and (AStartPoint < iEnd) then
        Exit;

      iBegin := iEnd - ALineSize;
      Result := Result + 1;
    end;

    //循环结束后，Result的值即为Eof
  end;
begin
  Result.FCol := innerPointToCoord(rctCol, APoint.X,
    IfThen([goVertTitleLine, goVertLine] * Options <> [], FGridLineWidth, 0));
  Result.FRow := innerPointToCoord(rctRow, APoint.Y,
    IfThen([goHorzTitleLine, goHorzLine] * Options <> [], FGridLineWidth, 0));
end;

procedure TDUIGridBase.ShowEditor;
begin
  if not (goEditing in Options) or (goRowSelect in Options) or (csDesigning in ComponentState) then
    Exit;

  if not Assigned(FEditor) and Assigned(GetEditClass(Col, Row)) then
  begin
    FEditor := GetEditClass(Col, Row).Create(Self);
    FOldEditWndProc := FEditor.WindowProc;
    FEditor.WindowProc := EditWndProc;
    FEditor.DUIParent := Self;
    InitEditor(FEditor);
  end;

  AdjustEditorPosition;
end;

procedure TDUIGridBase.UpdateScrollPos;
  procedure setScrollBar(AMinPosition, APosition, AMaxPosition: TDUIRowColID; APageSize: Integer);
  var
    iMin, iMax, iPos: Integer;
  begin
    if AMinPosition = AMaxPosition then
      FScrollBars[APosition.FType].Visible := False
    else if (FGridState = gsNormal) and Assigned(RootParent)
      and not PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos)) //鼠标不在表格区域内
      and (FScrollBars[rctCol].Area = sbaNone) //鼠标没有拖拽滚动条
      and (FScrollBars[rctRow].Area = sbaNone) then
      FScrollBars[APosition.FType].Visible := False
    else
    begin
      FScrollBars[APosition.FType].Visible := True;
      FScrollBars[APosition.FType].OnChange := nil;
      try
        IDsToPos(iMin, iMax, iPos,
          AMinPosition, Last(APosition.FType, [mmHide, mmFroze]), APosition);

        FScrollBars[APosition.FType].UpdateData(iMin, iMax, iPos, APageSize);
      finally
        FScrollBars[APosition.FType].OnChange := DoScrollBarChange;
      end;
    end;
  end;
var
  gcMaxTopLeft: TDUIGridCoord;
  gs: TDUIGridSize;
begin
  gcMaxTopLeft.FCol := Last(rctCol, [mmHide, mmFroze]);
  gcMaxTopLeft.FRow := Last(rctRow, [mmHide, mmFroze]);
  gcMaxTopLeft := CalcDiagonal(gs, gcMaxTopLeft, False);

  setScrollBar(GetMinTopLeft(rctCol), FTopLeft.FCol, gcMaxTopLeft.FCol, gs.FColSize);
  setScrollBar(GetMinTopLeft(rctRow), FTopLeft.FRow, gcMaxTopLeft.FRow, gs.FRowSize);
end;

function TDUIGridBase.GetAnchor(AType: TDUIRowColType): TDUIRowColID;
begin
  if AType = rctCol then
    Result := FAnchor.FCol
  else
    Result := FAnchor.FRow;
end;

function TDUIGridBase.GetCalcCellSize(const AIndex: TDUIRowColID): Integer;
begin
  Result := GetCellSize(AIndex);
end;

function TDUIGridBase.GetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList;
begin
  Result := nil;
end;

function TDUIGridBase.GetTopLeft(AType: TDUIRowColType): TDUIRowColID;
begin
  if AType = rctCol then
    Result := FTopLeft.FCol
  else
    Result := FTopLeft.FRow;
end;

function TDUIGridBase.GetEditText(const ACol, ARow: TDUIRowColID): String;
begin
  if IsFirst(ACol) or IsFirst(ARow) then
  begin
    raise Exception.Create('索引越界');
    Exit;
  end;

  Result := '';
  if not Assigned(FData) then
    Exit;

  Result := FData.GetEditText(ACol, ARow);
end;

procedure TDUIGridBase.SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String);
begin
  if IsFirst(ACol) or IsFirst(ARow) then
  begin
    raise Exception.Create('索引越界');
    Exit;
  end;

  if not Assigned(FData) then
  begin
    FData := TDUIGridHashData.Create(Self);
    FData.FGrid := Self;
    FOwnData := True;
  end;

  FData.SetEditText(ACol, ARow, AValue);
end;

procedure TDUIGridBase.SizeChanged(const AIndex: TDUIRowColID);
begin
  UpdateScrollPos;
  AdjustEditorPosition;
  Invalidate;
end;

function TDUIGridBase.GetTitleSize(const AType: TDUIRowColType): Integer;
begin
  Result := FTitleSize[AType];
end;

procedure TDUIGridBase.SetTitleSize(const AType: TDUIRowColType; const AValue: Integer);
begin
  if FTitleSize[AType] = AValue then
    Exit;

  FTitleSize[AType] := AValue;
  SizeChanged(First(AType));
end;

function TDUIGridBase.GetDefaultCellSize(const AType: TDUIRowColType): Integer;
begin
  Result := FDefaultSize[AType];
end;

procedure TDUIGridBase.SetDefaultCellSize(const AType: TDUIRowColType; const AValue: Integer);
begin
  if FDefaultSize[AType] = AValue then
    Exit;

  FDefaultSize[AType] := AValue;
  SizeChanged(Eof(AType));
end;

function TDUIGridBase.GetSelection: TDUIGridRect;
  function min(ALeft, ARight: TDUIRowColID): TDUIRowColID;
  begin
    if ALeft < ARight then
      Result := ALeft
    else
      Result := ARight;
  end;
  function max(ALeft, ARight: TDUIRowColID): TDUIRowColID;
  begin
    if ALeft < ARight then
      Result := ARight
    else
      Result := ALeft;
  end;
begin
  Result.Left := min(Col, FAnchor.FCol);
  Result.Right := max(Col, FAnchor.FCol);
  Result.Top := min(Row, FAnchor.FRow);
  Result.Bottom := max(Row, FAnchor.FRow);
end;

procedure TDUIGridBase.SetSelection(AValue: TDUIGridRect);
begin
  FAnchor := AValue.TopLeft;
  MoveCurrent(AValue.Right, AValue.Bottom, False);
  Invalidate;
end;

procedure TDUIGridBase.SetGridLineWidth(AValue: Integer);
begin
  if FGridLineWidth = AValue then
    Exit;

  FGridLineWidth := AValue;
  SizeChanged(Eof(rctRow));
end;

procedure TDUIGridBase.SetOptions(AValue: TDUIGridOptions);
begin
  if FOptions = AValue then
    Exit;

  FOptions := AValue;
  SizeChanged(Eof(rctRow));
end;

procedure TDUIGridBase.SetData(const AValue: TDUIGridData);
begin
  if FData = AValue then
    Exit;

  if FOwnData then
  begin
    FreeAndNil(FData);
    FOwnData := False;
  end
  else if Assigned(FData) then
    FData.RemoveFreeNotification(Self);

  FData := AValue;
  if Assigned(FData) then
  begin
    FData.FGrid := Self;
    FData.FreeNotification(Self);
  end;

  Invalidate;
end;

end.
