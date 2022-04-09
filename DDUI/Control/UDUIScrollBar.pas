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
unit UDUIScrollBar;

interface

uses
  Windows, Classes, Forms, Controls, Messages, Consts, Math,
  IGDIPlus, UDUICore, UDUICoordinateTransform, UDUIGraphics;

type
  TDUIScrollBarArea = (sbaLineUp, sbaPageUp, sbaTracing, sbaPageDown, sbaLineDown, sbaNone);
  TDUIScrollBarAreaHeight = array[TDUIScrollBarArea] of Integer;
  TDUIScrollBar = class(TDUIBase)
  private
    FAngleBrush: TDUIBrush;
    FTracingBrush: TDUIBrush;
    FTimer: Pointer;
    FOriginalMouse: TDUICoord;
    FOriginalPosition: Integer;
    FArea: TDUIScrollBarArea;
    FKind: TScrollBarKind;
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FPageSize: Integer;
    FOnChange: TNotifyEvent;
    function CalcAreaHeight: TDUIScrollBarAreaHeight;
    function CoordToArea(ACoord: TDUICoord): TDUIScrollBarArea;
    procedure SetKind(AValue: TScrollBarKind);
    procedure SetMax(AValue: Integer);
    procedure SetMin(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    procedure SetPageSize(AValue: Integer);
    procedure WMTimer(var AMessage: TWMTimer); message WM_TIMER;
  protected
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseMove(AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateData(AMin, AMax, APosition, APageSize: Integer);
    property Area: TDUIScrollBarArea read FArea;
  published
    property Kind: TScrollBarKind read FKind write SetKind default sbVertical;
    property Max: Integer read FMax write SetMax default 100;
    property Min: Integer read FMin write SetMin default 0;
    property PageSize: Integer read FPageSize write SetPageSize;
    property Position: Integer read FPosition write SetPosition default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  UDUIForm;

{ TDUIScrollBar }

const
  GFold: array[TScrollBarKind] of TDUIMatrix = (
    ( //sbHorizontal 45度对折
      F00: 0; F10: 1;
      F01: 1; F11: 0
    ),
    ( //sbVertical 没有任何坐标转换
      F00: 1; F10: 0;
      F01: 0; F11: 1
    )
  );

constructor TDUIScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FAngleBrush := TDUIBrush.Create(Self, 'SCROLL.ANGLE');
  FTracingBrush := TDUIBrush.Create(Self, 'SCROLL.TRACING');

  ControlStyle := ControlStyle + [csCaptureMouse];

  FKind := sbVertical;
  SetBounds(0, 0, 10, 120);
  FMin := 0;
  FMax := 100;
  FPosition := 0;
  FPageSize := 10;
  FArea := sbaNone;
end;

procedure TDUIScrollBar.SetKind(AValue: TScrollBarKind);
begin
  if FKind = AValue then
    Exit;

  FKind := AValue;

  if not (csLoading in ComponentState) then
    SetBounds(Left, Top, Height, Width);
end;

procedure TDUIScrollBar.UpdateData(AMin, AMax, APosition, APageSize: Integer);
begin
  if (FMin = AMin) and (FMax = AMax) and (FPosition = APosition) and (FPageSize = APageSize) then
    Exit;

  if AMax < AMin then
    raise EInvalidOperation.Create(SScrollBarRange);

  if APosition > AMax - APageSize + 1 then
    APosition := AMax - APageSize + 1;
  if APosition < AMin then
    APosition := AMin;

  FMin := AMin;
  FMax := AMax;
  FPosition := APosition;
  FPageSize := APageSize;

  if Assigned(FOnChange) then
    FOnChange(Self);

  Invalidate;
end;

procedure TDUIScrollBar.SetMin(AValue: Integer);
begin
  UpdateData(AValue, FMax, FPosition, FPageSize);
end;

procedure TDUIScrollBar.SetMax(AValue: Integer);
begin
  UpdateData(FMin, AValue, FPosition, FPageSize);
end;

procedure TDUIScrollBar.SetPosition(AValue: Integer);
begin
  UpdateData(FMin, FMax, AValue, FPageSize);
end;

procedure TDUIScrollBar.SetPageSize(AValue: Integer);
begin
  UpdateData(FMin, FMax, FPosition, AValue);
end;

procedure TDUIScrollBar.DoPaint(AGPCanvas: IGPGraphics);
type
  TTransformType = (ttSpin0, ttSpin180);
const
  GSpin: array[TTransformType] of TDUIMatrix = (
    //旋转θ度，则新老坐标转换公式为
    //x1 = cos(θ) * x - sin(θ) * y
    //y1 = sin(θ) * x + cos(θ) * y
    ( //ttSpin0 旋转0度(没有任何坐标转换)
      F00: 1; F10: 0;
      F01: 0; F11: 1
    ),
    ( //ttSpin180 旋转180度
      F00: -1; F10: 0;
      F01: 0; F11: -1
    )
  );
  procedure drawAngle(const AAreaHeight: TDUIScrollBarAreaHeight; const ASize: TDUICoord);
  var
    cos: TDUICoords;
  begin
    cos := MakeDUICoords([0, - AAreaHeight[sbaLineUp] div 2,
      ASize.FWidth div 2, AAreaHeight[sbaLineUp] div 2,
      - ASize.FWidth div 2, AAreaHeight[sbaLineUp] div 2]);

    //绘制上移按钮(朝上的三角)
    AGPCanvas.FillPolygon(FAngleBrush, MakePoints(
      (cos * GSpin[ttSpin0] + MakeDUICoord(ASize.FWidth div 2, AAreaHeight[sbaLineUp] div 2))
      * GFold[FKind]));

    //绘制下移按钮(朝下的三角)
    AGPCanvas.FillPolygon(FAngleBrush, MakePoints(
      (cos * GSpin[ttSpin180] + MakeDUICoord(ASize.FWidth div 2, ASize.FHeight - AAreaHeight[sbaLineDown] div 2))
      * GFold[FKind]));
  end;
  procedure drawTracing(const AAreaHeight: TDUIScrollBarAreaHeight; const ASize: TDUICoord);
  const
    CAngle: array[TScrollBarKind] of Single = (-90.0, 0.0);
  var
    cos: TDUICoords;
  begin
    //绘制当前位置的矩形框
    if AAreaHeight[sbaTracing] <= ASize.FWidth then
    begin
      cos := MakeDUICoords([0, AAreaHeight[sbaLineUp] + AAreaHeight[sbaPageUp],
        ASize.FWidth, AAreaHeight[sbaTracing]]) * GFold[FKind];
      AGPCanvas.FillEllipse(FTracingBrush,
        cos.FCoords[0].FLeft, cos.FCoords[0].FTop,
        cos.FCoords[1].FWidth, cos.FCoords[1].FHeight);
    end
    else
    begin
      cos := MakeDUICoords([0, AAreaHeight[sbaLineUp] + AAreaHeight[sbaPageUp],
        ASize.FWidth, ASize.FWidth]) * GFold[FKind];
      AGPCanvas.FillPie(FTracingBrush, MakeGPRect(cos), -180.0 + CAngle[FKind], 180.0);

      cos := MakeDUICoords([1, AAreaHeight[sbaLineUp] + AAreaHeight[sbaPageUp] + ASize.FWidth div 2,
        ASize.FWidth - 1, AAreaHeight[sbaTracing] - ASize.FWidth]) * GFold[FKind];
      AGPCanvas.FillRectangle(FTracingBrush, MakeGPRect(cos));

      cos := MakeDUICoords([0, AAreaHeight[sbaLineUp] + AAreaHeight[sbaPageUp] + AAreaHeight[sbaTracing] - ASize.FWidth,
        ASize.FWidth, ASize.FWidth]) * GFold[FKind];
      AGPCanvas.FillPie(FTracingBrush, MakeGPRect(cos), CAngle[FKind], 180.0);
    end;
  end;
var
  sbah: TDUIScrollBarAreaHeight;
  siSize: TDUICoord;
begin
  sbah := CalcAreaHeight;
  siSize := MakeDUICoord(Width, Height) * GFold[FKind];

  drawAngle(sbah, siSize);
  drawTracing(sbah, siSize);
end;

function TDUIScrollBar.CalcAreaHeight: TDUIScrollBarAreaHeight;
var
  siSize: TDUICoord;
  iHeight, iTop, iPageSize, iBottom: Integer;
begin
  siSize := MakeDUICoord(Width, Height) * GFold[FKind];

  Result[sbaNone] := 0;

  if siSize.FHeight < 2 * siSize.FWidth then
  begin
    Result[sbaLineUp] := siSize.FHeight div 2;
    Result[sbaLineDown] := siSize.FHeight div 2;
  end
  else
  begin
    Result[sbaLineUp] := siSize.FWidth;
    Result[sbaLineDown] := siSize.FWidth;
  end;

  if (siSize.FHeight < 2 * siSize.FWidth) or (FMin >= FMax) then
  begin
    Result[sbaPageUp] := 0;
    Result[sbaPageDown] := 0;
  end
  else
  begin
    iHeight := siSize.FHeight - Result[sbaLineUp] - Result[sbaLineDown];
    iTop := FPosition - FMin;
    iPageSize := IfThen(FPosition + FPageSize > FMax, FMax - FPosition, FPageSize);
    iBottom := (FMax - FPosition) - iPageSize;

    Result[sbaPageUp] := iTop * iHeight div (FMax - FMin);
    Result[sbaPageDown] := iBottom * iHeight div (FMax - FMin);
  end;

  Result[sbaTracing] := siSize.FHeight - Result[sbaLineUp] - Result[sbaLineDown]
    - Result[sbaPageUp] - Result[sbaPageDown];
end;

function TDUIScrollBar.CoordToArea(ACoord: TDUICoord): TDUIScrollBarArea;
var
  iPos, iTop: Integer;
  sbah: TDUIScrollBarAreaHeight;
begin
  iPos := 0;
  iTop := (ACoord * GFold[FKind]).FTop;
  sbah := CalcAreaHeight;
  for Result := Low(TDUIScrollBarArea) to High(TDUIScrollBarArea) do
  begin
    if (iPos <= iTop) and (iPos + sbah[Result] > iTop) then
      Exit;

    Inc(iPos, sbah[Result]);
  end;

  Result := sbaNone;
end;

procedure TDUIScrollBar.WMTimer(var AMessage: TWMTimer);
  function coordToPosition(ACoord: TDUICoord): Integer;
  var
    siCoord, siSize: TDUICoord;
  begin
    siCoord := ACoord * GFold[FKind];
    siSize := MakeDUICoord(Width, Height) * GFold[FKind];
    if siSize.FHeight = 0 then
      Result := FMin
    else
      Result := FMin + (FMax - FMin) * siCoord.FTop div siSize.FHeight;
  end;
var
  iPosition: Integer;
  iPageSize: Integer;
begin
  case FArea of
    sbaLineUp: SetPosition(FPosition - 1);
    sbaLineDown: SetPosition(FPosition + 1);
    sbaPageUp:
    begin
      iPosition := coordToPosition(ScreenToClient(Mouse.CursorPos));
      iPageSize := IfThen(FPageSize < 1, 1, FPageSize);
      SetPosition(IfThen(FPosition - iPageSize < iPosition, iPosition, FPosition - iPageSize));
    end;
    sbaPageDown:
    begin
      iPosition := coordToPosition(ScreenToClient(Mouse.CursorPos));
      iPageSize := IfThen(FPageSize < 1, 1, FPageSize);
      SetPosition(IfThen(FPosition + iPageSize > iPosition, iPosition, FPosition + iPageSize));
    end;
  end;
end;

procedure TDUIScrollBar.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  FOriginalMouse := MakeDUICoord(AX, AY);
  FOriginalPosition := FPosition;
  FArea := CoordToArea(FOriginalMouse);
  if not (FArea in [sbaNone, sbaTracing]) then
    FTimer := TDUIForm(RootParent).SetDUITimer(Self, 100, True);

  inherited;
end;

procedure TDUIScrollBar.MouseMove(AShift: TShiftState; AX, AY: Integer);
var
  sbah: TDUIScrollBarAreaHeight;
  iHeight: Integer;
  coDelta: TDUICoord;
begin
  if FArea = sbaTracing then
  begin
    sbah := CalcAreaHeight;
    iHeight := sbah[sbaPageUp] + sbah[sbaTracing] + sbah[sbaPageDown];
    if iHeight <> 0 then
    begin
      coDelta := (MakeDUICoord(AX, AY) - FOriginalMouse) * GFold[FKind];
      SetPosition(FOriginalPosition + coDelta.FTop * (FMax - FMin) div iHeight);
    end;
  end;

  inherited;
end;

procedure TDUIScrollBar.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  if Assigned(FTimer) then
  begin
    TDUIForm(RootParent).KillDUITimer(FTimer);
    FTimer := nil;
  end;

  FArea := sbaNone;

  inherited;
end;

end.
