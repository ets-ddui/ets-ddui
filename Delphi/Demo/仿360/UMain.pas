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
      str := Format('������Ϣ��'#$D#$A'(%s)%s'#$D#$A'����ջ��'#$D#$A'%s',
        [AExceptObj.ClassName, Exception(AExceptObj).Message, slst.Text])
    else
      str := Format('������Ϣ��'#$D#$A'%s'#$D#$A'����ջ��'#$D#$A'%s',
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
