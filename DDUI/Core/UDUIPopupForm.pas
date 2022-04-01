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
