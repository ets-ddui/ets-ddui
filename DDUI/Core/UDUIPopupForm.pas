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
unit UDUIPopupForm;

interface

uses
  Windows, Classes, Messages, Forms, UDUIForm;

type
  TDUIPopupForm = class(TDUIForm)
  protected
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor CreateNew(AOwner: TComponent; ADummy: Integer = 0); override;
  end;

implementation

{ TDUIPopupForm }

constructor TDUIPopupForm.CreateNew(AOwner: TComponent; ADummy: Integer);
begin
  inherited;

  Position := poDesigned;
  BorderStyle := bsToolWindow;
end;

procedure TDUIPopupForm.WndProc(var AMessage: TMessage);
  function isChildFocused: Boolean;
  var
    hFocus: HWnd;
  begin
    Result := False;

    hFocus := GetFocus;
    if hFocus = 0 then
      Exit;

    repeat
      if Handle = hFocus then
      begin
        Result := True;
        Exit;
      end;

      hFocus := GetParent(hFocus);
    until hFocus = 0;
  end;
begin
  case AMessage.Msg of
    WM_NCHITTEST:
    begin
      inherited WndProc(AMessage);

      if AMessage.Result in [HTTOPLEFT, HTTOPRIGHT, HTBOTTOMLEFT, HTBOTTOMRIGHT,
        HTTOP, HTBOTTOM, HTLEFT, HTRIGHT, HTCAPTION] then
        AMessage.Result := HTCLIENT;

      Exit;
    end;
    WM_KILLFOCUS:
    begin
      inherited WndProc(AMessage);

      if not isChildFocused then
        Close;

      Exit;
    end;
  end;

  inherited WndProc(AMessage);
end;

end.
