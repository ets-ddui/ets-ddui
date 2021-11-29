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
unit UDUICreator;

interface

uses
  Classes, SysUtils, ToolsAPI, UDUIWizard;

type
  TDUICreator = class(TInterfacedObject, IOTACreator)
  strict private
    FDUIRepositoryWizard: TDUIRepositoryWizard;
  protected
    //IOTACreatorʵ��
    function GetCreatorType: String; virtual; abstract;
    function GetExisting: Boolean;
    function GetFileSystem: String;
    function GetOwner: IOTAModule; virtual; abstract;
    function GetUnnamed: Boolean;
  public
    constructor Create(ADUIRepositoryWizard: TDUIRepositoryWizard); virtual;
    property DUIRepositoryWizard: TDUIRepositoryWizard read FDUIRepositoryWizard;
  end;

  TDUIFormCreator = class(TDUICreator, IOTAModuleCreator)
  private
    //IOTAModuleCreatorʵ��
    function GetAncestorName: String;
    function GetImplFileName: String;
    function GetIntfFileName: String;
    function GetFormName: String;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const AFormIdent, AAncestorIdent: String): IOTAFile;
    function NewImplSource(const AModuleIdent, AFormIdent, AAncestorIdent: String): IOTAFile;
    function NewIntfSource(const AModuleIdent, AFormIdent, AAncestorIdent: String): IOTAFile;
    procedure FormCreated(const AFormEditor: IOTAFormEditor);
  private
    FAncestorName, FFormName, FImplFileName, FTemplateName: String;
    FHandle: THandle;
  protected
    function GetCreatorType: String; override;
    function GetOwner: IOTAModule; override;
  public
    constructor Create(ADUIRepositoryWizard: TDUIRepositoryWizard;
      AFormClass: TComponentClass; ATemplateName: String; AHandle: THandle); reintroduce;
  end;

implementation

uses
  UDUIFile, UTool;

{ TDUICreator }

constructor TDUICreator.Create(ADUIRepositoryWizard: TDUIRepositoryWizard);
begin
  FDUIRepositoryWizard := ADUIRepositoryWizard;
end;

function TDUICreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TDUICreator.GetFileSystem: String;
begin
  Result := '';
end;

function TDUICreator.GetUnnamed: Boolean;
begin
  Result := True;
end;

{ TDUIFormCreator }

constructor TDUIFormCreator.Create(ADUIRepositoryWizard: TDUIRepositoryWizard;
  AFormClass: TComponentClass; ATemplateName: String; AHandle: THandle);
var
  sUnitIdent: String;
begin
  inherited Create(ADUIRepositoryWizard);

  FAncestorName := Copy(AFormClass.ClassName, 2, MaxInt);
  sUnitIdent := '';
  FFormName := FAncestorName;
  FImplFileName := '.pas';
  FTemplateName := ATemplateName;
  FHandle := AHandle;

  (BorlandIDEServices as IOTAModuleServices).GetNewModuleAndClassName('Unit',
    sUnitIdent, FFormName, FImplFileName);
end;

procedure TDUIFormCreator.FormCreated(const AFormEditor: IOTAFormEditor);
begin
end;

function TDUIFormCreator.GetAncestorName: String;
begin
  Result := FAncestorName;
end;

function TDUIFormCreator.GetCreatorType: String;
begin
  Result := sForm;
end;

function TDUIFormCreator.GetFormName: String;
begin
  Result := FFormName;
end;

function TDUIFormCreator.GetImplFileName: String;
begin
  Result := FImplFileName; //IDE�����Ǹ����ļ���׺��ʶ���ļ����ͣ�����д��ȷ
end;

function TDUIFormCreator.GetIntfFileName: String;
begin
  Result := '';
end;

function TDUIFormCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TDUIFormCreator.GetOwner: IOTAModule;
begin
  Result := GetActiveProject;
end;

function TDUIFormCreator.GetShowForm: Boolean;
begin
  Result := True;
end;

function TDUIFormCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TDUIFormCreator.NewFormFile(const AFormIdent, AAncestorIdent: String): IOTAFile;
begin
  Result := nil;
end;

function TDUIFormCreator.NewImplSource(const AModuleIdent, AFormIdent, AAncestorIdent: String): IOTAFile;
begin
  Result := TDUIFile.Create(FHandle, FTemplateName,
    Format('UnitName=%s,ClassName=%s', [ExtractNakedFileName(FImplFileName), FFormName]));
end;

function TDUIFormCreator.NewIntfSource(const AModuleIdent, AFormIdent, AAncestorIdent: String): IOTAFile;
begin
  Result := nil;
end;

end.
