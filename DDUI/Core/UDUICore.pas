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
unit UDUICore;

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Messages, Types,
  IGDIPlus, UDUIUtils;

const
  DDUI_ASYNC_PERFORM = WM_APP + 1000;

type
  TDUIOnPaint = procedure (ASender: TObject; AGPCanvas: IGPGraphics) of object;

  {$IFDEF DESIGNTIME}
  TDUIRoot = TWinControl;
  {$ELSE}
  TDUIRoot = TControl;
  {$ENDIF}

  //TDUIBase������DUI�ؼ��Ļ���
  TDUIBase = class(TDUIRoot)
  {$IFDEF DESIGNTIME}
  private
    procedure CMControlListChanging(var AMessage: TMessage); message CM_CONTROLLISTCHANGING;
    procedure CMEnabledChanged(var AMessage: TMessage); message CM_ENABLEDCHANGED;
    procedure WMEraseBkgnd(var AMessage: TWmEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure PaintWindow(ADC: HDC); override;
    procedure WndProc(var AMessage: TMessage); override;
  public
    procedure Invalidate; override;
    procedure InvalidateRect(AGPRect: TGPRect);
    procedure Update; override;
  published
    property Padding;
  {$ELSE}
  private
    FAlignLevel: Word;
    FDUIParent: TDUIBase;
    FDUIControls: TList;
    FPadding: TPadding;
    procedure AlignControl(ADUIControl: TDUIBase);
    function GetControlCount: Integer;
    function GetControl(AIndex: Integer): TDUIBase;
    procedure InsertDUIControl(ADUIControl: TDUIBase);
    procedure RemoveDUIControl(ADUIControl: TDUIBase);
    procedure SetPadding(const AValue: TPadding);
    procedure DoPaddingChange(ASender: TObject);
    procedure WMLButtonDown(var AMessage: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonDblClk(var AMessage: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WMLButtonUp(var AMessage: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMVisibleChanged(var AMessage: TMessage); message CM_VISIBLECHANGED;
  protected
    procedure WndProc(var AMessage: TMessage); override;
    procedure AlignControls(AControl: TControl; var ARect: TRect); virtual; //TControlû�ж������������Ϊ���ֺ�TWinControl����ʽ��ͳһ�����¶���һ���µ�
    function GetClientOrigin: TPoint; override;
    procedure ReadState(AReader: TReader); override;
    procedure RequestAlign; override;
    procedure Resize; override;
    procedure SetParentComponent(AValue: TComponent); override;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    function ControlAtPos(const APos: TPoint; AAllowDisabled: Boolean): TDUIBase;
    //DisableAlign��EnableAlign��TWinControl����ͬ��ʵ�֣������ʵ��DUI����
    procedure DisableAlign;
    procedure EnableAlign;
    procedure Invalidate; override;
    procedure InvalidateRect(AGPRect: TGPRect);
    property ControlCount: Integer read GetControlCount;
    property Controls[AIndex: Integer]: TDUIBase read GetControl;
  published
    property Padding: TPadding read FPadding write SetPadding;
  {$ENDIF}
  private
    FAlignKeepSize: Boolean;
    FAlignOrder: Integer;
    FDUIOriginalParentSize: TPoint;
    FOnInitSkin: TNotifyEvent;
    FOnPaint: TDUIOnPaint;
    function GetHint: String;
    procedure SetAlignOrder(const AValue: Integer);
    procedure SetAlignKeepSize(const AValue: Boolean);
    function GetDUIParent: TDUIBase;
    procedure SetDUIParent(const ADUIParent: TDUIBase);
    function GetRootParent: TWinControl;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
  protected
    procedure CalcSize(out ANewWidth, ANewHeight: Integer); virtual;
    function CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean; override;
    procedure DoPaint(AGPCanvas: IGPGraphics); virtual;
    procedure DoPaintAfter(AGPCanvas: IGPGraphics); virtual;
    procedure DoParentChanged; virtual;
    procedure DoInitSkin; virtual;
    procedure DefineProperties(AFiler: TFiler); override;
    function IsTransparent: Boolean; virtual;
    procedure Loaded; override;
    procedure SetHint(const AValue: String); virtual;
    procedure SetParent(AParent: TWinControl); override;
    procedure SetZOrder(ATopMost: Boolean); override;
    procedure ValidateContainer(AComponent: TComponent); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure PerformAsync(AMessage: Cardinal; AWParam, ALParam: Longint);
    procedure ReInitSkin;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    property DUIParent: TDUIBase read GetDUIParent write SetDUIParent;
    property RootParent: TWinControl read GetRootParent;
  published
    property Align;
    property AlignKeepSize: Boolean read FAlignKeepSize write SetAlignKeepSize default False;
    property AlignOrder: Integer read FAlignOrder write SetAlignOrder default 0;
    property Anchors;
    property Hint: String read GetHint write SetHint;
    property Visible;
    property OnInitSkin: TNotifyEvent read FOnInitSkin write FOnInitSkin;
    property OnPaint: TDUIOnPaint read FOnPaint write FOnPaint;
  end;

  TDUIAsyncMessage = class(TComponent)
  private
    FControl: TDUIBase;
    FMessage: Cardinal;
    FWParam: LongInt;
    FLParam: LongInt;
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AControl: TDUIBase; AMessage: Cardinal; AWParam, ALParam: LongInt); reintroduce;
    procedure Execute;
  end;

  TDUIBaseClass = class of TDUIBase;

  //TDUIKeyboardBase�������ܴ�������¼��Ŀؼ��Ļ���(���磬�ı��༭��)
  TDUIKeyboardBase = class(TDUIBase)
  {$IFDEF DESIGNTIME}
  {$ELSE}
  private
    FOnKeyDown: TKeyEvent;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyUp: TKeyEvent;
    procedure WMKeyDown(var AMessage: TWMKeyDown); message WM_KEYDOWN;
    procedure WMSysKeyDown(var AMessage: TWMKeyDown); message WM_SYSKEYDOWN;
    procedure WMKeyUp(var AMessage: TWMKeyUp); message WM_KEYUP;
    procedure WMSysKeyUp(var AMessage: TWMKeyUp); message WM_SYSKEYUP;
    procedure WMChar(var AMessage: TWMChar); message WM_CHAR;
    procedure WMLButtonDown(var AMessage: TWMLButtonDown); message WM_LBUTTONDOWN;
  protected
    procedure KeyDown(var AKey: Word; AShift: TShiftState); dynamic;
    function DoKeyDown(var AMessage: TWMKey): Boolean;
    procedure KeyUp(var AKey: Word; AShift: TShiftState); dynamic;
    function DoKeyUp(var AMessage: TWMKey): Boolean;
    procedure KeyPress(var AKey: Char); dynamic;
    function DoKeyPress(var AMessage: TWMKey): Boolean;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
  public
    function CanFocus: Boolean; dynamic;
  {$ENDIF}
  published
    property Text;
  end;

  TDUIKeyboardBaseClass = class of TDUIKeyboardBase;

procedure ListControls(AParent: TControl; var AAlignControls, AAnchorsControls: TControlsList);
procedure ArrangeControls(AAlignControls, AAnchorsControls: TControlsList; var ARect: TRect);
function GPRectToRect(const AGPRect: TGPRect): TRect;
function PtInGPRect(const AGPRect: TGPRect; const APoint: TPoint): Boolean;

implementation

uses
  Consts, UDUIForm, UDUIHint, UTool;

type
  TControlHelper = class(TControl)
  end;
  TWinControlHelper = class(TWinControl)
  public
    procedure DUIArrangeControl(AControl: TControl; const AParentSize: TPoint);
  end;

{ TWinControlHelper }

procedure TWinControlHelper.DUIArrangeControl(AControl: TControl; const AParentSize: TPoint);
var
  ai: TAlignInfo;
  rct: TRect;
begin
  ArrangeControl(AControl, AParentSize, alNone, ai, rct, False);
end;

function ListCompare(AItem1, AItem2: Pointer): Integer;
  function compare(AValue1, AValue2: Integer): Integer;
  begin
    if AValue1 < AValue2 then
      Result := -1
    else if AValue1 > AValue2 then
      Result := 1
    else
      Result := 0;
  end;
var
  ctl1, ctl2: TControl;
  iOrder1, iOrder2: Integer;
begin
  ctl1 := TControl(AItem1);
  ctl2 := TControl(AItem2);

  //1.0 ��AlignOrder����
  iOrder1 := 0;
  iOrder2 := 0;
  if ctl1 is TDUIBase then
    iOrder1 := TDUIBase(ctl1).AlignOrder;
  if ctl2 is TDUIBase then
    iOrder2 := TDUIBase(ctl2).AlignOrder;

  if iOrder1 <> iOrder2 then
  begin
    Result := -1 * compare(iOrder1, iOrder2);
    Exit;
  end;

  //2.0 ��Align����
  //��ʱ������alNone��alCustom��ͳһ��alCustom����(������alCustom��������������)
  iOrder1 := Ord(ctl1.Align);
  if iOrder1 = Ord(alNone) then
    iOrder1 := Ord(alCustom);
  iOrder2 := Ord(ctl2.Align);
  if iOrder2 = Ord(alNone) then
    iOrder2 := Ord(alCustom);

  if iOrder1 <> iOrder2 then
  begin
    Result := compare(iOrder1, iOrder2);
    Exit;
  end
  else if iOrder1 = Ord(alCustom) then
  begin
    //ͬʱΪalNone����������벻���Ⱥ�(���������������Anchors����δ����Align������)
    Result := compare(0, 0);
    Exit;
  end
  else
  begin
    //���õ�Alignֵ��ͬ�����������ж�
  end;

  //3.0 ����������
  case ctl1.Align of
    alTop: Result := compare(ctl1.Top, ctl2.Top);
    alBottom: Result := -1 * compare(ctl1.Top + ctl1.Height, ctl2.Top + ctl2.Height);
    alLeft: Result := compare(ctl1.Left, ctl2.Left);
    alRight: Result := -1 * compare(ctl1.Left + ctl1.Width, ctl2.Left + ctl2.Width);
  else
    Result := compare(0, 0); //���ַ�ʽ���ᴥ��
  end;
end;

procedure ListControls(AParent: TControl; var AAlignControls, AAnchorsControls: TControlsList);
var
  i: Integer;
  ctl: TControl;
begin
  AAlignControls.Clear;
  AAnchorsControls.Clear;

{$IFDEF DESIGNTIME}
  for i := 0 to TWinControl(AParent).ControlCount - 1 do
  begin
    ctl := TWinControl(AParent).Controls[i];

    if (ctl.Align in [alNone, alCustom]) and (ctl.Anchors = [akLeft, akTop])
      and not (csAlignmentNeeded in ctl.ControlState) then
      Continue;

    if not ctl.Visible and not (csDesigning in ctl.ComponentState) then
      Continue;

    if ctl.Align in [alNone, alCustom] then
      AAnchorsControls.Add(ctl)
    else
      AAlignControls.Add(ctl);
  end;
{$ELSE}
  if AParent is TDUIBase then
    for i := 0 to TDUIBase(AParent).ControlCount - 1 do
    begin
      ctl := TDUIBase(AParent).Controls[i];

      if (ctl.Align in [alNone, alCustom]) and (ctl.Anchors = [akLeft, akTop])
        and not (csAlignmentNeeded in ctl.ControlState) then
        Continue;

      if not ctl.Visible and not (csDesigning in ctl.ComponentState) then
        Continue;

      if ctl.Align in [alNone, alCustom] then
        AAnchorsControls.Add(ctl)
      else
        AAlignControls.Add(ctl);
    end;

  if AParent is TDUIForm then
    for i := 0 to TWinControl(AParent).ControlCount - 1 do
    begin
      ctl := TWinControl(AParent).Controls[i];

      if (ctl.Align in [alNone, alCustom]) and (ctl.Anchors = [akLeft, akTop])
        and not (csAlignmentNeeded in ctl.ControlState) then
        Continue;

      if not ctl.Visible and not (csDesigning in ctl.ComponentState) then
        Continue;

      if ctl.Align in [alNone, alCustom] then
        AAnchorsControls.Add(ctl)
      else
        AAlignControls.Add(ctl);
    end;
{$ENDIF}

  AAlignControls.MergeSort(ListCompare);
  //AAnchorsControls�����򣬰����ʱ��ӵ�˳����
end;

procedure ArrangeControls(AAlignControls, AAnchorsControls: TControlsList; var ARect: TRect);
  procedure doAlign(AControl: TControl);
  var
    rctNew: TGPRect;
    rctMargin: TRect;
    bKeepSize: Boolean;
  begin
    //1.0 �����³ߴ��ֵ
    //������Ϊ�ؼ���ʵ�ʳߴ磬������Margins�Ĵ�������������TMargins.SetControlBounds�е�����
    if AControl.AlignWithMargins then
      rctMargin := Rect(AControl.Margins.Left, AControl.Margins.Top,
        AControl.Margins.Right, AControl.Margins.Bottom)
    else
      rctMargin := Rect(0, 0, 0, 0);

    bKeepSize := False;
    if AControl is TDUIBase then
      bKeepSize := TDUIBase(AControl).AlignKeepSize;

    //�ؼ�����֮ǰ���ȴ����ؼ��ߴ���Զ�����
    if TControlHelper(AControl).AutoSize then
      AControl.Width := ARect.Right - ARect.Left - (rctMargin.Left + rctMargin.Right);

    if bKeepSize then
    begin
      case AControl.Align of
        alTop:
        begin
          rctNew := MakeRect(
            ARect.Left + (ARect.Right - ARect.Left - AControl.Width) div 2,
            ARect.Top + rctMargin.Top,
            AControl.Width,
            AControl.Height);
        end;
        alBottom:
        begin
          rctNew := MakeRect(
            ARect.Left + (ARect.Right - ARect.Left - AControl.Width) div 2,
            ARect.Bottom - rctMargin.Bottom - AControl.Height,
            AControl.Width,
            AControl.Height);
        end;
        alLeft:
        begin
          rctNew := MakeRect(
            ARect.Left + rctMargin.Left,
            ARect.Top + (ARect.Bottom - ARect.Top - AControl.Height) div 2,
            AControl.Width,
            AControl.Height);
        end;
        alRight:
        begin
          rctNew := MakeRect(
            ARect.Right - rctMargin.Right - AControl.Width,
            ARect.Top + (ARect.Bottom - ARect.Top - AControl.Height) div 2,
            AControl.Width,
            AControl.Height);
        end;
        alClient:
        begin
          rctNew := MakeRect(
            ARect.Left + (ARect.Right - ARect.Left - AControl.Width) div 2,
            ARect.Top + (ARect.Bottom - ARect.Top - AControl.Height) div 2,
            AControl.Width,
            AControl.Height);
        end;
      end;
    end
    else
    begin
      case AControl.Align of
        alTop:
        begin
          rctNew := MakeRect(
            ARect.Left + rctMargin.Left,
            ARect.Top + rctMargin.Top,
            ARect.Right - ARect.Left - (rctMargin.Left + rctMargin.Right),
            AControl.Height);
        end;
        alBottom:
        begin
          rctNew := MakeRect(
            ARect.Left + rctMargin.Left,
            ARect.Bottom - rctMargin.Bottom - AControl.Height,
            ARect.Right - ARect.Left - (rctMargin.Left + rctMargin.Right),
            AControl.Height);
        end;
        alLeft:
        begin
          rctNew := MakeRect(
            ARect.Left + rctMargin.Left,
            ARect.Top + rctMargin.Top,
            AControl.Width,
            ARect.Bottom - ARect.Top - (rctMargin.Top + rctMargin.Bottom));
        end;
        alRight:
        begin
          rctNew := MakeRect(
            ARect.Right - rctMargin.Right - AControl.Width,
            ARect.Top + rctMargin.Top,
            AControl.Width,
            ARect.Bottom - ARect.Top - (rctMargin.Top + rctMargin.Bottom));
        end;
        alClient:
        begin
          rctNew := MakeRect(
            ARect.Left + rctMargin.Left,
            ARect.Top + rctMargin.Top,
            ARect.Right - ARect.Left - (rctMargin.Left + rctMargin.Right),
            ARect.Bottom - ARect.Top - (rctMargin.Top + rctMargin.Bottom));
        end;
      end;
    end;

    if rctNew.Width < 0 then
      rctNew.Width := 0;
    if rctNew.Height < 0 then
      rctNew.Height := 0;

    //2.0 ���TMargins.SetControlBounds�еĴ����Խ��������
    if AControl.AlignWithMargins and Assigned(AControl.Parent) then
      rctNew := MakeRect(
        rctNew.X - rctMargin.Left,
        rctNew.Y - rctMargin.Top,
        rctNew.Width + (rctMargin.Left + rctMargin.Right),
        rctNew.Height + (rctMargin.Top + rctMargin.Bottom));

    AControl.Margins.SetControlBounds(rctNew.X, rctNew.Y, rctNew.Width, rctNew.Height, True);

    //3.0 �����ARect��ֵ������
    case AControl.Align of
      alTop: Inc(ARect.Top, AControl.Height + rctMargin.Top + rctMargin.Bottom);
      alBottom: Dec(ARect.Bottom, AControl.Height + rctMargin.Top + rctMargin.Bottom);
      alLeft: Inc(ARect.Left, AControl.Width + rctMargin.Left + rctMargin.Right);
      alRight: Dec(ARect.Right, AControl.Width + rctMargin.Left + rctMargin.Right);
      alClient: {TODO: ��δ������};
    end;
  end;
  procedure doAnchors(AControl: TControl; const AParentSize: TPoint);
  var
    rctNew: TGPRect;
    rctMargin: TRect;
  begin
    //1.0 ���������Parent���ԣ���ֱ�ӵ���Ĭ��ʵ��
    if Assigned(AControl.Parent) then
    begin
      TWinControlHelper(AControl.Parent).DUIArrangeControl(AControl, AParentSize);
      Exit;
    end;

    //2.0 ��ǶDUI�ؼ�(DUI�ؼ��е�DUI�ؼ�)���봦��
    if not (AControl is TDUIBase) then //�ߵ����AControlһ����TDUIBase
      Exit;

    //2.1 �³ߴ����
    if AControl.AlignWithMargins then
      rctMargin := Rect(AControl.Margins.Left, AControl.Margins.Top,
        AControl.Margins.Right, AControl.Margins.Bottom)
    else
      rctMargin := Rect(0, 0, 0, 0);

    rctNew := MakeRect(AControl.Left, AControl.Top, AControl.Width, AControl.Height);

    if akRight in AControl.Anchors then
      if akLeft in AControl.Anchors then
        rctNew.Width := AControl.Width + (AParentSize.X - TDUIBase(AControl).FDUIOriginalParentSize.X)
      else
        rctNew.X := AControl.Left + (AParentSize.X - TDUIBase(AControl).FDUIOriginalParentSize.X)
    else if not (akLeft in AControl.Anchors) then
      rctNew.X := MulDiv(AControl.Left + AControl.Width div 2,
        AParentSize.X,
        TDUIBase(AControl).FDUIOriginalParentSize.X)
        - rctNew.Width div 2;

    if akBottom in AControl.Anchors then
      if akTop in AControl.Anchors then
        rctNew.Height := AControl.Height + (AParentSize.Y - TDUIBase(AControl).FDUIOriginalParentSize.Y)
      else
        rctNew.Y := AControl.Top + (AParentSize.Y - TDUIBase(AControl).FDUIOriginalParentSize.Y)
    else if not (akTop in AControl.Anchors) then
      rctNew.Y := MulDiv(AControl.Top + AControl.Height div 2,
        AParentSize.Y,
        TDUIBase(AControl).FDUIOriginalParentSize.Y)
        - rctNew.Height div 2;

    if rctNew.Width < 0 then
      rctNew.Width := 0;
    if rctNew.Height < 0 then
      rctNew.Height := 0;

    //2.2 ���TMargins.SetControlBounds�еĴ����Խ��������
    if AControl.AlignWithMargins and Assigned(AControl.Parent) then
      rctNew := MakeRect(
        rctNew.X - rctMargin.Left,
        rctNew.Y - rctMargin.Top,
        rctNew.Width + (rctMargin.Left + rctMargin.Right),
        rctNew.Height + (rctMargin.Top + rctMargin.Bottom));

    AControl.Margins.SetControlBounds(rctNew.X, rctNew.Y, rctNew.Width, rctNew.Height, True);

    //2.3 ��¼�����ڵĵ�ǰ�ߴ�(�������ڳߴ����������ݴ�ֵ�����ӿؼ��Ĵ�С)
    TDUIBase(AControl).FDUIOriginalParentSize := AParentSize;
  end;
var
  i: Integer;
  ptParentSize: TPoint;
begin
  ptParentSize.X := ARect.Right - ARect.Left;
  ptParentSize.Y := ARect.Bottom - ARect.Top;

  if Assigned(AAlignControls) then
    for i := 0 to AAlignControls.Count - 1 do
      doAlign(TControl(AAlignControls[i]));

  if Assigned(AAnchorsControls) then
    for i := 0 to AAnchorsControls.Count - 1 do
      doAnchors(TControl(AAnchorsControls[i]), ptParentSize);
end;

function GPRectToRect(const AGPRect: TGPRect): TRect;
begin
  Result.Left := AGPRect.X;
  Result.Top := AGPRect.Y;
  Result.Right := AGPRect.X + AGPRect.Width;
  Result.Bottom := AGPRect.Y + AGPRect.Height;
end;

function PtInGPRect(const AGPRect: TGPRect; const APoint: TPoint): Boolean;
begin
  Result := PtInRect(GPRectToRect(AGPRect), APoint);
end;

{ TDUIBase }

{$IFDEF DESIGNTIME}

constructor TDUIBase.Create(AOwner: TComponent);
begin
  inherited;

  if csDesigning in ComponentState then
    ControlStyle := [csAcceptsControls];

  DoInitSkin;
end;

procedure TDUIBase.CreateParams(var AParams: TCreateParams);
begin
  inherited;

  AParams.Style := AParams.Style and not WS_CLIPSIBLINGS and not WS_CLIPCHILDREN;
end;

procedure TDUIBase.CMControlListChanging(var AMessage: TMessage);
var
  cli: PControlListItem;
begin
  if Boolean(AMessage.LParam) then //True��ʾ�����ؼ���False��ʾɾ���ؼ�
  begin
    cli := PControlListItem(AMessage.WParam);
    if not (cli.Control is TDUIBase) and not (cli.Control is TDUIScrollControl) then
      raise Exception.Create('DUI�ؼ���ֻ�������DUI�ؼ�');
  end;

  inherited;
end;

procedure TDUIBase.CMEnabledChanged(var AMessage: TMessage);
begin
  inherited;

  Invalidate;
end;

procedure TDUIBase.WMEraseBkgnd(var AMessage: TWmEraseBkgnd);
begin
  AMessage.Result := 1;
end;

procedure TDUIBase.WMPaint(var AMessage: TWMPaint);
begin
  ControlState := ControlState + [csCustomPaint]; //����csCustomPaint��TWinControl�ᴥ��PaintWindow�ĵ���
  inherited;
  ControlState := ControlState - [csCustomPaint];
end;

procedure TDUIBase.Invalidate;
begin
  if not (csDesigning in ComponentState) and not Visible then
    Exit;

  if Assigned(DUIParent) then
    DUIParent.InvalidateRect(MakeRect(Left - 3, Top - 3, Width + 6, Height + 6)) //���ʱ���ؼ���Χ��6����(�ؼ���3���أ��ؼ���3����)��ѡ���ָʾ��
  else
    InvalidateRect(MakeRect(-3, -3, Width + 6, Height + 6));
end;

procedure TDUIBase.InvalidateRect(AGPRect: TGPRect);
var
  rct: TRect;
begin
  if not (csDesigning in ComponentState) and not Visible then
    Exit;

  AGPRect.X := AGPRect.X + Left;
  AGPRect.Y := AGPRect.Y + Top;

  if Assigned(DUIParent) then
    DUIParent.InvalidateRect(AGPRect)
  else if Assigned(Parent) and Parent.HandleAllocated then
  begin
    rct := GPRectToRect(AGPRect);
    Windows.InvalidateRect(Parent.Handle, @rct, False);
  end;
end;

procedure TDUIBase.Update;
begin
  Invalidate;
end;

procedure TDUIBase.PaintWindow(ADC: HDC);
begin
  if Assigned(FOnPaint) then
    FOnPaint(Self, TGPGraphics.Create(ADC))
  else
    DoPaint(TGPGraphics.Create(ADC));
end;

procedure TDUIBase.WndProc(var AMessage: TMessage);
  function getOpaqueParent: TWinControl;
  begin
    Result := Parent;
    while True do
    begin
      if not Assigned(Result) or not (Result is TDUIBase) then
        Exit;

      if not TDUIBase(Result).IsTransparent then
        Exit;

      Result := Result.Parent;
    end;
  end;
var
  wcParent: TWinControl;
  pt: TPoint;
begin
  if (csDesigning in ComponentState) or not IsTransparent then
  begin
    inherited WndProc(AMessage);
    Exit;
  end;

  //͸���ؼ���Ҫ����Ϣת�����²㴰��
  //Ŀǰ��ʵ���˸����ڵ��������͸Ч�����ֵܴ��ڲ�֧��
  wcParent := getOpaqueParent;
  if not Assigned(wcParent) then
  begin
    inherited WndProc(AMessage);
    Exit;
  end;

  case AMessage.Msg of
    CM_MOUSEENTER:
    begin
      AMessage.Result := wcParent.Perform(AMessage.Msg,
        AMessage.WParam, AMessage.LParam);
    end;
    CM_MOUSELEAVE:
    begin
      AMessage.Result := wcParent.Perform(AMessage.Msg,
        AMessage.WParam, AMessage.LParam);
    end;
    WM_MOUSEFIRST..WM_MOUSELAST:
    begin
      if AMessage.Msg = WM_MOUSEMOVE then
      begin
        //WM_MOUSEMOVE��Ϣ����ת���������򣬻ᵼ��WM_MOUSELEAVE��Ϣ��ע�ᵽwcParent�ϣ�
        //����Ϣ������󣬲���ϵͳ������겻��wcParent�ϣ���ˣ���������WM_MOUSELEAVE��Ϣ
        inherited WndProc(AMessage);
        Exit;
      end;

      pt := ClientToScreen(SmallPointToPoint(TWMMouse(AMessage).Pos));
      pt := wcParent.ScreenToClient(pt);
      AMessage.Result := wcParent.Perform(AMessage.Msg,
        AMessage.WParam, Longint(PointToSmallPoint(pt)));
    end;
  else
    inherited WndProc(AMessage);
  end;
end;

procedure TDUIBase.SetParent(AParent: TWinControl);
begin
  if Parent = AParent then
    Exit;

  if Assigned(AParent) and not (AParent is TDUIBase)
    and not (AParent is TDUIForm) and not (AParent is TDUIFrame)
    and not (AParent is TDUIScrollControl) then
    raise Exception.Create('DUI�ؼ�ֻ����TDUIForm��ʹ��');

  inherited;

  if not (csDestroying in ComponentState) then
    DoParentChanged;
end;

procedure TDUIBase.SetZOrder(ATopMost: Boolean);
begin
  inherited;
end;

function TDUIBase.GetRootParent: TWinControl;
begin
  Result := Parent;
end;

function TDUIBase.GetDUIParent: TDUIBase;
begin
  if Parent is TDUIBase then
    Result := Parent as TDUIBase
  else
    Result := nil;
end;

procedure TDUIBase.SetDUIParent(const ADUIParent: TDUIBase);
begin
  Parent := ADUIParent;
end;

{$ELSE}

var
  GMouseInClientControl: TDUIBase = nil;
  GCaptureControl: TDUIBase = nil;

procedure SetMouseInClientControl(AValue: TDUIBase);
begin
  if GMouseInClientControl = AValue then
    Exit;

  if Assigned(GMouseInClientControl) then
    GMouseInClientControl.Perform(CM_MOUSELEAVE, 0, 0);
  GMouseInClientControl := AValue;
  if Assigned(GMouseInClientControl) then
    GMouseInClientControl.Perform(CM_MOUSEENTER, 0, 0);
end;

procedure SetDUICaptureControl(AValue: TDUIBase);
var
  duiParent: TDUIBase;
begin
  if GCaptureControl = AValue then
    Exit;

  if not Assigned(AValue) then
  begin
    duiParent := GCaptureControl;
    while Assigned(duiParent.DUIParent) do
      duiParent := duiParent.DUIParent;

    GCaptureControl := nil;
    duiParent.MouseCapture := False;
  end
  else
  begin
    duiParent := AValue;
    while Assigned(duiParent.DUIParent) do
      duiParent := duiParent.DUIParent;

    if Assigned(duiParent.Parent) and (csCaptureMouse in duiParent.Parent.ControlStyle) then
    begin
      GCaptureControl := AValue;
      duiParent.MouseCapture := True;
    end;
  end;
end;

constructor TDUIBase.Create(AOwner: TComponent);
begin
  inherited;

  //DelphiԴ�붨����csCreating����δʹ�ã���֪������;��
  //���ô�״̬�����ڿؼ����������У�Ƶ������AlignControl������
  ControlState := ControlState + [csCreating];
  ControlStyle := ControlStyle - [csCaptureMouse];

  FDUIControls := TList.Create;
  FPadding := TPadding.Create(Self);
  FPadding.OnChange := DoPaddingChange;

  DoInitSkin;
end;

procedure TDUIBase.AfterConstruction;
begin
  inherited;

  ControlState := ControlState - [csCreating];
end;

destructor TDUIBase.Destroy;
var
  ctl: TDUIBase;
begin
  //�����ؼ��ͷ�ʱ��������ؼ����ӿؼ���Owner���󣬻��ڵ���inheritedʱ���ͷ��ӿؼ���
  //���ӿؼ�����SetDUIParent���Լ��Ӹ��ؼ���FDUIControls�����ʱ��
  //����Ϊ���ؼ��Ѿ��ͷţ������·���Υ������ˣ��������ͷ�ʱ��
  //�Ƚ��ӿؼ�ȫ���ͷţ���ֹ��������(�ο�TWinControl.Destroy�ж��ӿؼ��Ĵ���ģʽ)
  while FDUIControls.Count > 0 do
  begin
    ctl := FDUIControls[FDUIControls.Count - 1];
    FDUIControls.Delete(FDUIControls.Count - 1);
    ctl.Free;
  end;

  SetDUIParent(nil);
  FreeAndNil(FPadding);
  FreeAndNil(FDUIControls);

  if GMouseInClientControl = Self then
    GMouseInClientControl := nil;
  if GCaptureControl = Self then
    GCaptureControl := nil;

  inherited;
end;

function TDUIBase.ControlAtPos(const APos: TPoint; AAllowDisabled: Boolean): TDUIBase;
var
  i: Integer;
  pt, ptOrigin: TPoint;
begin
  if Self is TDUIScrollControl then
    ptOrigin := TDUIScrollControl(Self).ClientToScroll(APos)
  else
    ptOrigin := APos;
  
  for i := FDUIControls.Count - 1 downto 0 do
  begin
    Result := FDUIControls[i];
    pt := Point(ptOrigin.X - Result.Left, ptOrigin.Y - Result.Top);
    if PtInRect(Result.ClientRect, pt) then
    begin
      if (csDesigning in Result.ComponentState)
        and (Result.Visible or not (csNoDesignVisible in Result.ControlStyle)) then
        Exit;

      if Result.Visible and (Result.Enabled or AAllowDisabled)
        and (Result.Perform(CM_HITTEST, 0, Longint(PointToSmallPoint(pt))) <> 0) then
        Exit;
    end;
  end;

  Result := nil;
end;

procedure TDUIBase.WndProc(var AMessage: TMessage);
  function isDUIChild(AControl: TDUIBase): Boolean;
  begin
    Result := False;
    while Assigned(AControl) do
    begin
      if AControl = Self then
      begin
        Result := True;
        Exit;
      end;

      AControl := AControl.DUIParent;
    end;
  end;
var
  dui: TDUIBase;
  pt: TPoint;
begin
  case AMessage.Msg of
    WM_NCHITTEST:
    begin
      dui := ControlAtPos(ScreenToClient(SmallPointToPoint(TWMNCHitTest(AMessage).Pos)), False);
      if Assigned(dui) and (dui is TDUIBase) then
      begin
        dui.WindowProc(AMessage);
        if HTTRANSPARENT <> AMessage.Result then
          Exit;
      end;
    end;
    CM_MOUSELEAVE:
    begin
      if GMouseInClientControl = Self then
        GMouseInClientControl := nil
      else if isDUIChild(GMouseInClientControl) then
      begin
        SetMouseInClientControl(nil);
        Exit;
      end;
    end;
    WM_MOUSEFIRST..WM_MOUSELAST:
    begin
      if GCaptureControl = Self then
      begin
        inherited WndProc(AMessage);
        AMessage.Result := 1;

        Exit;
      end;

      //����ؼ��п��ܽ���Ϣת���������ؼ�����(���磬TDUIScrollControl�жԹ������Ĵ���)��
      //�������Ӷ�Parent�ļ�飬��Ϊ�˷�ֹ����ת����������ѭ����
      //�������̣�TForm����Ϣ������һ��TDUIBase�ؼ����˿ؼ�ֱ�ӽ���Ϣת��������ؼ���
      //���ԣ����ParentΪ�գ���˵����ǰ�ؼ��յ�����Ϣ����ת������(����TForm�Զ�����)��
      //���������ؼ�����Ϣ��ת������1��TDUIBase�ؼ�������Ȼ���γ���ѭ��
      //TDUIBase��Ϣ��Դ���ܣ�
      //1.0 ��TFormת������
      //2.0 ��TForm��һ��TDUIBaseת��������ؼ�
      //3.0 �ɽ���ؼ�ת���������ؼ�(�����ؼ����Լ���ת��)
      if Assigned(Parent) and Assigned(GCaptureControl) and Assigned(GCaptureControl.RootParent)
        and (GCaptureControl.RootParent.Handle = GetCapture) then
      begin
        pt := ClientToScreen(Point(TWMMouse(AMessage).XPos, TWMMouse(AMessage).YPos));
        pt := GCaptureControl.ScreenToClient(pt);
        AMessage.Result := GCaptureControl.Perform(AMessage.Msg,
          TWMMouse(AMessage).Keys, Longint(PointToSmallPoint(pt)));

        Exit;
      end;

      GCaptureControl := nil;

      dui := ControlAtPos(SmallPointToPoint(TWMMouse(AMessage).Pos), False);
      if Assigned(dui) then
      begin
        pt := ClientToScreen(Point(TWMMouse(AMessage).XPos, TWMMouse(AMessage).YPos));
        pt := dui.ScreenToClient(pt);
        AMessage.Result := dui.Perform(AMessage.Msg,
          TWMMouse(AMessage).Keys, Longint(PointToSmallPoint(pt)));

        if AMessage.Result <> 0 then
          Exit;
      end;

      if AMessage.Msg = WM_MOUSEWHEEL then
      begin
        with TWMMouseWheel(AMessage) do
        begin
          if DoMouseWheel(KeysToShiftState(Keys), WheelDelta, SmallPointToPoint(Pos)) then
            AMessage.Result := 1
          else
            AMessage.Result := 0;
        end;

        Exit;
      end
      else if IsTransparent then
      begin
        AMessage.Result := 0;
        Exit;
      end
      else
      begin
        SetMouseInClientControl(Self);
        AMessage.Result := 1;

        if AMessage.Msg = WM_MOUSEMOVE then
        begin
          TDUIHint.HintMouseMessage(Self, SmallPointToPoint(TWMMouse(AMessage).Pos));
          Dispatch(AMessage);
          Exit;
        end;
      end;
    end;
    CM_CONTROLCHANGE:
    begin
      if Assigned(FDUIParent) then
        FDUIParent.Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam)
      else if Assigned(Parent) then
        Parent.Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);
    end;
  end;

  inherited WndProc(AMessage);
end;

procedure TDUIBase.WMPaint(var AMessage: TWMPaint);
  procedure paintDUIControls(AGPCanvas: IGPGraphics);
  var
    i: Integer;
    dui: TDUIBase;
    gc: TGPGraphicsContainer;
    reg: IGPRegion;
  begin
    for i := 0 to FDUIControls.Count - 1 do
    begin
      dui := TDUIBase(FDUIControls[i]);

      if (not dui.Visible or ((csDesigning in dui.ComponentState) and (csDesignerHide in dui.ControlState)))
        and (not (csDesigning in dui.ComponentState) or (csDesignerHide in dui.ControlState)
          or (csNoDesignVisible in dui.ControlStyle)) then
        Continue;

      reg := AGPCanvas.GetClip;
      reg.Intersect(MakeRect(dui.Left, dui.Top, dui.Width, dui.Height));
      if reg.IsEmpty(AGPCanvas) then
        Continue;

      gc := AGPCanvas.BeginContainer;
      try
        AGPCanvas.TranslateTransform(dui.Left, dui.Top);
        //IntersectClipRect(AMessage.DC, 0, 0, dui.Width, dui.Height);
        dui.Perform(WM_PAINT, AMessage.DC, Integer(AGPCanvas));
      finally
        AGPCanvas.EndContainer(gc);
      end;
    end;
  end;
var
  gpg: IGPGraphics;
  gc: TGPGraphicsContainer;
  bClearGraphics: Boolean;
begin
  if csDestroying in ComponentState then
    Exit;

  if AMessage.Unused = 0 then
  begin
    if AMessage.DC = 0 then
      Exit;

    gpg := TGPGraphics.Create(AMessage.DC);
    gpg.SetPageUnit(UnitPixel);
    AMessage.Unused := Integer(gpg);
    bClearGraphics := True;
  end
  else
  begin
    gpg := IGPGraphics(AMessage.Unused);
    bClearGraphics := False;
  end;

  gc := gpg.BeginContainer;
  try
    gpg.SetClip(MakeRect(0, 0, Width, Height), CombineModeIntersect);

    if Self is TDUIScrollControl then
      with TDUIScrollControl(Self).ScrollToClient(Point(0, 0)) do
        gpg.TranslateTransform(X, Y);

    if Assigned(FOnPaint) then
      FOnPaint(Self, gpg)
    else
      DoPaint(gpg);
    paintDUIControls(gpg);
    DoPaintAfter(gpg);
  finally
    gpg.EndContainer(gc);
    if bClearGraphics then
      AMessage.Unused := 0;
  end;
end;

procedure TDUIBase.WMLButtonDown(var AMessage: TWMLButtonDown);
begin
  inherited;

  if csCaptureMouse in ControlStyle then
    SetDUICaptureControl(Self);
end;

procedure TDUIBase.WMLButtonDblClk(var AMessage: TWMLButtonDblClk);
begin
  inherited;

  if csCaptureMouse in ControlStyle then
    SetDUICaptureControl(Self);
end;

procedure TDUIBase.WMLButtonUp(var AMessage: TWMLButtonUp);
begin
  inherited;

  if csCaptureMouse in ControlStyle then
    SetDUICaptureControl(nil);
end;

procedure TDUIBase.WMNCHitTest(var AMessage: TWMNCHitTest);
begin
  if IsTransparent then
    AMessage.Result := HTTRANSPARENT
  else
    AMessage.Result := HTCLIENT;
end;

procedure TDUIBase.CMVisibleChanged(var AMessage: TMessage);
var
  i: Integer;
begin
  inherited;

  for i := 0 to ControlCount - 1 do
    Controls[i].Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);

  Invalidate;
