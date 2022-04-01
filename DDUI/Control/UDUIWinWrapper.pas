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
unit UDUIWinWrapper;

interface

uses
  Windows, Classes, SysUtils, Controls, Forms, Messages, Graphics,
  IGDIPlus, UDUICore;

type
  TDUIWinBase = class(TDUIKeyboardBase)
  {$IFDEF DESIGNTIME}
  {$ELSE}
  private
    FOldWinControlWndProc: TWndMethod;
    procedure WinControlWndProc(var AMessage: TMessage);
    procedure CMEnabledChanged(var AMessage: TMessage); message CM_ENABLEDCHANGED;
    procedure CMVisibleChanged(var AMessage: TMessage); message CM_VISIBLECHANGED;
  protected
    procedure WndProc(var AMessage: TMessage); override;
    procedure DoParentChanged; override;
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
  {$ENDIF}
  private
    FAutoHide: Boolean;
    FWinControl: TWinControl;
  protected
    function GetWinControlClass: TWinControlClass; virtual; abstract;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateNew(AOwner: TComponent; AAutoHide: Boolean); reintroduce;
    destructor Destroy; override;
    property AutoHide: Boolean read FAutoHide;
    property WinControl: TWinControl read FWinControl;
  end;

  TDUIWinContainer = class(TDUIWinBase)
  {$IFDEF DESIGNTIME}
  private
    FCanvas: TCanvas;
    procedure CMControlListChanging(var AMessage: TMessage); message CM_CONTROLLISTCHANGING;
  protected
    procedure PaintWindow(ADC: HDC); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  {$ELSE}
  protected
    function GetChildParent: TComponent; override;
  {$ENDIF}
  private
    procedure CMColorChanged(var AMessage: TMessage); message CM_COLORCHANGED;
  protected
    function GetWinControlClass: TWinControlClass; override;
  published
    property Color;
  end;

implementation

uses
  UDUIForm;

type
  TDUIWinFrame = class(TWinControl)
  private
    FCanvas: TCanvas;
    procedure WMPaint(var AMessage: TWMPaint); message WM_PAINT;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure PaintWindow(ADC: HDC); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

{ TDUIWinBase }

{$IFDEF DESIGNTIME}

constructor TDUIWinBase.CreateNew(AOwner: TComponent; AAutoHide: Boolean);
begin
  inherited Create(AOwner);

  FAutoHide := AAutoHide;
  FWinControl := GetWinControlClass.Create(nil);
  FWinControl.FreeNotification(Self);
  FWinControl.SetBounds(0, 0, Width, Height);
end;

{$ELSE}

constructor TDUIWinBase.CreateNew(AOwner: TComponent; AAutoHide: Boolean);
begin
  inherited Create(AOwner);

  FAutoHide := AAutoHide;
  FWinControl := GetWinControlClass.Create(AOwner);
  FWinControl.FreeNotification(Self);
  if FAutoHide then
    FWinControl.Visible := False;
  FWinControl.SetBounds(0, 0, Width, Height);
  FOldWinControlWndProc := FWinControl.WindowProc;
  FWinControl.WindowProc := WinControlWndProc;
end;

procedure TDUIWinBase.WinControlWndProc(var AMessage: TMessage);
var
  wcParent: TWinControl;
begin
  case AMessage.Msg of
    WM_GETDLGCODE:
    begin
      AMessage.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS;
      Exit;
    end;
    //FWinControl�ϴ����ļ�����Ϣ����ת���������ڣ������ڻ��Զ�����TAB�л��¼���
    //��������ٽ���Ϣת����TDUIWinBase.WndProc��
    //�����߽���Ϣ���͸�FWinControl��������Ϣ������
    WM_KEYFIRST..WM_KEYLAST:
    begin
      wcParent := RootParent;
      if Assigned(wcParent) then
        AMessage.Result := wcParent.Perform(AMessage.Msg, AMessage.WParam, AMessage.LParam);

      Exit;
    end;
    WM_SETFOCUS:
    begin
      wcParent := RootParent;
      if Assigned(wcParent) and (wcParent is TDUIForm) then
        TDUIForm(wcParent).SetDUIFocusedControl(Self);
    end;
  end;

  if Assigned(FWinControl) then
    FOldWinControlWndProc(AMessage);
end;

procedure TDUIWinBase.WndProc(var AMessage: TMessage);
var
  ptLeftTop: TPoint;
begin
  case AMessage.Msg of
    WM_GETDLGCODE:
    begin
      if Assigned(FWinControl) then
        FOldWinControlWndProc(AMessage);

      Exit;
    end;
    WM_KEYFIRST..WM_KEYLAST:
    begin
      if Assigned(FWinControl) then
        FOldWinControlWndProc(AMessage);

      Exit;
    end;
    WM_SETFOCUS:
    begin
      if Assigned(FWinControl) then
      begin
        if FAutoHide then
          FWinControl.Visible := True;

        if not FWinControl.Focused and FWinControl.CanFocus
          and not FWinControl.ContainsControl(FindControl(GetFocus)) then
          FWinControl.SetFocus;
      end;

      Exit;
    end;
    WM_KILLFOCUS:
    begin
      if Assigned(FWinControl) then
      begin
        if FAutoHide then
          FWinControl.Visible := False;
      end;
    end;
    WM_WINDOWPOSCHANGED:
    begin
      if Assigned(FWinControl) then
      begin
        if Assigned(FWinControl.Parent) then
        begin
          ptLeftTop := ClientToScreen(Point(0, 0));
          ptLeftTop := FWinControl.Parent.ScreenToClient(ptLeftTop);
          FWinControl.SetBounds(ptLeftTop.X, ptLeftTop.Y, Width, Height);
        end
        else
          FWinControl.SetBounds(FWinControl.Left, FWinControl.Top, Width, Height);
      end;
    end;
  end;

  inherited;
