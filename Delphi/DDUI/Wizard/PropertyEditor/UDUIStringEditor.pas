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
unit UDUIStringEditor;

interface

uses
  UDUIForm, UDUIButton, UDUICore, UDUIPanel, Classes, Controls, StdCtrls,
  DesignIntf, DesignEditors;

type
  TDUIStringEditorDlg = class(TDUIForm)
    MmValue: TMemo;
    PnlControl: TDUIPanel;
    BtnSave: TDUIButton;
    BtnCancel: TDUIButton;
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
  end;

  TDUIStringProperty = class(TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

implementation

{$R *.dfm}

{ TDUIStringEditorDlg }

procedure TDUIStringEditorDlg.BtnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TDUIStringEditorDlg.BtnSaveClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

{ TDUIStringProperty }

procedure TDUIStringProperty.Edit;
begin
  with TDUIStringEditorDlg.Create(nil) do
  begin
    MmValue.Text := GetValue;
    if ShowModal = mrOK then
      SetValue(MmValue.Text);
  end;
end;

function TDUIStringProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

end.
