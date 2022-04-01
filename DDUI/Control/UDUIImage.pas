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
unit UDUIImage;

interface

uses
  Classes, SysUtils, ActiveX, IGDIPlus, UDUICore, UDUIGraphics;

type
  TDUIImage = class(TDUIBase)
  private
    FPicture: TDUIPicture;
    procedure SetPicture(const AValue: TDUIPicture);
  protected
    procedure DoPaint(AGPCanvas: IGPGraphics); override;
    function IsTransparent: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Picture: TDUIPicture read FPicture write SetPicture;
  end;

implementation

{ TDUIImage }

constructor TDUIImage.Create(AOwner: TComponent);
begin
  inherited;

  FPicture := TDUIPicture.Create(Self, '');
end;

procedure TDUIImage.DoPaint(AGPCanvas: IGPGraphics);
var
  rct: TGPRect;
begin
  if not Assigned(FPicture.Image) then
    Exit;

  if (Width = 0) or (Height = 0) or (FPicture.Width = 0) or (FPicture.Height = 0) then
    Exit;

  if (FPicture.Width > Width) or (FPicture.Height > Height) then
  begin
    if (FPicture.Width / FPicture.Height) > (Width / Height) then
    begin
      rct.Width := Width;
      rct.Height := Width * FPicture.Height div FPicture.Width;
    end
    else
    begin
      rct.Width := Height * FPicture.Width div FPicture.Height;
      rct.Height := Height;
    end;
  end
  else
  begin
    rct.Width := FPicture.Width;
    rct.Height := FPicture.Height;
  end;

  rct.X := (Width - rct.Width) div 2;
  rct.Y := (Height - rct.Height) div 2;

  AGPCanvas.DrawImage(FPicture.Image, rct);
end;

function TDUIImage.IsTransparent: Boolean;
begin
  Result := True;
end;

procedure TDUIImage.SetPicture(const AValue: TDUIPicture);
begin
  FPicture.Assign(AValue);
end;

end.
