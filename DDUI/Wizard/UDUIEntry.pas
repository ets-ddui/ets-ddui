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
  (BorlandIDEServices as IOTAWizardServices).AddWizard(TDUIFrameWizard.Create(TDUIFrame)); //Wizard类无法复用，否则，IDE中只能显示一个

  RegComponents;

  RegisterPropertyEditor(TypeInfo(TDUIPicture), nil, '', TDUIPictureProperty);
  RegisterPropertyEditor(TypeInfo(String), TDUIGraphicsObject, 'SkinName', TDUISkinNameProperty);
  RegisterPropertyEditor(TypeInfo(TDUIShape), TDUIButtonBase, '', TDUIButtonFilter);
  RegisterPropertyEditor(TypeInfo(TCaption), TDUILabel, 'Caption', TDUIStringProperty);
end;

end.