end;

function TDUIBase.GetClientOrigin: TPoint;
begin
  if Assigned(Parent) then
    Result := inherited GetClientOrigin
  else if Assigned(DUIParent) then
  begin
    Result := DUIParent.ClientOrigin;

    if DUIParent is TDUIScrollControl then
    begin
      Inc(Result.X, Left - TDUIScrollControl(DUIParent).Position[sbHorizontal]);
      Inc(Result.Y, Top - TDUIScrollControl(DUIParent).Position[sbVertical]);
    end
    else
    begin
      Inc(Result.X, Left);
      Inc(Result.Y, Top);
    end;
  end
  else
    Result := Point(0, 0);
end;

procedure TDUIBase.DisableAlign;
begin
  Inc(FAlignLevel);
end;

procedure TDUIBase.EnableAlign;
begin
  Dec(FAlignLevel);
  if FAlignLevel <> 0 then
    Exit;

  if csAlignmentNeeded in ControlState then
    AlignControl(nil);
end;

procedure TDUIBase.Invalidate;
begin
//  if not Visible then
//    Exit;

  if Assigned(DUIParent) then
    DUIParent.InvalidateRect(MakeRect(Left, Top, Width, Height))
  else if Assigned(Parent) then
    inherited;
end;

procedure TDUIBase.InvalidateRect(AGPRect: TGPRect);
var
  rct: TRect;
