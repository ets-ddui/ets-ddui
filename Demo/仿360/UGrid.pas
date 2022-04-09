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
    DgTest.Cells[3, 3] := '玉不琢';
    DgTest.Cells[3, 4] := '不成器';
    DgTest.Cells[3, 5] := '人不学';
    DgTest.Cells[3, 6] := '不知道';

    DgTest.Cells[4, 7] := '放空';
    DgTest.Cells[4, 8] := '半生雪';
    DgTest.Cells[4, 9] := '不如';
    DgTest.Cells[4, 10] := '热爱105°c的你';
    DgTest.Cells[4, 11] := '雾里';
    DgTest.Cells[4, 12] := '别错过';
    DgTest.Cells[4, 13] := '踏山河';
    DgTest.Cells[4, 14] := '大风吹';
    DgTest.Cells[4, 15] := '怎叹';
    DgTest.Cells[4, 16] := '不该用情';

    DgTest.CellWidth[4] := 170;
    DgTest.Cells[4, 50] := '最简单的社交技巧是长得美';
    DgTest.Cells[4, 51] := '最实用的收纳技巧是房子大';
    DgTest.Cells[4, 52] := '最迅速的解题技巧是脑子好';
    DgTest.Cells[4, 53] := '最有效的减压技巧是死了心';
    DgTest.Cells[4, 54] := '最有用的省钱妙招是赚的多';
    DgTest.Cells[4, 55] := '最直接的安心快乐是家有矿';
  end;
  procedure initTgTest;
  var
    i: Integer;
  begin
    for i := 0 to 20 do
      TgTest.RootNode.AddChild('无题');

    for i := 0 to 3 do
      TgTest.RootNode[0].AddChild('');
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0]] := '诗经';
    TgTest.Cells[TgTest.Columns[1], TgTest.RootNode[0]] := '周南';
    TgTest.Cells[TgTest.Columns[2], TgTest.RootNode[0]] := '关雎';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][0]] := '关关雎鸠';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][1]] := '在河之洲';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][2]] := '窈窕淑女';
    TgTest.Cells[TgTest.Columns[0], TgTest.RootNode[0][3]] := '君子好逑';

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
