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
unit UWelcome;

interface

uses
  UDUIForm, UDUIPanel, Classes, Controls, UDUICore, UDUILabel, UDUIImage;

type
  TFrmWelcome = class(TDUIFrame)
    ImgWelcome: TDUIImage;
    PnlLeft: TDUIPanel;
    PnlTool: TDUIPanel;
    PnlClient: TDUIPanel;
    DUILabel1: TDUILabel;
    DUILabel2: TDUILabel;
  end;

implementation

{$R *.dfm}

end.
