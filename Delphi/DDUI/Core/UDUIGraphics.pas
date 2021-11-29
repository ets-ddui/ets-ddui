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
unit UDUIGraphics;

interface

uses
  Classes, Controls, SysUtils, StrUtils, ActiveX, IGDIPlus, UDUICore;

type
  TDUIGraphicsObject = class(TPersistent)
  private
    class var FObjects: TList;
    class procedure Init;
    class procedure UnInit;
  public
    class procedure ChangeSkin;
  strict private
    FFreeNotify: TComponent;
    FIsValidateHandle: Boolean;
    FHandle: IInterface;
    FSkinName, FDefaultSkinName: String;
    FOnChange: TNotifyEvent;
    FUpdateCount: Integer;
    procedure ReadSkinName(AReader: TReader);
    procedure WriteSkinName(AWriter: TWriter);
    function GetHandle: IInterface;
    procedure SetHandle(const AValue: IInterface);
    function GetComponentOwner: TComponent;
    procedure SetSkinName(const AValue: String);
  protected
    procedure AssignTo(ADest: TPersistent); override;
    function CreateHandle: IInterface; virtual; abstract;
    procedure DoChange;
    procedure DefineProperties(AFiler: TFiler); override;
    procedure InvalidateHandle;
    property IsValidateHandle: Boolean read FIsValidateHandle;
    property Handle: IInterface read GetHandle write SetHandle;
    property Owner: TComponent read GetComponentOwner;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent; ASkinName: String); reintroduce; virtual;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
  published
    property SkinName: String read FSkinName write SetSkinName stored False;
  end;

  TOnAdjustBrush = procedure(ASender: TObject; var ABrushHelper: TObject; var ADealed: Boolean) of object;
  TOnCheckValidate = procedure(ASender: TObject; const AHandle: IInterface; var AValid: Boolean) of object;
  TDUIBrush = class(TDUIGraphicsObject, IGPBrush)
  private
    FOnAdjustBrush: TOnAdjustBrush;
    FOnCheckValidate: TOnCheckValidate;
    function GetBrush: IGPBrush;
    procedure SetBrush(const AValue: IGPBrush);
  protected
    function CreateHandle: IInterface; override;
  public
    property Brush: IGPBrush read GetBrush write SetBrush implements IGPBrush;
    property OnAdjustBrush: TOnAdjustBrush read FOnAdjustBrush write FOnAdjustBrush;
    property OnCheckValidate: TOnCheckValidate read FOnCheckValidate write FOnCheckValidate;
  end;

  TDUIColor = class(TDUIGraphicsObject)
  private
    FColor: TGPColor;
    procedure SetColor(const AValue: TGPColor);
    function GetColor: TGPColor;
  protected
    procedure AssignTo(ADest: TPersistent); override;
    function CreateHandle: IInterface; override;
  public
    property Color: TGPColor read GetColor write SetColor;
  end;

  TDUIFont = class(TDUIGraphicsObject, IGPFont)
  private
    function GetFont: IGPFont;
    procedure SetFont(const AValue: IGPFont);
  protected
    function CreateHandle: IInterface; override;
  public
    property Font: IGPFont read GetFont write SetFont implements IGPFont;
    property OnChange;
  end;

  TDUIPen = class(TDUIGraphicsObject, IGPPen)
  private
    function GetPen: IGPPen;
    procedure SetPen(const AValue: IGPPen);
  protected
    function CreateHandle: IInterface; override;
  public
    property Pen: IGPPen read GetPen write SetPen implements IGPPen;
  end;

  TDUIPicture = class;
  TDUIPictureChild = class(TCollectionItem)
  private
    FName: String;
    FRect: TGPRect;
    function GetValue(const AIndex: Integer): Integer;
    procedure SetValue(const AIndex, AValue: Integer);
    function GetImage: IGPImage;
  protected
    procedure AssignTo(ADest: TPersistent); override;
  public
    property Image: IGPImage read GetImage;
  published
    property Name: String read FName write FName;
    property Left: Integer index 1 read GetValue write SetValue;
    property Top: Integer index 2 read GetValue write SetValue;
    property Width: Integer index 3 read GetValue write SetValue;
    property Height: Integer index 4 read GetValue write SetValue;
  end;

  TDUIPictureChilds = class(TCollection)
  private
    FParent: TDUIPicture;
    function GetItems(AIndex: Integer): TDUIPictureChild;
    procedure SetItems(AIndex: Integer; const AValue: TDUIPictureChild);
  protected
    procedure Update(AItem: TCollectionItem); override;
  public
    constructor Create(AParent: TDUIPicture);
    function AddChild(AName: String; ALeft, ATop, AWidth, AHeight: Integer): TDUIPictureChild;
    function IndexOfName(AName: String): Integer;
    property Items[AIndex: Integer]: TDUIPictureChild read GetItems write SetItems; default;
  end;

  TDUIPicture = class(TDUIGraphicsObject, IGPImage)
  private
    class var FClsidPng, FClsidBmp: TCLSID;
    class procedure Init;
  private
    FChilds: TDUIPictureChilds;
    FBitmapCache: IGPBitmap;
    procedure ReadData(AStream: TStream);
    procedure WriteData(AStream: TStream);
    function GetBitmap: IGPBitmap;
    function GetHeight: Integer;
    function GetWidth: Integer;
    function GetImage: IGPImage;
    procedure SetImage(const AValue: IGPImage);
    procedure SetChilds(const AValue: TDUIPictureChilds);
  protected
    procedure AssignTo(ADest: TPersistent); override;
    function CreateHandle: IInterface; override;
    procedure DefineProperties(AFiler: TFiler); override;
  public
    constructor Create(AOwner: TComponent; ASkinName: String); override;
    destructor Destroy; override;
    function GetChildImage(const ARect: TGPRect): IGPImage;
    procedure LoadFromFile(AFileName: String);
    procedure LoadFromStream(AStream: TStream); virtual;
    property Height: Integer read GetHeight;
    property Bitmap: IGPBitmap read GetBitmap;
    property Image: IGPImage read GetImage write SetImage implements IGPImage;
    property Width: Integer read GetWidth;
    property OnChange;
  published
    property Childs: TDUIPictureChilds read FChilds write SetChilds;
  end;

