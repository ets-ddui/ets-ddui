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
unit UDUICreator;

interface

uses
  Classes, SysUtils, ToolsAPI, UDUIWizard;

type
  TDUICreator = class(TInterfacedObject, IOTACreator)
  strict private
    FDUIRepositoryWizard: TDUIRepositoryWizard;
  protected
    //IOTACreator实现
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
    //IOTAModuleCreator实现
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
  Result := FImplFileName; //IDE好像是根据文件后缀名识别文件类型，需填写正确
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
