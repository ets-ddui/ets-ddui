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
unit UDUIForm;

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, TypInfo, Variants, Messages, Graphics,
  UDUICore, IGDIPlus, UTool, UDUIButton, UDUIPanel, UDUIGraphics, UDUIShape,
  UDUIScrollBar, UDUIUtils;

type
  {$IFDEF DESIGNTIME}
  TDUIScrollControlRoot = TScrollingWinControl;
  TDUIFrameRoot = TCustomFrame;
  {$ELSE}
  TDUIScrollControlRoot = TDUIBase;
  TDUIFrameRoot = TDUIBase;
  {$ENDIF}

  TDUIScrollControl = class(TDUIScrollControlRoot)
  {$IFDEF DESIGNTIME}
  private
    procedure WMNCHitTest(var AMessage: TMessage); message WM_NCHITTEST;
  public
    constructor Create(AOwner: TComponent); override;
  {$ELSE}
  private
    FScrollBars: TControlsList;
    FCaptured: TDUIScrollBar;
    procedure CalcAutoRange;
    function GetScrollBars(AType: TScrollBarKind): TDUIScrollBar;
    property ScrollBars[AType: TScrollBarKind]: TDUIScrollBar read GetScrollBars;
  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure DoScrollBarChange(ASender: TObject);
    procedure DoPaintAfter(AGPCanvas: IGPGraphics); override;
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  {$ENDIF}
  private
    function GetPosition(AKind: TScrollBarKind): Integer;
    procedure SetPosition(AKind: TScrollBarKind; const AValue: Integer);
    function GetRange(AKind: TScrollBarKind; const AIndex: Integer): Integer;
  protected
    procedure DefineProperties(AFiler: TFiler); override;
  public
    function ClientToScroll(const APoint: TPoint): TPoint;
    function ScrollToClient(const APoint: TPoint): TPoint;
    property Position[AKind: TScrollBarKind]: Integer read GetPosition write SetPosition;
    property Min[AKind: TScrollBarKind]: Integer index 1 read GetRange;
    property Max[AKind: TScrollBarKind]: Integer index 2 read GetRange;
  end;

  TDUIFrame = class(TDUIFrameRoot)
  {$IFDEF DESIGNTIME}
  private
    FAlignKeepSize: Boolean;
    FAlignOrder: Cardinal;
    FCanvas: TCanvas;
    FOnInitSkin: TNotifyEvent;
    procedure CMControlListChanging(var AMessage: TMessage); message CM_CONTROLLISTCHANGING;
  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure PaintWindow(ADC: HDC); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property AlignKeepSize: Boolean read FAlignKeepSize write FAlignKeepSize default False;
    property AlignOrder: Cardinal read FAlignOrder write FAlignOrder default 0;
    property Anchors;
    property Padding;
    property Visible;
    property OnInitSkin: TNotifyEvent read FOnInitSkin write FOnInitSkin;
  {$ELSE}
  protected
    function IsTransparent: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  {$ENDIF}
  published
    property OnResize;
  end;

  TDUIForm = class(TForm)
  {$IFDEF DESIGNTIME}
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure Paint; override;
  {$ELSE}
  private
    FCaption: TDUIPanel;
    FDUIActiveControl: TDUIKeyboardBase; //当前获取焦点的控件(TCustomForm.FActiveControl作废)
    FResetActiveControl: Boolean;
    FMinimize, FMaximize, FClose: TDUIButton;
    procedure WMNCCalcSize(var AMessage: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMControlChange(var AMessage: TMessage); message CM_CONTROLCHANGE;
  protected
    procedure DoClick(ASender: TObject); virtual;
    procedure WndProc(var AMessage: TMessage); override;
    function AddSysButton(AShapeType: TDUIShapeType): TDUIButton;
    procedure GetBorderIconStyles(var AStyle, AExStyle: Cardinal); override;
  public
    function SetFocusedControl(AControl: TWinControl): Boolean; override;
  {$ENDIF}
  private
    class var FForms: TList;
    class procedure Init;
    class procedure UnInit;
  public
    class procedure ChangeSkin;
  private
    FTimer: TList;
    FOnInitSkin: TNotifyEvent;
    procedure DoInitSkin;
    function GetBorderWidth: Integer;
    procedure WMTimer(var AMessage: TWMTimer); message WM_TIMER;
    procedure DDUIAsyncPerform(var AMessage: TMessage); message DDUI_ASYNC_PERFORM;
  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure DoClose(var AAction: TCloseAction); override;
    procedure DoCreate; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor CreateNew(AOwner: TComponent; ADummy: Integer = 0); override;
    constructor CreateDebug(AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure ReInitSkin;
    function SetDUIFocusedControl(ADUIControl: TDUIKeyboardBase): Boolean;
    procedure SelectNext(AGoForward: Boolean);
    function SetDUITimer(ADUIControl: TDUIBase; AMilliSeconds: Cardinal; ARepeat: Boolean = False): Pointer;
    procedure KillDUITimer(AID: Pointer);
  published
    //隐藏父类中BorderWidth的声明
    property BorderWidth: Integer read GetBorderWidth;
    property OnInitSkin: TNotifyEvent read FOnInitSkin write FOnInitSkin;
  end;

implementation

uses
  RTLConsts, Types, UDUIRcStream, UDUIWinWrapper, UDUIRegComponents;

{ TDUIScrollControl }

{$IFDEF DESIGNTIME}

constructor TDUIScrollControl.Create(AOwner: TComponent);
begin
  inherited;

  AutoScroll := True;
  ControlStyle := [csAcceptsControls];
end;

procedure TDUIScrollControl.WMNCHitTest(var AMessage: TMessage);
begin
  DefaultHandler(AMessage);
end;

function TDUIScrollControl.GetPosition(AKind: TScrollBarKind): Integer;
begin
  case AKind of
    sbHorizontal: Result := HorzScrollBar.Position;
    sbVertical: Result := VertScrollBar.Position;
  else
    Result := 0;
  end;
end;

procedure TDUIScrollControl.SetPosition(AKind: TScrollBarKind; const AValue: Integer);
begin
  case AKind of
    sbHorizontal: HorzScrollBar.Position := AValue;
    sbVertical: VertScrollBar.Position := AValue;
  end;
end;

function TDUIScrollControl.GetRange(AKind: TScrollBarKind; const AIndex: Integer): Integer;
begin
  Result := 0;

  if AIndex = 2 then //2表示取最大值，最小值在GUI模式下始终为0
  begin
    case AKind of
      sbHorizontal: Result := HorzScrollBar.Range;
      sbVertical: Result := VertScrollBar.Range;
    end;
  end;
end;

function TDUIScrollControl.ClientToScroll(const APoint: TPoint): TPoint;
begin
  Result := APoint;
end;

function TDUIScrollControl.ScrollToClient(const APoint: TPoint): TPoint;
begin
  Result := APoint;
end;

{$ELSE}

constructor TDUIScrollControl.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle + [csCaptureMouse];

  FScrollBars := TControlsList.Create;
  FScrollBars.Add(TDUIScrollBar.Create(Self));
  FScrollBars.Add(TDUIScrollBar.Create(Self));
  with ScrollBars[sbHorizontal] do
  begin
    //DUIParent := Self;
    Kind := sbHorizontal;
    Align := alBottom;
    Visible := False;
    OnChange := DoScrollBarChange;
  end;
  with ScrollBars[sbVertical] do
  begin
    //DUIParent := Self;
    Kind := sbVertical;
    Align := alRight;
    Visible := False;
    OnChange := DoScrollBarChange;
  end;
end;

destructor TDUIScrollControl.Destroy;
var
  i: Integer;
begin
  for i := FScrollBars.Count - 1 downto 0 do
    TDUIBase(FScrollBars[i]).Free;
  FreeAndNil(FScrollBars);

  inherited;
end;

procedure TDUIScrollControl.AlignControls(AControl: TControl; var ARect: TRect);
begin
  //1.0 子控件对齐调整
  CalcAutoRange;

  ARect.Left := ScrollBars[sbHorizontal].Min;
  ARect.Top := ScrollBars[sbVertical].Min;
  ARect.Right := ScrollBars[sbHorizontal].Max;
  ARect.Bottom := ScrollBars[sbVertical].Max;

  inherited;

  //2.0 滚动条对齐调整(注意滚动条的DUIParent未设置)
  ARect := GetClientRect;
  ArrangeControls(FScrollBars, nil, ARect);
end;

procedure TDUIScrollControl.CalcAutoRange;
var
  i, iHMin, iHMax, iVMin, iVMax, iPosition: Integer;
  ctl: TControl;
begin
  iHMin := 0;
  iHMax := 0;
  iVMin := 0;
  iVMax := 0;
  for i := 0 to ControlCount - 1 do
  begin
    ctl := Controls[i];
    if ctl.Left < iHMin then
      iHMin := ctl.Left;
    if (ctl.Left + ctl.Width - 1) > iHMax then
      iHMax := ctl.Left + ctl.Width - 1;
    if ctl.Top < iVMin then
      iVMin := ctl.Top;
    if (ctl.Top + ctl.Height - 1) > iVMax then
      iVMax := ctl.Top + ctl.Height - 1;
  end;

  if (iHMin = 0) and (iHMax <= Width) then
  begin
    iPosition := 0;
    ScrollBars[sbHorizontal].Visible := False;
  end
  else
  begin
    iPosition := ScrollBars[sbHorizontal].Position;
    ScrollBars[sbHorizontal].Visible := True;
  end;
  ScrollBars[sbHorizontal].UpdateData(iHMin, iHMax, iPosition, Width);

  if (iVMin = 0) and (iVMax <= Height) then
  begin
    iPosition := 0;
    ScrollBars[sbVertical].Visible := False;
  end
  else
  begin
    iPosition := ScrollBars[sbVertical].Position;
    ScrollBars[sbVertical].Visible := True;
  end;
  ScrollBars[sbVertical].UpdateData(iVMin, iVMax, iPosition, Height);
end;

procedure TDUIScrollControl.DoScrollBarChange(ASender: TObject);
begin
  Invalidate;
end;

procedure TDUIScrollControl.DoPaintAfter(AGPCanvas: IGPGraphics);
var
  i: Integer;
  dui: TDUIBase;
  gc: TGPGraphicsContainer;
begin
  AGPCanvas.TranslateTransform(Position[sbHorizontal], Position[sbVertical]);

  for i := 0 to FScrollBars.Count - 1 do
  begin
    dui := TDUIBase(FScrollBars[i]);

    if (not dui.Visible or ((csDesigning in dui.ComponentState) and (csDesignerHide in dui.ControlState)))
      and (not (csDesigning in dui.ComponentState) or (csDesignerHide in dui.ControlState)
        or (csNoDesignVisible in dui.ControlStyle)) then
      Continue;

    gc := AGPCanvas.BeginContainer;
    try
      AGPCanvas.TranslateTransform(dui.Left, dui.Top);
      dui.Perform(WM_PAINT, 0, Integer(AGPCanvas));
    finally
      AGPCanvas.EndContainer(gc);
    end;
  end;
end;

procedure TDUIScrollControl.WndProc(var AMessage: TMessage);
var
  pt: TPoint;
begin
  if (AMessage.Msg = WM_LBUTTONDOWN) or (AMessage.Msg = WM_LBUTTONDBLCLK)
    or (AMessage.Msg = WM_MOUSEMOVE)
    or (AMessage.Msg = WM_LBUTTONUP) then
  begin
    if (AMessage.Msg = WM_LBUTTONDOWN) or (AMessage.Msg = WM_LBUTTONDBLCLK) then
    begin
      if not Assigned(FCaptured) then
      begin
        pt := SmallPointToPoint(TWMMouse(AMessage).Pos);
        if PtInRect(ScrollBars[sbHorizontal].BoundsRect, pt) then
          FCaptured := ScrollBars[sbHorizontal]
        else if PtInRect(ScrollBars[sbVertical].BoundsRect, pt) then
          FCaptured := ScrollBars[sbVertical];
      end;
    end;

    if Assigned(FCaptured) then
    begin
      pt.X := TWMMouse(AMessage).XPos - FCaptured.Left;
      pt.Y := TWMMouse(AMessage).YPos - FCaptured.Top;
      AMessage.Result := FCaptured.Perform(AMessage.Msg,
        TWMMouse(AMessage).Keys, Longint(PointToSmallPoint(pt)));

      if AMessage.Msg = WM_LBUTTONUP then
        FCaptured := nil;

      //将消息分发到控件的消息处理函数中
      //会触发WMLButtonDown等函数的执行，将焦点控件设置为自身
      Dispatch(AMessage);

      Exit;
    end;
  end;

  inherited;
end;

function TDUIScrollControl.GetPosition(AKind: TScrollBarKind): Integer;
begin
  Result := ScrollBars[AKind].Position;
end;

procedure TDUIScrollControl.SetPosition(AKind: TScrollBarKind; const AValue: Integer);
begin
  ScrollBars[AKind].Position := AValue;
end;

function TDUIScrollControl.GetRange(AKind: TScrollBarKind; const AIndex: Integer): Integer;
begin
  Result := 0;

  if AIndex = 1 then //Min
    Result := ScrollBars[AKind].Min
  else if AIndex = 2 then //Max
    Result := ScrollBars[AKind].Max;
end;

function TDUIScrollControl.GetScrollBars(AType: TScrollBarKind): TDUIScrollBar;
begin
  Result := TDUIScrollBar(FScrollBars[Ord(AType)]);
end;

function TDUIScrollControl.ClientToScroll(const APoint: TPoint): TPoint;
begin
  Result.X := APoint.X + GetPosition(sbHorizontal);
  Result.Y := APoint.Y + GetPosition(sbVertical);
end;

function TDUIScrollControl.ScrollToClient(const APoint: TPoint): TPoint;
begin
  Result.X := APoint.X - GetPosition(sbHorizontal);
  Result.Y := APoint.Y - GetPosition(sbVertical);
end;

{$ENDIF}

procedure TDUIScrollControl.DefineProperties(AFiler: TFiler);
begin
  //屏蔽掉基类中的属性定义，包括：
  //TControl中的IsControl、ExplicitLeft、ExplicitTop、ExplicitWidth、ExplicitHeight
  //TWinControl中的DesignSize
end;

{ TDUIFrame }

{$IFDEF DESIGNTIME}

constructor TDUIFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ParentColor := False;
  Color := clBlack;
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
end;

destructor TDUIFrame.Destroy;
begin
  FreeAndNil(FCanvas);

  inherited Destroy;
end;

procedure TDUIFrame.AlignControls(AControl: TControl; var ARect: TRect);
  procedure disableControlsAlign(AControls: TControlsList);
  var
    i: Integer;
    ctl: TControl;
  begin
    for i := 0 to AControls.Count - 1 do
    begin
      ctl := AControls[i];
      if ctl is TDUIBase then
        TDUIBase(ctl).DisableAlign
      else if ctl is TWinControl then
        TWinControl(ctl).DisableAlign;
    end;
  end;
  procedure enableControlsAlign(AControls: TControlsList);
  var
    i: Integer;
    ctl: TControl;
  begin
    for i := 0 to AControls.Count - 1 do
    begin
      ctl := AControls[i];
      if ctl is TDUIBase then
        TDUIBase(ctl).EnableAlign
      else if ctl is TWinControl then
        TWinControl(ctl).EnableAlign;
    end;
  end;
var
  lstAlign, lstAnchors: TControlsList;
begin
  lstAlign := nil;
  lstAnchors := nil;
  try
    lstAlign := TControlsList.Create;
    lstAnchors := TControlsList.Create;

    Inc(ARect.Left, Padding.Left);
    Inc(ARect.Top, Padding.Top);
    Dec(ARect.Right, Padding.Right);
    Dec(ARect.Bottom, Padding.Bottom);

    ListControls(Self, lstAlign, lstAnchors);

    disableControlsAlign(lstAlign);
    disableControlsAlign(lstAnchors);
    try
      ArrangeControls(lstAlign, lstAnchors, ARect);
    finally
      //TWinControl是在上层调用函数AlignControl中才将csAlignmentNeeded状态移除
      //TDUIBase将此动作移到这里，是为了保证enableControlsAlign可以触发子控件的AlignControl处理
      ControlState := ControlState - [csAlignmentNeeded];
      enableControlsAlign(lstAlign);
      enableControlsAlign(lstAnchors);
    end;
  finally
    FreeAndNil(lstAlign);
    FreeAndNil(lstAnchors);
  end;
end;

procedure TDUIFrame.CMControlListChanging(var AMessage: TMessage);
var
  cli: PControlListItem;
begin
  if Boolean(AMessage.LParam) then //True表示新增控件，False表示删除控件
  begin
    cli := PControlListItem(AMessage.WParam);
    if not (cli.Control is TDUIBase) then
      raise Exception.Create('DUI控件中只允许放置DUI控件');
  end;

  inherited;
end;

procedure TDUIFrame.CreateParams(var AParams: TCreateParams);
begin
  inherited;

  AParams.Style := AParams.Style and not WS_CLIPCHILDREN;
end;

procedure TDUIFrame.PaintWindow(ADC: HDC);
begin
  FCanvas.Lock;
  try
    FCanvas.Handle := ADC;
    try
      FCanvas.Brush.Color := Color;
      FCanvas.FillRect(ClientRect);
    finally
      FCanvas.Handle := 0;
    end;
  finally
    FCanvas.Unlock;
  end;
end;

{$ELSE}

constructor TDUIFrame.Create(AOwner: TComponent);
begin
  inherited;

  if (ClassType <> TDUIFrame) and not (csDesignInstance in ComponentState) then
  begin
    if not InitInheritedComponent(Self, TDUIFrame) then
      raise EResNotFound.CreateFmt(SResNotFound, [ClassName]);
  end;
end;

function TDUIFrame.IsTransparent: Boolean;
begin
  Result := True;
end;

{$ENDIF}

{ TDUIForm }

{$IFDEF DESIGNTIME}

constructor TDUIForm.CreateNew(AOwner: TComponent; ADummy: Integer);
begin
  inherited;

  DoubleBuffered := True;
end;

procedure TDUIForm.CreateParams(var AParams: TCreateParams);
begin
  inherited;

  AParams.Style := AParams.Style and not WS_CLIPCHILDREN;
end;

procedure TDUIForm.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  inherited;
end;

function TDUIForm.SetDUIFocusedControl(ADUIControl: TDUIKeyboardBase): Boolean;
begin
  Result := SetFocusedControl(ADUIControl);
end;

procedure TDUIForm.SelectNext(AGoForward: Boolean);
begin
  inherited SelectNext(ActiveControl, AGoForward, True);
end;

{$ELSE}

type
  TSystemButtonType = (sbtClose, sbtMaximize, sbtMinimize);

const
  CButtonWidth: Integer = 30;
  CButtonHeight: Integer = 19;
  CShapeWidth: Integer = 13;
  CShapeHeight: Integer = 11;
  CMaxAlignOrder: Integer = $7FFFFFFF;

function TDUIForm.AddSysButton(AShapeType: TDUIShapeType): TDUIButton;
  function getMinAlignOrder: Integer;
  var
    i: Integer;
  begin
    Result := CMaxAlignOrder;
    for i := 0 to FCaption.ControlCount - 1 do
      if FCaption.Controls[i].AlignOrder < Result then
        Result := FCaption.Controls[i].AlignOrder;
  end;
begin
  Result := TDUIButton.Create(FCaption);
  with Result do
  begin
    BrushPress.SkinName := 'SYSTEM.PRESS';
    BrushHover.SkinName := 'SYSTEM.HOVER';
    DUIParent := FCaption;
    Height := CButtonHeight;
    Width := CButtonWidth;
    AlignOrder := getMinAlignOrder - 1;
    AlignKeepSize := True;
    Align := alRight;
    Shape.ShapeType := AShapeType;
    Shape.Height := CShapeHeight;
    Shape.Width := CShapeWidth;
    OnClick := DoClick;
  end;
end;

constructor TDUIForm.CreateNew(AOwner: TComponent; ADummy: Integer);
begin
  inherited;

  FForms.Add(Self);

  DoubleBuffered := True;

  DisableAlign;
  try
    ControlState := ControlState + [csAlignmentNeeded];

    FCaption := TDUIPanel.Create(Self);
    with FCaption do
    begin
      Parent := Self;
      Height := CButtonHeight;
      AlignOrder := CMaxAlignOrder;
      Align := alTop;
    end;

    FClose := AddSysButton(stClose);
    FClose.BrushPress.SkinName := 'SYSTEM.PRESS.CLOSE';
    FClose.BrushHover.SkinName := 'SYSTEM.HOVER.CLOSE';
    FClose.Shape.LineWidth := 5;
    FMaximize := AddSysButton(stMaximize);
    FMinimize := AddSysButton(stMinimize);
  finally
    EnableAlign;
  end;
end;

procedure TDUIForm.DoClick(ASender: TObject);
begin
  if ASender = FClose then
    PostMessage(Handle, WM_SYSCOMMAND, SC_CLOSE, 0)
  else if ASender = FMinimize then
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0)
  else if ASender = FMaximize then
  begin
    if IsZoomed(Handle) then
    begin
      FMaximize.Shape.ShapeType := stMaximize;
      PostMessage(Handle, WM_SYSCOMMAND, SC_RESTORE, 0);
    end
    else
    begin
      FMaximize.Shape.ShapeType := stRestore;
      PostMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
    end;
  end;
end;

procedure TDUIForm.GetBorderIconStyles(var AStyle, AExStyle: Cardinal);
begin
  //在设置BorderIcons、BorderStyle属性时，都会影响窗口右上角系统按钮的显示状态，
  //而且这些属性都会触发对GetBorderIconStyles的调用，因此，在此函数中修正对应按钮的状态
  inherited GetBorderIconStyles(AStyle, AExStyle);

  FCaption.Visible := AStyle and WS_SYSMENU <> 0;
  FMinimize.Visible := AStyle and (WS_SYSMENU or WS_MINIMIZEBOX) = (WS_SYSMENU or WS_MINIMIZEBOX);
  FMaximize.Visible := AStyle and (WS_SYSMENU or WS_MAXIMIZEBOX) = (WS_SYSMENU or WS_MAXIMIZEBOX);
end;

procedure TDUIForm.SelectNext(AGoForward: Boolean);
  procedure listControl(var AControlList: TList; AParent: TDUIBase);
  var
    i: Integer;
    ctl: TControl;
  begin
    if not Assigned(AParent) then
    begin
      for i := 0 to ControlCount - 1 do
      begin
        ctl := Controls[i];
        if not (ctl is TDUIBase) then
          Continue;

        listControl(AControlList, TDUIBase(ctl));
        if ctl is TDUIKeyboardBase then
          AControlList.Add(ctl);
      end;
    end
    else
    begin
      for i := 0 to AParent.ControlCount - 1 do
      begin
        listControl(AControlList, AParent.Controls[i]);
        if AParent.Controls[i] is TDUIKeyboardBase then
          AControlList.Add(AParent.Controls[i]);
      end;
    end;
  end;
var
  lstControls: TList;
  i, iCurr: Integer;
begin
  lstControls := TList.Create;
  try
    listControl(lstControls, nil);
    if lstControls.Count = 0 then
      Exit;

    iCurr := -1;
    if Assigned(FDUIActiveControl) then
      iCurr := lstControls.IndexOf(FDUIActiveControl);

    for i := 1 to lstControls.Count do
    begin
      if AGoForward then
        Dec(iCurr)
      else
        Inc(iCurr);

      if iCurr < 0 then
        iCurr := lstControls.Count - 1
      else if iCurr >= lstControls.Count then
        iCurr := 0;

      if TDUIKeyboardBase(lstControls[iCurr]).CanFocus then
      begin
        SetDUIFocusedControl(TDUIKeyboardBase(lstControls[iCurr]));
        Exit;
      end;
    end;
  finally
    FreeAndNil(lstControls);
  end;
end;

function TDUIForm.SetFocusedControl(AControl: TWinControl): Boolean;
  procedure listDUIControl(var AResult: TList; AParent: TDUIBase);
  var
    i: Integer;
    ctl: TDUIBase;
  begin
    for i := 0 to AParent.ControlCount - 1 do
    begin
      ctl := AParent.Controls[i];
      if ctl is TDUIWinBase then
        AResult.Add(ctl)
      else
        listDUIControl(AResult, ctl);
    end;
  end;
  procedure listWinControl(var AResult: TList; AParent: TWinControl);
  var
    i: Integer;
    ctl: TControl;
  begin
    for i := 0 to AParent.ControlCount - 1 do
    begin
      ctl := AParent.Controls[i];
      if ctl is TDUIWinBase then
        AResult.Add(ctl)
      else if ctl is TDUIBase then
        listDUIControl(AResult, TDUIBase(ctl))
      else if ctl is TWinControl then
        listWinControl(AResult, TWinControl(ctl));
    end;
  end;
var
  i: Integer;
  lstDUIWinBase: TList;
begin
  Result := inherited SetFocusedControl(AControl);

  if Assigned(FDUIActiveControl) and (FDUIActiveControl is TDUIWinBase)
    and TDUIWinBase(FDUIActiveControl).WinControl.ContainsControl(AControl) then
  begin
    SetDUIFocusedControl(FDUIActiveControl);
    Exit;
  end;

  lstDUIWinBase := TList.Create;
  try
    listWinControl(lstDUIWinBase, Self);

    for i := 0 to lstDUIWinBase.Count - 1 do
    begin
      if TDUIWinBase(lstDUIWinBase[i]).WinControl.ContainsControl(AControl) then
      begin
        SetDUIFocusedControl(TDUIWinBase(lstDUIWinBase[i]));
        Exit;
      end;
    end;
  finally
    FreeAndNil(lstDUIWinBase);
  end;

  SetDUIFocusedControl(nil);
end;

function TDUIForm.SetDUIFocusedControl(ADUIControl: TDUIKeyboardBase): Boolean;
begin
  if Assigned(ADUIControl) and not ADUIControl.CanFocus then
  begin
    Result := False;
    Exit;
  end;

  FResetActiveControl := True;

  if FDUIActiveControl = ADUIControl then
  begin
    Result := True;
    Exit;
  end;

  if Assigned(FDUIActiveControl) then
  begin
    FDUIActiveControl.RemoveFreeNotification(Self);
    FDUIActiveControl.Perform(WM_KILLFOCUS, 0, 0);
  end;

  FDUIActiveControl := ADUIControl;

  if Assigned(FDUIActiveControl) then
  begin
    FDUIActiveControl.FreeNotification(Self);
    FDUIActiveControl.Perform(WM_SETFOCUS, 0, 0);
  end;

  Result := True;
end;

procedure TDUIForm.WndProc(var AMessage: TMessage);
var
  ctl: TControl;
  pt: TPoint;
begin
  case AMessage.Msg of
    WM_DROPFILES:
    begin
      ctl := ControlAtPos(ScreenToClient(Mouse.CursorPos), False);
      while Assigned(ctl) and (ctl is TDUIBase) do
      begin
        AMessage.Result := 1;
        ctl.WindowProc(AMessage);
        if 0 = AMessage.Result then
          Exit;

        ctl := TDUIBase(ctl).ControlAtPos(ctl.ScreenToClient(Mouse.CursorPos), False);
      end;

      inherited WndProc(AMessage);
      Exit;
    end;
    WM_NCHITTEST:
    begin
      inherited WndProc(AMessage);
      if HTCAPTION <> AMessage.Result then
        Exit;

      ctl := ControlAtPos(ScreenToClient(SmallPointToPoint(TWMNCHitTest(AMessage).Pos)), False);
      if Assigned(ctl) and (ctl is TDUIBase) then
      begin
        ctl.WindowProc(AMessage);
        if HTTRANSPARENT = AMessage.Result then
          AMessage.Result := HTCAPTION;
      end;

      Exit;
    end;
    WM_LBUTTONDOWN:
    begin
      FResetActiveControl := False;

      inherited WndProc(AMessage);

      if not FResetActiveControl and Assigned(FDUIActiveControl) then
        SetDUIFocusedControl(nil);

      Exit;
    end;
    WM_NCLBUTTONDOWN:
    begin
      SetDUIFocusedControl(nil);
    end;
    WM_MOUSEWHEEL:
    begin
      //Delphi对WM_MOUSEWHEEL的实现有Bug，按MSDN的文档说明，此消息的LParam表示屏幕坐标，
      //这点和其他鼠标消息有差异，但Delphi统一都是按窗口坐标来处理，这里进行修正，
      //优先将消息发给焦点控件，若不处理，则转发给鼠标所在的控件
      if Assigned(FDUIActiveControl) then
      begin
        pt := FDUIActiveControl.ScreenToClient(SmallPointToPoint(TWMMouseWheel(AMessage).Pos));
        AMessage.Result := FDUIActiveControl.Perform(AMessage.Msg,
          AMessage.WParam, Longint(PointToSmallPoint(pt)));
        if AMessage.Result <> 0 then
          Exit;
      end;

      pt := ScreenToClient(SmallPointToPoint(TWMMouseWheel(AMessage).Pos));
      ctl := ControlAtPos(pt, False);
      if Assigned(ctl) and (ctl is TDUIBase) then
      begin
        Dec(pt.X, ctl.Left);
        Dec(pt.Y, ctl.Top);
        AMessage.Result := ctl.Perform(AMessage.Msg,
          AMessage.WParam, Longint(PointToSmallPoint(pt)));
        if AMessage.Result <> 0 then
          Exit;
      end;

      //转发给窗口的WMMouseWheel处理(转发前先对坐标进行修正)，
      //这样不会导致窗口的OnMouseWheel、OnMouseWheelDown、OnMouseWheelUp事件失效
      pt := ScreenToClient(SmallPointToPoint(TWMMouseWheel(AMessage).Pos));
      AMessage.LParam := Longint(PointToSmallPoint(pt));
      Dispatch(AMessage); //这里用的是Dispatch，不是WndProc，以跳过TWinControl中的Bug

      Exit;
    end;
    WM_GETDLGCODE: //DUI窗口自己处理TAB按钮
    begin
      //从测试结果来看，只有DLGC_WANTTAB有效，其他按钮均没有效果
      //1.0 按钮按下前，先触发WM_GETDLGCODE的按钮
      //1.1 TAB键
      //    设置DLGC_WANTCHARS，触发WM_GETDLGCODE、WM_KEYDOWN、WM_GETDLGCODE、WM_CHAR、WM_KEYUP
      //    不设置DLGC_WANTCHARS，只会触发WM_GETDLGCODE、WM_KEYUP
      //1.2 方向键(DLGC_WANTARROWS是否有设置，均没有效果)
      //    触发WM_GETDLGCODE、WM_KEYDOWN、WM_KEYUP
      //1.3 ESC、Enter键
      //    触发WM_GETDLGCODE、WM_KEYDOWN、WM_GETDLGCODE、WM_CHAR、WM_KEYUP
      //2.0 按钮按下前，不触发WM_GETDLGCODE的按钮
      //2.1 功能键(F1~F12)、HOME、END、INSERT、DELETE、CAPS、SHIFT、CTRL、WINS、PageUP、PageDown键
      //    触发WM_KEYDOWN、WM_KEYUP
      //2.2 ALT键
      //    触发WM_SYSKEYDOWN、WM_SYSKEYUP
      //2.3 PrtSc(截屏键)、Fn + ESC键
      //    只会触发WM_KEYUP
      //3.0 在WM_CHAR前触发WM_GETDLGCODE的按钮
      //3.1 `(ESC下面的按钮)、1、2、......、、=、Backspace
      //    Q、W、......、]、\
      //    A、S、......、;、'
      //    Z、X、......、.、/
      //    Space(空格键)
      //    触发WM_KEYDOWN、WM_GETDLGCODE、WM_CHAR、WM_KEYUP

      AMessage.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS;
      Exit;
    end;
    WM_KEYFIRST..WM_KEYLAST:
    begin
      if Word(AMessage.WParam) = VK_TAB then
      begin
        if AMessage.LParam and $20000000 <> 0 then //ALT + TAB是屏幕切换键(参考Forms.KeyDataToShiftState的实现)
          Exit;

        if Assigned(FDUIActiveControl)
          and ((FDUIActiveControl.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTTAB) = 0) then
        begin
          if (AMessage.Msg = WM_KEYDOWN) or (AMessage.Msg = WM_SYSKEYDOWN) then
            SelectNext(GetKeyState(VK_SHIFT) >= 0);

          Exit;
        end;
      end;

      if Assigned(FDUIActiveControl) then
        FDUIActiveControl.Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);

      Exit;
    end;
  end;

  inherited WndProc(AMessage);