end;

procedure TDUIWinBase.CMEnabledChanged(var AMessage: TMessage);
begin
  inherited;

  if Assigned(FWinControl) then
    FWinControl.Enabled := Enabled;
end;

procedure TDUIWinBase.CMVisibleChanged(var AMessage: TMessage);
var
  ctl: TDUIBase;
begin
  inherited;

  if not Assigned(FWinControl) then
    Exit;

  ctl := Self;
  while Assigned(ctl) do
  begin
    if not ctl.Visible then
    begin
      FWinControl.Visible := False;
      Exit;
    end;

    ctl := ctl.DUIParent;
  end;

  if not FAutoHide then
    FWinControl.Visible := True;
end;

procedure TDUIWinBase.DoParentChanged;
var
  ctl: TDUIBase;
begin
  inherited;

  if not Assigned(FWinControl) then
    Exit;

  ctl := Self;
  while Assigned(ctl.DUIParent) do
    ctl := ctl.DUIParent;

  if FWinControl.Parent <> ctl.Parent then
  begin
    FWinControl.Parent := ctl.Parent;
    Perform(WM_WINDOWPOSCHANGED, 0, 0);
  end;
end;

procedure TDUIWinBase.DoPaint(AGPCanvas: IGPGraphics);
begin
  inherited;

  //������ؼ�������Left��Top�����仯�������ᴥ��Resize�¼�����FFrame�ĳߴ�ʵ���Ѿ������仯
  //��ˣ������Ϊ���DoPaint
  Perform(WM_WINDOWPOSCHANGED, 0, 0);
end;

{$ENDIF}

constructor TDUIWinBase.Create(AOwner: TComponent);
begin
  CreateNew(AOwner, False);
end;

destructor TDUIWinBase.Destroy;
begin
  if Assigned(FWinControl) then
  begin
    FWinControl.RemoveFreeNotification(Self);
    FreeAndNil(FWinControl);
  end;

  inherited;
end;

procedure TDUIWinBase.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if (AOperation = opRemove) and (FWinControl = AComponent) then
    FWinControl := nil;
end;

{ TDUIWinContainer }

{$IFDEF DESIGNTIME}

constructor TDUIWinContainer.Create(AOwner: TComponent);
begin
  inherited;

  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
end;

destructor TDUIWinContainer.Destroy;
begin
  FreeAndNil(FCanvas);

  inherited;
end;

procedure TDUIWinContainer.CMControlListChanging(var AMessage: TMessage);
var
  cli: PControlListItem;
begin
  if Boolean(AMessage.LParam) then //True��ʾ�����ؼ���False��ʾɾ���ؼ�
  begin
    cli := PControlListItem(AMessage.WParam);
    if cli.Control is TDUIBase then
      raise Exception.Create('TDUIWinWrapper�в��������DUI�ؼ�');
  end;
end;

procedure TDUIWinContainer.PaintWindow(ADC: HDC);
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

function TDUIWinContainer.GetChildParent: TComponent;
begin
  Result := WinControl;
end;

{$ENDIF}

procedure TDUIWinContainer.CMColorChanged(var AMessage: TMessage);
begin
  inherited;
  TDUIWinFrame(FWinControl).Color := Color;
end;

function TDUIWinContainer.GetWinControlClass: TWinControlClass;
begin
  Result := TDUIWinFrame;
end;

{ TDUIWinFrame }

constructor TDUIWinFrame.Create(AOwner: TComponent);
begin
  inherited;

  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
end;

destructor TDUIWinFrame.Destroy;
begin
  FreeAndNil(FCanvas);

  inherited;
end;

procedure TDUIWinFrame.WMPaint(var AMessage: TWMPaint);
begin
  ControlState := ControlState + [csCustomPaint]; //����csCustomPaint��TWinControl�ᴥ��PaintWindow�ĵ���
  inherited;
  ControlState := ControlState - [csCustomPaint];
end;

procedure TDUIWinFrame.CreateParams(var AParams: TCreateParams);
begin
  inherited;

  if Parent = nil then
    AParams.WndParent := Application.Handle;
end;

procedure TDUIWinFrame.PaintWindow(ADC: HDC);
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

procedure TDUIWinFrame.SetParent(AParent: TWinControl);
begin
  if Parent = AParent then
    Exit;

  if not HandleAllocated then
  begin
    inherited;
    Exit;
  end;

  UpdateRecreatingFlag(True);
  try
    if Parent = nil then
      DestroyHandle;

    inherited;
  finally
    UpdateRecreatingFlag(False);
  end;
end;

end.
