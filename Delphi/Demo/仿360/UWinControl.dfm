object FrmWinControl: TFrmWinControl
  Left = 0
  Top = 0
  Width = 881
  Height = 489
  object WcMain: TDUIWinContainer
    Left = 0
    Top = 0
    Width = 881
    Height = 489
    Align = alClient
    Color = clBtnShadow
    object ScEdit: TScintilla
      Left = 381
      Top = 0
      Width = 500
      Height = 489
      Anchors = [akLeft, akTop, akRight, akBottom]
      Language = lagCpp
      ShowLineNumber = True
      StyleFile = 'embed:DefaultStyle'
      Text = 
        '#include "stdio.h"'#13#10#13#10'int main()'#13#10'{'#13#10'    printf("hello world!");' +
        #13#10'    return 0;'#13#10'}'
    end
    object Button1: TButton
      Left = 198
      Top = 70
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 1
    end
    object Edit1: TEdit
      Left = 40
      Top = 72
      Width = 121
      Height = 21
      TabOrder = 2
      Text = 'Edit1'
    end
    object ComboBox1: TComboBox
      Left = 40
      Top = 120
      Width = 145
      Height = 21
      ItemHeight = 13
      TabOrder = 3
      Items.Strings = (
        #36873#25321'1'
        #36873#25321'2'
        #36873#25321'3')
    end
    object Panel1: TPanel
      Left = 32
      Top = 160
      Width = 313
      Height = 257
      Caption = 'Panel1'
      TabOrder = 4
    end
    object CheckBox1: TCheckBox
      Left = 40
      Top = 24
      Width = 97
      Height = 17
      Caption = 'CheckBox1'
      Color = clCream
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindow
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentCtl3D = False
      ParentFont = False
      TabOrder = 5
    end
    object RadioButton1: TRadioButton
      Left = 160
      Top = 24
      Width = 113
      Height = 17
      Caption = 'RadioButton1'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindow
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 6
    end
  end
end
