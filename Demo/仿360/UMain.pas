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
unit UMain;

interface

uses
  Windows, SysUtils, UDUIForm, Classes, Controls, UDUICore, UDUIButton, UDUIPanel;

type
  TFmMain = class(TDUIForm)
    PnlControl: TDUIPanel;
    SbAbout: TDUISpeedButton;
    SbWelcome: TDUISpeedButton;
    SbWinControl: TDUISpeedButton;
    SbGrid: TDUISpeedButton;
    SbNormal: TDUISpeedButton;
    procedure DoOnClick(Sender: TObject);
    procedure DUIFormShow(Sender: TObject);
  private
    FFrame: array of TDUIBase;
    FCurrFrame: TDUIBase;
  end;

var
  FmMain: TFmMain;

implementation

uses
  Messages, UTool, JclDebug, JclHookExcept,
  UDUISkin, UWelcome, UNormal, UGrid, UWinControl, UAbout;

{$R *.dfm}

procedure TFmMain.DoOnClick(Sender: TObject);
const
  CFrameClass: array[0..4] of TDUIBaseClass = (TFrmWelcome, TFrmNormal, TFrmGrid, TFrmWinControl, TFrmAbout);
var
  i, iTag: Integer;
begin
  iTag := TDUISpeedButton(Sender).Tag;
  if (iTag < Low(CFrameClass)) or (iTag > High(CFrameClass)) then
    Exit;

  if Length(FFrame) = 0 then
  begin
    SetLength(FFrame, Length(CFrameClass));
    for i := Length(FFrame) - 1 downto 0 do
      FFrame[i] := nil;
  end;

  if Assigned(CFrameClass[iTag]) and not Assigned(FFrame[iTag]) then
  begin
    FFrame[iTag] := CFrameClass[iTag].Create(Self);
    FFrame[iTag].Visible := True;
    FFrame[iTag].Align := alClient;
    FFrame[iTag].Parent := Self;
  end;

  if FCurrFrame = FFrame[iTag] then
    Exit;

  if Assigned(FCurrFrame) then
    FCurrFrame.Visible := False;

  FCurrFrame := FFrame[iTag];

  if Assigned(FCurrFrame) then
    FCurrFrame.Visible := True;
end;

procedure TFmMain.DUIFormShow(Sender: TObject);
begin
  SbWelcome.Perform(WM_LBUTTONDOWN, 0, MakeLParam(0, 0));
  SbWelcome.Perform(WM_LBUTTONUP, 0, MakeLParam(0, 0));
end;

procedure DoJclException(AExceptObj: TObject; AExceptAddr: Pointer; AOSException: Boolean);
var
  slst: TStringList;
  str: String;
begin
  slst := TStringList.Create;
  try
    JclLastExceptStackListToStrings(slst, True);
    if AExceptObj is Exception then
      str := Format('错误信息：'#$D#$A'(%s)%s'#$D#$A'调用栈：'#$D#$A'%s',
        [AExceptObj.ClassName, Exception(AExceptObj).Message, slst.Text])
    else
      str := Format('错误信息：'#$D#$A'%s'#$D#$A'调用栈：'#$D#$A'%s',
        [AExceptObj.ClassName, slst.Text]);
  finally
    FreeAndNil(slst);
  end;

  WriteView(str);
end;

initialization
  JclStartExceptionTracking;
  JclAddExceptNotifier(DoJclException);

end.