begin
  if not Visible then
    Exit;

  {TODO: ����AGPRect�뵱ǰ�ؼ��߽�Ľ�������}

  AGPRect.X := AGPRect.X + Left;
  AGPRect.Y := AGPRect.Y + Top;

  if Assigned(DUIParent) then
    DUIParent.InvalidateRect(AGPRect)
  else if Assigned(Parent) and Parent.HandleAllocated then
  begin
    rct := GPRectToRect(AGPRect);
    Windows.InvalidateRect(Parent.Handle, @rct, False);
  end;
end;

procedure TDUIBase.AlignControl(ADUIControl: TDUIBase);
var
  rct: TRect;
begin
  if csDestroying in ComponentState then
    Exit;

  if FAlignLevel <> 0 then
  begin
    ControlState := ControlState + [csAlignmentNeeded];
    Exit;
  end;

  //�������Ż���������ؼ��д�AlignControl�ĵ��ã���ǰ�ؼ���AlignControl�ӻ�ִ�У�
  //�����ؼ���AlignControl��������ʱ���ٴ�����ǰ�ؼ���AlignControl����(AlignControls�������ʵ��)��
  //�Լ���AlignControl�ĵ���Ƶ��
  if Assigned(Parent) and (csAlignmentNeeded in Parent.ControlState) then
  begin
    ControlState := ControlState + [csAlignmentNeeded];
    Exit;
  end;

  if Assigned(DUIParent) and (csAlignmentNeeded in DUIParent.ControlState) then
  begin
    ControlState := ControlState + [csAlignmentNeeded];
    Exit;
  end;

  //�ؼ�����������(���ӿؼ�������ߴ��ʼ���Ķ���)��������AlignControl��ִ��
  if csCreating in ControlState then
  begin
    ControlState := ControlState + [csAlignmentNeeded];
    Exit;
  end;

  DisableAlign;
  try
    rct := GetClientRect;
    AlignControls(ADUIControl, rct);
  finally
    ControlState := ControlState - [csAlignmentNeeded];
    EnableAlign;
  end;
