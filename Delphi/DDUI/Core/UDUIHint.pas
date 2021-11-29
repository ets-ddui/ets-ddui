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
unit UDUIHint;

interface

uses
  Windows, Forms, Controls, Classes, SysUtils, Graphics, Messages, IGDIPlus, UDUICore, UDUIForm;

const
  DDUI_HINTHIDEPAUSE = WM_APP + 1001; //��CM_HINTSHOWPAUSE����ʹ��

type
  TMode = (moShow, moHide, moCheck);

  TDUIHintInfo = record
    FRawData: THintInfo;
    FDUIClass: TWinControlClass; //DUI�ؼ���ͨ�����ֶΣ�ָ��TDUIForm��ΪHint����
    FDUISize: TGPSize; //Hint���ڳߴ磬���THintWindow.CalcHintRect�Ĺ���
  end;

  TDUIHint = class(TDUIBase)
  private
    class var FHintControl: TDUIBase;
    class var FHintCursorRect: TGPRect; //�洢�ؼ�����(����Ļ���꣬���TApplication.HintMouseMessage�еı�׼�߼���ͬ)
    class var FHintWindow: TWinControl;
    class var FInstance: TDUIHint;
    class var FMode: TMode;
    class var FTimer: Pointer;
    class var FTimerForm: TDUIForm;
    class procedure Init;
    class procedure UnInit;
    class procedure ActivateHint(ACursorPos: TPoint); //ACursorPosΪFHintControl���������
    class procedure CancelHint;
    class function SetTimer(APause: Integer; AMode: TMode): Boolean;
    class procedure KillTimer;
  private
    procedure WMTimer(var AMessage: TWMTimer); message WM_TIMER;
  protected
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
  public
    class procedure HintMouseMessage(AControl: TDUIBase; const APoint: TPoint);
  end;

implementation

{ TDUIHint }

class procedure TDUIHint.HintMouseMessage(AControl: TDUIBase; const APoint: TPoint);
var
  iPause: Integer;
  msg: TMessage;
begin
  //1.0 ���ر�׼��Hint����
  if Assigned(AControl) then
  begin
    FillChar(msg, SizeOf(msg), 0);
    msg.Msg := WM_MOUSEMOVE;
    msg.LParamLo := AControl.Width + 1;
    msg.LParamHi := AControl.Height + 1;
    Application.HintMouseMessage(AControl, msg);
  end;

  if not Application.ShowHint then
  begin
    CancelHint;
    Exit;
  end;

  //2.0 DUI Hint���ڴ���
  if not Assigned(AControl) or not AControl.ShowHint then
  begin
    if Assigned(FHintWindow) then
    begin
      iPause := Application.HintHidePause;
      if Assigned(FHintControl) then
        FHintControl.Perform(DDUI_HINTHIDEPAUSE, 0, Longint(@iPause));
      if iPause = 0 then
        CancelHint
      else
        SetTimer(iPause, moHide);
    end;
  end
  else if (FHintControl = AControl) and PtInGPRect(FHintCursorRect, APoint) and Assigned(FHintWindow) then
  begin
    //���δ�Ƴ�FHintControl��ʲô������
  end     
  else
  begin
    if FHintControl <> AControl then
    begin
      if Assigned(FHintControl) then
        FHintControl.RemoveFreeNotification(FInstance);
      FHintControl := AControl;
      FHintControl.FreeNotification(FInstance);
    end;
    FHintCursorRect := MakeRect(FHintControl.ClientRect);

    iPause := 0;
    if not Assigned(FHintWindow) then
    begin
      iPause := Application.HintPause;
      FHintControl.Perform(CM_HINTSHOWPAUSE, 0, Longint(@iPause));
    end;

    if iPause = 0 then
      ActivateHint(APoint)
    else
      SetTimer(iPause, moShow);
  end;
end;

