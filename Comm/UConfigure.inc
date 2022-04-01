{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi，让漂亮界面做起来更简单。

  本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
  发布此库的目的是希望其有用，但不做任何保证。
  如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

  开源地址: https://github.com/ets-ddui/ets-ddui
  开源协议: The MIT License (MIT)
  作者邮箱: xinghun87@163.com
  官方博客：https://blog.csdn.net/xinghun61
}
//1.0 Free Pascal版本定义
{$IFDEF FPC}
{$DEFINE LAZARUS}
{$ENDIF}

//2.0 Delphi及C++ Builder版本定义
{
http://blog.csdn.net/cb168/article/details/9319393
DELPHI的版本宏：
VER80  - Delphi 1
VER90  - Delphi 2
VER100 - Delphi 3
VER120 - Delphi 4
VER130 - Delphi 5
VER140 - Delphi 6
VER150 - Delphi 7
VER160 - Delphi 8
VER170 - Delphi 2005
VER180 - Delphi 2006
VER190 - Delphi 2007（兼容2006）
VER185 - Delphi 2007
VER200 - CodeGear RAD Studio 2009
VER210 - CodeGear RAD Studio 2010
VER220 - CodeGear RAD Studio 2011 XE
VER230 - Delphi XE2 / C++Builder XE2
VER240 - Delphi XE3 / C++Builder XE3
VER250 - Delphi XE4 / C++Builder XE4
VER260 - Delphi XE5 / C++Builder XE5
VER270 - Delphi XE6 / C++Builder XE6
VER280 - Delphi XE7 / C++Builder XE7

BCB的版本宏：
VER93  - BCB 1
VER110 - BCB 3
VER125 - BCB 4
VER135 - BCB 5
VER145 - BCB 6

Kylix的版本宏：
VER140 - Kylix 1, Kylix 2
VER150 - Kylix 3

更老的Turbo Pascal版本宏：
VER40  - TP 4
VER50  - TP 5
VER55  - TP 5.5
VER60  - TP 6
VER10  - TPW 1
VER15  - TPW 1.5
VER70  - TP 7, BP 7, BP 7.01
}
//2.1 定义版本标识
{$IFDEF VER90}
{$DEFINE D0002}
{$ENDIF}

{$IFDEF VER100}
{$DEFINE D0003}
{$ENDIF}

{$IFDEF VER120}
{$DEFINE D0004}
{$ENDIF}

{$IFDEF VER130}
{$DEFINE D0005}
{$ENDIF}

{$IFDEF VER140}
{$DEFINE D0006}
{$ENDIF}

{$IFDEF VER150}
{$DEFINE D0007}
{$ENDIF}

{$IFDEF VER160}
{$DEFINE D0008}
{$ENDIF}

{$IFDEF VER170}
{$DEFINE D2005}
{$ENDIF}

{$IFDEF VER180}
{$DEFINE D2006}
{$ENDIF}

{$IFDEF VER190}
{$DEFINE D2007}
{$ENDIF}

{$IFDEF VER200}
{$DEFINE D2009}
{$ENDIF}

{$IFDEF VER210}
{$DEFINE D2010}
{$ENDIF}

{$IFDEF VER220}
{$DEFINE XE}
{$ENDIF}

{$IFDEF VER230}
{$DEFINE XE2}
{$ENDIF}

{$IFDEF VER240}
{$DEFINE XE3}
{$ENDIF}

{$IFDEF VER250}
{$DEFINE XE4}
{$ENDIF}

{$IFDEF VER260}
{$DEFINE XE5}
{$ENDIF}

{$IFDEF VER270}
{$DEFINE XE6}
{$ENDIF}

{$IFDEF VER280}
{$DEFINE XE7}
{$ENDIF}

//2.2 扩展版本标识定义
{$IFDEF XE7}
{$DEFINE XE6}
{$ENDIF}

{$IFDEF XE6}
{$DEFINE XE5}
{$ENDIF}

{$IFDEF XE5}
{$DEFINE XE4}
{$ENDIF}

{$IFDEF XE4}
{$DEFINE XE3}
{$ENDIF}

{$IFDEF XE3}
{$DEFINE XE2}
{$ENDIF}

{$IFDEF XE2}
{$DEFINE XE}
{$ENDIF}

{$IFDEF XE}
{$DEFINE D2010}
{$ENDIF}

{$IFDEF D2010}
{$DEFINE D2009}
{$ENDIF}

{$IFDEF D2009}
{$DEFINE D2007}
{$ENDIF}

{$IFDEF D2007}
{$DEFINE D2006}
{$ENDIF}

{$IFDEF D2006}
{$DEFINE D2005}
{$ENDIF}

{$IFDEF D2005}
{$DEFINE D0008}
{$ENDIF}

{$IFDEF D0008}
{$DEFINE D0007}
{$ENDIF}

{$IFDEF D0007}
{$DEFINE D0006}
{$ENDIF}

{$IFDEF D0006}
{$DEFINE D0005}
{$ENDIF}

{$IFDEF D0005}
{$DEFINE D0004}
{$ENDIF}

{$IFDEF D0004}
{$DEFINE D0003}
{$ENDIF}

{$IFDEF D0003}
{$DEFINE D0002}
{$ENDIF}

{$IFDEF D0002}
{$DEFINE DELPHI}
{$ENDIF}

//3.0 其他选项设置
{$IFDEF LAZARUS}
{$MODE objfpc}
//{$MODESWITCH CVAR-}
//{$MODESWITCH NESTEDCOMMENTS-}
{$MODESWITCH CLASSICPROCVARS+} //在给事件属性赋值时，不需添加"@"
//{$MODESWITCH REPEATFORWARD-}
{$MODESWITCH POINTERTOPROCVAR+} //指针类型的赋值，不会检查指针类型(例如通过Windows.GetProcAddress获取的值可以直接赋给过程变量)
{$MODESWITCH AUTODEREF+}
{$MODESWITCH DUPLICATELOCALS+} //函数入参可以与属性重名
{$H+}
{$ASMMODE INTEL}

{$DEFINE PACKAGE_COMPILE_MODE}
{$ENDIF}
