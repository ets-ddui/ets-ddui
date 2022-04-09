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