class procedure TDUIHint.ActivateHint(ACursorPos: TPoint);
  //findScanline��getCursorHeightMargin����TApplication.ActivateHint�п�������
  function findScanline(ASource: Pointer; AMaxLen: Cardinal; AValue: Cardinal): Cardinal; assembler;
  asm
    PUSH    ECX
    MOV     ECX, EDX
    MOV     EDX, EDI
    MOV     EDI, EAX
    POP     EAX
    REPE    SCASB
    MOV     EAX, ECX
    MOV     EDI, EDX
  end;
  function getCursorHeightMargin: Integer;
  var
    IconInfo: TIconInfo;
    BitmapInfoSize, BitmapBitsSize, ImageSize: DWORD;
    Bitmap: PBitmapInfoHeader;
    Bits: Pointer;
    BytesPerScanline: Integer;
  begin
    Result := GetSystemMetrics(SM_CYCURSOR);
    if not GetIconInfo(GetCursor, IconInfo) then
      Exit;

    Bitmap := nil;
    try
      GetDIBSizes(IconInfo.hbmMask, BitmapInfoSize, BitmapBitsSize);
      Bitmap := AllocMem(DWORD(BitmapInfoSize) + BitmapBitsSize);
      Bits := Pointer(DWORD(Bitmap) + BitmapInfoSize);
      if GetDIB(IconInfo.hbmMask, 0, Bitmap^, Bits^) and
        (Bitmap^.biBitCount = 1) then
      begin
        with Bitmap^ do
        begin
          BytesPerScanline := ((biWidth * biBitCount + 31) and not 31) div 8;
          ImageSize := biWidth * BytesPerScanline;
          Bits := Pointer(DWORD(Bits) + BitmapBitsSize - ImageSize);
          Result := findScanline(Bits, ImageSize, $FF);
          if (Result = 0) and (biHeight >= 2 * biWidth) then
            Result := findScanline(Pointer(DWORD(Bits) - ImageSize),
            ImageSize, $00);
          Result := Result div BytesPerScanline;
        end;
        Dec(Result, IconInfo.yHotSpot);
      end;
    finally
      if Assigned(Bitmap) then
        FreeMem(Bitmap, BitmapInfoSize + BitmapBitsSize);
      if IconInfo.hbmColor <> 0 then
        DeleteObject(IconInfo.hbmColor);
      if IconInfo.hbmMask <> 0 then
        DeleteObject(IconInfo.hbmMask);
    end;
  end;
var
  ht: TDUIHintInfo;
  ptCursor: TPoint;
  iCursorHeight: Integer;
  bCanShow: Boolean;
  rct: TGPRect;
begin
  KillTimer;

  //1.0 ���Hint���ڵĽṹ��Ϣ
  ht.FRawData.HintControl := FHintControl;
  ht.FRawData.HintWindowClass := Forms.HintWindowClass;
  ht.FRawData.HintPos := FHintControl.ClientToScreen(ACursorPos);

  iCursorHeight := getCursorHeightMargin;
  GetCursorPos(ptCursor);
  if (ht.FRawData.HintPos.Y >= ptCursor.Y) and (ht.FRawData.HintPos.Y < ptCursor.Y + iCursorHeight) then
    ht.FRawData.HintPos.Y := ptCursor.Y + iCursorHeight;

  ht.FRawData.HintMaxWidth := Screen.Width;
  ht.FRawData.HintColor := Application.HintColor;
  ht.FRawData.CursorRect := FHintControl.ClientRect;
  ht.FRawData.CursorPos := ACursorPos;
  ht.FRawData.HideTimeout := Application.HintHidePause;
  ht.FRawData.HintStr := FHintControl.Hint;
  ht.FRawData.HintData := nil;
  ht.FDUIClass := nil;

  //2.0 HintControl�Խṹ��Ϣ�����ݽ��ж���
  bCanShow := FHintControl.Perform(CM_HINTSHOW, 1, Longint(@ht)) = 0; //ͨ��WParam������Delphi�ı�׼��Ϣ������DUI�Ķ�����Ϣ(��׼��Ϣ��0��������Ϣ��1)
  if bCanShow and Assigned(Application.OnShowHint) then
    Application.OnShowHint(ht.FRawData.HintStr, bCanShow, ht.FRawData);

  if not bCanShow then
    Exit;

  FHintCursorRect := MakeRect(ht.FRawData.CursorRect);

  //3.0 �������ڲ����㴰����ʾ����
  FreeAndNil(FHintWindow);
  if Assigned(ht.FDUIClass) then
  begin
    FHintWindow := ht.FDUIClass.Create(Application);
    rct := MakeRect(ht.FRawData.HintPos.X, ht.FRawData.HintPos.Y,
      ht.FDUISize.Width, ht.FDUISize.Height);
    SetWindowPos(FHintWindow.Handle, HWND_TOPMOST, rct.X, rct.Y, rct.Width, rct.Height, SWP_NOACTIVATE);
    FHintWindow.ParentWindow := Application.Handle;
    ShowWindow(FHintWindow.Handle, SW_SHOWNOACTIVATE);
    FHintWindow.Invalidate;
  end
  else
  begin
    if Assigned(ht.FRawData.HintWindowClass) then
      FHintWindow := ht.FRawData.HintWindowClass.Create(Application)
    else
      FHintWindow := Forms.HintWindowClass.Create(Application);

    rct := MakeRect((FHintWindow as THintWindow).CalcHintRect(
      ht.FRawData.HintMaxWidth, ht.FRawData.HintStr, ht.FRawData.HintData));
    rct.X := rct.X + ht.FRawData.HintPos.X;
    rct.Y := rct.Y + ht.FRawData.HintPos.Y;

    (FHintWindow as THintWindow).Color := ht.FRawData.HintColor;
    (FHintWindow as THintWindow).ActivateHintData(
      Rect(rct.X, rct.Y, rct.X + rct.Width, rct.Y + rct.Height),
      ht.FRawData.HintStr, ht.FRawData.HintData);
  end;

  SetTimer(100, moCheck);
