{
  Copyright (c) 2021-2031 Steven Shi

  ETS_DDUI For Delphi����Ư���������������򵥡�

  ��UI���ǿ�Դ�������������������� MIT Э�飬�޸ĺͷ����˳���
  �����˿��Ŀ����ϣ�������ã��������κα�֤��
  ���������������ҵ��Ŀ�����ڱ����е�Bug����������κη��ռ���ʧ�������߲��е��κ����Ρ�

  ��Դ��ַ: https://github.com/ets-ddui/ets-ddui
  ��ԴЭ��: The MIT License (MIT)
  ��������: xinghun87@163.com
  �ٷ����ͣ�https://blog.csdn.net/xinghun61
}
//1.0 Free Pascal�汾����
{$IFDEF FPC}
{$DEFINE LAZARUS}
{$ENDIF}

//2.0 Delphi��C++ Builder�汾����
{
http://blog.csdn.net/cb168/article/details/9319393
DELPHI�İ汾�꣺
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
VER190 - Delphi 2007������2006��
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

BCB�İ汾�꣺
VER93  - BCB 1
VER110 - BCB 3
VER125 - BCB 4
VER135 - BCB 5
VER145 - BCB 6

Kylix�İ汾�꣺
VER140 - Kylix 1, Kylix 2
VER150 - Kylix 3

���ϵ�Turbo Pascal�汾�꣺
VER40  - TP 4
VER50  - TP 5
VER55  - TP 5.5
VER60  - TP 6
VER10  - TPW 1
VER15  - TPW 1.5
VER70  - TP 7, BP 7, BP 7.01
}
//2.1 ����汾��ʶ
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

//2.2 ��չ�汾��ʶ����
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

//3.0 ����ѡ������
{$IFDEF LAZARUS}
{$MODE objfpc}
//{$MODESWITCH CVAR-}
//{$MODESWITCH NESTEDCOMMENTS-}
{$MODESWITCH CLASSICPROCVARS+} //�ڸ��¼����Ը�ֵʱ����������"@"
//{$MODESWITCH REPEATFORWARD-}
{$MODESWITCH POINTERTOPROCVAR+} //ָ�����͵ĸ�ֵ��������ָ������(����ͨ��Windows.GetProcAddress��ȡ��ֵ����ֱ�Ӹ������̱���)
{$MODESWITCH AUTODEREF+}
{$MODESWITCH DUPLICATELOCALS+} //������ο�������������
{$H+}
{$ASMMODE INTEL}

{$DEFINE PACKAGE_COMPILE_MODE}
{$ENDIF}