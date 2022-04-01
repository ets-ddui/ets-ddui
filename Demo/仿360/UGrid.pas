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
unit UGrid;

interface

uses
  UDUIForm, UDUITreeGrid, Classes, Controls, SysUtils, UDUICore, UDUIGrid, UDUIGridEx;

type
  TFrmGrid = class(TDUIFrame)
    DgTest: TDUIDrawGrid;
    TgTest: TDUITreeGrid;
    procedure DUIFrameResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.dfm}

constructor TFrmGrid.Create(AOwner: TComponent);
  procedure initDgTest;
  begin
    DgTest.Cells[3, 3] := '����';
    DgTest.Cells[3, 4] := '������';
    DgTest.Cells[3, 5] := '�˲�ѧ';
    DgTest.Cells[3, 6] := '��֪��';

    DgTest.Cells[4, 7] := '�ſ�';
    DgTest.Cells[4, 8] := '����ѩ';
    DgTest.Cells[4, 9] := '����';
    DgTest.Cells[4, 10] := '�Ȱ�105��c����';
    DgTest.Cells[4, 11] := '����';
    DgTest.Cells[4, 12] := '����';
    DgTest.Cells[4, 13] := '̤ɽ��';
    DgTest.Cells[4, 14] := '��紵';
    DgTest.Cells[4, 15] := '��̾';
    DgTest.Cells[4, 16] := '��������';

    DgTest.CellWidth[4] := 170;
    DgTest.Cells[4, 50] := '��򵥵��罻�����ǳ�����';
    DgTest.Cells[4, 51] := '��ʵ�õ����ɼ����Ƿ��Ӵ�';
    DgTest.Cells[4, 52] := '��Ѹ�ٵĽ��⼼�������Ӻ�';
    DgTest.Cells[4, 53] := '����Ч�ļ�ѹ������������';
    DgTest.Cells[4, 54] := '�����õ�ʡǮ������׬�Ķ�';
    DgTest.Cells[4, 55] := '��ֱ�ӵİ��Ŀ����Ǽ��п�';
  end;
  procedure initTgTest;
  var
    i: Integer;
  begin
    for i := 0 to 20 do
      TgTest.RootNode.AddChild('����');

    for i := 0 to 3 do
      TgTest.RootNode[0].AddChild('');
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0]] := 'ʫ��';
    TgTest.Cells[TgTest.Columns[1], TgTest.RootNode[0]] := '����';
    TgTest.Cells[TgTest.Columns[2], TgTest.RootNode[0]] := '����';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][0]] := '�ع����';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][1]] := '�ں�֮��';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][2]] := '����Ů';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][3]] := '���Ӻ���';

    for i := 0 to 3 do
      TgTest.RootNode[15].AddChild('');
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[15]] := 'Barry Fitzpatrick';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[15][0]] := 'I have searched a thousand years';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[15][1]] := 'And I have cried a thousand tears';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[15][2]] := 'I found everything I need';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[15][3]] := 'You are everything to me';
    TgTest.RootNode[15].Collapsed := True;
  end;
begin
  inherited;

  initDgTest;
  initTgTest;
end;

procedure TFrmGrid.DUIFrameResize(Sender: TObject);
const
  CSpace: Integer = 50;
begin
  DgTest.Width := (Width - CSpace) div 2;
  TgTest.Width := (Width - CSpace) div 2;
end;

end.