implementation

uses
  GDIHelper, UDUISkin;

type
  TFreeNotify = class(TComponent)
  public
    FGraphicsObject: TObject;
    destructor Destroy; override;
  end;

{ TFreeNotify }

destructor TFreeNotify.Destroy;
var
  obj: TObject;
begin
  if Assigned(FGraphicsObject) then
  begin
    obj := FGraphicsObject;
    FGraphicsObject := nil;
    obj.Free;
  end;

  inherited;
end;

{ TDUIGraphicsObject }

procedure TDUIGraphicsObject.DoChange;
begin
  if FUpdateCount = 0 then
  begin
    if Assigned(FOnChange) then
      FOnChange(Self)
    else if Assigned(FFreeNotify.Owner) and (FFreeNotify.Owner is TDUIBase) then
      TDUIBase(FFreeNotify.Owner).Invalidate;
  end;
end;

constructor TDUIGraphicsObject.Create(AOwner: TComponent; ASkinName: String);
begin
  FFreeNotify := TFreeNotify.Create(AOwner);
  TFreeNotify(FFreeNotify).FGraphicsObject := Self;

  inherited Create;

  FSkinName := ASkinName;
  FDefaultSkinName := ASkinName;

  FHandle := CreateHandle;
  FIsValidateHandle := True;
end;

destructor TDUIGraphicsObject.Destroy;
begin
  if Assigned(TFreeNotify(FFreeNotify).FGraphicsObject) then
  begin
    TFreeNotify(FFreeNotify).FGraphicsObject := nil;
    FreeAndNil(FFreeNotify);
  end;

  inherited;
end;

