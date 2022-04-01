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
unit UDUIWizard;

interface

uses
  Classes, Windows, Controls, ToolsAPI;

type
  TDUIWizard = class(TNotifierObject, IOTAWizard)
  protected
    //IOTAWizardʵ��
    function GetIDString: String;
    function GetName: String; virtual;
    function GetState: TWizardState;
    procedure Execute; virtual; abstract;
  end;

  TDUIRepositoryWizard = class(TDUIWizard, IOTARepositoryWizard)
  strict private
    FModule: IOTAModule;
  protected
    //IOTARepositoryWizardʵ��
    function GetAuthor: String;
    function GetComment: String; virtual;
    function GetPage: String;
    function GetGlyph: Cardinal; virtual;
  public
    procedure CreateModule(AOTACreator: IOTACreator);
    property Module: IOTAModule read FModule;
  end;

  TDUIFormWizard = class(TDUIRepositoryWizard, IOTAProjectWizard, IOTAFormWizard)
  private
    FFormClass: TComponentClass;
  protected
    function GetGlyph: Cardinal; override;
    function GetName: String; override;
    procedure Execute; override;
  public
    constructor Create(AFormClass: TComponentClass);
  end;

  TDUIFrameWizard = class(TDUIRepositoryWizard, IOTAProjectWizard, IOTAFormWizard)
  private
    FFrameClass: TComponentClass;
  protected
    function GetGlyph: Cardinal; override;
    function GetName: String; override;
    procedure Execute; override;
  public
    constructor Create(AFrameClass: TComponentClass);
  end;

implementation

{$R DUI.res}

uses
  UDUICreator;

{ TDUIWizard }

function TDUIWizard.GetIDString: String;
begin
  Result := 'ETS.WIZARD.' + ClassName;
end;

function TDUIWizard.GetName: String;
begin
  Result := ClassName;
end;

function TDUIWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

{ TDUIRepositoryWizard }

function TDUIRepositoryWizard.GetAuthor: String;
begin
  Result := 'John Steven';
end;

function TDUIRepositoryWizard.GetComment: String;
begin
  Result := 'ETS��';
end;

function TDUIRepositoryWizard.GetGlyph: Cardinal;
begin
  Result := 0;
end;

function TDUIRepositoryWizard.GetPage: String;
begin
  Result := 'ETS';
end;

procedure TDUIRepositoryWizard.CreateModule(AOTACreator: IOTACreator);
begin
  FModule := (BorlandIDEServices as IOTAModuleServices).CreateModule(AOTACreator);
end;

{ TDUIFormWizard }

constructor TDUIFormWizard.Create(AFormClass: TComponentClass);
begin
  FFormClass := AFormClass;
end;

procedure TDUIFormWizard.Execute;
begin
  CreateModule(TDUIFormCreator.Create(Self, FFormClass, 'Template_Form', HInstance));
end;

function TDUIFormWizard.GetGlyph: Cardinal;
begin
  Result := LoadIcon(HInstance, 'Form');
end;

function TDUIFormWizard.GetName: String;
begin
  Result := 'DUI Form';
end;

{ TDUIFrameWizard }

constructor TDUIFrameWizard.Create(AFrameClass: TComponentClass);
begin
  FFrameClass := AFrameClass;
end;

procedure TDUIFrameWizard.Execute;
begin
  CreateModule(TDUIFormCreator.Create(Self, FFrameClass, 'Template_Frame', HInstance));
end;

function TDUIFrameWizard.GetGlyph: Cardinal;
begin
  Result := LoadIcon(HInstance, 'Frame');
end;

function TDUIFrameWizard.GetName: String;
begin
  Result := 'DUI Frame';
end;

end.
