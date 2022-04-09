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
unit UDUIShape;

interface

uses
  Windows, Classes, SysUtils, Messages, IGDIPlus,
  UDUICore, UDUIGraphics, UDUICoordinateTransform;

type
  TDUIShapeType = (stNone, stMinimize, stMaximize, stRestore, stClose, stCommit,
    stSkin, stSetting, stLog, stAngle, stPlus, stPicture, stCustom);
  TDoShape = function: IGPGraphicsPath of object;
  TDUIShape = class(TDUIBase)
  private
    FPen: TDUIPen;
    FBrush: TDUIBrush;
    FShapeType: TDUIShapeType;
    FSpin: Integer; //顺时针旋转的度数
    FShapes: array[TDUIShapeType] of TDoShape;
    FLineWidth: Integer;
    FPicture: TDUIPicture;
    FOnCustomPaint: TDUIOnPaint;
    procedure DoChange(ASender: TObject);
    procedure SetShapeType(const AValue: TDUIShapeType);
    procedure SetSpin(const AValue: Integer);
    procedure SetBrush(const AValue: TDUIBrush);
    procedure SetPen(const AValue: TDUIPen);
    function GetMatrix(ASpin: Integer): TDUIMatrix;
    function ShapeNone: IGPGraphicsPath;
    function ShapeMinimize: IGPGraphicsPath;
    function ShapeMaximize: IGPGraphicsPath;
    function ShapeRestore: IGPGraphicsPath;
    function ShapeClose: IGPGraphicsPath;
    function ShapeCommit: IGPGraphicsPath;
    function ShapeSkin: IGPGraphicsPath;
    function ShapeSetting: IGPGraphicsPath;
    function ShapeLog: IGPGraphicsPath;
    function ShapeAngle: IGPGraphicsPath;
    function ShapePlus: IGPGraphicsPath;
    procedure SetLineWidth(const AValue: Integer);
    procedure SetPicture(const AValue: TDUIPicture);
  protected
    procedure AssignTo(ADest: TPersistent); override;
    procedure CalcSize(out ANewWidth, ANewHeight: Integer); override;
    function CanResize(var ANewWidth, ANewHeight: Integer): Boolean; override;
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    function IsTransparent: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property AutoSize;
    property Brush: TDUIBrush read FBrush write SetBrush;
    property Pen: TDUIPen read FPen write SetPen;
    property Picture: TDUIPicture read FPicture write SetPicture;
    property LineWidth: Integer read FLineWidth write SetLineWidth default 3;
    property ShapeType: TDUIShapeType read FShapeType write SetShapeType default stNone;
    property Spin: Integer read FSpin write SetSpin default 0;
    property OnCustomPaint: TDUIOnPaint read FOnCustomPaint write FOnCustomPaint;
  end;

implementation

{ TDUIShape }

constructor TDUIShape.Create(AOwner: TComponent);
begin
  inherited;

  FPen := TDUIPen.Create(Self, 'SHAPE');
  FBrush := TDUIBrush.Create(Self, 'SHAPE');
  FPicture := TDUIPicture.Create(Self, '');
  FPicture.OnChange := DoChange;

  FShapes[stNone] := ShapeNone;
  FShapes[stMinimize] := ShapeMinimize;
  FShapes[stMaximize] := ShapeMaximize;
  FShapes[stRestore] := ShapeRestore;
  FShapes[stClose] := ShapeClose;
  FShapes[stCommit] := ShapeCommit;
  FShapes[stSkin] := ShapeSkin;
  FShapes[stSetting] := ShapeSetting;
  FShapes[stLog] := ShapeLog;
  FShapes[stAngle] := ShapeAngle;
  FShapes[stPlus] := ShapePlus;

  FLineWidth := 3;
end;

procedure TDUIShape.SetBrush(const AValue: TDUIBrush);
begin
  FBrush.Assign(AValue);
  Invalidate;
end;

procedure TDUIShape.SetLineWidth(const AValue: Integer);
begin
  if FLineWidth < 0 then
  begin
    raise Exception.Create('无效入参');
    Exit;
  end;

  if FLineWidth = AValue then
    Exit;

  FLineWidth := AValue;
  Invalidate;
end;

procedure TDUIShape.SetPen(const AValue: TDUIPen);
begin
  FPen.Assign(AValue);
  Invalidate;
end;

procedure TDUIShape.SetPicture(const AValue: TDUIPicture);
begin
  FPicture.Assign(AValue);
  Invalidate;
end;

procedure TDUIShape.SetShapeType(const AValue: TDUIShapeType);
begin
  if FShapeType = AValue then
    Exit;

  FShapeType := AValue;
  SetBounds(Left, Top, Width, Height); //触发CanResize的执行
  Invalidate;
end;

procedure TDUIShape.SetSpin(const AValue: Integer);
begin
  if FSpin = AValue then
    Exit;

  FSpin := AValue;
  Invalidate;
