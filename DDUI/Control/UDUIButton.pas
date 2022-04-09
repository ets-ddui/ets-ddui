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
unit UDUIButton;

interface

uses
  Windows, Classes, SysUtils, Controls, Messages, Math, IGDIPlus,
  UDUICore, UDUIGraphics, UDUIShape, UDUILabel;

type
  TButtonStatus = (bsDown, bsHover);
  TButtonStatusSet = set of TButtonStatus;
  TDUIButtonBase = class(TDUIBase)
  private
    FLabel: TDUILabel;
    FShape: TDUIShape;
    FStatus: TButtonStatusSet;
    function CreateShape: TDUIShape;
    function GetBrushText: TDUIBrush;
    procedure SetBrushText(const AValue: TDUIBrush);
    function GetFont: TDUIFont;
    procedure SetFont(const AValue: TDUIFont);
    function GetTextAlign: TAlign;
    procedure SetTextAlign(const AValue: TAlign);
    procedure CMTextChanged(var AMessage: TMessage); message CM_TEXTCHANGED;
    procedure CMEnabledChanged(var AMessage: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure IncludeStatus(AStatus: TButtonStatus); virtual;
    procedure ExcludeStatus(AStatus: TButtonStatus); virtual;
    procedure WriteState(AWriter: TWriter); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Status: TButtonStatusSet read FStatus;
  published
    property BrushText: TDUIBrush read GetBrushText write SetBrushText;
    property Font: TDUIFont read GetFont write SetFont;
    property Shape: TDUIShape read FShape;
    property TextAlign: TAlign read GetTextAlign write SetTextAlign default alBottom;
    property Caption;
    property Enabled;
    property Height default 80;
    property Width default 80;
    property OnClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TDUIButton = class(TDUIButtonBase)
  private
    FBrushs: array[1..2] of TDUIBrush;
    procedure CMMouseEnter(var AMessage: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMessage: TMessage); message CM_MOUSELEAVE;
    function GetBrush(const AIndex: Integer): TDUIBrush;
    procedure SetBrush(const AIndex: Integer; const AValue: TDUIBrush);
  protected
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BrushPress: TDUIBrush index 1 read GetBrush write SetBrush;
    property BrushHover: TDUIBrush index 2 read GetBrush write SetBrush;
    property ShowHint;
  end;

  TDUISpeedButton = class(TDUIButton)
  private
    FGroupIndex: Integer;
    procedure SetGroupIndex(const AValue: Integer);
    function GetSiblingCount: Integer;
    function GetSibling(AIndex: Integer): TControl;
    procedure ExcludeSiblingStatus(AStatus: TButtonStatus);
    property SiblingCount: Integer read GetSiblingCount;
    property Sibling[AIndex: Integer]: TControl read GetSibling;
  protected
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
  published
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex;
  end;

  TOnChangingEvent = procedure(ASender: TObject; AOldIndex, ANewIndex: Integer; var ACanChange: Boolean) of object;
  TOnChangedEvent = procedure(ASender: TObject; AOldIndex, ANewIndex: Integer) of object;

  TDUIButtonList = class(TDUIBase)
  private
    FItems: TStringList;
    FButtonWidth: Integer;
    FActiveButtonIndex: Integer;
    FOnChanging: TOnChangingEvent;
    FOnChanged: TOnChangedEvent;
    FTextAlign: TAlign;
    procedure DoMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure SetButtonWidth(const AValue: Integer);
    procedure SetActiveButtonIndex(const AValue: Integer);
    procedure SetTextAlign(const AValue: TAlign);
    function GetButtonCount: Integer;
    function GetButton(AIndex: Integer): TDUISpeedButton;
  protected
    function IsTransparent: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddButton(ACaption: String; AImage: IGPImage = nil): Integer;
    procedure DelButton(AIndex: Integer);
    function IndexOf(AButton: TDUISpeedButton): Integer;
    procedure InsertButton(AIndex: Integer; ACaption: String; AImage: IGPImage = nil);
    procedure Clear;
    property Button[AIndex: Integer]: TDUISpeedButton read GetButton; default;
    property ButtonCount: Integer read GetButtonCount;
  published
    property ActiveButtonIndex: Integer read FActiveButtonIndex write SetActiveButtonIndex default -1;
    property ButtonWidth: Integer read FButtonWidth write SetButtonWidth default 80;
    property TextAlign: TAlign read FTextAlign write SetTextAlign default alBottom;
    property Height default 80;
    property Width default 240;
    property OnChanging: TOnChangingEvent read FOnChanging write FOnChanging;
    property OnChanged: TOnChangedEvent read FOnChanged write FOnChanged;
  end;

implementation

uses
  UDUIUtils;

{ TDUIButtonBase }

constructor TDUIButtonBase.Create(AOwner: TComponent);
begin
  DisableAlign;

  inherited;

  FLabel := TDUILabel.Create(Self);
  FLabel.DUIParent := Self;
  FLabel.HAlign := taCenter;
  FLabel.Visible := False;
  FLabel.WordWrap := True;

  FShape := CreateShape;
  FShape.DUIParent := Self;
  FShape.SetSubComponent(True);

  SetTextAlign(alBottom);
  SetBounds(0, 0, 80, 80);

  EnableAlign;
end;

function TDUIButtonBase.CreateShape: TDUIShape;
begin
  Result := TDUIShape.Create(Self);
  Result.AlignKeepSize := True;
  Result.SetBounds(0, 0, 50, 50);
  Result.Align := alClient;
end;

procedure TDUIButtonBase.CMEnabledChanged(var AMessage: TMessage);
begin
  inherited;

  FLabel.Enabled := Enabled;
  FShape.Enabled := Enabled;
end;

procedure TDUIButtonBase.CMTextChanged(var AMessage: TMessage);
begin
  DisableAlign;
  try
    FLabel.Caption := Caption;
    FLabel.Visible := FLabel.Caption <> '';
  finally
    EnableAlign;
  end;
end;

procedure TDUIButtonBase.ExcludeStatus(AStatus: TButtonStatus);
begin
  if not (AStatus in FStatus) then
    Exit;

  Exclude(FStatus, AStatus);
  Invalidate;
end;

procedure TDUIButtonBase.IncludeStatus(AStatus: TButtonStatus);
begin
  if AStatus in FStatus then
    Exit;

  Include(FStatus, AStatus);
  Invalidate;
end;

procedure TDUIButtonBase.WriteState(AWriter: TWriter);
var
  sha: TDUIShape;
begin
  TWriterHook.Hook;
  try
    sha := CreateShape;
    sha.SetBounds(FShape.Left, FShape.Top, sha.Width, sha.Height);
    TWriterHook.RegisterComponent(FShape, sha); //sha的所有权会转移，无需释放
    inherited;
  finally
    TWriterHook.UnHook;
    TWriterHook.UnRegisterComponent(FShape);
  end;
end;

function TDUIButtonBase.GetBrushText: TDUIBrush;
begin
  Result := FLabel.TextBrush;
end;

procedure TDUIButtonBase.SetBrushText(const AValue: TDUIBrush);
begin
  FLabel.TextBrush := AValue;;
end;

function TDUIButtonBase.GetFont: TDUIFont;
begin
  Result := FLabel.Font;
end;

procedure TDUIButtonBase.SetFont(const AValue: TDUIFont);
begin
  FLabel.Font := AValue;
end;

function TDUIButtonBase.GetTextAlign: TAlign;
begin
  Result := FLabel.Align;
end;

procedure TDUIButtonBase.SetTextAlign(const AValue: TAlign);
begin
  FLabel.Align := AValue;
end;

{ TDUIButton }

procedure TDUIButton.CMMouseEnter(var AMessage: TMessage);
begin
  inherited;

  IncludeStatus(bsHover);
end;

procedure TDUIButton.CMMouseLeave(var AMessage: TMessage);
begin
  inherited;

  ExcludeStatus(bsHover);
end;

constructor TDUIButton.Create(AOwner: TComponent);
begin
  inherited;

  FBrushs[1] := TDUIBrush.Create(Self, 'BUTTON.PRESS');
  FBrushs[2] := TDUIBrush.Create(Self, 'BUTTON.HOVER');

  ControlStyle := ControlStyle + [csCaptureMouse];
end;

procedure TDUIButton.DoPaint(AGPCanvas: IGPGraphics);
begin
  if bsDown in FStatus then
    AGPCanvas.FillRectangle(FBrushs[1], MakeRect(0, 0, Width, Height))
  else if bsHover in FStatus then
    AGPCanvas.FillRectangle(FBrushs[2], MakeRect(0, 0, Width, Height));

  inherited;
end;

function TDUIButton.GetBrush(const AIndex: Integer): TDUIBrush;
begin
  Result := FBrushs[AIndex];
end;

procedure TDUIButton.MouseDown(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  inherited;

  IncludeStatus(bsDown);
end;

procedure TDUIButton.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  inherited;

  ExcludeStatus(bsDown);
end;

procedure TDUIButton.SetBrush(const AIndex: Integer; const AValue: TDUIBrush);
begin
  FBrushs[AIndex].Assign(AValue);
  Invalidate;
end;

{ TDUISpeedButton }

{$IFDEF DESIGNTIME}

function TDUISpeedButton.GetSibling(AIndex: Integer): TControl;
begin
  if Assigned(Parent) then
    Result := Parent.Controls[AIndex]
  else
    Result := nil;
end;

function TDUISpeedButton.GetSiblingCount: Integer;
begin
  if Assigned(Parent) then
    Result := Parent.ControlCount
  else
    Result := 0;
end;

{$ELSE}

function TDUISpeedButton.GetSibling(AIndex: Integer): TControl;
begin
  if Assigned(DUIParent) then
    Result := DUIParent.Controls[AIndex]
  else if Assigned(Parent) then
    Result := Parent.Controls[AIndex]
  else
    Result := nil;
end;

function TDUISpeedButton.GetSiblingCount: Integer;
begin
  if Assigned(DUIParent) then
    Result := DUIParent.ControlCount
  else if Assigned(Parent) then
    Result := Parent.ControlCount
  else
    Result := 0;
end;

{$ENDIF}

procedure TDUISpeedButton.ExcludeSiblingStatus(AStatus: TButtonStatus);
var
  i: Integer;
  ctl: TControl;
begin
  if FGroupIndex = 0 then
    Exit;

  for i := 0 to SiblingCount - 1 do
  begin
    ctl := Sibling[i];

    if ctl = Self then
      Continue;

    if not (ctl is TDUISpeedButton) then
      Continue;

    if TDUISpeedButton(ctl).GroupIndex <> FGroupIndex then
      Continue;

    TDUIButtonBase(ctl).ExcludeStatus(AStatus);
  end;
end;

procedure TDUISpeedButton.MouseUp(AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  inherited;

  if PtInRect(ClientRect, Point(AX, AY)) then
  begin
    IncludeStatus(bsDown);
    ExcludeSiblingStatus(bsDown);
  end;
end;

procedure TDUISpeedButton.SetGroupIndex(const AValue: Integer);
begin
  if FGroupIndex = AValue then
    Exit;

  FGroupIndex := AValue;
  if bsDown in Status then
    ExcludeSiblingStatus(bsDown);
end;

{ TDUIButtonList }

constructor TDUIButtonList.Create(AOwner: TComponent);
begin
  inherited;

  FItems := TStringList.Create;

  FActiveButtonIndex := -1;
  FButtonWidth := 80;
  FTextAlign := alBottom;
  SetBounds(0, 0, 240, 80);
end;

destructor TDUIButtonList.Destroy;
begin
  FreeAndNil(FItems);

  inherited;
end;

procedure TDUIButtonList.DoMouseUp(ASender: TObject; AButton: TMouseButton;
  AShift: TShiftState; AX, AY: Integer);
var
  iNewIndex: Integer;
begin
  if AButton <> mbLeft then
    Exit;

  if not (bsDown in TDUISpeedButton(ASender).Status) then
    Exit;

  iNewIndex := FItems.IndexOfObject(ASender);
  if iNewIndex < 0 then
    Exit;

  if PtInRect(TDUISpeedButton(ASender).ClientRect, Point(AX, AY)) then
    SetActiveButtonIndex(iNewIndex);

  //如果ActiveButtonIndex同步失败，则需回退TDUIButtonBase.Click中设置的按钮状态
  if iNewIndex <> FActiveButtonIndex then
  begin
    TDUISpeedButton(ASender).ExcludeStatus(bsDown);
    Abort; //跳过TDUISpeedButton.MouseUp的后续处理(即不将bsDown状态切换到当前按钮)
  end;
end;

function TDUIButtonList.GetButton(AIndex: Integer): TDUISpeedButton;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Result := nil
  else
    Result := TDUISpeedButton(FItems.Objects[AIndex]);
end;

function TDUIButtonList.GetButtonCount: Integer;
begin
  Result := FItems.Count;
end;

function TDUIButtonList.IndexOf(AButton: TDUISpeedButton): Integer;
begin
  for Result := 0 to FItems.Count - 1 do
    if FItems.Objects[Result] = AButton then
      Exit;

  Result := -1;
end;

procedure TDUIButtonList.InsertButton(AIndex: Integer; ACaption: String; AImage: IGPImage);
var
  btn: TDUISpeedButton;
begin
  btn := TDUISpeedButton.Create(Self);

  FItems.InsertObject(AIndex, ACaption, btn);

  btn.DUIParent := Self;
  btn.Align := alLeft;
  btn.Width := FButtonWidth;
  btn.Left := FButtonWidth * FItems.Count;
  btn.Caption := ACaption;
  btn.GroupIndex := 1;
  btn.TextAlign := FTextAlign;
  btn.Shape.Picture.Image := AImage;
  btn.OnMouseUp := DoMouseUp;
end;

function TDUIButtonList.IsTransparent: Boolean;
begin
  Result := True;
end;

function TDUIButtonList.AddButton(ACaption: String; AImage: IGPImage): Integer;
begin
  Result := FItems.Count;
  InsertButton(Result, ACaption, AImage);
end;

procedure TDUIButtonList.DelButton(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  FItems.Objects[AIndex].Free;
  FItems.Delete(AIndex);

  for AIndex := AIndex to FItems.Count - 1 do
    TDUISpeedButton(FItems.Objects[AIndex]).Left := AIndex * FButtonWidth;

  if FActiveButtonIndex >= FItems.Count then
    SetActiveButtonIndex(-1);
end;

procedure TDUIButtonList.Clear;
var
  i: Integer;
begin
  for i := FItems.Count - 1 downto 0 do
    FItems.Objects[i].Free;
  FItems.Clear;
  SetActiveButtonIndex(-1);
end;

procedure TDUIButtonList.SetActiveButtonIndex(const AValue: Integer);
var
  bCanChange: Boolean;
  iOldIndex: Integer;
begin
  if AValue = FActiveButtonIndex then
    Exit;

  //-1表示没有选中任何按钮
  if (AValue < -1) or (AValue >= FItems.Count) then
    raise Exception.Create('入参不合法');

  bCanChange := True;
  if Assigned(FOnChanging) then
    FOnChanging(Self, FActiveButtonIndex, AValue, bCanChange);

  if not bCanChange then
    Exit;

  if (FActiveButtonIndex >= 0) and (FActiveButtonIndex < FItems.Count) then
    TDUISpeedButton(FItems.Objects[FActiveButtonIndex]).ExcludeStatus(bsDown);

  if (AValue >= 0) and (AValue < FItems.Count) then
    TDUISpeedButton(FItems.Objects[AValue]).IncludeStatus(bsDown);

  iOldIndex := FActiveButtonIndex;
  FActiveButtonIndex := AValue;

  if Assigned(FOnChanged) then
    FOnChanged(Self, iOldIndex, AValue);
end;

procedure TDUIButtonList.SetButtonWidth(const AValue: Integer);
var
  i: Integer;
begin
  if AValue < 0 then
    Exit;

  FButtonWidth := AValue;
  for i := FItems.Count - 1 downto 0 do
  begin
    TDUISpeedButton(FItems.Objects[i]).Left := i * FButtonWidth;
    TDUISpeedButton(FItems.Objects[i]).Width := FButtonWidth;
  end;
end;

procedure TDUIButtonList.SetTextAlign(const AValue: TAlign);
var
  i: Integer;
begin
  if FTextAlign = AValue then
    Exit;

  FTextAlign := AValue;
  for i := FItems.Count - 1 downto 0 do
    TDUISpeedButton(FItems.Objects[i]).TextAlign := FTextAlign;
end;

end.
