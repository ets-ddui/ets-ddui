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
unit UAbout;

interface

uses
  UDUIForm, Classes, Controls, UDUICore, UDUILabel, UDUIPanel, UDUIImage;

type
  TFrmAbout = class(TDUIFrame)
    LblLicense: TDUILabel;
    LblAuthor: TDUILabel;
    LblAbout: TDUILabel;
    PnlContent: TDUIPanel;
    ImgMain: TDUIImage;
  end;

implementation

{$R *.dfm}

end.
