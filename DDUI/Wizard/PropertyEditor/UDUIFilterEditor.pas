{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi，让漂亮界面做起来更简单。

  本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
  发布此库的目的是希望其有用，但不做任何保证。
  如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

  开源地址: https://github.com/ets-ddui/ets-ddui
            https://gitee.com/ets-ddui/ets-ddui
  开源协议: The MIT License (MIT)
  作者邮箱: xinghun87@163.com
  官方博客：https://blog.csdn.net/xinghun61
}
unit UDUIFilterEditor;

interface

uses
  DesignEditors, DesignIntf, Classes, SysUtils, TypInfo;

type
  TDUIFilter = class(TClassProperty)
  private
    function Filter(const ATestEditor: IProperty): Boolean;
  protected
    function GetPropertynames: TStringList; virtual; abstract;
  public
    procedure GetProperties(AProc: TGetPropProc); override;
  end;

  TDUIButtonFilter = class(TDUIFilter)
  private
    class var
      FPropertyNames: TStringList;
    class procedure Init;
    class procedure UnInit;
  protected
    function GetPropertynames: TStringList; override;
  end;

implementation

{ TDUIFilter }

function TDUIFilter.Filter(const ATestEditor: IProperty): Boolean;
begin
  if GetPropertynames.IndexOf(LowerCase(ATestEditor.GetName)) >= 0 then
    Result := False
  else
    Result := True;
end;

procedure TDUIFilter.GetProperties(AProc: TGetPropProc);
var
  i, iValue: Integer;
  dsComponents: IDesignerSelections;
begin
  dsComponents := TDesignerSelections.Create;

  for i := 0 to PropCount - 1 do
  begin
    iValue := GetOrdValueAt(i);
    if iValue <> 0 then
      dsComponents.Add(TComponent(iValue));
  end;

  if dsComponents.Count > 0 then
    GetComponentProperties(dsComponents, tkProperties, Designer, AProc, Filter);
end;

{ TDUIButtonFilter }

function TDUIButtonFilter.GetPropertynames: TStringList;
begin
  Result := FPropertyNames;
end;

class procedure TDUIButtonFilter.Init;
begin
  FPropertyNames := TStringList.Create;
  FPropertyNames.Sorted := True;
  FPropertyNames.Add(LowerCase('Align'));
  FPropertyNames.Add(LowerCase('AlignKeepSize'));
  FPropertyNames.Add(LowerCase('AlignOrder'));
  FPropertyNames.Add(LowerCase('AlignWithMargins'));
  FPropertyNames.Add(LowerCase('Anchors'));
  FPropertyNames.Add(LowerCase('Cursor'));
  FPropertyNames.Add(LowerCase('HelpContext'));
  FPropertyNames.Add(LowerCase('HelpKeyword'));
  FPropertyNames.Add(LowerCase('HelpType'));
  FPropertyNames.Add(LowerCase('Hint'));
  FPropertyNames.Add(LowerCase('Left'));
  FPropertyNames.Add(LowerCase('Margins'));
  FPropertyNames.Add(LowerCase('Name'));
  FPropertyNames.Add(LowerCase('Padding'));
  FPropertyNames.Add(LowerCase('ShowHint'));
  FPropertyNames.Add(LowerCase('Tag'));
  FPropertyNames.Add(LowerCase('Top'));
end;

class procedure TDUIButtonFilter.UnInit;
begin
  FreeAndNil(FPropertyNames);
end;

initialization
  TDUIButtonFilter.Init;
finalization
  TDUIButtonFilter.UnInit;

end.