end;

procedure TDUIBase.ReadState(AReader: TReader);
begin
  DisableAlign;
  try
    inherited ReadState(AReader);
  finally
    EnableAlign;
  end;
end;

procedure TDUIBase.RequestAlign;
begin
  if Assigned(FDUIParent) then
  begin
    FDUIParent.AlignControl(Self);
    Invalidate;
  end
  else
    inherited;
end;

procedure TDUIBase.Resize;
begin
  AlignControl(nil);
  Invalidate;

  inherited;
end;

function TDUIBase.GetControlCount: Integer;
begin
  Result := FDUIControls.Count;
end;

function TDUIBase.GetControl(AIndex: Integer): TDUIBase;
begin
  Result := FDUIControls[AIndex];
end;

function TDUIBase.GetRootParent: TWinControl;
var
  duiParent: TDUIBase;
begin
  duiParent := Self;
  while Assigned(duiParent.DUIParent) do
    duiParent := duiParent.DUIParent;

  Result := duiParent.Parent;
end;

procedure TDUIBase.SetParent(AParent: TWinControl);
begin
  if Parent = AParent then
    Exit;

  if Assigned(AParent) then
    DUIParent := nil;

  inherited;

  if not (csDestroying in ComponentState) then
    DoParentChanged;
end;

procedure TDUIBase.SetZOrder(ATopMost: Boolean);
var
  iNewIndex, iCurrIndex: Integer;
