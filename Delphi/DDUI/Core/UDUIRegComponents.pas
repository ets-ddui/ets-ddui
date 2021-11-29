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
unit UDUIRegComponents;

interface

procedure RegComponents;

implementation

uses
  Classes, UDUIForm, UDUIPanel, UDUIButton, UDUITreeGrid, UDUIImage, UDUIWinWrapper,
  UDUIEdit, UDUILabel, UDUIScrollBar, UDUIGridEx, UDUIShape, Scintilla;

{$IFDEF DESIGNTIME}
procedure RegComponentsImpl(AClasses: array of TComponentClass);
begin
  if Assigned(RegisterComponentsProc) then
    RegisterComponents('DDUI', AClasses);
end;
{$ELSE}
procedure RegComponentsImpl(AClasses: array of TPersistentClass);
begin
  RegisterClasses(AClasses);
end;
{$ENDIF}

procedure RegComponents;
begin
  RegComponentsImpl([TDUIScrollControl, TDUIWinContainer, TDUIPanel, TDUIImage,
    TDUIButton, TDUISpeedButton, TDUIButtonList, TDUIEdit, TDUILabel, TDUIScrollBar,
    TDUIDrawGrid, TDUITreeGrid, TDUIShape,
    TScintilla]);
end;

end.
