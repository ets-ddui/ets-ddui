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
unit UDUIComboBox;

interface

uses
  Windows, Classes, SysUtils, Controls, Forms, Messages,
  UDUICore, UDUIEdit, UDUIButton, UDUIShape, UDUIPopupForm, UDUIGrid, UDUIGridEx;

type
  TDUIComboBox = class(TDUIBase)
  private
    FEdit: TDUIEdit;
    FButton: TDUIButton;
    FDropDownForm: TDUIPopupForm;
    FDropDownGrid: TDUIDrawGrid;
    FOldFormWndProc: TWndMethod;
    procedure DoDropDown(ASender: TObject);
    procedure DoClose(ASender: TObject; var AAction: TCloseAction);
    procedure FormWndProc(var AMessage: TMessage);
    function GetOnChange: TNotifyEvent;
    function GetReadOnly: Boolean;
    procedure SetOnChange(const AValue: TNotifyEvent);
    procedure SetReadOnly(const AValue: Boolean);
  protected
    procedure WndProc(var AMessage: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    function AddData(AValue: String): Integer;
    procedure Clear;
  published
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Text;
    property OnChange: TNotifyEvent read GetOnChange write SetOnChange;
  end;

implementation

{ TDUIComboBox }

const
  CButtonWidth: Integer = 10;

constructor TDUIComboBox.Create(AOwner: TComponent);
begin
  inherited;

  SetBounds(0, 0, 121, 25);

  FEdit := TDUIEdit.Create(Self);
  FEdit.DUIParent := Self;
  FEdit.ArcBorder := False;
  FEdit.Align := alClient;

  FButton := TDUIButton.Create(Self);
  FButton.DUIParent := FEdit;
  FButton.Width := CButtonWidth;
  FButton.Align := alRight;
  FButton.Shape.ShapeType := stAngle;
  FButton.Shape.AlignKeepSize := False;
  FButton.Shape.Spin := 90;
  FButton.OnClick := DoDropDown;

  FDropDownGrid := TDUIDrawGrid.Create(Self);
  FDropDownGrid.Options := [];
  FDropDownGrid.ColCount := 1;
  FDropDownGrid.Align := alClient;
end;

function TDUIComboBox.AddData(AValue: String): Integer;
begin
  FDropDownGrid.RowCount := FDropDownGrid.RowCount + 1;
  FDropDownGrid.Cells[1, FDropDownGrid.RowCount] := AValue;
  Result := FDropDownGrid.RowCount;
end;

procedure TDUIComboBox.Clear;
begin
  FDropDownGrid.RowCount := 0;
end;

procedure TDUIComboBox.DoClose(ASender: TObject; var AAction: TCloseAction);
begin
  FDropDownForm := nil;
  FDropDownGrid.Parent := nil;
end;

procedure TDUIComboBox.DoDropDown(ASender: TObject);
var
  pt: TPoint;
  iMaxCount: Integer;
begin
  if Assigned(FDropDownForm) or (Height = 0) then
    Exit;

  iMaxCount := Screen.Height div Height div 2; //�����������ֻռ��Ļ��һ��߶�

  pt := ClientToScreen(Point(0, Height));
  FDropDownForm := TDUIPopupForm.CreateNew(nil);
  FDropDownForm.OnClose := DoClose;
  FOldFormWndProc := FDropDownForm.WindowProc;
  FDropDownForm.WindowProc := FormWndProc;
  FDropDownForm.Width := Width;
  if FDropDownGrid.RowCount = 0 then
    FDropDownForm.Height := Height
  else if FDropDownGrid.RowCount > iMaxCount then
    FDropDownForm.Height := Height * iMaxCount
  else
    FDropDownForm.Height := Height * FDropDownGrid.RowCount;
  FDropDownForm.Left := pt.X;
  if (pt.Y + FDropDownForm.Height) < Screen.Height then
    FDropDownForm.Top := pt.Y
  else
    FDropDownForm.Top := pt.Y - Height - FDropDownForm.Height;

  FDropDownGrid.Parent := FDropDownForm;
  FDropDownGrid.DefaultColWidth := Width;
  FDropDownGrid.DefaultRowHeight := Height;

  FDropDownForm.Show;
  FDropDownForm.SetDUIFocusedControl(FDropDownGrid);
end;

procedure TDUIComboBox.FormWndProc(var AMessage: TMessage);
begin
  FOldFormWndProc(AMessage);

  case AMessage.Msg of
    WM_CHAR:
    begin
      case TWMKey(AMessage).CharCode of
        VK_ESCAPE:
        begin
          FDropDownForm.Close;
          Exit;
        end;
        VK_RETURN:
        begin
          FEdit.Text := FDropDownGrid.Cells[1, FDropDownGrid.Row];
          FDropDownForm.Close;
          Exit;
        end;
      end;
    end;
    WM_LBUTTONUP, WM_RBUTTONUP:
    begin
      FEdit.Text := FDropDownGrid.Cells[1, FDropDownGrid.Row];
      FDropDownForm.Close;
      Exit;
    end;
  end;
end;

procedure TDUIComboBox.WndProc(var AMessage: TMessage);
begin
  case AMessage.Msg of
    WM_GETTEXTLENGTH, WM_GETTEXT, WM_SETTEXT:
    begin
      //��Text������ص��¼���ȫ��ת����FEdit����
      FEdit.WindowProc(AMessage);
      Exit;
    end;
  end;

  inherited;
end;

function TDUIComboBox.GetOnChange: TNotifyEvent;
begin
  Result := FEdit.OnChange;
end;

procedure TDUIComboBox.SetOnChange(const AValue: TNotifyEvent);
begin
  FEdit.OnChange := AValue;
end;

function TDUIComboBox.GetReadOnly: Boolean;
begin
  Result := FEdit.ReadOnly;
end;

procedure TDUIComboBox.SetReadOnly(const AValue: Boolean);
begin
  FEdit.ReadOnly := AValue;
  FButton.Enabled := not AValue;
end;

end.