begin
  if Assigned(Parent) then
  begin
    inherited;
    Exit;
  end;

  if not Assigned(FDUIParent) or (FDUIParent.FDUIControls.Count = 0) then
    Exit;

  iCurrIndex := FDUIParent.FDUIControls.IndexOf(Self);
  if iCurrIndex < 0 then
    Exit;

  if ATopMost then
    iNewIndex := FDUIParent.FDUIControls.Count - 1
  else
    iNewIndex := 0;

  if iNewIndex = iCurrIndex then
    Exit;

  FDUIParent.FDUIControls.Delete(iCurrIndex);
  FDUIParent.FDUIControls.Insert(iNewIndex, Self);

  FDUIParent.AlignControl(nil);
  FDUIParent.Invalidate;
end;

procedure TDUIBase.SetParentComponent(AValue: TComponent);
begin
  if (Parent = AValue) or (DUIParent = AValue) then
    Exit;

  if AValue is TWinControl then //TDUIForm
    Parent := TWinControl(AValue)
  else if AValue is TDUIBase then
    DUIParent := TDUIBase(AValue);
end;

procedure TDUIBase.InsertDUIControl(ADUIControl: TDUIBase);
begin
  FDUIControls.Add(ADUIControl);
  ADUIControl.FDUIParent := Self;

  ADUIControl.FDUIOriginalParentSize.X := Width - (Padding.Left + Padding.Right);
  ADUIControl.FDUIOriginalParentSize.Y := Height - (Padding.Top + Padding.Bottom);

  if [csReading, csDestroying] * ADUIControl.ComponentState = [] then
  begin
    ADUIControl.Invalidate;
    AlignControl(ADUIControl);
  end;

  Perform(CM_CONTROLCHANGE, Integer(ADUIControl), Integer(True));