procedure TDUIGraphicsObject.AssignTo(ADest: TPersistent);
begin
  if not Assigned(ADest) or not (ADest is TDUIGraphicsObject) then
  begin
    inherited;
    Exit;
  end;

  TDUIGraphicsObject(ADest).FIsValidateHandle := FIsValidateHandle;
  TDUIGraphicsObject(ADest).FHandle := FHandle;
  TDUIGraphicsObject(ADest).FSkinName := FSkinName;
  TDUIGraphicsObject(ADest).FDefaultSkinName := FDefaultSkinName;
  //TDUIGraphicsObject(ADest).FOnChange := FOnChange;

  TDUIGraphicsObject(ADest).DoChange;
end;

procedure TDUIGraphicsObject.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TDUIGraphicsObject.EndUpdate;
begin
  Dec(FUpdateCount);
  DoChange;
end;

procedure TDUIGraphicsObject.DefineProperties(AFiler: TFiler);
var
  bDoWrite: Boolean;
begin
  inherited;

  //将SkinName的stored定义为False，可屏蔽Delphi将属性值写入到dfm的默认行为
  //通过重写DefineProperties，可实现对dfm写入的自定义行为
  bDoWrite := (FSkinName <> '') and (FSkinName <> FDefaultSkinName);
  AFiler.DefineProperty('SkinName', ReadSkinName, WriteSkinName, bDoWrite);
end;

procedure TDUIGraphicsObject.ReadSkinName(AReader: TReader);
begin
  SetSkinName(AReader.ReadString);
end;

procedure TDUIGraphicsObject.WriteSkinName(AWriter: TWriter);
begin
  AWriter.WriteString(FSkinName);
end;

function TDUIGraphicsObject.GetHandle: IInterface;
begin
  if not IsValidateHandle then
  begin
    FHandle := CreateHandle;
    FIsValidateHandle := True;
  end;

  Result := FHandle;
end;

function TDUIGraphicsObject.GetComponentOwner: TComponent;
begin
  Result := FFreeNotify.Owner;
end;

procedure TDUIGraphicsObject.SetHandle(const AValue: IInterface);
begin
  FHandle := AValue;
  FIsValidateHandle := True;
  FSkinName := '';
  DoChange;
end;

procedure TDUIGraphicsObject.SetSkinName(const AValue: String);
begin
  if FSkinName = AValue then
    Exit;

  if AValue = '' then
    FSkinName := FDefaultSkinName
  else
    FSkinName := AValue;

  FHandle := CreateHandle;
  FIsValidateHandle := True;

  DoChange;
end;

class procedure TDUIGraphicsObject.Init;
begin
  FObjects := TList.Create;
end;

procedure TDUIGraphicsObject.InvalidateHandle;
begin
  FHandle := nil;
  FIsValidateHandle := False;
end;

class procedure TDUIGraphicsObject.UnInit;
begin
  FreeAndNil(FObjects);
end;

class procedure TDUIGraphicsObject.ChangeSkin;
var
  i: Integer;
begin
  for i := 0 to FObjects.Count - 1 do
    if TDUIGraphicsObject(FObjects[i]).FSkinName <> '' then
      TDUIGraphicsObject(FObjects[i]).FIsValidateHandle := False;
end;

{ TDUIBrush }

function TDUIBrush.CreateHandle: IInterface;
var
  skin: IRawSkin;
  hlp: TBaseHelper;
  bDealed: Boolean;
begin
  if not Assigned(Owner) or not (Owner is TControl) then
  begin
    Result := GetSkin.GetBrush(SkinName);
    Exit;
  end;

  skin := GetSkin as IRawSkin;
  hlp := skin.GetHelper(SkinName +  '.__brush__');
  try
    if not Assigned(hlp) then
    begin
      Result := GetSkin.GetBrush(SkinName);
      Exit;
    end;

    if Assigned(FOnAdjustBrush) then
    begin
      bDealed := False;
      FOnAdjustBrush(Self, TObject(hlp), bDealed);
      if bDealed then
      begin
        Result := (hlp as TBrushHelper).Brush;
        Exit;
      end;
    end;

    if hlp is TLinearGradientBrushHelper then
    begin
      TLinearGradientBrushHelper(hlp).Width := TControl(Owner).Width;
      TLinearGradientBrushHelper(hlp).Height := TControl(Owner).Height;
    end;

    Result := (hlp as TBrushHelper).Brush;
  finally
    FreeAndNil(hlp);
  end;
