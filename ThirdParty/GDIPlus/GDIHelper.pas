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
unit GDIHelper;

interface

uses
  Classes, SysUtils, Graphics, IGDIPlus, UDUIGraphics;

type
  TBaseHelper = class(TComponent)
  protected
    //屏蔽冗余的属性
    property Name;
    property Tag;
  end;

  TBaseHelperClass = class of TBaseHelper;

  TBrushHelper = class(TBaseHelper)
  protected
    function GetBrush: IGPBrush; virtual; abstract;
  public
    property Brush: IGPBrush read GetBrush;
  end;

  TSolidBrushHelper = class(TBrushHelper)
  private
    FColor: TGPColor;
  protected
    function GetBrush: IGPBrush; override;
  published
    property Color: TGPColor read FColor write FColor;
  end;

  TTextureBrushHelper = class(TBrushHelper)
  private
    FPicture: TDUIPicture;
    FWrapMode: TGPWrapMode;
    procedure SetPicture(const AValue: TDUIPicture);
  protected
    function GetBrush: IGPBrush; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Picture: TDUIPicture read FPicture write SetPicture;
    property WrapMode: TGPWrapMode read FWrapMode write FWrapMode;
  end;

  TLinearGradientBrushHelper = class(TBrushHelper)
  private
    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FColor1: TGPColor;
    FColor2: TGPColor;
    FMode: TGPLinearGradientMode;
  protected
    function GetBrush: IGPBrush; override;
  published
    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property Color1: TGPColor read FColor1 write FColor1;
    property Color2: TGPColor read FColor2 write FColor2;
    property Mode: TGPLinearGradientMode read FMode write FMode;
  end;

  THatchBrushHelper = class(TBrushHelper)
  private
    FHatchStyle: TGPHatchStyle;
    FForeColor: TGPColor;
    FBackColor: TGPColor;
  protected
    function GetBrush: IGPBrush; override;
  published
    property HatchStyle: TGPHatchStyle read FHatchStyle write FHatchStyle;
    property ForeColor: TGPColor read FForeColor write FForeColor;
    property BackColor: TGPColor read FBackColor write FBackColor;
  end;

  TPathGradientBrushHelper = class(TBrushHelper)
  private
    FPoints: array of TGPPoint;
    FWrapMode: TGPWrapMode;
    function GetCount: Integer;
    function GetPoint(AIndex: Integer): TGPPoint;
  protected
    function GetBrush: IGPBrush; override;
  public
    procedure AddPoint(APoint: TGPPoint);
    procedure Clear;
    property Count: Integer read GetCount;
    property Point[AIndex: Integer]: TGPPoint read GetPoint;
  published
    property WrapMode: TGPWrapMode read FWrapMode write FWrapMode;
  end;

  TColorHelper = class(TBaseHelper)
  private
    FColor: TGPColor;
  published
    property Color: TGPColor read FColor write FColor;
  end;

  TFontHelper = class(TBaseHelper)
  private
    FFamily: String;
    FSize: Single;
    FStyle: TFontStyles;
    FFontUnit: TGPUnit;
    function GetFont: IGPFont;
  public
    property Font: IGPFont read GetFont;
  published
    property Family: String read FFamily write FFamily;
    property Size: Single read FSize write FSize;
    property Style: TFontStyles read FStyle write FStyle;
    property FontUnit: TGPUnit read FFontUnit write FFontUnit;
  end;

  TImageHelper = class(TBaseHelper)
  private
    FPicture: TDUIPicture;
    function GetImage: IGPImage;
    procedure SetPicture(const AValue: TDUIPicture);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Image: IGPImage read GetImage;
  published
    property Picture: TDUIPicture read FPicture write SetPicture;
  end;

  TPenHelper = class(TBaseHelper)
  private
    FColor: TGPColor;
    FWidth: Single;
    function GetPen: IGPPen;
  public
    property Pen: IGPPen read GetPen;
  published
    property Color: TGPColor read FColor write FColor;
    property Width: Single read FWidth write FWidth;
  end;

