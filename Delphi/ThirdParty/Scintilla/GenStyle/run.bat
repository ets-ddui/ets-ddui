::Copyright (c) 2021-2031 Steven Shi
::
::ETS_DDUI For Delphi����Ư���������������򵥡�
::
::��UI���ǿ�Դ������������������� MIT Э�飬�޸ĺͷ����˳���
::�����˿��Ŀ����ϣ�������ã��������κα�֤��
::���������������ҵ��Ŀ�����ڱ����е�Bug����������κη��ռ���ʧ�������߲��е��κ����Ρ�
::
::��Դ��ַ: https://github.com/ets-ddui/ets-ddui
::��ԴЭ��: The MIT License (MIT)
::��������: xinghun87@163.com
::�ٷ����ͣ�https://blog.csdn.net/xinghun61

set path=E:\Tool\bin

cd /d "%~dp0"

.\Release\GenStyle.exe "%~1" 1>Style.json

sed -i "s/$(style.\([^.]\+\).\([0-9]\+\))/$(lexers.\1.style.\2)/" Style.json

pause