end;

procedure TDUIShape.DoChange(ASender: TObject);
begin
  if not Assigned(FPicture.Image) then
    Exit;

  FShapeType := stPicture;
  if AutoSize then
    SetBounds(Left, Top, Width, Height);
end;

procedure TDUIShape.DoPaint(AGPCanvas: IGPGraphics);
var
  gp: IGPGraphicsPath;
begin
  AGPCanvas.TranslateTransform(Width / 2, Height / 2);
  AGPCanvas.RotateTransform(FSpin);

  case FShapeType of
    stPicture:
    begin
      if not Assigned(FPicture.Image) then
        Exit;

      if FPicture.Childs.Count >= 2 then
      begin
        if Enabled then
          AGPCanvas.DrawImage(FPicture.Childs[0].Image,
            MakeRect(- Width div 2, - Height div 2, Width - 1, Height - 1))
        else
          AGPCanvas.DrawImage(FPicture.Childs[1].Image,
            MakeRect(- Width div 2, - Height div 2, Width - 1, Height - 1));
      end
      else if FPicture.Childs.Count = 1 then
        AGPCanvas.DrawImage(FPicture.Childs[0].Image,
          MakeRect(- Width div 2, - Height div 2, Width - 1, Height - 1))
      else
        AGPCanvas.DrawImage(FPicture,
          MakeRect(- Width div 2, - Height div 2, Width - 1, Height - 1));
    end;
    stCustom:
    begin
      if Assigned(FOnCustomPaint) then
        FOnCustomPaint(Self, AGPCanvas);
    end;
  else
    gp := FShapes[FShapeType];
    if not Assigned(gp) then
      Exit;

    AGPCanvas.DrawPath(FPen, gp);
    AGPCanvas.FillPath(FBrush, gp);
  end;
end;

function TDUIShape.IsTransparent: Boolean;
begin
  Result := True;
end;

function TDUIShape.GetMatrix(ASpin: Integer): TDUIMatrix;
var
  eSpin: Extended;
begin
  //按顺时针旋转(注意Y轴朝下)
  eSpin := ASpin * Pi / 180;
  Result := MakeDUIMatrix(Cos(eSpin), Sin(eSpin), - Sin(eSpin), Cos(eSpin));
end;

procedure TDUIShape.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TDUIShape) then
  begin
    inherited;
    Exit;
  end;

  TDUIShape(ADest).FPen.Assign(FPen);
  TDUIShape(ADest).FBrush.Assign(FBrush);
  TDUIShape(ADest).FShapeType := FShapeType;
  TDUIShape(ADest).FSpin := FSpin;
  TDUIShape(ADest).FLineWidth := FLineWidth;
  TDUIShape(ADest).FPicture.Assign(FPicture);
end;

procedure TDUIShape.CalcSize(out ANewWidth, ANewHeight: Integer);
var
  img: IGPImage;
begin
  if (FShapeType = stPicture) and Assigned(FPicture.Image) then
  begin
    if FPicture.Childs.Count > 0 then
      img := FPicture.Childs[0].Image
    else
      img := FPicture.Image;

    ANewWidth := img.Width;
    ANewHeight := img.Height;
  end;
end;

function TDUIShape.CanResize(var ANewWidth, ANewHeight: Integer): Boolean;
begin
  Result := inherited CanResize(ANewWidth, ANewHeight);

  if FShapeType = stPicture then
    Exit;

  //保证控件的尺寸为奇数
  if ANewWidth > 0 then
    ANewWidth := ANewWidth or 1;

  if ANewHeight > 0 then
    ANewHeight := ANewHeight or 1;
end;

//TDoShape均是以控件的中心点为坐标原点来计算，然后，根据AMatrix做旋转，根据AOffset做平移
function TDUIShape.ShapeNone: IGPGraphicsPath;
begin
  Result := nil;
end;

function TDUIShape.ShapeMinimize: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddRectangle(- Width div 2, Height div 2 - FLineWidth + 1, Width - 1, FLineWidth - 1);
end;

function TDUIShape.ShapeMaximize: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddRectangle(- Width div 2, - Height div 2, Width - 1, Height - 1);
  Result.AddRectangle(
    - Width div 2 + FLineWidth - 1, - Height div 2 + FLineWidth - 1,
    Width - 2 * FLineWidth + 1, Height - 2 * FLineWidth + 1);
end;

function TDUIShape.ShapeRestore: IGPGraphicsPath;
const
  CAdjust: Integer = 3;
