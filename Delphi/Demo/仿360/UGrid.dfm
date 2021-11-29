object FrmGrid: TFrmGrid
  Left = 0
  Top = 0
  Width = 881
  Height = 489
  OnResize = DUIFrameResize
  object DgTest: TDUIDrawGrid
    Left = 0
    Top = 0
    Width = 400
    Height = 489
    Align = alLeft
    ColCount = 30
    RowCount = 100
    Options = [goVertTitleLine, goHorzTitleLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goVertTitle, goHorzTitle]
  end
  object TgTest: TDUITreeGrid
    Left = 481
    Top = 0
    Width = 400
    Height = 489
    Align = alRight
    Columns = <
      item
        Caption = #21015'1'
        Percent = True
        Width = 20
      end
      item
        Caption = #21015'2'
        Percent = True
        Width = 10
      end
      item
        Caption = #21015'3'
        Width = 80
      end>
    Options = [goVertTitleLine, goHorzTitleLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect, goVertTitle]
  end
end
