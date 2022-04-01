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
unit UDUIEntry;

interface

procedure Register;

implementation

uses
  Classes, Controls, DesignIntf, DesignEditors, ToolsAPI, UDUIWizard, UDUIForm, UDUIGraphics,
  UDUIButton, UDUIShape, UDUILabel, UDUIPictureEditor, UDUIFilterEditor, UDUIStringEditor,
  UDUIRegComponents;

procedure Register;
begin
  RegisterCustomModule(TDUIForm, TCustomModule);
  (BorlandIDEServices as IOTAWizardServices).AddWizard(TDUIFormWizard.Create(TDUIForm));

  RegisterCustomModule(TDUIFrame, TCustomModule);
  (BorlandIDEServices as IOTAWizardServices).AddWizard(TDUIFrameWizard.Create(TDUIFrame)); //Wizard���޷����ã�����IDE��ֻ����ʾһ��

  RegComponents;

  RegisterPropertyEditor(TypeInfo(TDUIPicture), nil, '', TDUIPictureProperty);
  RegisterPropertyEditor(TypeInfo(String), TDUIGraphicsObject, 'SkinName', TDUISkinNameProperty);
  RegisterPropertyEditor(TypeInfo(TDUIShape), TDUIButtonBase, '', TDUIButtonFilter);
  RegisterPropertyEditor(TypeInfo(TCaption), TDUILabel, 'Caption', TDUIStringProperty);
end;

end.