end;

procedure TDUIBase.RemoveDUIControl(ADUIControl: TDUIBase);
begin
  if not (csDestroying in ComponentState) then
  begin
    Perform(CM_CONTROLCHANGE, Integer(ADUIControl), Integer(False));
    ADUIControl.Invalidate;
  end;

  FDUIControls.Remove(ADUIControl);
  ADUIControl.FDUIParent := nil;

  AlignControl(nil);
end;

function TDUIBase.GetDUIParent: TDUIBase;
begin
  Result := FDUIParent;
end;

procedure TDUIBase.SetDUIParent(const ADUIParent: TDUIBase);
begin
  if FDUIParent = ADUIParent then
    Exit;

  if ADUIParent = Self then
    raise Exception.Create('�����ڲ���Ϊ����');

  if Assigned(ADUIParent) then
    Parent := nil;

  if Assigned(FDUIParent) then
    FDUIParent.RemoveDUIControl(Self);

  if Assigned(ADUIParent) then
    ADUIParent.InsertDUIControl(Self);

  if not (csDestroying in ComponentState) then
    DoParentChanged;
end;

procedure TDUIBase.SetPadding(const AValue: TPadding);
begin
  FPadding.Assign(AValue);
end;

procedure TDUIBase.DoPaddingChange(ASender: TObject);
begin
  AlignControl(nil);
  Invalidate;