end;

procedure TDUIForm.WMNCCalcSize(var AMessage: TWMNCCalcSize);
begin
  AMessage.Result := 0;

  //修正窗口最大化后显示不完整的问题(操作系统自动计算出来的尺寸有偏移，原因未知)
  if AMessage.CalcValidRects and IsZoomed(Handle) then
    with AMessage.CalcSize_Params.rgrc[0] do
    begin
      Right := Right + Left;
      Bottom := Bottom + Top;
      Left := 0;
      Top := 0;
    end;
end;

procedure TDUIForm.WMNCHitTest(var AMessage: TWMNCHitTest);
const
  CBorderWidth: Integer = 5;
var
  pt: TPoint;
begin
  if IsZoomed(Handle) then
  begin
    AMessage.Result := HTCAPTION;
    Exit;
  end;

  pt := ScreenToClient(SmallPointToPoint(AMessage.Pos));
  if PtInRect(Rect(0, 0, CBorderWidth, CBorderWidth), pt) then
    AMessage.Result := HTTOPLEFT
  else if PtInRect(Rect(Width - CBorderWidth, 0, Width, CBorderWidth), pt) then
    AMessage.Result := HTTOPRIGHT
  else if PtInRect(Rect(0, Height - CBorderWidth, CBorderWidth, Height), pt) then
    AMessage.Result := HTBOTTOMLEFT
  else if PtInRect(Rect(Width - CBorderWidth, Height - CBorderWidth, Width, Height), pt) then
    AMessage.Result := HTBOTTOMRIGHT
  else if PtInRect(Rect(0, 0, Width, CBorderWidth), pt) then
    AMessage.Result := HTTOP
  else if PtInRect(Rect(0, Height - CBorderWidth, Width, Height), pt) then
    AMessage.Result := HTBOTTOM
  else if PtInRect(Rect(0, 0, CBorderWidth, Height), pt) then
    AMessage.Result := HTLEFT
  else if PtInRect(Rect(Width - CBorderWidth, 0, Width, Height), pt) then
    AMessage.Result := HTRIGHT
  else
    AMessage.Result := HTCAPTION;
