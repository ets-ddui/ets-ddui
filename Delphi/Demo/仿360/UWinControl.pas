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
unit UWinControl;

interface

uses
  UDUIForm, Classes, Controls, UDUICore, UDUIWinWrapper, Scintilla, StdCtrls,
  ExtCtrls;

type
  TFrmWinControl = class(TDUIFrame)
    WcMain: TDUIWinContainer;
    ScEdit: TScintilla;
    Button1: TButton;
    Edit1: TEdit;
    ComboBox1: TComboBox;
    Panel1: TPanel;
    CheckBox1: TCheckBox;
    RadioButton1: TRadioButton;
  end;

implementation

{$R *.dfm}

end.