end;

{$ENDIF}

procedure TDUIBase.CalcSize(out ANewWidth, ANewHeight: Integer);
begin
  //�ӿؼ�ͨ���˺�������ؼ���ʵ�ʴ�С(������AutoSize����ʱ��Ч)
end;

function TDUIBase.CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean;
begin
  //CanAutoSize��Delphi��׼�Ĵ���AutoSize���Եĺ�����TWinControl�еı�׼ʵ���Ǽ��������ӿؼ��ĳߴ�߽磬
  //����Align����ΪalClientʱ�����ᴥ���˺�����ִ�У���ˣ�DDUIʹ��CalcSize����˺����Ĺ���
  Result := False;
end;

procedure TDUIBase.DoPaint(AGPCanvas: IGPGraphics);
begin
end;

procedure TDUIBase.DoPaintAfter(AGPCanvas: IGPGraphics);
begin
end;

procedure TDUIBase.DoParentChanged;
var
  ctl: TControl;
  i: Integer;
begin
  for i := 0 to ControlCount - 1 do
  begin
    ctl := Controls[i];
    if ctl is TDUIBase then
      TDUIBase(ctl).DoParentChanged;
  end;
end;

procedure TDUIBase.DefineProperties(AFiler: TFiler);
begin
  //���ε������е����Զ��壬������
  //TControl�е�IsControl��ExplicitLeft��ExplicitTop��ExplicitWidth��ExplicitHeight
  //TWinControl�е�DesignSize
end;

procedure TDUIBase.DoInitSkin;
begin
  if Assigned(FOnInitSkin) then
    FOnInitSkin(Self);
end;

procedure TDUIBase.AlignControls(AControl: TControl; var ARect: TRect);
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
      //TWinControl�����ϲ���ú���AlignControl�вŽ�csAlignmentNeeded״̬�Ƴ�
      //TDUIBase���˶����Ƶ������Ϊ�˱�֤enableControlsAlign���Դ����ӿؼ���AlignControl����
      ControlState := ControlState - [csAlignmentNeeded];
      enableControlsAlign(lstAlign);
      enableControlsAlign(lstAnchors);
    end;
  finally
    FreeAndNil(lstAlign);
    FreeAndNil(lstAnchors);
  end;
end;

function TDUIBase.IsTransparent: Boolean;
begin
  Result := False;
end;

procedure TDUIBase.Loaded;
begin
  inherited;

  //�����ؼ��ߴ�����¼���
  if AutoSize then
    SetBounds(Left, Top, Width, Height);