end;

procedure TDUIForm.CMControlChange(var AMessage: TMessage);
var
  ctlOldActiveControl: TDUIBase;
begin
  if Assigned(FDUIActiveControl) and not Boolean(AMessage.LParam)
    and (TControl(AMessage.WParam) = FDUIActiveControl) then
  begin
    ctlOldActiveControl := FDUIActiveControl;
    SelectNext(False);
    if ctlOldActiveControl = FDUIActiveControl then
      SetDUIFocusedControl(nil);
  end;
end;

{$ENDIF}

destructor TDUIForm.Destroy;
begin
  KillDUITimer(nil);
  FForms.Remove(Self);

  inherited;
end;

procedure TDUIForm.AlignControls(AControl: TControl; var ARect: TRect);
  procedure disableControlsAlign(AControls: TControlsList);
  var
    i: Integer;
    ctl: TControl;
  begin
    for i := 0 to AControls.Count - 1 do
    begin
      ctl := AControls[i];
      if ctl is TDUIBase then
        TDUIBase(ctl).DisableAlign
      else if ctl is TWinControl then
        TWinControl(ctl).DisableAlign;
    end;
  end;
  procedure enableControlsAlign(AControls: TControlsList);
  var
    i: Integer;
    ctl: TControl;
  begin
    for i := 0 to AControls.Count - 1 do
    begin
      ctl := AControls[i];
      if ctl is TDUIBase then
        TDUIBase(ctl).EnableAlign
      else if ctl is TWinControl then
        TWinControl(ctl).EnableAlign;
    end;
  end;
