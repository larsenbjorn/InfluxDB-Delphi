object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Influx DB Demo'
  ClientHeight = 624
  ClientWidth = 1016
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 40
    Top = 32
    Width = 161
    Height = 25
    Caption = 'Create Database'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 40
    Top = 152
    Width = 753
    Height = 353
    TabOrder = 1
  end
  object Button2: TButton
    Left = 40
    Top = 63
    Width = 161
    Height = 25
    Caption = 'Show Databases'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 248
    Top = 32
    Width = 201
    Height = 25
    Caption = 'Write 1'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 248
    Top = 63
    Width = 201
    Height = 25
    Caption = 'Write 1.2'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 480
    Top = 32
    Width = 169
    Height = 25
    Caption = 'Write 1000'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 40
    Top = 96
    Width = 161
    Height = 25
    Caption = 'Server Version'
    TabOrder = 6
    OnClick = Button6Click
  end
end
