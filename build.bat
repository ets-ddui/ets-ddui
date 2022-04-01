set path=%path%;C:\Windows\Microsoft.NET\Framework\v2.0.50727
set BDS=C:\Program Files (x86)\CodeGear\RAD Studio\5.0
set BinDir=%~dp0Out

MSBuild.exe DDUI\dclDDUI.dproj
MSBuild.exe DDUI\DDUI.dproj
::MSBuild.exe ThirdParty\JCL\JCL.dproj
MSBuild.exe Demo\ทย360\Fake360.dproj

pause