var
  lstAlign, lstAnchors: TControlsList;
begin
  lstAlign := nil;
  lstAnchors := nil;
  try
    lstAlign := TControlsList.Create;
    lstAnchors := TControlsList.Create;

    Inc(ARect.Left, Padding.Left);
    Inc(ARect.Top, Padding.Top);
    Dec(ARect.Right, Padding.Right);
    Dec(ARect.Bottom, Padding.Bottom);

    ListControls(Self, lstAlign, lstAnchors);

    disableControlsAlign(lstAlign);
    disableControlsAlign(lstAnchors);
    try
      ArrangeControls(lstAlign, lstAnchors, ARect);
    finally
      //TWinControl是在上层调用函数AlignControl中才将csAlignmentNeeded状态移除
      //TDUIBase将此动作移到这里，是为了保证enableControlsAlign可以触发子控件的AlignControl处理
      ControlState := ControlState - [csAlignmentNeeded];
      enableControlsAlign(lstAlign);
      enableControlsAlign(lstAnchors);
    end;
  finally
    FreeAndNil(lstAlign);
    FreeAndNil(lstAnchors);
  end;
end;

procedure TDUIForm.DDUIAsyncPerform(var AMessage: TMessage);
var
  am: TDUIAsyncMessage;
begin
  am := TDUIAsyncMessage(AMessage.LParam);
  try
    am.Execute;
  finally
    FreeAndNil(am);
  end;