end;

procedure TDUIBase.PerformAsync(AMessage: Cardinal; AWParam, ALParam: Integer);
var
  wc: TWinControl;
begin
  wc := GetRootParent;
  if not Assigned(wc) then
    Exit;

  PostMessage(wc.Handle, DDUI_ASYNC_PERFORM,
    0, Integer(TDUIAsyncMessage.Create(Self, AMessage, AWParam, ALParam)));
end;

procedure TDUIBase.ReInitSkin;
var
  i: Integer;
begin
  for i := 0 to ControlCount - 1 do
    if Controls[i] is TDUIBase then
      TDUIBase(Controls[i]).ReInitSkin;

  DoInitSkin;

  Invalidate;
end;

procedure TDUIBase.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  iWidth, iHeight: Integer;
  objOwner: TComponent;
begin
  repeat
    if not AutoSize then
      Break;

    if (csLoading in ComponentState) or (csCreating in ControlState) then
      Break;

    objOwner := Owner;
    while Assigned(objOwner) do
    begin
      if csLoading in objOwner.ComponentState then
        Break;

      if (objOwner is TControl) and (csCreating in TControl(objOwner).ControlState) then
        Break;

      objOwner := objOwner.Owner;
    end;
    if Assigned(objOwner) then
      Break;

    //Delphi����AutoSize�ı�׼�����޷���ȷ����AlignKeepSize���ԣ�
    //��ˣ�����ʵ�ֳߴ��Զ����ŵ��߼���CanAutoSize����������
    if FAlignKeepSize or (Align <> alClient) then
    begin
      iWidth := AWidth;
      iHeight := AHeight;
      CalcSize(iWidth, iHeight);
      if FAlignKeepSize then
      begin
        AWidth := iWidth;
        AHeight := iHeight;
      end
      else
      begin
        if Align in [alNone, alLeft, alRight] then
          AWidth := iWidth;

        if Align in [alNone, alTop, alBottom] then
          AHeight := iHeight;
      end;
    end;
  until True;

  Invalidate; //ˢ��ԭ������ػ�(���ʱ�ؼ������Զ�����)
  inherited;
end;

function TDUIBase.GetHint: String;
begin
  Result := inherited Hint;
end;

procedure TDUIBase.SetHint(const AValue: String);
begin
  inherited Hint := AValue;
end;

procedure TDUIBase.SetAlignKeepSize(const AValue: Boolean);
begin
  if FAlignKeepSize = AValue then
    Exit;

  FAlignKeepSize := AValue;
  RequestAlign;
end;

procedure TDUIBase.SetAlignOrder(const AValue: Integer);
begin
  if FAlignOrder = AValue then
    Exit;

  FAlignOrder := AValue;
  RequestAlign;
end;

procedure TDUIBase.ValidateContainer(AComponent: TComponent);
begin
  if Assigned(AComponent) and not (AComponent is TDUIBase)
    and not (AComponent is TDUIForm) and not (AComponent is TDUIFrame)
    and not (AComponent is TDUIScrollControl) then
    raise Exception.Create('DUI�ؼ�ֻ����TDUIForm��ʹ��');

  inherited;
end;

{ TDUIAsyncMessage }

constructor TDUIAsyncMessage.Create(AControl: TDUIBase; AMessage: Cardinal; AWParam, ALParam: Integer);
begin
  inherited Create(nil);

  FControl := AControl;
  FMessage := AMessage;
  FWParam := AWParam;
  FLParam := ALParam;

  FControl.FreeNotification(Self);
end;

procedure TDUIAsyncMessage.Execute;
begin
  if Assigned(FControl) then
    FControl.Perform(FMessage, FWParam, FLParam);
end;

procedure TDUIAsyncMessage.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if AOperation = opRemove then
    if AComponent = FControl then
      FControl := nil;
end;

{ TDUIKeyboardBase }

{$IFDEF DESIGNTIME}

{$ELSE}

procedure TDUIKeyboardBase.KeyDown(var AKey: Word; AShift: TShiftState);
begin
  if Assigned(FOnKeyDown) then
    FOnKeyDown(Self, AKey, AShift);
end;

function TDUIKeyboardBase.DoKeyDown(var AMessage: TWMKey): Boolean;
begin
  Result := False;

  if csNoStdEvents in ControlStyle then
    Exit;

  KeyDown(AMessage.CharCode, KeyDataToShiftState(AMessage.KeyData));

  Result := AMessage.CharCode = 0;
end;

procedure TDUIKeyboardBase.WMKeyDown(var AMessage: TWMKeyDown);
begin
  if not DoKeyDown(AMessage) then
    inherited;
end;

procedure TDUIKeyboardBase.WMSysKeyDown(var AMessage: TWMKeyDown);
begin
  if not DoKeyDown(AMessage) then
    inherited;
end;

procedure TDUIKeyboardBase.KeyUp(var AKey: Word; AShift: TShiftState);
begin
  if Assigned(FOnKeyUp) then
    FOnKeyUp(Self, AKey, AShift);
end;

function TDUIKeyboardBase.DoKeyUp(var AMessage: TWMKey): Boolean;
begin
  Result := False;

  if csNoStdEvents in ControlStyle then
    Exit;

  KeyUp(AMessage.CharCode, KeyDataToShiftState(AMessage.KeyData));

  Result := AMessage.CharCode = 0;
end;

procedure TDUIKeyboardBase.WMKeyUp(var AMessage: TWMKeyUp);
begin
  if not DoKeyUp(AMessage) then
    inherited;
end;

procedure TDUIKeyboardBase.WMSysKeyUp(var AMessage: TWMKeyUp);
begin
  if not DoKeyUp(AMessage) then
    inherited;
end;

procedure TDUIKeyboardBase.KeyPress(var AKey: Char);
begin
  if Assigned(FOnKeyPress) then
    FOnKeyPress(Self, AKey);
end;

function TDUIKeyboardBase.DoKeyPress(var AMessage: TWMKey): Boolean;
var
  c: Char;
begin
  Result := False;

  if csNoStdEvents in ControlStyle then
    Exit;

  c := Char(AMessage.CharCode);
  KeyPress(c);
  AMessage.CharCode := Word(c);

  Result := c = #0;
end;

procedure TDUIKeyboardBase.WMChar(var AMessage: TWMChar);
begin
  if not DoKeyPress(AMessage) then
    inherited;
end;

procedure TDUIKeyboardBase.WMLButtonDown(var AMessage: TWMLButtonDown);
var
  wcParent: TWinControl;
begin
  inherited;

  wcParent := RootParent;
  if Assigned(wcParent) and (wcParent is TDUIForm) and CanFocus then
    TDUIForm(wcParent).SetDUIFocusedControl(Self);
end;

function TDUIKeyboardBase.CanFocus: Boolean;
var
  ctl: TDUIBase;
begin
  ctl := Self;
  while True do
  begin
    if not (ctl.Visible and ctl.Enabled) then
    begin
      Result := False;
      Exit;
    end;

    if not Assigned(ctl.DUIParent) then
      Break;

    ctl := ctl.DUIParent;
  end;

  Result := Assigned(ctl.Parent) and ctl.Parent.Visible and ctl.Parent.Enabled;  
end;

{$ENDIF}

end.
