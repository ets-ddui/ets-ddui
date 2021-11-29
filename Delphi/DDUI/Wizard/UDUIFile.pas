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
unit UDUIFile;

interface

uses
  Windows, Classes, SysUtils, ToolsAPI;

type
  TDUIFile = class(TInterfacedObject, IOTAFile)
  private
    FHandle: THandle;
    FResName: String;
    FParameters: TStringList;
  protected
    function GetSource: String;
    function GetAge: TDateTime;
  public
    constructor Create(AHandle: THandle; AResName, AParameters: String); overload;
    constructor Create(AHandle: THandle; AResName: String; AParameters: TStringList); overload;
    destructor Destroy; override;
  end;

implementation

uses
  UDUIRcStream, UTool;

{ TDUIFile }

constructor TDUIFile.Create(AHandle: THandle; AResName, AParameters: String);
begin
  FHandle := AHandle;
  FResName := AResName;

  FParameters := TStringList.Create;
  FParameters.StrictDelimiter := True;
  FParameters.DelimitedText := AParameters;
end;

constructor TDUIFile.Create(AHandle: THandle; AResName: String; AParameters: TStringList);
begin
  FHandle := AHandle;
  FResName := AResName;

  FParameters := TStringList.Create;
  if Assigned(AParameters) then
    FParameters.Assign(AParameters);
end;

destructor TDUIFile.Destroy;
begin
  FreeAndNil(FParameters);

  inherited;
end;

function TDUIFile.GetAge: TDateTime;
begin
  Result := -1;
end;

function TDUIFile.GetSource: String;
begin
  with TResourceStream.Create(FHandle, FResName, RT_RCDATA) do
    try
      SetLength(Result, Size);
      Read(Result[1], Size);
    finally
      Free;
    end;
  Result := FormatEh(Result, FParameters);
end;

end.
