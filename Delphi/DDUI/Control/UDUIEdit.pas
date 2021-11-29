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
unit UDUIEdit;

interface

uses
  Windows, Classes, Controls, StdCtrls, Messages, IGDIPlus, UDUIWinWrapper, UDUIGraphics;

type
  TDUIEdit = class(TDUIWinBase)
  private
    FFont: TDUIFont;
    FTextBrush: TDUIBrush;
    FHintBrush: TDUIBrush;
    FStringFormat: IGPStringFormat;
    FLinePen: TDUIPen;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyDown: TKeyEvent;
    FOnChange: TNotifyEvent;
    FOnKeyUp: TKeyEvent;
    FArcBorder: Boolean;
    procedure DoChange(ASender: TObject);
    procedure DoKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure DoKeyPress(ASender: TObject; var AKey: Char);
    procedure DoKeyUp(ASender: TObject; var AKey: Word; AShift: TShiftState);
    function GetEdit: TEdit;
    function GetMaxLength: Integer;
    function GetPasswordChar: Char;
    function GetReadOnly: Boolean;
    procedure SetMaxLength(const AValue: Integer);
    procedure SetPasswordChar(const AValue: Char);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetArcBorder(const AValue: Boolean);
  protected
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    function GetWinControlClass: TWinControlClass; override;
    procedure SetHint(const AValue: String); override;
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ArcBorder: Boolean read FArcBorder write SetArcBorder default True;
    property MaxLength: Integer read GetMaxLength write SetMaxLength default 0;
    property PasswordChar: Char read GetPasswordChar write SetPasswordChar default #0;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ShowHint;
    property Text;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
  end;

implementation

type
  TInnerEdit = class(TEdit)
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
  end;

{ TInnerEdit }

procedure TInnerEdit.CreateParams(var AParams: TCreateParams);
begin
  inherited;

  with AParams do
  begin
    Style := Style and not WS_BORDER;
    ExStyle := ExStyle and not WS_EX_CLIENTEDGE;
  end;
end;

{ TDUIEdit }

constructor TDUIEdit.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, True);

  FArcBorder := True;

  SetBounds(0, 0, 121, 25);

  GetEdit.AutoSize := False;
  GetEdit.OnChange := DoChange;
  GetEdit.OnKeyDown := DoKeyDown;
  GetEdit.OnKeyPress := DoKeyPress;
  GetEdit.OnKeyUp := DoKeyUp;

  FStringFormat := TGPStringFormat.Create;
  FStringFormat.SetAlignment(StringAlignmentNear);
  FStringFormat.SetLineAlignment(StringAlignmentCenter);

  FFont := TDUIFont.Create(Self, 'EDIT.TEXT');
  FTextBrush := TDUIBrush.Create(Self, 'EDIT.TEXT');
  FHintBrush := TDUIBrush.Create(Self, 'EDIT.HINT');
  FLinePen := TDUIPen.Create(Self, 'EDIT.LINE');
end;