function GetCacheGraphics: IGPGraphics;

implementation

{ TSolidBrushHelper }

function TSolidBrushHelper.GetBrush: IGPBrush;
begin
  Result := TGPSolidBrush.Create(FColor);
end;

{ TTextureBrushHelper }

constructor TTextureBrushHelper.Create(AOwner: TComponent);
begin
  inherited;

  FPicture := TDUIPicture.Create(nil, '');
end;

destructor TTextureBrushHelper.Destroy;
begin
  FreeAndNil(FPicture);

  inherited;
end;

function TTextureBrushHelper.GetBrush: IGPBrush;
begin
  TGPTextureBrush.Create(FPicture.Image, FWrapMode);
end;

procedure TTextureBrushHelper.SetPicture(const AValue: TDUIPicture);
begin
  FPicture.Assign(AValue);
end;

{ TLinearGradientBrushHelper }

function TLinearGradientBrushHelper.GetBrush: IGPBrush;
begin
  Result := TGPLinearGradientBrush.Create(MakeRect(FLeft, FTop, FWidth, FHeight),
    FColor1, FColor2, FMode);
end;

{ THatchBrushHelper }

function THatchBrushHelper.GetBrush: IGPBrush;
begin
  Result := TGPHatchBrush.Create(FHatchStyle, FForeColor, FBackColor);
end;

{ TPathGradientBrushHelper }

procedure TPathGradientBrushHelper.AddPoint(APoint: TGPPoint);
var
  iLen: Integer;
begin
  iLen := Length(FPoints);
  SetLength(FPoints, iLen + 1);
  FPoints[iLen] := APoint;
end;

procedure TPathGradientBrushHelper.Clear;
begin
  SetLength(FPoints, 0);
end;

function TPathGradientBrushHelper.GetBrush: IGPBrush;
begin
  Result := TGPPathGradientBrush.Create(FPoints, FWrapMode);
end;

function TPathGradientBrushHelper.GetCount: Integer;
begin
  Result := Length(FPoints);
end;

function TPathGradientBrushHelper.GetPoint(AIndex: Integer): TGPPoint;
begin
  Result := FPoints[AIndex];
end;

{ TFontHelper }

function TFontHelper.GetFont: IGPFont;
begin
  Result := TGPFont.Create(FFamily, FSize, FStyle, FFontUnit);
end;

{ TImageHelper }

constructor TImageHelper.Create(AOwner: TComponent);
begin
  inherited;

  FPicture := TDUIPicture.Create(nil, '');
end;

destructor TImageHelper.Destroy;
begin
  FreeAndNil(FPicture);

  inherited;
end;

function TImageHelper.GetImage: IGPImage;
begin
  Result := FPicture.Image;
end;

procedure TImageHelper.SetPicture(const AValue: TDUIPicture);
begin
  FPicture.Assign(AValue);
end;

{ TPenHelper }

function TPenHelper.GetPen: IGPPen;
begin
  Result := TGPPen.Create(FColor, FWidth);
end;

{ 杂项函数 }

function ColorToIdent(AColor: Longint; var AIdent: String): Boolean;
begin
  AIdent := RGBAColorToString(AColor);
  Result := True;
end;

function IdentToColor(const AIdent: String; var AColor: Longint): Boolean;
begin
  AColor := StringToRGBAColor(AIdent);
  Result := True;
end;

var
  GCacheGraphics: IGPGraphics = nil;

function GetCacheGraphics: IGPGraphics;
begin
  if not Assigned(GCacheGraphics) then
    GCacheGraphics := TGPGraphics.Create(TGPBitmap.Create(1, 1));

  Result := GCacheGraphics;
end;

initialization
  RegisterClasses([TSolidBrushHelper, TTextureBrushHelper,
    TLinearGradientBrushHelper, THatchBrushHelper, TPathGradientBrushHelper,
    TColorHelper, TFontHelper, TImageHelper, TPenHelper]);

  RegisterIntegerConsts(TypeInfo(TGPColor), IdentToColor, ColorToIdent);

end.
