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
unit UDUILabel;

interface

uses
  Windows, Classes, Controls, StdCtrls, Messages, IGDIPlus, UDUICore, UDUIGraphics;

type
  TDUILabel = class(TDUIBase)
  private
    FFont: TDUIFont;
    FTextBrush: TDUIBrush;
    FStringFormat: IGPStringFormat;
    function GetHAlign: TAlignment;
    procedure SetHAlign(const AValue: TAlignment);
    function GetVAlign: TTextLayout;
    procedure SetVAlign(const AValue: TTextLayout);
    function GetWordWrap: Boolean;
    procedure SetWordWrap(AValue: Boolean);
    procedure CMTextChanged(var AMessage: TMessage); message CM_TEXTCHANGED;
    procedure SetFont(const AValue: TDUIFont);
    procedure SetTextBrush(const AValue: TDUIBrush);
    procedure DoFontChanged(ASender: TObject);
  protected
    procedure CalcSize(out ANewWidth, ANewHeight: Integer); override;
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    function IsTransparent: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AutoSize default True;
    property Caption;
    property Font: TDUIFont read FFont write SetFont;
    property HAlign: TAlignment read GetHAlign write SetHAlign default taLeftJustify;
    property TextBrush: TDUIBrush read FTextBrush write SetTextBrush;
    property VAlign: TTextLayout read GetVAlign write SetVAlign default tlCenter;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap default False;
  end;

implementation

uses
  Math, GDIHelper;

{ TDUILabel }

constructor TDUILabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FFont := TDUIFont.Create(Self, 'TEXT');
  FFont.OnChange := DoFontChanged;
  FTextBrush := TDUIBrush.Create(Self, 'TEXT');

  SetBounds(0, 0, 65, 25);
  AutoSize := True;

  FStringFormat := TGPStringFormat.Create;
  FStringFormat.SetAlignment(StringAlignmentNear);
  FStringFormat.SetLineAlignment(StringAlignmentCenter);
  SetWordWrap(False);
end;

procedure TDUILabel.CalcSize(out ANewWidth, ANewHeight: Integer);
var
  str: String;
  si: TGPSizeF;
begin
  str := Caption;
  if str = '' then
    str := ' ';

  if GetWordWrap then //��������У���ֻ�����߶�ֵ
    si := GetCacheGraphics.MeasureStringF(str, FFont, MakeSizeF(ANewWidth, 0), FStringFormat)
  else
    si := GetCacheGraphics.MeasureStringF(str, FFont, FStringFormat);

  ANewWidth := Ceil(si.Width);
  ANewHeight := Ceil(si.Height);
end;

procedure TDUILabel.DoFontChanged(ASender: TObject);
begin
  SetBounds(Left, Top, Width, Height); //�����ؼ��ߴ�����¼���
end;

procedure TDUILabel.DoPaint(AGPCanvas: IGPGraphics);
begin
  AGPCanvas.DrawStringF(Caption, FFont, MakeRectF(0, 0, Width, Height), FStringFormat, FTextBrush);
end;

procedure TDUILabel.SetFont(const AValue: TDUIFont);
begin
  FFont.Assign(AValue);
  Invalidate;
end;

function TDUILabel.GetHAlign: TAlignment;
begin
  case FStringFormat.GetAlignment of
    StringAlignmentNear: Result := taLeftJustify;
    StringAlignmentCenter: Result := taCenter;
  else //StringAlignmentFar
    Result := taRightJustify;
  end;
end;

procedure TDUILabel.SetHAlign(const AValue: TAlignment);
const
  cAlignment: array[TAlignment] of TGPStringAlignment = (StringAlignmentNear, StringAlignmentFar, StringAlignmentCenter);
begin
  if GetHAlign = AValue then
    Exit;

  FStringFormat.SetAlignment(cAlignment[AValue]);
  Invalidate;
end;

procedure TDUILabel.SetTextBrush(const AValue: TDUIBrush);
begin
  FTextBrush.Assign(AValue);
  Invalidate;
end;

function TDUILabel.GetVAlign: TTextLayout;
begin
  case FStringFormat.GetLineAlignment of
    StringAlignmentNear: Result := tlTop;
    StringAlignmentCenter: Result := tlCenter;
  else //StringAlignmentFar
    Result := tlBottom;
  end;
end;

procedure TDUILabel.SetVAlign(const AValue: TTextLayout);
const
  cAlignment: array[TTextLayout] of TGPStringAlignment = (StringAlignmentNear, StringAlignmentCenter, StringAlignmentFar);
begin
  if GetVAlign = AValue then
    Exit;

  FStringFormat.SetLineAlignment(cAlignment[AValue]);
  Invalidate;
end;

function TDUILabel.GetWordWrap: Boolean;
begin
  if Assigned(FStringFormat) then
    Result := FStringFormat.GetFormatFlags and StringFormatFlagsNoWrap = 0
  else
    Result := False;
end;

function TDUILabel.IsTransparent: Boolean;
begin
  Result := True;
end;

procedure TDUILabel.SetWordWrap(AValue: Boolean);
begin
  if GetWordWrap = AValue then
    Exit;

  if AValue then
    FStringFormat.SetFormatFlags(FStringFormat.GetFormatFlags and not StringFormatFlagsNoWrap)
  else
    FStringFormat.SetFormatFlags(FStringFormat.GetFormatFlags or StringFormatFlagsNoWrap);

  SetBounds(Left, Top, Width, Height); //�����ؼ��ߴ�����¼���
  Invalidate;
end;

procedure TDUILabel.CMTextChanged(var AMessage: TMessage);
begin
  SetBounds(Left, Top, Width, Height); //�����ؼ��ߴ�����¼���
  Invalidate;
end;

end.