procedure TDUIEdit.DoChange(ASender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDUIEdit.DoKeyDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  if Assigned(FOnKeyDown) then
    FOnKeyDown(Self, AKey, AShift);
end;

procedure TDUIEdit.DoKeyPress(ASender: TObject; var AKey: Char);
begin
  if Assigned(FOnKeyPress) then
    FOnKeyPress(Self, AKey);
end;

procedure TDUIEdit.DoKeyUp(ASender: TObject; var AKey: Word; AShift: TShiftState);
begin
  if Assigned(FOnKeyUp) then
    FOnKeyUp(Self, AKey, AShift);
end;

procedure TDUIEdit.DoPaint(AGPCanvas: IGPGraphics);
var
  gp: IGPGraphicsPath;
  eIndent: Extended;
  strText: String;
  iLen: Integer;
begin
  inherited;

  if Height = 0 then
    Exit;

  gp := TGPGraphicsPath.Create;

  if FArcBorder then
  begin
    gp.AddArcF(0, 0, Height - 1, Height - 1, 90, 180);
    gp.AddLineF(Height / 2, 0, Width - Height / 2, 0);
    gp.AddArcF(Width - Height - 1, 0, Height - 1, Height - 1, -90, 180);
    gp.AddLineF(Width - Height / 2, Height - 1, Height / 2, Height - 1);
    AGPCanvas.DrawPath(FLinePen, gp);
    eIndent := Height / 2;
  end
  else
  begin
    gp.AddRectangle(MakeRect(0, 0, Width - 1, Height - 1));
    AGPCanvas.DrawPath(FLinePen, gp);
    eIndent := 0;
  end;

  if Text <> '' then
  begin
    iLen := Length(Text);
    if (GetPasswordChar <> #0) and (iLen > 0) then
    begin
      SetLength(strText, iLen);
      FillChar(strText[1], iLen, GetPasswordChar);
      AGPCanvas.DrawStringF(strText, FFont, MakeRectF(eIndent, 0, Width - 2 * eIndent, Height), FStringFormat, FTextBrush);
    end
    else
      AGPCanvas.DrawStringF(Text, FFont, MakeRectF(eIndent, 0, Width - 2 * eIndent, Height), FStringFormat, FTextBrush);
  end
  else if Hint <> '' then
    AGPCanvas.DrawStringF(Hint, FFont, MakeRectF(eIndent, 0, Width - 2 * eIndent, Height), FStringFormat, FHintBrush);
end;

function TDUIEdit.GetEdit: TEdit;
begin
  Result := WinControl as TEdit;
end;

function TDUIEdit.GetWinControlClass: TWinControlClass;
begin
  Result := TInnerEdit;
end; 

function TDUIEdit.GetMaxLength: Integer;
begin
  Result := GetEdit.MaxLength;
end;

procedure TDUIEdit.SetArcBorder(const AValue: Boolean);
begin
  if FArcBorder = AValue then
    Exit;

  FArcBorder := AValue;
  Perform(WM_WINDOWPOSCHANGED, 0, 0);
  Invalidate;
end;

procedure TDUIEdit.SetHint(const AValue: String);
begin
  inherited;
  Invalidate;
end;

procedure TDUIEdit.SetMaxLength(const AValue: Integer);
begin
  GetEdit.MaxLength := AValue;
end;

function TDUIEdit.GetPasswordChar: Char;
begin
  Result := GetEdit.PasswordChar;
end;

procedure TDUIEdit.SetPasswordChar(const AValue: Char);
begin
  GetEdit.PasswordChar := AValue;
  Invalidate;
end;

function TDUIEdit.GetReadOnly: Boolean;
begin
  Result := GetEdit.ReadOnly;
end;

procedure TDUIEdit.SetReadOnly(const AValue: Boolean);
begin
  GetEdit.ReadOnly := AValue;
end;

procedure TDUIEdit.WndProc(var AMessage: TMessage);
var
  ptLeftTop: TPoint;
begin
  case AMessage.Msg of
    WM_GETTEXTLENGTH, WM_GETTEXT, WM_SETTEXT:
    begin
      //��Text������ص��¼���ȫ��ת����TEdit����
      WinControl.WindowProc(AMessage);
      Exit;
    end;
    WM_KEYDOWN, WM_KEYUP, WM_CHAR:
    begin
      if AutoHide and (TWMKey(AMessage).CharCode = $D) then
      begin
        WinControl.Visible := False;
        Exit;
      end;
    end;
    WM_SETFOCUS:
    begin
      if GetReadOnly then
        Exit;
    end;
    WM_WINDOWPOSCHANGED:
    begin
      if Assigned(GetEdit.Parent) and FArcBorder then
      begin
        ptLeftTop := ClientToScreen(Point(0, 0));
        ptLeftTop := GetEdit.Parent.ScreenToClient(ptLeftTop);
        GetEdit.SetBounds(ptLeftTop.X + Height div 2, ptLeftTop.Y + 1,
          Width - Height, Height - 2);
      end
      //�о�TWinControl.WMWindowPosChangedʵ����Bug��
      //δ���Message.WindowPos����Ч�Ծ�ֱ��ʹ��(TControl.WMWindowPosChangedû����)��
      //����������
      else if not (TObject(Self) is TWinControl) or (AMessage.LParam <> 0) then
        inherited;

      Exit;
    end;
  end;

  inherited;
end;

end.
