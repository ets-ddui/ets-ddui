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
unit UDUITreeGrid;

interface

uses
  Classes, SysUtils, StrUtils, Controls, Windows, Graphics, Messages, IGDIPlus,
  UDUICore, UDUIGrid, UDUIUtils;

type
  TDUITreeGrid = class;

  TDUITreeColumn = class(TCollectionItem)
  private
    FCaption: String;
    FVisible: Boolean;
    FPercent: Boolean; //按比例缩放
    FWidth: Integer;
    FCalcWidth: Integer;
    procedure SetCaption(const AValue: String);
    procedure SetVisible(const AValue: Boolean);
    procedure SetPercent(const AValue: Boolean);
    procedure SetWidth(const AValue: Integer);
  public
    constructor Create(ACollection: TCollection); override;
  published
    property Caption: String read FCaption write SetCaption;
    property Visible: Boolean read FVisible write SetVisible default True;
    property Percent: Boolean read FPercent write SetPercent default False;
    property Width: Integer read FWidth write SetWidth;
  end;

  TDUITreeColumns = class(TCollection)
  private
    FParent: TDUITreeGrid;
    function GetColumn(AIndex: Integer): TDUITreeColumn;
    procedure SetColumn(AIndex: Integer; const AValue: TDUITreeColumn);
  protected
    function GetOwner: TPersistent; override;
    procedure Notify(AItem: TCollectionItem; AAction: TCollectionNotification); override;
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(AParent: TDUITreeGrid; AItemClass: TCollectionItemClass);
    function Add(ACaption: String): TDUITreeColumn;
    property Items[AIndex: Integer]: TDUITreeColumn read GetColumn write SetColumn; default;
  end;

  TDUITreeData = class
  private
    FCollapsed: Boolean;
    FHeight: Integer;
    FOwned: Boolean;
    FObject: TObject;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TDUITreeNodeClass = class of TDUITreeNode;
  TDUITreeNode = class
  private
    //叶子节点、节点链表的尾节点都会存在一些空指针，重复利用这些指针存放一些特殊信息：
    //叶子节点：FLast属性存放父节点指针(FFirst为nil即为叶子节点)
    //节点链表尾节点：存放祖父节点(可通过读取最后一个子节点的FLast属性，获取父节点指针)
    FPrior, FNext, FFirst, FLast: TDUITreeNode;
    FCaption: String;
    FIndex: Integer;
    FNodeClass: TDUITreeNodeClass;
    function GetIndex: Integer;
    function GetLevel: Integer;
    function GetParent: TDUITreeNode;
    procedure SetCaption(const AValue: String);
    function GetCells(AColIndex: Integer): String;
    procedure SetCells(AColIndex: Integer; const AValue: String);
    function GetCollapsed: Boolean;
    procedure SetCollapsed(const AValue: Boolean);
    function GetHeight: Integer;
    procedure SetHeight(const AValue: Integer);
    function GetChildCount: Integer;
    function GetChilds(AIndex: Integer): TDUITreeNode;
    function GetNode(const AIndex: Integer): TDUITreeNode;
    function GetObjectData: TObject;
    procedure SetObjectData(const AValue: TObject);
  protected
    procedure AdjustGridNode(ANewNode: TDUITreeNode);
    procedure Changed(AItem: TDUITreeNode);
    procedure Notify(AAction: TCollectionNotification);
    function IsFirst: Boolean;
    function IsLast: Boolean;
    function IsLeaf: Boolean;
    function GetGrid: TDUITreeGrid;
    function GetData(AAutoCreate: Boolean = False): TDUITreeData;
  public
    procedure BeforeDestruction; override;
    constructor Create(ANodeClass: TDUITreeNodeClass);
    destructor Destroy; override;
    function AddChild(ACaption: String; AFirst: Boolean = False): TDUITreeNode;
    procedure Clear;
    function Move(ADistinct: Integer): TDUITreeNode;
    property Caption: String read FCaption write SetCaption;
    property Cells[AColIndex: Integer]: String read GetCells write SetCells;
    property ChildCount: Integer read GetChildCount;
    property Childs[AIndex: Integer]: TDUITreeNode read GetChilds; default;
    //True表示折叠，False表示展开
    property Collapsed: Boolean read GetCollapsed write SetCollapsed;
    property Height: Integer read GetHeight write SetHeight;
    property Index: Integer read GetIndex;
    property Level: Integer read GetLevel;
    property ObjectData: TObject read GetObjectData write SetObjectData; //SetObjectData会导致对象的所有权发生转移
    property Prior: TDUITreeNode index 1 read GetNode;
    property Next: TDUITreeNode index 2 read GetNode;
    property First: TDUITreeNode index 3 read GetNode;
    property Last: TDUITreeNode index 4 read GetNode;
  end;

  TOnGetPaintControls = function (ASender: TObject; const ACol, ARow: TDUIRowColID): TControlsList of object;
  TOnSelectCell = procedure (ASender: TObject; const ACol, ARow: TDUIRowColID; AX, AY: Integer) of object;
  TDUITreeGrid = class(TDUIGridBase)
  private
    FColumnSizeChanged: Boolean;
    FColumns: TDUITreeColumns;
    FRootNode: TDUITreeNode;
    FPaintControls: TControlsList;
    FOnGetPaintControls: TOnGetPaintControls;
    FOnSelectCell: TOnSelectCell;
    FOnSelectCellDouble: TOnSelectCell;
    procedure ButtonMouseDown(ASender: TObject; AButton: TMouseButton;
      AShift: TShiftState; AX, AY: Integer);
    //CalcDiagonalNode - 计算右下角的节点ID
    //返回值 - 右下角的节点ID
    //ADistinct(出参) - 返回节点和ANode的距离
    function CalcDiagonalNode(ANode: TDUIRowColID; ADistinct: PInteger = nil): TDUIRowColID;
    //CalcNodePos - 计算ANode所在的序号位置
    //返回值 - ANode序号位置
    //ACount(出参) - 总序号个数(所有父节点的Count求和)
    function CalcNodePos(ANode: TDUIRowColID; ACount: PInteger = nil): Integer;
    procedure SetColumns(const AValue: TDUITreeColumns);
    function GetCells(ACol: TDUITreeColumn; ARow: TDUITreeNode): String;
    procedure SetCells(ACol: TDUITreeColumn; ARow: TDUITreeNode; const AValue: String);
  protected
    procedure DoCreate(var AColumns: TDUITreeColumns; var ARootNode: TDUITreeNode); virtual;
    function CalcMovedID(const AIndex: TDUIRowColID;
      ACount: Integer; AMoveModes: TDUIMoveModes): TDUIRowColID; override;
    function DoCompare(const ALeft, ARight: TDUIRowColID): Integer; override;
    function IsFirst(AIndex: TDUIRowColID): Boolean; override;
    function IsEof(AIndex: TDUIRowColID): Boolean; override;
    function First(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID; override;
    function Last(AType: TDUIRowColType; AMoveModes: TDUIMoveModes = []): TDUIRowColID; override;
    function Eof(AType: TDUIRowColType): TDUIRowColID; override;
    function GetMinTopLeft(AType: TDUIRowColType): TDUIRowColID; override;
    function GetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList; override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    function PosToID(AType: TDUIRowColType; APos: Integer): TDUIRowColID; override;
    procedure IDsToPos(var AResMin, AResMax, AResPos: Integer;
      const AMin, AMax, APos: TDUIRowColID); override;
    procedure SizeChanged(const AIndex: TDUIRowColID); override;
    function GetEditClass(const ACol, ARow: TDUIRowColID): TDUIKeyboardBaseClass; override;
    procedure InitEditor(AEditor: TDUIKeyboardBase); override;
    function GetEditText(const ACol, ARow: TDUIRowColID): String; override;
    procedure SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String); override;
    function GetCalcCellSize(const AIndex: TDUIRowColID): Integer; override;
    function GetCellSize(const AIndex: TDUIRowColID): Integer; override;
    procedure SetCellSize(const AIndex: TDUIRowColID; const AValue: Integer); override;
    function GetCellVisible(const AIndex: TDUIRowColID): Boolean; override;
    procedure SetCellVisible(const AIndex: TDUIRowColID; const AValue: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Cells[ACol: TDUITreeColumn; ARow: TDUITreeNode]: String read GetCells write SetCells;
    property RootNode: TDUITreeNode read FRootNode;
  published
    property Columns: TDUITreeColumns read FColumns write SetColumns;
    property DefaultColWidth;
    property DefaultRowHeight;
    property GridLineWidth;
    property Options;
    property TitleHeight;
    property TitleWidth;
    property OnGetPaintControls: TOnGetPaintControls read FOnGetPaintControls write FOnGetPaintControls;
    property OnSelectCell: TOnSelectCell read FOnSelectCell write FOnSelectCell;
    property OnSelectCellDouble: TOnSelectCell read FOnSelectCellDouble write FOnSelectCellDouble;
  end;

implementation

uses
  Types, UDUIEdit, UDUIButton, UDUIShape, UDUILabel;

const
  CIndent: Integer = 10; //树的每个子节点的缩进长度

{ TDUITreeColumn }

constructor TDUITreeColumn.Create(ACollection: TCollection);
begin
  inherited;

  FWidth := -1; //默认取TDUITreeGrid上的默认宽度
  FVisible := True;
end;

procedure TDUITreeColumn.SetCaption(const AValue: String);
begin
  if FCaption = AValue then
    Exit;

  FCaption := AValue;
  Changed(False);
end;

procedure TDUITreeColumn.SetPercent(const AValue: Boolean);
begin
  if FPercent = AValue then
    Exit;

  FPercent := AValue;
  Changed(True);
end;

procedure TDUITreeColumn.SetVisible(const AValue: Boolean);
begin
  if FVisible = AValue then
    Exit;

  FVisible := AValue;
  Changed(True);
end;

procedure TDUITreeColumn.SetWidth(const AValue: Integer);
begin
  if FWidth = AValue then
    Exit;

  FWidth := AValue;
  Changed(True);
end;

{ TDUITreeColumns }

function TDUITreeColumns.Add(ACaption: String): TDUITreeColumn;
begin
  Result := TDUITreeColumn(inherited Add);
  Result.Caption := ACaption;
end;

constructor TDUITreeColumns.Create(AParent: TDUITreeGrid; AItemClass: TCollectionItemClass);
begin
  inherited Create(AItemClass);

  FParent := AParent;
end;

function TDUITreeColumns.GetColumn(AIndex: Integer): TDUITreeColumn;
begin
  Result := TDUITreeColumn(inherited Items[AIndex]);
end;

function TDUITreeColumns.GetOwner: TPersistent;
begin
  Result := FParent;
end;

procedure TDUITreeColumns.Notify(AItem: TCollectionItem; AAction: TCollectionNotification);
begin
  inherited;

  if not Assigned(FParent) or not Assigned(FParent.FRootNode) then
    Exit;

  case AAction of
    cnAdded:
    begin

    end;
    cnExtracting:
    begin
      if AItem = FParent.Col.FIndex then
        FParent.MoveCurrent(FParent.Col + 1, FParent.Row, True);

      if AItem = FParent.GetAnchor(rctCol).FIndex then
        FParent.MoveCurrent(FParent.Col, FParent.Row, True);

      if AItem = FParent.GetTopLeft(rctCol).FIndex then
        FParent.MoveTopLeft(FParent.GetTopLeft(rctCol) + 1, FParent.GetTopLeft(rctRow));
    end;
  end;
end;

procedure TDUITreeColumns.SetColumn(AIndex: Integer; const AValue: TDUITreeColumn);
begin
  Items[AIndex].Assign(AValue);
end;

procedure TDUITreeColumns.Update(AItem: TCollectionItem);
begin
  if Assigned(FParent) and Assigned(FParent.FRootNode) then
  begin
    if Assigned(AItem) then
      TDUITreeGrid(FParent).SizeChanged(TDUITreeGrid(FParent).MakeCol(AItem))
    else
      TDUITreeGrid(FParent).SizeChanged(TDUITreeGrid(FParent).Eof(rctCol));
  end;
end;

{ TDUITreeData }

constructor TDUITreeData.Create;
begin
  FHeight := -1; //默认取TDUITreeGrid上的默认高度
end;

destructor TDUITreeData.Destroy;
begin
  if FOwned then
    FreeAndNil(FObject);

  inherited;
end;

{ TDUITreeNode }

constructor TDUITreeNode.Create(ANodeClass: TDUITreeNodeClass);
begin
  FNodeClass := ANodeClass;
end;

destructor TDUITreeNode.Destroy;
begin
  GetData.Free;

  inherited;
end;

function TDUITreeNode.AddChild(ACaption: String; AFirst: Boolean): TDUITreeNode;
begin
  Result := FNodeClass.Create(FNodeClass);
  Result.FCaption := ACaption;
  Result.FLast := Self;

  if IsLeaf then
  begin
    Result.FPrior := FFirst;
    Result.FNext := FLast;

    FFirst := Result;
    FLast := Result;
  end
  else if AFirst then
  begin
    Result.FIndex := FFirst.FIndex - 1;
    Result.FPrior := FFirst.FPrior;
    Result.FNext := FFirst;

    FFirst.FPrior := Result;
    FFirst := Result;
  end
  else
  begin
    Result.FIndex := FLast.FIndex + 1;
    Result.FNext := FLast.FNext;
    Result.FPrior := FLast;

    FLast.FNext := Result;
    FLast := Result;
  end;

  Result.Notify(cnAdded);
end;

procedure TDUITreeNode.AdjustGridNode(ANewNode: TDUITreeNode);
  function hasChild(AChild: TDUITreeNode): Boolean;
  begin
    //AChild与Self相等也返回True
    while Assigned(AChild) and (AChild <> Self) do
      AChild := AChild.GetParent;

    Result := AChild = Self;
  end;
var
  tg: TDUITreeGrid;
begin
  tg := GetGrid;
  if not Assigned(tg) or not Assigned(tg.FRootNode) then
    Exit;

  if not tg.IsFirst(tg.Row) and not tg.IsEof(tg.Row)
    and hasChild(TDUITreeNode(tg.Row.FIndex)) then
    tg.MoveCurrent(tg.Col, tg.MakeRow(ANewNode), True);

  if not tg.IsFirst(tg.GetAnchor(rctRow)) and not tg.IsEof(tg.GetAnchor(rctRow))
    and hasChild(TDUITreeNode(tg.GetAnchor(rctRow).FIndex)) then
    tg.MoveCurrent(tg.Col, tg.MakeRow(ANewNode), True);

  if not tg.IsFirst(tg.GetTopLeft(rctRow)) and not tg.IsEof(tg.GetTopLeft(rctRow))
    and hasChild(TDUITreeNode(tg.GetTopLeft(rctRow).FIndex)) then
    tg.MoveTopLeft(tg.GetTopLeft(rctCol), tg.MakeRow(ANewNode));
end;

procedure TDUITreeNode.BeforeDestruction;
begin
  inherited;

  Notify(cnExtracting);
  Clear;
end;

procedure TDUITreeNode.Changed(AItem: TDUITreeNode);
var
  tg: TDUITreeGrid;
begin
  tg := GetGrid;
  if not Assigned(tg) or not Assigned(tg.FRootNode) then
    Exit;

  if Assigned(AItem) then
    tg.SizeChanged(tg.MakeRow(AItem))
  else
    tg.SizeChanged(tg.Eof(rctRow));
end;

procedure TDUITreeNode.Clear;
var
  tnDelete, tnFirst, tnLast: TDUITreeNode;
begin
  if IsLeaf then
    Exit;

  tnFirst := FFirst;
  tnLast := FLast;

  FFirst := tnFirst.FPrior; //将当前节点调整为叶子节点(调整父节点及数据节点的指针)
  FLast := tnLast.FNext;
  AdjustGridNode(Self);

  while tnFirst <> tnLast do
  begin
    tnDelete := tnFirst;
    tnFirst := tnFirst.FNext;
    tnDelete.Free;
  end;
  FreeAndNil(tnLast);

  Changed(nil);
end;

procedure TDUITreeNode.Notify(AAction: TCollectionNotification);
  function nextNode(ADefault: TDUITreeNode): TDUITreeNode;
  begin
    Result := Self;
    while Assigned(Result) do
    begin
      if not Result.IsLast then
      begin
        Result := Result.FNext;
        Exit;
      end;

      Result := Result.GetParent;
    end;

    Result := ADefault;
  end;
var
  tg: TDUITreeGrid;
  tnParent, tnNext: TDUITreeNode;
begin
  tg := GetGrid;
  if not Assigned(tg) or not Assigned(tg.FRootNode) then
    Exit;

  case AAction of
    cnAdded:
    begin
      Changed(nil);
    end;
    cnExtracting:
    begin
      //1.0 计算第3步待修正的节点位置(需要放在第2步前面，否则，因链接信息被修正，而无法正确获取数据)
      tnNext := nextNode(TDUITreeNode(tg.Eof(rctRow).FIndex));

      //2.0 修正TDUITreeNode的链表指针
      tnParent := GetParent;
      if Assigned(tnParent) then
      begin
        if tnParent.FFirst = tnParent.FLast then //只有一个节点
        begin
          tnParent.FFirst := FPrior;
          tnParent.FLast := FNext;
        end
        else if IsFirst then //删除第一个节点
        begin
          tnParent.FFirst := FNext;
          FNext.FPrior := FPrior;
        end
        else if IsLast then //删除最后一个节点
        begin
          tnParent.FLast := FPrior;
          FPrior.FNext := FNext;
        end
        else //从中间删除
        begin
          FPrior.FNext := FNext;
          FNext.FPrior := FPrior;

          while True do
          begin
            FNext.FIndex := FNext.FPrior.FIndex + 1;
            if tnParent.FLast = FNext then
              Break;

            FNext := FNext.FNext;
          end;

          FIndex := FNext.FIndex + 1;
        end;

        tnParent.AdjustGridNode(tnNext); //当前节点已被从链表中删除，因此，要用父节点来调整表格节点，否则，会因为无法获取表格指针而调整失败
        tnParent.Changed(nil); //触发刷新界面事件
      end;
    end;
  end;
end;

function TDUITreeNode.GetData(AAutoCreate: Boolean): TDUITreeData;
begin
  if IsLeaf then
  begin
    Result := TDUITreeData(FFirst);
    if not Assigned(Result) and AAutoCreate then
    begin
      Result := TDUITreeData.Create;
      FFirst := TDUITreeNode(Result);
    end;
  end
  else
  begin
    Result := TDUITreeData(FFirst.FPrior);
    if not Assigned(Result) and AAutoCreate then
    begin
      Result := TDUITreeData.Create;
      FFirst.FPrior := TDUITreeNode(Result);
    end;
  end;
end;

function TDUITreeNode.GetGrid: TDUITreeGrid;
  function isRoot(ANode: TDUITreeNode): Boolean;
  begin
    if ANode.IsLeaf then
      Result := TObject(ANode.FLast) is TDUITreeGrid
    else
      Result := TObject(ANode.FLast.FNext) is TDUITreeGrid;
  end;
var
  tn, tnParent: TDUITreeNode;
begin
  tn := Self;
  while not isRoot(tn) do
  begin
    tnParent := tn.GetParent;
    //检测父节点与当前节点是否已断开连接
    if not Assigned(tnParent) or tnParent.IsLeaf
      or (tnParent.FFirst.FIndex > tn.FIndex)
      or (tnParent.FLast.FIndex < tn.FIndex) then
    begin
      Result := nil;
      Exit;
    end;

    tn := tnParent;
  end;

  if tn.IsLeaf then
    Result := TObject(tn.FLast) as TDUITreeGrid
  else
    Result := TObject(tn.FLast.FNext) as TDUITreeGrid;
end;

function TDUITreeNode.GetIndex: Integer;
begin
  if GetParent <> nil then
    Result := FIndex - GetParent.FFirst.FIndex //从0开始计算
  else
    Result := FIndex;
end;

function TDUITreeNode.GetLevel: Integer;
var
  ndParent: TDUITreeNode;
begin
  Result := -1;

  ndParent := Self;
  repeat
    Inc(Result);
    ndParent := ndParent.GetParent;
  until not Assigned(ndParent);
end;

function TDUITreeNode.GetNode(const AIndex: Integer): TDUITreeNode;
begin
  Result := nil;

  case AIndex of
    1: //Prior
    begin
      if IsFirst then
        Exit;

      Result := FPrior;
    end;
    2: //Next
    begin
      if IsLast then
        Exit;

      Result := FNext;
    end;
    3: //First
    begin
      if IsLeaf then
        Exit;

      Result := FFirst;
    end;
    4: //Last
    begin
      if IsLeaf then
        Exit;

      Result := FLast;
    end;
  end;
end;

function TDUITreeNode.GetParent: TDUITreeNode;
begin
  if IsLeaf then
    Result := FLast
  else
    Result := FLast.FNext;

  if TObject(Result) is TDUITreeGrid then
    Result := nil;
end;

function TDUITreeNode.IsFirst: Boolean;
begin
  Result := not Assigned(FPrior) or (TObject(FPrior) is TDUITreeData);
end;

function TDUITreeNode.IsLast: Boolean;
var
  trParent: TDUITreeNode;
begin
  Result := True;
  trParent := GetParent;
  if not Assigned(trParent) then
    Exit;

  Result := trParent.FLast = Self;
end;

function TDUITreeNode.IsLeaf: Boolean;
begin
  Result := not Assigned(FFirst) or (TObject(FFirst) is TDUITreeData);
end;

function TDUITreeNode.Move(ADistinct: Integer): TDUITreeNode;
  function prior(ADistinct: Integer): TDUITreeNode;
  var
    i, iCount: Integer;
  begin
    Result := Self;
    while ADistinct > 0 do
    begin
      iCount := Result.Index + 1;
      if ADistinct < iCount then
      begin
        for i := 1 to ADistinct do
          Result := Result.FPrior;

        Exit;
      end;

      Dec(ADistinct, iCount);
      if Result.GetParent = nil then
        Exit;

      Result := Result.GetParent;
    end;
  end;
  function next(ADistinct: Integer): TDUITreeNode;
  var
    trParent: TDUITreeNode;
    i, iCount: Integer;
  begin
    Result := Self;
    while ADistinct > 0 do
    begin
      trParent := Result.GetParent;
      if not Assigned(trParent) then
        Break;

      iCount := trParent.FLast.FIndex - Result.FIndex;
      if ADistinct <= iCount then
      begin
        for i := 1 to ADistinct do
          Result := Result.FNext;

        Exit;
      end;

      Dec(ADistinct, iCount);
      Result := trParent;
    end;

    Result := TDUITreeNode(1);
  end;
begin
  if ADistinct < 0 then
    Result := prior(-ADistinct)
  else if ADistinct > 0 then
    Result := next(ADistinct)
  else
    Result := Self;
end;

procedure TDUITreeNode.SetCaption(const AValue: String);
begin
  if FCaption = AValue then
    Exit;

  FCaption := AValue;
  Changed(Self);
end;

function TDUITreeNode.GetCells(AColIndex: Integer): String;
var
  tg: TDUITreeGrid;
begin
  Result := '';

  tg := GetGrid;
  if not Assigned(tg) then
    Exit;

  Result := tg.Cells[tg.Columns[AColIndex], Self];
end;

procedure TDUITreeNode.SetCells(AColIndex: Integer; const AValue: String);
var
  tg: TDUITreeGrid;
begin
  tg := GetGrid;
  if not Assigned(tg) then
    Exit;

  tg.Cells[tg.Columns[AColIndex], Self] := AValue;
end;

function TDUITreeNode.GetChildCount: Integer;
begin
  if IsLeaf then
    Result := 0
  else
    Result := FLast.FIndex - FFirst.FIndex + 1;
end;

function TDUITreeNode.GetChilds(AIndex: Integer): TDUITreeNode;
var
  i: Integer;
begin
  if (AIndex < 0) or (AIndex >= GetChildCount) then
    raise Exception.Create('索引越界');

  Result := FFirst;
  for i := 1 to AIndex do
    Result := Result.FNext;
end;

function TDUITreeNode.GetCollapsed: Boolean;
var
  td: TDUITreeData;
begin
  Result := False;

  td := GetData;
  if not Assigned(td) then
    Exit;

  Result := td.FCollapsed;
end;

procedure TDUITreeNode.SetCollapsed(const AValue: Boolean);
begin
  if GetCollapsed = AValue then
    Exit;

  GetData(True).FCollapsed := AValue;
  Changed(nil);
end;

function TDUITreeNode.GetHeight: Integer;
var
  td: TDUITreeData;
begin
  Result := -1;

  td := GetData;
  if not Assigned(td) then
    Exit;

  Result := td.FHeight;
end;

procedure TDUITreeNode.SetHeight(const AValue: Integer);
begin
  if GetHeight = AValue then
    Exit;

  GetData(True).FHeight := AValue;
  Changed(nil);
end;

function TDUITreeNode.GetObjectData: TObject;
var
  td: TDUITreeData;
begin
  Result := nil;

  td := GetData;
  if not Assigned(td) then
    Exit;

  Result := td.FObject;
end;

procedure TDUITreeNode.SetObjectData(const AValue: TObject);
begin
  if GetObjectData = AValue then
    Exit;

  with GetData(True) do
  begin
    if FOwned and Assigned(FObject) then
      FObject.Free;

    FOwned := True;
    FObject := AValue;
  end;
end;

{ TDUITreeGrid }

constructor TDUITreeGrid.Create(AOwner: TComponent);
begin
  inherited;

  DoCreate(FColumns, FRootNode);
  FRootNode.FLast := TDUITreeNode(Self);
end;

destructor TDUITreeGrid.Destroy;
var
  i: Integer;
begin
  FreeAndNil(FRootNode); //在行列变化的响应事件中，通过此字段是否为空来识别当前是否在析构阶段，必须放在开头

  FColumns.FParent := nil;
  FreeAndNil(FColumns);

  if Assigned(FPaintControls) then
  begin
    for i := FPaintControls.Count - 1 downto 0 do
      TDUIBase(FPaintControls[i]).Free;
    FreeAndNil(FPaintControls);
  end;

  inherited;
end;

procedure TDUITreeGrid.DoCreate(var AColumns: TDUITreeColumns; var ARootNode: TDUITreeNode);
begin
  AColumns := TDUITreeColumns.Create(Self, TDUITreeColumn);
  AColumns.Add('');

  ARootNode := TDUITreeNode.Create(TDUITreeNode);
end;

function TDUITreeGrid.CalcDiagonalNode(ANode: TDUIRowColID; ADistinct: PInteger): TDUIRowColID;
var
  gc: TDUIGridCoord;
  si: TDUIGridSize;
begin
  gc.FCol := GetTopLeft(rctCol);
  gc.FRow := ANode;
  gc := CalcDiagonal(si, gc, True);
  Result := gc.FRow;

  if Assigned(ADistinct) then
    ADistinct^ := Integer(si.FRowSize);
end;

function TDUITreeGrid.CalcMovedID(const AIndex: TDUIRowColID;
  ACount: Integer; AMoveModes: TDUIMoveModes): TDUIRowColID;
  function nextColumn(var AResult: TDUITreeColumn): Boolean;
  var
    iIndex: Integer;
  begin
    Result := False;

    case Integer(AResult) of
      0:
      begin
        if FColumns.Count = 0 then
          Exit;

        AResult := FColumns[0];
        Result := True;
        Exit;
      end;
      1:
      begin
        Exit;
      end;
    end;

    if AResult.Collection <> FColumns then
      Exit;

    iIndex := AResult.Index;
    if (iIndex >= 0) and (iIndex < AResult.Collection.Count - 1) then
    begin
      AResult := TDUITreeColumn(AResult.Collection.Items[iIndex + 1]);
      Result := True;
      Exit;
    end;
  end;
  function priorColumn(var AResult: TDUITreeColumn): Boolean;
  var
    iIndex: Integer;
  begin
    Result := False;

    case Integer(AResult) of
      0:
      begin
        Exit;
      end;
      1:
      begin
        if FColumns.Count = 0 then
          AResult := Pointer(0)
        else
          AResult := FColumns[FColumns.Count - 1];

        Result := True;
        Exit;
      end;
    end;

    if AResult.Collection <> FColumns then
      Exit;

    iIndex := AResult.Index;
    if iIndex > 0 then
      AResult := TDUITreeColumn(AResult.Collection.Items[iIndex - 1])
    else
      AResult := Pointer(0);
    Result := True;
    Exit;
  end;
  function nodeConform(AIndex: TDUITreeNode): Boolean;
  var
    id: TDUIRowColID;
  begin
    id.FParent := Self;
    id.FType := rctRow;
    id.FIndex := AIndex;

    Result := Conform(id, AMoveModes);
  end;
  function nextNode(var AResult: TDUITreeNode): Boolean;
  begin
    Result := False;

    if Integer(AResult) = 1 then
      Exit;

    if AResult = FRootNode then
    begin
      if FRootNode.IsLeaf then
        Exit;

      AResult := FRootNode.FFirst;
      Result := True;
      Exit;
    end;

    //1.0 取第一个子节点
    if not AResult.IsLeaf and nodeConform(AResult.FFirst) then
    begin
      AResult := AResult.FFirst;
      Result := True;
      Exit;
    end;

    //2.0 取下一个兄弟节点，如果不存在，则取父节点的兄弟节点
    repeat
      if nodeConform(AResult) then
      begin
        if not AResult.IsLast then
        begin
          AResult := AResult.FNext;
          Result := True;
          Exit;
        end;
      end;

      AResult := AResult.GetParent;
    until not Assigned(AResult);
  end;
  function priorNode(var AResult: TDUITreeNode): Boolean;
  begin
    Result := False;

    if AResult = FRootNode then
      Exit;

    if Integer(AResult) = 1 then
    begin
      AResult := FRootNode;
      while not AResult.IsLeaf do
        AResult := AResult.FLast;

      Result := True;
      Exit;
    end;

    if nodeConform(AResult) and not AResult.IsFirst then
    begin
      AResult := AResult.FPrior;
      while not AResult.IsLeaf do
        AResult := AResult.FLast;

      Result := True;
      Exit;
    end;

    if AResult.GetParent <> nil then
    begin
      AResult := AResult.GetParent;
      Result := True;
    end;
  end;
var
  iStep: Integer;
  bMoved: Boolean;
begin
  Result := AIndex;
  if ACount = 0 then
    Exit;

  iStep := IfThen(ACount > 0, 1, -1);
  while ACount <> 0 do
  begin
    if ACount > 0 then
    begin
      if AIndex.FType = rctCol then
        bMoved := nextColumn(TDUITreeColumn(Result.FIndex))
      else
        bMoved := nextNode(TDUITreeNode(Result.FIndex));
    end
    else
    begin
      if AIndex.FType = rctCol then
        bMoved := priorColumn(TDUITreeColumn(Result.FIndex))
      else
        bMoved := priorNode(TDUITreeNode(Result.FIndex));
    end;

    if not bMoved then
    begin
      if ACount < 0 then
        Result := First(AIndex.FType)
      else
        Result := Eof(AIndex.FType);
      Exit;
    end;

    if not Conform(Result, AMoveModes) then
      Continue;

    ACount := ACount - iStep;
  end;
end;

function TDUITreeGrid.CalcNodePos(ANode: TDUIRowColID; ACount: PInteger): Integer;
var
  tn, tnParent: TDUITreeNode;
  iCount: Integer;
begin
  if IsFirst(ANode) then
  begin
    Result := 0;
    iCount := FRootNode.ChildCount;
  end
  else if IsEof(ANode) then
  begin
    Result := FRootNode.ChildCount;
    iCount := FRootNode.ChildCount;
  end
  else
  begin
    Result := 0;
    iCount := 0;

    tn := TDUITreeNode(ANode.FIndex);
    tnParent := tn.GetParent;
    while Assigned(tnParent) do
    begin
      Inc(Result, tn.Index + 1);
      Inc(iCount, tnParent.ChildCount);

      tn := tnParent;
      tnParent := tnParent.GetParent;
    end;
  end;

  if Assigned(ACount) then
    ACount^ := iCount;
end;

function TDUITreeGrid.DoCompare(const ALeft, ARight: TDUIRowColID): Integer;
  function compareColumn(ALeftColumn, ARightColumn: TDUITreeColumn): Integer;
  var
    iLeft, iRight: Integer;
  begin
    iLeft := ALeftColumn.Index;
    iRight := ARightColumn.Index;

    if iLeft < iRight then
      Result := -1
    else if iLeft > iRight then
      Result := 1
    else //iLeft = iRight
      Result := 0;
  end;
  function compareNode(ALeftNode, ARightNode: TDUITreeNode): Integer;
  var
    iLeft, iRight: Integer;
  begin
    //1.0 比较两个节点的深度，并将节点的深度调整为相同
    iLeft := ALeftNode.Level;
    iRight := ARightNode.Level;

    if iLeft < iRight then
    begin
      Result := -1;
      repeat
        ARightNode := ARightNode.GetParent;
        Dec(iRight);
      until iLeft = iRight;
    end
    else if iLeft > iRight then
    begin
      Result := 1;
      repeat
        ALeftNode := ALeftNode.GetParent;
        Dec(iLeft);
      until iLeft = iRight;
    end
    else //iLeft = iRight
      Result := 0;

    while True do
    begin
      //2.0 将待比较的两个节点，定位到相同的父节点下面
      if not Assigned(ALeftNode) or not Assigned(ARightNode) then
        raise Exception.Create('未知错误');

      if ALeftNode.GetParent <> ARightNode.GetParent then
      begin
        ALeftNode := ALeftNode.GetParent;
        ARightNode := ARightNode.GetParent;
        Continue;
      end;
      
      //3.0 比较节点大小
      iLeft := ALeftNode.FIndex;
      iRight := ARightNode.FIndex;

      if iLeft < iRight then
        Result := -1
      else if iLeft > iRight then
        Result := 1
      else //iLeft = iRight
        ; //如果相同，则使用第1步深度的比较结果

      Exit;
    end;
  end;
begin
  if ALeft.FType = rctCol then
    Result := compareColumn(TDUITreeColumn(ALeft.FIndex), TDUITreeColumn(ARight.FIndex))
  else
    Result := compareNode(TDUITreeNode(ALeft.FIndex), TDUITreeNode(ARight.FIndex));
end;

procedure TDUITreeGrid.ButtonMouseDown(ASender: TObject; AButton: TMouseButton;
  AShift: TShiftState; AX, AY: Integer);
var
  btn: TDUIButton;
  gc: TDUIGridCoord;
  tn: TDUITreeNode;
begin
  btn := TDUIBase(FPaintControls[0]) as TDUIButton;
  gc := PointToCoord(Point(AX + btn.Left, AY + btn.Top));
  if IsFirst(gc.FRow) or IsEof(gc.FRow) then
    Exit;

  tn := TDUITreeNode(gc.FRow.FIndex);

  if tn.IsLeaf then
    Exit;

  tn.Collapsed := not tn.Collapsed;
end;

function TDUITreeGrid.IsFirst(AIndex: TDUIRowColID): Boolean;
begin
  if AIndex.FType = rctCol then
    Result := Integer(AIndex.FIndex) = 0
  else
    Result := AIndex.FIndex = FRootNode;
end;

function TDUITreeGrid.IsEof(AIndex: TDUIRowColID): Boolean;
begin
  Result := Integer(AIndex.FIndex) = 1;
end;

function TDUITreeGrid.First(AType: TDUIRowColType; AMoveModes: TDUIMoveModes): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := AType;
  if AType = rctCol then
    Result.FIndex := Pointer(0)
  else
    Result.FIndex := FRootNode;

  if Conform(Result, AMoveModes) then
    Exit;

  Result := CalcMovedID(Result, 1, AMoveModes);
end;

function TDUITreeGrid.Last(AType: TDUIRowColType; AMoveModes: TDUIMoveModes): TDUIRowColID;
begin
  Result := CalcMovedID(Eof(AType), -1, AMoveModes);
end;

procedure TDUITreeGrid.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  gcCurr: TDUIGridCoord;
  pt: TPoint;
  sc: TOnSelectCell;
begin
  if ssDouble in AShift then
    sc := FOnSelectCellDouble
  else
    sc := FOnSelectCell;

  if Assigned(sc) then
  begin
    gcCurr := PointToCoord(Point(AX, AY));
    if not IsFirst(gcCurr.FRow) and not IsEof(gcCurr.FRow)
      and not IsFirst(gcCurr.FCol) and not IsEof(gcCurr.FCol) then
    begin
      pt := CoordBeginPoint(gcCurr);
      sc(Self, gcCurr.FCol, gcCurr.FRow, AX - pt.X, AY - pt.Y);
    end;
  end;

  inherited;
end;

function TDUITreeGrid.Eof(AType: TDUIRowColType): TDUIRowColID;
begin
  Result.FParent := Self;
  Result.FType := AType;
  Result.FIndex := Pointer(1);
end;

function TDUITreeGrid.GetMinTopLeft(AType: TDUIRowColType): TDUIRowColID;
begin
  {TODO: 暂时不提供单元格冻结的功能}
  Result.FParent := Self;
  Result.FType := AType;

  if AType = rctCol then
  begin
    if not Assigned(FColumns) or (FColumns.Count = 0) then
      Result.FIndex := Pointer(0)
    else
      Result.FIndex := FColumns[0];
  end
  else
  begin
    if FRootNode.IsLeaf then
      Result.FIndex := FRootNode
    else
      Result.FIndex := FRootNode.FFirst;
  end;
end;

function TDUITreeGrid.GetPaintControls(const ACol, ARow: TDUIRowColID): TControlsList;
  procedure initPaintControls;
  begin
    if Assigned(FPaintControls) then
      Exit;

    FPaintControls := TControlsList.Create;

    FPaintControls.Add(TDUIButton.Create(Self));
    with TDUIButton(FPaintControls.Last) do
    begin
      BrushPress.SkinName := '__TRANSPARENT__'; //将皮肤置为透明色(皮肤中没有此名称的皮肤，会自动使用默认的透明色)
      Align := alLeft;
      AlignKeepSize := True;
      Width := 9;
      Height := 5;
      AlignWithMargins := True;
      Margins.Left := 3;
      Margins.Right := 3;
      Margins.Top := 0;
      Margins.Bottom := 0;
      Shape.ShapeType := stAngle;
      Shape.Height := 6;
      Shape.Width := 6;
      OnMouseDown := ButtonMouseDown;
    end;

    FPaintControls.Add(TDUILabel.Create(Self));
    with TDUILabel(FPaintControls.Last) do
    begin
      Align := alClient;
      Font.SkinName := 'GRID.TEXT';
      TextBrush.SkinName := 'GRID.TEXT';
    end;
  end;
  procedure adjustControlState;
  var
    btn: TDUIButton;
    lbl: TDUILabel;
    tn: TDUITreeNode;
  begin
    btn := TDUIBase(FPaintControls[0]) as TDUIButton;
    lbl := TDUIBase(FPaintControls[1]) as TDUILabel;
    tn := TDUITreeNode(ARow.FIndex);

    btn.Margins.Left := 3 + (TDUITreeNode(ARow.FIndex).Level - 1) * CIndent;
    lbl.Caption := GetEditText(ACol, ARow);

    if tn.IsLeaf then
      btn.Shape.ShapeType := stNone
    else if tn.Collapsed then
    begin
      btn.Shape.ShapeType := stAngle;
      btn.Shape.Spin := 0;
    end
    else
    begin
      btn.Shape.ShapeType := stAngle;
      btn.Shape.Spin := 45;
    end;
  end;
begin
  Result := nil;
  if IsFirst(ARow) or IsEof(ARow) or IsFirst(ACol) or IsEof(ACol) then
    Exit;

  if Assigned(FOnGetPaintControls) then
  begin
    Result := FOnGetPaintControls(Self, ACol, ARow);
    if Assigned(Result) then
      Exit;
  end;

  if TDUITreeColumn(ACol.FIndex).Index <> 0 then
    Exit;

  initPaintControls;
  adjustControlState;
  Result := FPaintControls;
end;

function TDUITreeGrid.PosToID(AType: TDUIRowColType; APos: Integer): TDUIRowColID;
var
  nd, ndDiagonal: TDUIRowColID;
  iPos, iDiagonalPos, iDiagonalCount, iDistinct, iTotalCount: Integer;
begin
  Result.FParent := Self;
  Result.FType := AType;

  if AType = rctCol then
  begin
    if APos = FColumns.Count then
      Result.FIndex := Pointer(1)
    else
      Result.FIndex := FColumns[APos];
  end
  else
  begin
    if APos < 1 then
    begin
      Result.FIndex := FRootNode;
      Exit;
    end;

    nd := GetTopLeft(rctRow);
    iPos := CalcNodePos(nd);

    ndDiagonal := CalcDiagonalNode(nd, @iDistinct);
    iDiagonalPos := CalcNodePos(ndDiagonal, @iDiagonalCount);

    iTotalCount := iPos + iDistinct + (iDiagonalCount - iDiagonalPos);
    iDiagonalPos := iPos + iDistinct;
    if APos > iTotalCount then
    begin
      Result.FIndex := Pointer(1);
      Exit;
    end;

    if APos < iPos then //[1, iPos)
    begin
      if IsEof(nd) then
      begin
        nd := Last(rctRow);
        Dec(iPos);
      end;

      if IsFirst(nd) or IsEof(nd) then
        Result.FIndex := FRootNode
      else
        Result.FIndex := TDUITreeNode(nd.FIndex).Move(APos - iPos);
    end
    else if APos < iDiagonalPos then //[iPos, iDiagonalPos)
    begin
      if APos <= ((iPos + iDiagonalPos) div 2) then
        Result := nd + (APos - iPos)
      else
        Result := ndDiagonal - (iDiagonalPos - APos);
    end
    else //[iDiagonalPos, iTotalCount]
    begin
      if IsFirst(ndDiagonal) or IsEof(ndDiagonal) then
        Result.FIndex := Pointer(1)
      else
        Result.FIndex := TDUITreeNode(ndDiagonal.FIndex).Move(APos - iDiagonalPos);
    end;
  end;
end;

procedure TDUITreeGrid.IDsToPos(var AResMin, AResMax, AResPos: Integer;
  const AMin, AMax, APos: TDUIRowColID);
var
  iDiagonalPos, iDiagonalCount, iDistinct: Integer;
begin
  if APos.FType = rctCol then
  begin
    AResMax := FColumns.Count;
    if AResMax >= 1 then
      AResMin := 1
    else
      AResMin := 0;

    if IsFirst(APos) then
      AResPos := 0
    else if IsEof(APos) then
      AResPos := FColumns.Count
    else
      AResPos := TDUITreeColumn(APos.FIndex).Index;
  end
  else
  begin
    AResPos := CalcNodePos(APos);
    iDiagonalPos := CalcNodePos(CalcDiagonalNode(APos, @iDistinct), @iDiagonalCount);

    AResMax := AResPos + iDistinct + (iDiagonalCount - iDiagonalPos);
    if AResMax >= 1 then
      AResMin := 1
    else
      AResMin := 0;
  end;
end;

function TDUITreeGrid.GetEditClass(const ACol, ARow: TDUIRowColID): TDUIKeyboardBaseClass;
begin
  if IsFirst(ACol) or IsFirst(ARow) then
    Result := nil
  else
    Result := TDUIEdit;
end;

procedure TDUITreeGrid.InitEditor(AEditor: TDUIKeyboardBase);
begin
  with TDUIEdit(AEditor) do
  begin
    ArcBorder := False;
    WinControl.Visible := True;
    Text := GetEditText(Col, Row);
  end;
end;

function TDUITreeGrid.GetEditText(const ACol, ARow: TDUIRowColID): String;
begin
  if IsEof(ACol) or IsEof(ARow) then
    Result := ''
  else if IsFirst(ACol) and IsFirst(ARow) then
    Result := ''
  else if IsFirst(ARow) then
    Result := TDUITreeColumn(ACol.FIndex).Caption
  else if IsFirst(ACol) then
    Result := IntToStr(TDUITreeNode(ARow.FIndex).Index)
  else if TDUITreeColumn(ACol.FIndex).Index = 0 then
    Result := TDUITreeNode(ARow.FIndex).Caption
  else
    Result := inherited GetEditText(ACol, ARow);
end;

procedure TDUITreeGrid.SetEditText(const ACol, ARow: TDUIRowColID; const AValue: String);
begin
  if (TDUITreeColumn(ACol.FIndex).Index = 0) and not IsFirst(ARow) then
    TDUITreeNode(ARow.FIndex).Caption := AValue
  else
    inherited;
end;

function TDUITreeGrid.GetCells(ACol: TDUITreeColumn; ARow: TDUITreeNode): String;
begin
  Result := GetEditText(MakeCol(ACol), MakeRow(ARow));
end;

procedure TDUITreeGrid.SetCells(ACol: TDUITreeColumn; ARow: TDUITreeNode; const AValue: String);
begin
  SetEditText(MakeCol(ACol), MakeRow(ARow), AValue);
end;

function TDUITreeGrid.GetCalcCellSize(const AIndex: TDUIRowColID): Integer;
var
  iLineSize, iWidth, iPercentTotalSize: Integer;
  idCol: TDUIRowColID;
begin
  if AIndex.FType = rctRow then
  begin
    Result := GetCellSize(AIndex);
    Exit;
  end;

  if IsFirst(AIndex) then
  begin
    Result := TitleWidth;
    Exit;
  end
  else if IsEof(AIndex) then
    raise Exception.Create('索引越界')
  else if not TDUITreeColumn(AIndex.FIndex).FPercent then
  begin
    Result := GetCellSize(AIndex);
    Exit;
  end
  else if not FColumnSizeChanged then
  begin
    Result := TDUITreeColumn(AIndex.FIndex).FCalcWidth;
    Exit;
  end;

  iLineSize := IfThen([goHorzTitleLine, goHorzLine] * Options <> [], GridLineWidth, 0);
  iPercentTotalSize := 0;
  iWidth := Width - iLineSize;
  idCol := First(rctCol, [mmHide]);
  while not IsEof(idCol) do
  begin
    if IsFirst(idCol) then
      iWidth := iWidth - iLineSize - GetCellSize(idCol)
    else if not TDUITreeColumn(idCol.FIndex).FPercent then
      iWidth := iWidth - iLineSize - GetCellSize(idCol)
    else
    begin
      iWidth := iWidth - iLineSize;
      iPercentTotalSize := iPercentTotalSize + GetCellSize(idCol);
    end;

    idCol := idCol + 1;
  end;

  idCol := First(rctCol, [mmHide]);
  while not IsEof(idCol) do
  begin
    if not IsFirst(idCol) then
    begin
      if (iWidth <= 0) or (iPercentTotalSize <= 0) then
        TDUITreeColumn(idCol.FIndex).FCalcWidth := 0
      else
        TDUITreeColumn(idCol.FIndex).FCalcWidth := GetCellSize(idCol) * iWidth div iPercentTotalSize;
    end;

    idCol := idCol + 1;
  end;

  FColumnSizeChanged := False;
  Result := TDUITreeColumn(AIndex.FIndex).FCalcWidth;
end;

function TDUITreeGrid.GetCellSize(const AIndex: TDUIRowColID): Integer;
begin
  if IsFirst(AIndex) then
    Result := IfThen(AIndex.FType = rctCol, TitleWidth, TitleHeight)
  else if IsEof(AIndex) then
    raise Exception.Create('索引越界')
  else if AIndex.FType = rctCol then
  begin
    if TDUITreeColumn(AIndex.FIndex).Width < 0 then
      Result := DefaultColWidth
    else
      Result := TDUITreeColumn(AIndex.FIndex).Width;
  end
  else
  begin
    if TDUITreeNode(AIndex.FIndex).Height < 0 then
      Result := DefaultRowHeight
    else
      Result := TDUITreeNode(AIndex.FIndex).Height;
  end;
end;

procedure TDUITreeGrid.SetCellSize(const AIndex: TDUIRowColID; const AValue: Integer);
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
  else if AIndex.FType = rctCol then
    TDUITreeColumn(AIndex.FIndex).Width := AValue
  else
    TDUITreeNode(AIndex.FIndex).Height := AValue;

  SizeChanged(AIndex);
end;

function TDUITreeGrid.GetCellVisible(const AIndex: TDUIRowColID): Boolean;
var
  nd: TDUITreeNode;
begin
  if IsFirst(AIndex) then
    Result := CTitle[AIndex.FType] in Options
  else if IsEof(AIndex) then
    raise Exception.Create('索引越界')
  else if AIndex.FType = rctCol then
    Result := TDUITreeColumn(AIndex.FIndex).Visible
  else
  begin
    Result := True;
    nd := TDUITreeNode(AIndex.FIndex);
    while True do
    begin
      nd := nd.GetParent;
      if not Assigned(nd) then
        Exit;

      if nd.Collapsed then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

procedure TDUITreeGrid.SetCellVisible(const AIndex: TDUIRowColID; const AValue: Boolean);
var
  nd: TDUITreeNode;
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
  else if AIndex.FType = rctCol then
    TDUITreeColumn(AIndex.FIndex).Visible := AValue
  else
  begin
    if AValue then
    begin
      while True do
      begin
        nd := TDUITreeNode(AIndex.FIndex).GetParent;
        if not Assigned(nd) then
          Break;

        nd.Collapsed := False;
      end;
    end
    else
    begin
      nd := TDUITreeNode(AIndex.FIndex).GetParent;
      if not Assigned(nd) then
        Exit;

      nd.Collapsed := True;
    end;
  end;

  SizeChanged(AIndex);
end;

procedure TDUITreeGrid.SetColumns(const AValue: TDUITreeColumns);
begin
  if FColumns = AValue then
    Exit;

  FColumns.Assign(AValue);
  Invalidate;
end;

procedure TDUITreeGrid.SizeChanged(const AIndex: TDUIRowColID);
begin
  if not Assigned(FRootNode) then
  begin
    FColumnSizeChanged := True;
    Exit;
  end;

  if IsFirst(GetTopLeft(rctCol)) or IsFirst(GetTopLeft(rctRow)) then
    MoveTopLeft(GetTopLeft(rctCol), GetTopLeft(rctRow));
  FColumnSizeChanged := True;

  inherited;
end;

end.