begin
  Result := TGPGraphicsPath.Create;

  //1.0 内矩形
  Result.AddRectangle(
    - Width div 2, - Height div 2 + CAdjust - 1,
    Width - CAdjust, Height - CAdjust);
  Result.AddRectangle(
    - Width div 2 + FLineWidth - 1, - Height div 2 + CAdjust - 1 + FLineWidth - 1,
    Width - (CAdjust - 1) - 2 * FLineWidth + 1, Height - (CAdjust - 1) - 2 * FLineWidth + 1);

  //2.0 外矩形
  Result.AddPolygon(MakePoints(
    MakeDUICoords([
      - Width div 2 + CAdjust - 1, - Height div 2 + CAdjust - 1,
      - Width div 2 + CAdjust - 1, - Height div 2,
      Width div 2, - Height div 2,
      Width div 2, Height div 2 - CAdjust + 1,
      Width div 2 - CAdjust + 1, Height div 2 - CAdjust + 1,
      Width div 2 - CAdjust + 1, - Height div 2 + CAdjust - 1])));
end;

function TDUIShape.ShapeClose: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddPolygon(MakePoints(MakeDUICoords([
    - Width div 2, - Height div 2,
    - Width div 2 + FLineWidth - 1, - Height div 2,
    0, - FLineWidth div 2,
    Width div 2 - FLineWidth + 1, - Height div 2,
    Width div 2, - Height div 2,
    FLineWidth div 2, 0,
    Width div 2, Height div 2,
    Width div 2 - FLineWidth + 1, Height div 2,
    0, FLineWidth div 2,
    - Width div 2 + FLineWidth - 1, Height div 2,
    - Width div 2, Height div 2,
    - FLineWidth div 2, 0])));
end;

function TDUIShape.ShapeCommit: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddPolygon(MakePoints(MakeDUICoords([
    - Width div 2, FLineWidth div 2,
    - Width div 2 + FLineWidth - 1, - FLineWidth div 2,
    0, Height div 2 - FLineWidth + 1,
    Width div 2 - FLineWidth + 1, - Height div 2,
    Width div 2, - Height div 2 + FLineWidth - 1,
    0, Height div 2])));
end;

function TDUIShape.ShapeSkin: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddPolygon(MakePoints(MakeDUICoords([
    - Width div 4, - Height div 2,
    - Width div 8, - Height div 2,
    - Width div 8, - Height * 5 div 12,
    Width div 8, - Height * 5 div 12,
    Width div 8, - Height div 2,
    Width div 4, - Height div 2,
    Width div 2, - Height div 6,
    Width div 4, 0,
    Width div 4, Height div 2,
    - Width div 4, Height div 2,
    - Width div 4, 0,
    - Width div 2, - Height div 6])));
end;

function TDUIShape.ShapeSetting: IGPGraphicsPath;
var
  cosTemplate, cosResult: TDUICoords;
  i, iSize: Integer;
begin
  Result := TGPGraphicsPath.Create;

  if Width > Height then
    iSize := Height
  else
    iSize := Width;

  cosTemplate := MakeDUICoords([
    iSize * 7 div 18, - iSize div 9,
    iSize div 2, - iSize div 9,
    iSize div 2, iSize div 9,
    iSize * 7 div 18, iSize div 9]);
  for i := 0 to 7 do
    cosResult := cosResult + (cosTemplate * GetMatrix(i * 45));

  Result.AddPolygon(MakePoints(cosResult));
  Result.AddEllipse(- iSize div 4, - iSize div 4, iSize div 2, iSize div 2);
end;

function TDUIShape.ShapeLog: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddPolygon(MakePoints(MakeDUICoords([
    - Width div 2, - Height div 2,
    - Width div 2, Height div 2,
    Width div 2, Height div 2,
    Width div 2, Height div 2 - FLineWidth + 1,
    - Width div 2 + FLineWidth - 1, Height div 2 - FLineWidth + 1,
    - Width div 2 + FLineWidth - 1, - Height div 2])));
end;

function TDUIShape.ShapeAngle: IGPGraphicsPath;
var
  iSize: Integer;
begin
  Result := TGPGraphicsPath.Create;

  if Width > Height then
    iSize := Height
  else
    iSize := Width;

  //顶点方向向右
  Result.AddPolygon(MakePoints(MakeDUICoords([
    - iSize div 2, - iSize div 2,
    iSize div 2, 0,
    - iSize div 2, iSize div 2])));
end;

function TDUIShape.ShapePlus: IGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;

  Result.AddPolygon(MakePoints(MakeDUICoords([
    - Width div 2, - FLineWidth div 2,
    - FLineWidth div 2, - FLineWidth div 2,
    - FLineWidth div 2, - Height div 2,
    FLineWidth div 2, - Height div 2,
    FLineWidth div 2, - FLineWidth div 2,
    Width div 2, - FLineWidth div 2,
    Width div 2, FLineWidth div 2,
    FLineWidth div 2, FLineWidth div 2,
    FLineWidth div 2, Height div 2,
    - FLineWidth div 2, Height div 2,
    - FLineWidth div 2, FLineWidth div 2,
    - Width div 2, FLineWidth div 2])));
end;

end.
