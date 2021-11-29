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
unit UDUIPanel;

interface

uses
  Windows, Classes, SysUtils, Controls, Messages, Types, IGDIPlus, UDUICore, UDUIGraphics;

type
  TDUIPanel = class(TDUIBase)
  private
    FBackground: TDUIBrush;
    function GetTransparent: Boolean;
    procedure SetTransparent(const AValue: Boolean);
    procedure SetBackground(const AValue: TDUIBrush);
  protected
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    function IsTransparent: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Background: TDUIBrush read FBackground write SetBackground;
    property Transparent: Boolean read GetTransparent write SetTransparent default True;
  end;

implementation

{ TDUIPanel }

constructor TDUIPanel.Create(AOwner: TComponent);
begin
  inherited;

  FBackground := TDUIBrush.Create(Self, 'SYSTEM.BACKGROUND');
end;

procedure TDUIPanel.DoPaint(AGPCanvas: IGPGraphics);
begin
  if Transparent then
    Exit;

  AGPCanvas.FillRectangleF(FBackground, 0, 0, Width, Height);
end;

function TDUIPanel.GetTransparent: Boolean;
begin
  Result := not (csOpaque in ControlStyle);
end;

function TDUIPanel.IsTransparent: Boolean;
begin
  Result := True;
end;

procedure TDUIPanel.SetBackground(const AValue: TDUIBrush);
begin
  FBackground.Assign(AValue);
  Invalidate;
end;

procedure TDUIPanel.SetTransparent(const AValue: Boolean);
begin
  if Transparent <> AValue then
  begin
    if AValue then
      ControlStyle := ControlStyle - [csOpaque]
    else
      ControlStyle := ControlStyle + [csOpaque];
    Invalidate;
  end;
end;

end.