end;

function TDUIBrush.GetBrush: IGPBrush;
var
  bValid: Boolean;
  brh: IGPLinearGradientBrush;
  rct: TGPRect;
begin
  if Assigned(Owner) and (Owner is TControl) and IsValidateHandle then
  begin
    if Assigned(FOnCheckValidate) then
    begin
      bValid := True;
      FOnCheckValidate(Self, Handle, bValid);
      if not bValid then
        InvalidateHandle;
    end
    else if Supports(Handle, IGPLinearGradientBrush, brh) then
    begin
      rct := brh.GetRectangle;
      if (rct.Width <> TControl(Owner).Width) or (rct.Height <> TControl(Owner).Height) then
        InvalidateHandle;
    end;
  end;

  Result := Handle as IGPBrush;
end;

procedure TDUIBrush.SetBrush(const AValue: IGPBrush);
begin
  Handle := AValue;
end;

{ TDUIColor }

procedure TDUIColor.AssignTo(ADest: TPersistent);
begin
  if Assigned(ADest) and (ADest is TDUIColor) then
    TDUIColor(ADest).FColor := FColor;

  inherited;
end;

function TDUIColor.CreateHandle: IInterface;
begin
  FColor := GetSkin.GetColor(SkinName);
  Result := nil;
end;

function TDUIColor.GetColor: TGPColor;
begin
  Handle; //触发GetHandle的动作(皮肤更新处理)
  Result := FColor;
end;

procedure TDUIColor.SetColor(const AValue: TGPColor);
begin
  FColor := AValue;
  Handle := nil;
end;

{ TDUIFont }

function TDUIFont.CreateHandle: IInterface;
begin
  Result := GetSkin.GetFont(SkinName);
end;

function TDUIFont.GetFont: IGPFont;
begin
  Result := Handle as IGPFont;
end;

procedure TDUIFont.SetFont(const AValue: IGPFont);
begin
  Handle := AValue;
end;

{ TDUIPen }

function TDUIPen.CreateHandle: IInterface;
begin
  Result := GetSkin.GetPen(SkinName);
end;

function TDUIPen.GetPen: IGPPen;
begin
  Result := Handle as IGPPen;
end;

procedure TDUIPen.SetPen(const AValue: IGPPen);
begin
  Handle := AValue;
end;

{ TDUIPictureChild }

procedure TDUIPictureChild.AssignTo(ADest: TPersistent);
begin
  if Assigned(ADest) and (ADest is TDUIPictureChild) then
  begin
    TDUIPictureChild(ADest).FName := FName;
    TDUIPictureChild(ADest).FRect := FRect;
  end
  else
    inherited;
end;

function TDUIPictureChild.GetImage: IGPImage;
begin
  Result := nil;
  if not Assigned(Collection) or not Assigned(TDUIPictureChilds(Collection).FParent) then
    Exit;

  Result := TDUIPictureChilds(Collection).FParent.GetChildImage(FRect);
end;

function TDUIPictureChild.GetValue(const AIndex: Integer): Integer;
begin
  case AIndex of
    1: Result := FRect.X;
    2: Result := FRect.Y;
    3: Result := FRect.Width;
    4: Result := FRect.Height;
  else
    Result := 0;
  end;
end;

procedure TDUIPictureChild.SetValue(const AIndex, AValue: Integer);
begin
  case AIndex of
    1: FRect.X := AValue;
    2: FRect.Y := AValue;
    3: FRect.Width := AValue;
    4: FRect.Height := AValue;
  end;

  Changed(False);
end;

{ TDUIPictureChilds }

constructor TDUIPictureChilds.Create(AParent: TDUIPicture);
begin
  inherited Create(TDUIPictureChild);

  FParent := AParent;
end;

function TDUIPictureChilds.AddChild(AName: String; ALeft, ATop, AWidth, AHeight: Integer): TDUIPictureChild;
begin
  Result := TDUIPictureChild(inherited Add);
  Result.Name := AName;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

