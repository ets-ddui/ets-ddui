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
unit UDUIPictureEditor;

interface

uses
  Classes, SysUtils, Controls, Dialogs, DesignIntf, DesignEditors, DesignConst,
  UDUIForm, UDUIGraphics, UDUICore, UDUIPanel, UDUIButton, UDUIImage;

type
  TDUIPictureEditorDlg = class(TDUIForm)
    PnlControl: TDUIPanel;
    ImgData: TDUIImage;
    BtnLoad: TDUIButton;
    BtnClear: TDUIButton;
    BtnSave: TDUIButton;
    BtnCancel: TDUIButton;
    procedure BtnLoadClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; const ADUIPicture: TDUIPicture); reintroduce;
  end;

  TDUIPictureProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: String; override;
    procedure SetValue(const AValue: String); override;
  end;

  TDUISkinNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(AProc: TGetStrProc); override;
  end;

implementation

{$R *.dfm}

{ TDUIPictureEditorDlg }

procedure TDUIPictureEditorDlg.BtnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TDUIPictureEditorDlg.BtnClearClick(Sender: TObject);
begin
  ImgData.Picture.Image := nil;
end;

procedure TDUIPictureEditorDlg.BtnLoadClick(Sender: TObject);
begin
  with TOpenDialog.Create(Self) do
    try
      Options := [ofFileMustExist];
      Filter := 'Image File|*.bmp;*.jpeg;*.jpg;*.gif;*.png;*.ico';
      if not Execute then
        Exit;

      ImgData.Picture.LoadFromFile(FileName);
    finally
      Free;
    end;
end;

procedure TDUIPictureEditorDlg.BtnSaveClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

constructor TDUIPictureEditorDlg.Create(AOwner: TComponent; const ADUIPicture: TDUIPicture);
begin
  inherited Create(AOwner);

  ImgData.Picture.Assign(ADUIPicture);
end;

{ TDUIPictureProperty }

procedure TDUIPictureProperty.Edit;
begin
  with TDUIPictureEditorDlg.Create(nil, TDUIPicture(GetOrdValue)) do
    if ShowModal = mrOK then
      SetOrdValue(Longint(ImgData.Picture));
end;

function TDUIPictureProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

function TDUIPictureProperty.GetValue: String;
var
  pic: TDUIPicture;
begin
  pic := TDUIPicture(GetOrdValue);

  if not Assigned(pic.Image) then
    Result := srNone
  else
    Result := '(TGPImage)';
end;

procedure TDUIPictureProperty.SetValue(const AValue: String);
begin
  if AValue = '' then
    SetOrdValue(0);
end;

{ TDUISkinNameProperty }

function TDUISkinNameProperty.GetAttributes: TPropertyAttributes;
begin
  //�ⲿ�ִ����TEnumProperty��ʵ���п�������
  Result := [paMultiSelect, paValueList, paSortList, paRevertable];
  if GetPropInfo.SetProc = nil then
    Result := Result + [paReadOnly, paDisplayReadOnly] - [paRevertable, paValueList];
end;

procedure TDUISkinNameProperty.GetValues(AProc: TGetStrProc);
begin
  {TODO: ���ӶԿ�ѡƤ���嵥�Ľ���}
  if GetComponent(0) is TDUIBrush then
  begin
  end;
end;

end.