end;

class procedure TDUIHint.CancelHint;
begin
  KillTimer;

  { ���ﲻ�ͷ�FHintControl��������ActivateHint�е���KillTimerʱ��
    �ᴥ��Notification����FHintControl�ͷţ�ActivateHint�ĺ���������ַ���Υ��
  if Assigned(FHintControl) then
  begin
    FHintControl.RemoveFreeNotification(FInstance);
    FHintControl := nil;
  end;
  }

  if Assigned(FHintWindow) then
    FreeAndNil(FHintWindow);
end;

class procedure TDUIHint.Init;
begin
  if not Assigned(FInstance) then
    FInstance := TDUIHint.Create(nil);
end;

class procedure TDUIHint.UnInit;
begin
  KillTimer;
  FreeAndNil(FInstance);
end;

class function TDUIHint.SetTimer(APause: Integer; AMode: TMode): Boolean;
var
  wcForm: TWinControl;
begin
  Result := False;

  if Assigned(FTimer) and (FMode = AMode) then
    Exit;

  //1.0 ɾ���ɵļ�ʱ��
  KillTimer;

  //2.0 FTimerForm��ʼ��
  repeat
    if Assigned(FTimerForm) then
      Break;

    wcForm := Application.MainForm;
    if Assigned(wcForm) and (wcForm is TDUIForm) then
    begin
      FTimerForm := wcForm as TDUIForm;
      Break;
    end;

    if not Assigned(FHintControl) then
      Exit;

    wcForm := FHintControl.RootParent;
    if Assigned(wcForm) and (wcForm is TDUIForm) then
    begin
      FTimerForm := wcForm as TDUIForm;
      Break;
    end;

    Exit;
  until True;

  //3.0 ���ü�ʱ��
  FMode := AMode;
  if AMode = moCheck then
    FTimer := FTimerForm.SetDUITimer(FInstance, APause, True)
  else
    FTimer := FTimerForm.SetDUITimer(FInstance, APause, False);

  Result := True;
end;

class procedure TDUIHint.KillTimer;
begin
  if not Assigned(FTimerForm) or not Assigned(FTimer) then
    Exit;

  FTimerForm.KillDUITimer(FTimer);
  FTimer := nil;
end;

procedure TDUIHint.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if AOperation = opRemove then
  begin
    if FHintControl = AComponent then
    begin
      FHintControl := nil;
      CancelHint;
    end
    else if FHintWindow = AComponent then
    begin
      FHintWindow := nil;
    end
    else if FTimer = AComponent then
    begin
      FTimer := nil;
      CancelHint;
    end
    else if FTimerForm = AComponent then
    begin
      FTimerForm := nil;
      CancelHint;
    end;
  end;
end;

procedure TDUIHint.WMTimer(var AMessage: TWMTimer);
var
  pt: TPoint;
begin
  case FMode of
    moShow:
    begin
      FTimer := nil;
      if not Assigned(FHintControl) then
        Exit;

      GetCursorPos(pt);
      ActivateHint(FHintControl.ScreenToClient(pt));
    end;
    moHide:
    begin
      FTimer := nil;

      CancelHint;
    end;
    moCheck:
    begin
      if not Assigned(FHintControl) then
      begin
        KillTimer;
        Exit;
      end;

      GetCursorPos(pt);
      pt := FHintControl.ScreenToClient(pt);
      if not PtInRect(FHintControl.ClientRect, pt) then
      begin
        KillTimer;
        HintMouseMessage(nil, Point(0, 0));
      end;
    end;  
  end;
end;

initialization
  TDUIHint.Init;

finalization
  TDUIHint.UnInit;

end.