end;

procedure TDUIForm.DoClose(var AAction: TCloseAction);
begin
  AAction := caFree;

  inherited;
end;

procedure TDUIForm.DoCreate;
begin
  inherited;

  DoInitSkin;
end;

procedure TDUIForm.DoInitSkin;
begin
  if Assigned(FOnInitSkin) then
    FOnInitSkin(Self);
end;

procedure TDUIForm.ReInitSkin;
var
  i: Integer;
begin
  for i := 0 to ControlCount - 1 do
    if Controls[i] is TDUIBase then
      TDUIBase(Controls[i]).ReInitSkin;

  DoInitSkin;

  Invalidate;
end;

type
  TDUITimerData = class(TComponent)
  strict private
    FDUIControl: TDUIBase;
    FMilliSeconds: Cardinal;
    FRepeat: Boolean;
    FLastTicketCount: Int64;
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent; ADUIControl: TDUIBase;
      AMilliSeconds: Cardinal; ARepeat: Boolean); reintroduce;
    procedure DoTimer;
  end;

constructor TDUITimerData.Create(AOwner: TComponent; ADUIControl: TDUIBase;
  AMilliSeconds: Cardinal; ARepeat: Boolean);
begin
  inherited Create(AOwner);

  FDUIControl := ADUIControl;
  FMilliSeconds := AMilliSeconds;
  FRepeat := ARepeat;
  FLastTicketCount := GetTickCount;

  FDUIControl.FreeNotification(Self);
