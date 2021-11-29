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
