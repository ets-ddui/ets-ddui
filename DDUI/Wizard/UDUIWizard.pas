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
unit UDUIWizard;

interface

uses
  Classes, Windows, Controls, ToolsAPI;

type
  TDUIWizard = class(TNotifierObject, IOTAWizard)
  protected
    //IOTAWizard实现
    function GetIDString: String;
    function GetName: String; virtual;
    function GetState: TWizardState;
    procedure Execute; virtual; abstract;
  end;

  TDUIRepositoryWizard = class(TDUIWizard, IOTARepositoryWizard)
  strict private
    FModule: IOTAModule;
  protected
    //IOTARepositoryWizard实现
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
  Result := 'ETS向导';
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