end;

procedure TDUITimerData.DoTimer;
var
  iTickCount: Int64;
begin
  //GetTickCount超过50天会溢出，这里做修正
  iTickCount := GetTickCount;
  if iTickCount < FLastTicketCount then
    FLastTicketCount := FLastTicketCount - $100000000; //有8个0(2^32)

  if (iTickCount - FLastTicketCount) < FMilliSeconds then
    Exit;

  FDUIControl.Perform(WM_TIMER, Integer(Self), 0); //WParam用于传递计时器的AID值(参见KillTimer的入参)

  if not FRepeat then
  begin
    Destroy;
    Exit;
  end;

  FLastTicketCount := iTickCount;
end;

procedure TDUITimerData.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if (AOperation = opRemove) and (AComponent = FDUIControl) then
    Destroy;
end;

function TDUIForm.SetDUITimer(ADUIControl: TDUIBase; AMilliSeconds: Cardinal; ARepeat: Boolean): Pointer;
var
  obj: TDUITimerData;
begin
  if not Assigned(FTimer) then
  begin
    FTimer := TList.Create;
    SetTimer(Handle, 1, 50, nil);
  end;

  obj := TDUITimerData.Create(nil, ADUIControl, AMilliSeconds, ARepeat);
  obj.FreeNotification(Self);
  FTimer.Add(obj);

  Result := obj;