function TDUIPictureChilds.IndexOfName(AName: String): Integer;
var
  iCount: Integer;
begin
  iCount := Count;
  for Result := 0 to iCount - 1 do
    if CompareText(AName, GetItems(Result).FName) = 0 then
      Exit;

  Result := -1;
end;

function TDUIPictureChilds.GetItems(AIndex: Integer): TDUIPictureChild;
begin
  Result := TDUIPictureChild(inherited Items[AIndex]);
end;

procedure TDUIPictureChilds.SetItems(AIndex: Integer; const AValue: TDUIPictureChild);
begin
  Items[AIndex].Assign(AValue);
end;

procedure TDUIPictureChilds.Update(AItem: TCollectionItem);
begin
  inherited;

  FParent.DoChange;
end;

{ TDUIPicture }

class procedure TDUIPicture.Init;
begin
  GetEncoderClsid('image/png', FClsidPng);
  GetEncoderClsid('image/bmp', FClsidBmp);
end;

procedure TDUIPicture.AssignTo(ADest: TPersistent);
begin
  if Assigned(ADest) and (ADest is TDUIPicture) then
  begin
    TDUIPicture(ADest).FChilds.Assign(FChilds);
    TDUIPicture(ADest).FBitmapCache := FBitmapCache;
  end;

  inherited;
end;

constructor TDUIPicture.Create(AOwner: TComponent; ASkinName: String);
begin
  FChilds := TDUIPictureChilds.Create(Self);

  inherited;
end;

destructor TDUIPicture.Destroy;
begin
  FreeAndNil(FChilds);

  inherited;
end;

function TDUIPicture.CreateHandle: IInterface;
var
  sSkinName, sChildNames: String;
  slstChilds: TStringList;
  hlp: TBaseHelper;
  i, iPos: Integer;
  pcSkin: TDUIPictureChilds;
begin
  BeginUpdate;
  try
    FChilds.Clear;
    FBitmapCache := nil;

    if SkinName = '' then
    begin
      Result := nil;
      Exit;
    end;

    sSkinName := SkinName;
    if sSkinName[Length(sSkinName)] = ']' then
    begin
      iPos := LastDelimiter('[', sSkinName);
      if iPos > 0 then
      begin
        sChildNames := MidStr(sSkinName, iPos + 1, Length(sSkinName) - iPos - 1);
        sSkinName := LeftStr(sSkinName, iPos - 1);
      end;
    end;

    slstChilds := nil;
    hlp := nil;
    try
      hlp := (GetSkin as IRawSkin).GetHelper(sSkinName +  '.__image__');
      if not Assigned(hlp) then
      begin
        Result := GetSkin.GetImage(sSkinName); //取默认图片
        Exit;
      end;

      Result := (hlp as TImageHelper).Picture.Image;
      pcSkin := (hlp as TImageHelper).Picture.Childs;

      if Trim(sChildNames) = '' then
      begin
        FChilds.Assign(pcSkin);
        Exit;
      end;

      slstChilds := TStringList.Create;
      slstChilds.Sorted := True;
      slstChilds.Delimiter := ',';
      slstChilds.DelimitedText := Trim(sChildNames);

      for i := 0 to slstChilds.Count - 1 do
      begin
        iPos := pcSkin.IndexOfName(Trim(slstChilds[i]));
        if iPos < 0 then
        begin
          iPos := StrToIntDef(Trim(slstChilds[i]), -1);
          if (iPos < 0) or (iPos >= FChilds.Count) then
            Continue;
        end;

        with pcSkin[iPos] do
          FChilds.AddChild(Name, Left, Top, Width, Height);
      end;
    finally
      FreeAndNil(hlp);
      FreeAndNil(slstChilds);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TDUIPicture.DefineProperties(AFiler: TFiler);
var
  bDoWrite: Boolean;
begin
  inherited;

  bDoWrite := (SkinName = '') and Assigned(Image);
