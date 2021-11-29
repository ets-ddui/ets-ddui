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