end;

procedure TDUIForm.KillDUITimer(AID: Pointer);
begin
  if Assigned(AID) then
    TDUITimerData(AID).Free
  else
    while Assigned(FTimer) and (FTimer.Count > 0) do
      TDUITimerData(FTimer[0]).Free;
end;

procedure TDUIForm.Notification(AComponent: TComponent; AOperation: TOperation);
var
  i: Integer;
begin
  inherited;

  {$IFDEF DESIGNTIME}
  {$ELSE}
  if (FDUIActiveControl = AComponent) and (AOperation = opRemove) then
  begin
    FDUIActiveControl := nil;
    Exit;
  end;
  {$ENDIF}

  if Assigned(FTimer) and (AOperation = opRemove) then
  begin
    i := FTimer.IndexOf(AComponent);
    if i >= 0 then
      FTimer.Delete(i);

    if FTimer.Count = 0 then
    begin
      KillTimer(Handle, 1);
      FreeAndNil(FTimer);
    end;
  end;
end;

procedure TDUIForm.WMTimer(var AMessage: TWMTimer);
var
  i: Integer;
begin
  for i := FTimer.Count - 1 downto 0 do
    TDUITimerData(FTimer[i]).DoTimer;
end;

function TDUIForm.GetBorderWidth: Integer;
begin
  Result := inherited BorderWidth;
end;