//  if Assigned(AFiler.Ancestor) and (AFiler.Ancestor is TDUIPicture) then
//    bDoWrite := (FImage = TDUIPicture(AFiler.Ancestor).FImage);

  AFiler.DefineBinaryProperty('Data', ReadData, WriteData, bDoWrite);
end;

function TDUIPicture.GetBitmap: IGPBitmap;
var
  sa: IStream;
begin
  if not Assigned(FBitmapCache) then
  begin
    if not Supports(Image, IGPBitmap, FBitmapCache) then
    begin
      sa := TStreamAdapter.Create(TMemoryStream.Create, soOwned);
      Image.Save(sa, TDUIPicture.FClsidBmp); //如果使用TStringStream，会导致这里保存的数据不全，原因未知
      FBitmapCache := TGPBitmap.FromStream(sa);
    end;
  end;

  Result := FBitmapCache;
end;

function TDUIPicture.GetChildImage(const ARect: TGPRect): IGPImage;
var
  gra: IGPGraphics;
begin
  Result := TGPBitmap.Create(ARect.Width, ARect.Height);
  gra := TGPGraphics.Create(Result);
  gra.DrawImage(Image, 0, 0, ARect.X, ARect.Y, ARect.Width, ARect.Height, UnitPixel);
end;

function TDUIPicture.GetHeight: Integer;
begin
  Result := 0;
  if Assigned(Image) then
    Result := Image.Height;
end;

function TDUIPicture.GetImage: IGPImage;
begin
  Result := Handle as IGPImage;
end;

procedure TDUIPicture.SetChilds(const AValue: TDUIPictureChilds);
begin
  if FChilds = AValue then
    Exit;

  FChilds.Assign(AValue);
  DoChange;
end;

procedure TDUIPicture.SetImage(const AValue: IGPImage);
begin
  FBitmapCache := nil;
  Handle := AValue;
end;

function TDUIPicture.GetWidth: Integer;
begin
  Result := 0;
  if Assigned(Image) then
    Result := Image.Width;
end;

procedure TDUIPicture.ReadData(AStream: TStream);
var
  iLen: UInt64;
  ms: TMemoryStream;
begin
  AStream.Read(iLen, SizeOf(iLen));
  if iLen = 0 then
  begin
    Handle := nil;
  end
  else
  begin
    ms := TMemoryStream.Create; //TStreamAdapter会接管ms，因此，这里不释放
    ms.CopyFrom(AStream, iLen);
    Handle := TGPImage.Create(TStreamAdapter.Create(ms, soOwned));
  end;
end;

procedure TDUIPicture.WriteData(AStream: TStream);
var
  iLen: UInt64;
  ms: TMemoryStream;
begin
  if not Assigned(Image) or (SkinName <> '') then
  begin
    iLen := 0;
    AStream.Write(iLen, SizeOf(iLen));
  end
  else
  begin
    ms := TMemoryStream.Create;
    try
      Image.Save(TStreamAdapter.Create(ms), FClsidPng);

      iLen := ms.Size;
      AStream.Write(iLen, SizeOf(iLen));
      AStream.CopyFrom(ms, 0); //第2个参数传0表示拷贝整个ms的内容(CopyFrom中会将Position重置为0后再拷贝)
    finally
      FreeAndNil(ms);
    end;
  end;
end;

procedure TDUIPicture.LoadFromFile(AFileName: String);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(fs);
  finally
    FreeAndNil(fs);
  end;
end;

procedure TDUIPicture.LoadFromStream(AStream: TStream);
var
  ms: TMemoryStream;
begin
  //TStreamAdapter本质上只是一层包装，最后还是通过AStream来读取数据的，
  //如果外部调用者在加载完成后将AStream释放，就会导致TStreamAdapter访问野指针，
  //因此，这里将AStream的内容拷贝一个副本出来，交给TStreamAdapter管理
  ms := TMemoryStream.Create;
  ms.CopyFrom(AStream, AStream.Size);

  Handle := TGPImage.Create(TStreamAdapter.Create(ms, soOwned));
end;

initialization
  TDUIGraphicsObject.Init;
  TDUIPicture.Init;

finalization
  TDUIGraphicsObject.UnInit;

end.
