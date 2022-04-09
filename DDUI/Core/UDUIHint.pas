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
unit UDUIHint;

interface

uses
  Windows, Forms, Controls, Classes, SysUtils, Graphics, Messages, IGDIPlus, UDUICore, UDUIForm;

const
  DDUI_HINTHIDEPAUSE = WM_APP + 1001; //与CM_HINTSHOWPAUSE配套使用

type
  TMode = (moShow, moHide, moCheck);

  TDUIHintInfo = record
    FRawData: THintInfo;
    FDUIClass: TWinControlClass; //DUI控件可通过此字段，指定TDUIForm作为Hint窗口
    FDUISize: TGPSize; //Hint窗口尺寸，替代THintWindow.CalcHintRect的功能
  end;

  TDUIHint = class(TDUIBase)
  private
    class var FHintControl: TDUIBase;
    class var FHintCursorRect: TGPRect; //存储控件坐标(非屏幕坐标，这和TApplication.HintMouseMessage中的标准逻辑不同)
    class var FHintWindow: TWinControl;
    class var FInstance: TDUIHint;
    class var FMode: TMode;
    class var FTimer: Pointer;
    class var FTimerForm: TDUIForm;
    class procedure Init;
    class procedure UnInit;
    class procedure ActivateHint(ACursorPos: TPoint); //ACursorPos为FHintControl的相对坐标
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
  //1.0 隐藏标准的Hint窗口
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

  //2.0 DUI Hint窗口处理
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
    //鼠标未移出FHintControl，什么都不做
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
  //findScanline、getCursorHeightMargin均从TApplication.ActivateHint中拷贝而来
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

  //1.0 填充Hint窗口的结构信息
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

  //2.0 HintControl对结构信息的内容进行定制
  bCanShow := FHintControl.Perform(CM_HINTSHOW, 1, Longint(@ht)) = 0; //通过WParam区分是Delphi的标准消息，还是DUI的定制消息(标准消息传0，定制消息传1)
  if bCanShow and Assigned(Application.OnShowHint) then
    Application.OnShowHint(ht.FRawData.HintStr, bCanShow, ht.FRawData);

  if not bCanShow then
    Exit;

  FHintCursorRect := MakeRect(ht.FRawData.CursorRect);

  //3.0 创建窗口并计算窗口显示坐标
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

  { 这里不释放FHintControl，否则，在ActivateHint中调用KillTimer时，
    会触发Notification而将FHintControl释放，ActivateHint的后续处理出现访问违例
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

  //1.0 删除旧的计时器
  KillTimer;

  //2.0 FTimerForm初始化
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

  //3.0 设置计时器
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