constructor TDUIForm.CreateDebug(AOwner: TComponent);
  function getFieldClass(AClass: String): TComponentClass;
  type
    PFieldClassTable = ^TFieldClassTable;
    TFieldClassTable = packed record
      FCount: SmallInt;
      FClasses: array[0..8191] of ^TComponentClass;
    end;
    PFieldTable = ^TFieldTable;
    TFieldTable = packed record //Classes.pas中没有此类的定义，根据代码逻辑整理
      FCount: SmallInt;
      FFieldClassTable: PFieldClassTable;
    end;
  var
    i: Integer;
    cls: TClass;
    fct: PFieldClassTable;
    ft: PFieldTable;
  begin
    cls := ClassType;
    while cls <> TPersistent do
    begin
      ft := PFieldTable(Pointer(Integer(cls) + vmtFieldTable)^);
      if Assigned(ft) then
      begin
        fct := ft.FFieldClassTable;
        if Assigned(fct) then
        begin
          for i := 0 to fct.FCount - 1 do
          begin
            Result := fct^.FClasses[i]^;
            if Result.ClassNameIs(AClass) and Result.InheritsFrom(TComponent) then
              Exit;
          end;
        end;
      end;

      cls := cls.ClassParent;
    end;
    
    Result := nil;
  end;
  function getFieldInfo(var AObject: TObject; APropertyName: String): PPropInfo;
  var
    i: Integer;
  begin
    Result := nil;

    with TStringList.Create do
      try
        Delimiter := '.';
        DelimitedText := APropertyName;

        for i := 0 to Count - 1 do
        begin
          Result := GetPropInfo(AObject, Strings[i]);
          if i = Count - 1 then
            Exit;

          if not Assigned(Result) or (Result^.PropType^.Kind <> tkClass) then
          begin
            Result := nil;
            Exit;
          end;

          AObject := TObject(GetOrdProp(AObject, Result));
        end;
      finally
        Free;
      end;
  end;
  function initPropertys(AObject: TObject; ADfmStream: TDfmStream): Boolean;
    function setInteger(AObject: TObject; APropInfo: PPropInfo; AValueType: TValueType; AValue: Variant): Boolean;
    var
      iti: TIdentToInt;
      iValue: Integer;
    begin
      Result := False;

      if AValueType = vaIdent then
      begin
        iti := FindIdentToInt(APropInfo^.PropType^);
        if not Assigned(iti) or not iti(VarToStr(AValue), iValue) then
          Exit;
      end
      else
        iValue := VarToInt(AValue);

      SetOrdProp(AObject, APropInfo, iValue);
      Result := True;
    end;
    function setCollection(ACollection: TCollection; ADfmStream: TDfmStream): Boolean;
    var
      vt: TValueType;
      v: Variant;
      per: TPersistent;
    begin
      Result := True;

      v := ADfmStream.ReadValue(vt);
      if vt = vaNull then
        Exit;

      ACollection.BeginUpdate;
      try
        ACollection.Clear;
        if vt in [vaInt8, vaInt16, vaInt32] then
          v := ADfmStream.ReadValue(vt);

        if vt <> vaList then
        begin
          Result := False;
          Exit;
        end;

        per := ACollection.Add;
        Result := initPropertys(per, ADfmStream);
      finally
        ACollection.EndUpdate;
      end;
    end;
    function setClass(AObject: TObject; APropInfo: PPropInfo; AValueType: TValueType; AValue: Variant): Boolean;
    begin
      case AValueType of
        vaNil: SetOrdProp(AObject, APropInfo, 0);
        vaCollection: setCollection(TCollection(GetOrdProp(AObject, APropInfo)), ADfmStream);
      else
        {TODO: FFixups处理}
        //SetObjectIdent(AObject, pi, ReadIdent);
      end;

      Result := True;
    end;
    function setMethod(AObject: TObject; APropInfo: PPropInfo; AValueType: TValueType; AValue: Variant): Boolean;
    var
      me: TMethod;
    begin
      Result := False;

      if AValueType = vaNil then
      begin
        me.Code := nil;
        me.Data := nil;
      end
      else
      begin
        me.Code := Self.MethodAddress(VarToStr(AValue));
        me.Data := Self;
        if me.Code = nil then
          Exit;
      end;

      SetMethodProp(AObject, APropInfo, me);
      Result := True;
    end;
    function setInterface(AObject: TObject; APropInfo: PPropInfo; AValueType: TValueType; AValue: Variant): Boolean;
    var
      itf: IInterface;
    begin
      if AValueType = vaNil then
      begin
        itf := nil;
        SetInterfaceProp(AObject, APropInfo, itf);
      end
      else
      begin
        {TODO: FFixups处理}
      end;

      Result := True;
    end;
  var
    sPropertyName, sTemp: String;
    vt: TValueType;
    v: Variant;
    pi: PPropInfo;
    obj: TObject;
  begin
    Result := False;

    while True do
    begin
      sPropertyName := ADfmStream.ReadStr;
      if sPropertyName = '' then
        Break;

      obj := AObject;
      pi := getFieldInfo(obj, sPropertyName);
      if not Assigned(pi) then
      begin
        v := ADfmStream.ReadValue(vt);
        if vt = vaList then
        begin
          sTemp := '';
          while True do
          begin
            v := ADfmStream.ReadValue(vt);
            if vt = vaNull then
            begin
              if sTemp <> '' then
                SetLength(sTemp, Length(sTemp) - 1);
              Break;
            end;

            sTemp := sTemp + VarToStr(v) + ',';
          end;
        end
        else
          sTemp := VarToStr(v);
        WriteView('属性[%s]不存在，其值为[%s]', [sPropertyName, sTemp]);
        Continue;
      end;

      v := ADfmStream.ReadValue(vt);
      case pi^.PropType^.Kind of
        tkInteger:
          if not setInteger(obj, pi, vt, v) then
            Exit;
        tkClass:
          if not setClass(obj, pi, vt, v) then
            Exit;
        tkMethod:
          if not setMethod(obj, pi, vt, v) then
            Exit;
        tkInterface:
          if not setInterface(obj, pi, vt, v) then
            Exit;
        tkEnumeration:
          SetOrdProp(obj, pi, GetEnumValue(pi^.PropType^, VarToStr(v)));
        tkVariant:
          SetVariantProp(obj, pi, v);
      else
        SetPropValue(obj, pi, v);
      end;
    end;

    Result := True;
  end;
  function initComponent(AObject, AParent: TObject; ADfmStream: TDfmStream): Boolean;
  var
    sClass, sName: String;
    cc: TComponentClass;
  begin
    Result := False;

    ADfmStream.ReadPrefix;
    sClass := ADfmStream.ReadStr;
    sName := ADfmStream.ReadStr;

    if not Assigned(AObject) then
    begin
      cc := getFieldClass(sClass);
      if not Assigned(cc) then
        Exit;

      AObject := cc.Create(Self);

      {$IFDEF DESIGNTIME}
      if (AObject is TControl) and (AParent is TWinControl) then
        TControl(AObject).Parent := TWinControl(AParent);
      {$ELSE}
      if AObject is TDUIBase then
      begin
        if AParent is TDUIForm then
          TDUIBase(AObject).Parent := TWinControl(AParent)
        else if AParent is TDUIBase then
          TDUIBase(AObject).DUIParent := TDUIBase(AParent)
        else
        begin
          AObject.Free;
          Exit;
        end;
      end
      else if (AObject is TControl) and (AParent is TWinControl) then
        TControl(AObject).Parent := TWinControl(AParent);
      {$ENDIF}

      TComponent(AObject).Name := sName;
    end;

    if not initPropertys(AObject, ADfmStream) then
      Exit;

    while ADfmStream.NextType <> vaNull do
      if not initComponent(nil, AObject, ADfmStream) then
        Exit;

    ADfmStream.ReadType;

    Result := True;
  end;
  function init(AClassType: TClass): Boolean;
  var
    ds: TDfmStream;
  begin
    Result := False;
    if (AClassType = TComponent) or (AClassType = TForm) then
      Exit;

    Result := init(AClassType.ClassParent);
    ds := nil;
    try try
      ds := TDfmStream.Create(AClassType);

      if ds.ReadSignature <> 'TPF0' then
        Exit;

      Result := initComponent(Self, nil, ds) or Result;
    except
      on e: EResNotFound do
      begin
        Exit;
      end;
    end;
    finally
      FreeAndNil(ds);
    end;
  end;
begin
  CreateNew(AOwner);

  Include(FFormState, fsCreating);
  try
    if not init(ClassType) then
      raise Exception.Create('DUI窗口创建失败');
  finally
    Exclude(FFormState, fsCreating);
  end;
end;

class procedure TDUIForm.Init;
begin
  FForms := TList.Create;
end;

class procedure TDUIForm.UnInit;
begin
  FreeAndNil(FForms);
end;

class procedure TDUIForm.ChangeSkin;
var
  iForm: Integer;
begin
  TDUIGraphicsObject.ChangeSkin;

  for iForm := 0 to FForms.Count - 1 do
    TDUIForm(FForms[iForm]).ReInitSkin;
end;

initialization
  TDUIForm.Init;
  RegComponents; //在UDUIRegComponents中通过initialization自注册的方式无法触发执行，改到这里处理

finalization
  TDUIForm.UnInit;

end.
