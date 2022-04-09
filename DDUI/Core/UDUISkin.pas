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
unit UDUISkin;

{$i UConfigure.inc}

interface

uses
  Windows, Graphics, qjson, qstring, IGDIPlus, GDIHelper;

type
  ISkin = interface
    ['{154F2AC6-E749-4302-B637-D6ED6E0DF18F}']
    function GetBrush(AName: WideString): IGPBrush;
    function GetColor(AName: WideString): TGPColor;
    function GetFont(AName: WideString): IGPFont;
    function GetImage(AName: WideString): IGPImage;
    function GetPen(AName: WideString): IGPPen;
  end;

  IRawSkin = interface(ISkin)
    ['{F48DD9CC-7F32-42F8-BDDF-48C06A59981A}']
    function GetSkinFile: String;
    procedure SetSkinFile(AValue: String);
    function GetRootNode: TQJson;
    procedure SaveData;
    function GetHelper(AName: String): TBaseHelper;
    procedure SetHelper(AName: String; AValue: TBaseHelper);
  end;

function GetSkin: ISkin; stdcall;

implementation

{$R Skin.res}

uses
  Classes, SysUtils, UDUIRcStream, UDUIGraphics, UDUIUtils, UTool;

type
  TSkin = class(TInterfacedObject, ISkin, IRawSkin)
  private
    //ISkin接口实现
    function GetBrush(AName: WideString): IGPBrush;
    function GetColor(AName: WideString): TGPColor;
    function GetFont(AName: WideString): IGPFont;
    function GetImage(AName: WideString): IGPImage;
    function GetPen(AName: WideString): IGPPen;
  private
    //IRawSkin接口实现
    function GetSkinFile: String;
    procedure SetSkinFile(AValue: String);
    function GetRootNode: TQJson;
    procedure SaveData;
    function GetHelper(AName: String): TBaseHelper;
    procedure SetHelper(AName: String; AValue: TBaseHelper);
  private
    class var FDefaultBrush: IGPBrush;
    class var FDefaultColor: TGPColor;
    class var FDefaultFont: IGPFont;
    class var FDefaultImage: IGPImage;
    class var FDefaultPen: IGPPen;
    class procedure Init;
  private
    FData: TQJson;
    FSkinFile: String;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

var
  GSkin: ISkin;

function GetSkin: ISkin;
begin
  if not Assigned(GSkin) then
    GSkin := TSkin.Create;
  Result := GSkin;
end;

{ TSkin }

constructor TSkin.Create;
begin
  inherited Create;

  SetSkinFile('Config\Skin.json');
end;

destructor TSkin.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

function TSkin.GetBrush(AName: WideString): IGPBrush;
var
  hlp: TBaseHelper;
begin
  hlp := GetHelper(AName +  '.__brush__');
  try
    if not Assigned(hlp) then
      Result := FDefaultBrush
    else
      Result := (hlp as TBrushHelper).Brush;
  finally
    FreeAndNil(hlp);
  end;
end;

function TSkin.GetColor(AName: WideString): TGPColor;
var
  hlp: TBaseHelper;
begin
  hlp := GetHelper(AName +  '.__color__');
  try
    if not Assigned(hlp) then
      Result := FDefaultColor
    else
      Result := (hlp as TColorHelper).Color;
  finally
    FreeAndNil(hlp);
  end;
end;

function TSkin.GetFont(AName: WideString): IGPFont;
var
  hlp: TBaseHelper;
begin
  hlp := GetHelper(AName +  '.__font__');
  try
    if not Assigned(hlp) then
      Result := FDefaultFont
    else
      Result := (hlp as TFontHelper).Font;
  finally
    FreeAndNil(hlp);
  end;
end;

function TSkin.GetImage(AName: WideString): IGPImage;
var
  hlp: TBaseHelper;
begin
  hlp := GetHelper(AName +  '.__image__');
  try
    if not Assigned(hlp) then
      Result := FDefaultImage
    else
      Result := (hlp as TImageHelper).Image;
  finally
    FreeAndNil(hlp);
  end;
end;

function TSkin.GetPen(AName: WideString): IGPPen;
var
  hlp: TBaseHelper;
begin
  hlp := GetHelper(AName +  '.__pen__');
  try
    if not Assigned(hlp) then
      Result := FDefaultPen
    else
      Result := (hlp as TPenHelper).Pen;
  finally
    FreeAndNil(hlp);
  end;
end;

function TSkin.GetSkinFile: String;
begin
  Result := FSkinFile;
end;

procedure TSkin.SetSkinFile(AValue: String);
var
  rs: TResourceStream;
begin
  if FSkinFile = AValue then
    Exit;

  FSkinFile := AValue;
  FreeAndNil(FData);

  if FileExists(FSkinFile) then
  begin
    FData := TQJson.Create;
    FData.LoadFromFile(FSkinFile, teUTF8);
  end
  else
  begin
    rs := nil;
    try try
      rs := TResourceStream.Create(HInstance, 'Skin', RT_RCDATA);

      FData := TQJson.Create;
      FData.LoadFromStream(rs, teUTF8);
    except
      on e: EResNotFound do
      begin
        Exit;
      end;
    end;
    finally
      FreeAndNil(rs);
    end;
  end;
end;

function TSkin.GetRootNode: TQJson;
begin
  Result := FData;
end;

procedure TSkin.SaveData;
begin
  FData.SaveToFile(FSkinFile, teUtf8, False, True);
end;

function TSkin.GetHelper(AName: String): TBaseHelper;
var
  nd: TQJson;
begin
  Result := nil;

  nd := FData.ItemByPath(AName);
  if not Assigned(nd) then
    Exit;

  if not JsonToComponent(TObject(Result), nd, nil) then
    FreeAndNil(Result);
end;

procedure TSkin.SetHelper(AName: String; AValue: TBaseHelper);
var
  nd: TQJson;
begin
  nd := FData.ForcePath(AName);
  if not Assigned(nd) then
    Exit;

  if not ComponentToJson(nd, AValue) then
    raise Exception.Create('皮肤保存失败');
end;

class procedure TSkin.Init;
begin
  FDefaultColor := $0;
  FDefaultBrush := TGPSolidBrush.Create($0);
  FDefaultFont := TGPFont.Create('Arial', 11, [], UnitPixel);
//  FDefaultImage := TGPImage.Create(TStreamAdapter.Create(
//    TStringStream.Create(Base64ToMem('')),
//    soOwned));
  FDefaultPen := TGPPen.Create($0);
end;

initialization
  TSkin.Init;

end.
