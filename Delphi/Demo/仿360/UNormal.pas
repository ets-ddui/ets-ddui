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
unit UNormal;

interface

uses
  UDUIForm, UDUIScrollBar, Classes, Controls, UDUICore, UDUIButton,
  UDUIWinWrapper, UDUIEdit, UDUILabel;

type
  TFrmNormal = class(TDUIFrame)
    Btn1: TDUIButton;
    SbVertical: TDUIScrollBar;
    SbHorizontal: TDUIScrollBar;
    Ed1: TDUIEdit;
    Sb2: TDUISpeedButton;
    Sb3: TDUISpeedButton;
    Lbl1: TDUILabel;
  end;

implementation

{$R *.dfm}

end.
