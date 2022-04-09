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
unit UAbout;

interface

uses
  UDUIForm, Classes, Controls, UDUICore, UDUILabel, UDUIPanel, UDUIImage;

type
  TFrmAbout = class(TDUIFrame)
    LblLicense: TDUILabel;
    LblAuthor: TDUILabel;
    LblAbout: TDUILabel;
    PnlContent: TDUIPanel;
    ImgMain: TDUIImage;
  end;

implementation

{$R *.dfm}

end.
