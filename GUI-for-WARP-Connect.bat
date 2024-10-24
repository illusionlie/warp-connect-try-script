:: GUI-for-WARP-Connect-Script v1.2.0-20241023
:top
endlocal
set "warpcs-ver=v1.2.0"
set "warpcs-date=20241023"
set "warpcs-title= -GUI-for-WARP-Connect-Script- %warpcs-ver%-%warpcs-date%"
@echo off&title %warpcs-title%&cd /D "%~dp0"&color 70&setlocal enabledelayedexpansion&cls&chcp 936&mode con cols=80 lines=24
set "_temp=%cd%\#TempforScript"
set "_settings=%_temp%\settings.ini"
set "_logfile=%_temp%\latest.log"
if "%~1"=="WCS-daemon" (goto :WCS-daemon)
if "%~1"=="WCS-try" (goto :WCS-try)
call :ResetALL
call :bootcheck
for %%t in ("%~dp0%~nx0.%~nx0.%random%.tmp") do > "%%~ft" (wmic process where "name='wmic.exe' and commandline like '%%_%~nx0_%%'" get parentprocessid /value & for /f "tokens=2 delims==" %%a in ('type "%%~ft"') do set "_mepid=%%a") & del /f "%%~ft"
call :filechange _mepid !_mepid! Pid Menu
call :filechange _mestatus running Signal Menu
start mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~f0","WCS-try",,,0)(window.close)
call :logger DEBUG Menu "已启动WCS-try"
timeout /t 3 /NOBREAK >nul
mshta vbscript:CreateObject("Shell.Application"^).ShellExecute("%~f0","WCS-daemon",,,0^)(window.close^)
call :logger DEBUG Menu "已启动WCS-daemon"
set /p=<nul
:main
cls
call :maincheck
echo.################################################################################
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#               !warpcs-title!                 #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#      WARP当前状态:  !_warpstatus!                                                 #
echo.#      Try进程当前状态:  !_trstatus!                                              #
echo.#                                                                              #
echo.#      防火墙当前状态: !_ena!                                                    #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
set /p=################################################################################<nul
timeout /t 2 /NOBREAK >nul
goto :main

:buildv4ip
for /f "delims=" %%i in ('findstr /v "#" .\ips-v4.txt') do (
	set "!random!_%%i=randomsort"
)
for /f "tokens=2,3,4 delims=_.=" %%i in ('set ^| findstr =randomsort ^| sort /m 10240') do (
	set /a "v4cidr=!random! %% 256"
	if NOT defined %%i.%%j.%%k.!v4cidr! (set "%%i.%%j.%%k.!v4cidr!=anycastip" & set /a _num+=1)
)
if !_num! GEQ 100 (goto %~1) else (goto :buildv4ip)
exit

:buildv6ip
for /f "delims=" %%i in ('findstr /v "#" .\ips-v6.txt') do (
	set "!random!_%%i=randomsort"
)
set "_str=0123456789abcdef"
for /f "tokens=2,3,4 delims=_:=" %%i in ('set ^| findstr =randomsort ^| sort /m 10240') do (
	set "v6cidr="
	for /l %%i in (1,1,16) do (
		set /a "_r=!random! %% 16"
		for %%j in (!_r!) do (
			set "v6cidr=!v6cidr!!_str:~%%j,1!"
		)
		if %%i EQU 4 set "v6cidr=!v6cidr!:"
		if %%i EQU 8 set "v6cidr=!v6cidr!:"
		if %%i EQU 12 set "v6cidr=!v6cidr!:"
	)
	if NOT defined [%%i:%%j:%%k::!v6cidr!] (set [%%i:%%j:%%k::!v6cidr!]=anycastip & set /a _num+=1)
)
if !_num! GEQ 100 (goto %~1) else (goto :buildv6ip)
exit

:testip
del /q ".\!_ipver!ip.txt" >nul 2>nul
for /f "tokens=1 delims==" %%i in ('set ^| findstr =randomsort') do (
	set %%i=
)
for /f "tokens=1 delims==" %%i in ('set ^| findstr =anycastip') do (
	echo %%i>>"!_ipver!ip.txt"
)
for /f "tokens=1 delims==" %%i in ('set ^| findstr =anycastip') do (
	set %%i=
)
del /q ".\!_ipver!fine.txt" >nul 2>nul
warp -file "!_ipver!ip.txt" -output "!_ipver!fine.txt" >nul 2>nul
del /q ".\!_ipver!ip.txt" >nul 2>nul
for /f "skip=1 tokens=1-3 delims=, " %%a in (.\!_ipver!fine.txt) do (
	set "_ip_port=%%a"
	set "_loss=%%b"
	set "_delay=%%c"
	set "_loss=!_loss:%%=!"
	set "_delay=!_delay: ms=!"
	if !_loss! LSS 40 (
		if !_delay! LSS 500 (
			echo !_ip_port! >>".\!_ipver!result.txt"
		)
    )
)
del /q ".\!_ipver!fine.txt" >nul 2>nul
goto :eof

:ErrorWarn
echo.[[91mERROR[30m]-%2 %1
call :logger ERROR %2 %1
(echo =-?-=-?-=-?-= &echo %1)|msg %username% /time:3
goto :eof

:ResetALL
set "_num=0"
set _log=
del /q ".\*ip.txt" >nul 2>nul
del /q ".\*fine.txt" >nul 2>nul
goto :eof

:bootcheck
if NOT exist "!_temp!" (md "!_temp!" 2>nul >nul)
(
echo.#WARP-Connect-Script-LogFile
echo.脚本启动于: !date!_!time:~0,8!
echo.脚本运行路径: %~dp0
)>"!_logfile!"
echo.!cd!|findstr /I "%% ^! ^^ ^| ^& ^' ^) ^("&&(call :ErrorWarn "文件夹路径包含非法字符-修改路径" BootCheck &pause>nul&exit)
call :logger DEBUG Bootcheck "已通过文件夹路径测试"
fltmc>nul 2>nul||mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~dpnx0",,,"runas",1)(window.close)&&exit
fltmc>nul 2>nul||(call :ErrorWarn "自动提权失败, 需要管理员权限-需要提权" BootCheck &pause>nul&exit)
call :logger DEBUG BootCheck "已成功提权"
for /f "tokens=2 delims==" %%i in ('wmic os get version /value') do (set "_winver=%%i")
if !_winver! LSS 10.0 (call :ErrorWarn "你的Windows系统版本低于Win10-升级Windows版本" BootCheck &pause>nul&exit)
call :logger DEBUG Bootcheck "已通过系统版本测试"
warp-cli -V 2>nul >nul||(call :ErrorWarn "未找到warp-cli或无法运行-检查warp安装目录" BootCheck &pause>nul&exit)
call :logger DEBUG Bootcheck "已通过warp-cli存在测试"
warp-cli settings list|findstr /C:"(user set)"|findstr "Organization">nul 2>nul&&(call :ErrorWarn "你正在使用Zero Trust-退出Zero Trust" BootCheck &pause>nul&exit)
call :logger DEBUG Bootcheck "已通过Zero Trust测试"
2>nul >nul findstr /B /X /c:"#WARP-Connect-Script-SettingsFile" "!_settings!"||call :resetsettings
call :logger DEBUG Bootcheck "配置文件头正常"
for /f "usebackq" %%a in ("!_settings!") do (set "%%a" 2>nul)
call :logger INFO Bootcheck "配置已读取"
(
for /f "usebackq" %%a in ("!_settings!") do (echo "%%a" 2>nul)
)>>"!_logfile!"
call :checker "!_profilever!" "!warpcs-ver!"
if "!_result!"=="false" (call :ErrorWarn "配置文件版本检查失败-脚本异常" BootCheck &pause>nul&exit)
if "!_update!"=="true" (
	call :resetsettings
) else (
if "!_update!"=="false" (
	call :resetsettings
)
)
call :logger DEBUG Bootcheck "配置文件检查更新: !_update!"
if "!_updater!"=="true" call :updater
if "!_proxydetect!"=="true" (
	for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD^|findstr /c:"ProxyEnable"') do (set "_proxy=%%a")
	call :logger DEBUG Bootcheck "系统代理开启检测: !_proxy!"
	if "!_proxy!"=="0x1" (
		for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer') do (set "_proxyserver=%%a")
		if "!_proxyserver:~0,9!"=="127.0.0.1" (set "_ifproxy=true")
		)
	sc query wintun|findstr /c:"STATE"|findstr /c:"RUNNING">nul&&set "_ifproxy=true"&&set "_wintun=true"
	call :logger DEBUG Bootcheck "wintun服务检测: !_wintun!"
	call :logger INFO Bootcheck "最终代理检测: !_ifproxy!"
	if "!_ifproxy!"=="true" (call :ErrorWarn "你似乎正在使用代理服务器-清理代理" BootCheck &&pause>nul&exit)
)
if NOT exist ".\warp.exe" (
	powershell -NoProfile -NonInteractive -Command "wget -Uri 'https://gitlab.com/Misaka-blog/warp-script/-/raw/main/files/warp-yxip/warp.exe' -OutFile 'warp.exe'"
)
if NOT exist ".\warp.exe" (
	call :ErrorWarn "warp.exe不存在, 并且下载失败-检查网络连接" DownloadFailed &pause>nul&exit
)
for %%i in (v4 v6) do (
	if exist ".\ips-%%i.txt" (
		2>nul >nul findstr /B /c:"#WARP-Connect-Script-IPsFile" ".\ips-%%i.txt"||(call :logger WARN BootCheck "IPs-%%i数据已过期-将重新下载" & del /f /q "ips-%%i.txt" >nul 2>nul)
		set "_ipsver-c="
		for /f "tokens=1,2 delims==" %%m in (.\ips-%%i.txt) do (
    		if "%%m"=="#Update" (set "_ipsver-c=%%n")
		)
		if /i !_ipsver! GTR !_ipsver-c! (
			call :logger INFO BootCheck "IPs-%%i数据已过期-将重新下载"
			del /f /q "ips-%%i.txt" >nul 2>nul
		)
	)
    if NOT exist ".\ips-%%i.txt" (powershell -NoProfile -NonInteractive -Command "wget -Uri 'https://gcore.jsdelivr.net/gh/illusionlie/warp-connect-try-script@latest/ips-%%i.txt' -OutFile 'ips-%%i.txt'"
		if NOT exist ".\ips-%%i.txt" (
			call :ErrorWarn "缺少 IP%%i 数据 ips-%%i.txt-检查网络连接" DownloadFailed &pause>nul&exit
	  	)
	)
)
call :logger DEBUG Bootcheck "已检查依赖文件"
>"!_temp!\WCS-Pid.file" (
echo._mepid=1
echo._trpid=1
)
>"!_temp!\WCS-Signal.file" (
echo._mestatus=undefined
echo._trstatus=undefined
echo._fwstatus=undefined
)
call :logger DEBUG Bootcheck "已初始化Pid和Signal文件"
goto :eof

:resetsettings
echo.[[91mERROR[30m]-ResetSettings 配置文件异常或不存在, 正在创建默认配置...
echo.[[94mINFO[30m]-ResetSettings 旧配置文件已被备份
move /y "!_settings!" "!_settings!.bak" >nul 2>nul 
>"!_settings!" (
echo.#WARP-Connect-Script-SettingsFile
echo._profilever=!warpcs-ver!
echo.#此为脚本配置文件版本号, 请勿修改
echo._ipsver=20241003
echo.#IPs日期, 请勿修改
echo._loop=1
echo.#循环一次的时间, 单位为秒
echo._check=10
echo.#触发连接失败的次数
echo._ipver=v6
echo.#要使用的IP 版本, v4 或 v6
echo._log=true
echo.#是否启动日志记录
echo._warpmode=warp
echo.#要使用的WARP 模式, 默认为warp, 使用`warp-cli mode --help`查看可用的值
echo._protocol=MASQUE
echo.#要使用的WARP 协议, 默认为MASQUE, 使用`warp-cli tunnel protocol set --help`查看可用的值
echo._renewnum=3
echo.#触发重新获取端点的次数
echo._proxydetect=true
echo.#是否检测代理已开启^(避免连接问题^)
echo._nosleep=false
echo.#是否在脚本运行时阻止系统睡眠
echo._notice=true
echo.#是否在脚本退出时显示气球通知
echo._updater=true
echo.#是否启动自动检查更新
)
goto :eof


:WCS-daemon
title WCS-Daemon
call :logger INFO WCS-daemon "已确定启动WCS-daemon"
:WCS-daemon-1
cls
for /f "usebackq" %%a in ("!_temp!\WCS-Pid.file") do (set "%%a")
for /f "usebackq" %%a in ("!_temp!\WCS-Signal.file") do (set "%%a")
tasklist /FI "PID eq !_mepid!" /FI "IMAGENAME eq cmd.exe"|findstr /c:"cmd.exe"||goto :menu-exit
if NOT "!_trstatus!"=="exited" if NOT "!_trstatus!"=="error" (
	tasklist /FI "PID eq !_trpid!" /FI "IMAGENAME eq cmd.exe"|findstr /c:"cmd.exe"||call :try-exit-signal
	if "!_nosleep!"=="true" (
		start mshta vbscript:CreateObject("WScript.Shell"^).SendKeys("{SCROLLLOCK 2}"^)(window.close^)
	)
)
timeout /t 1 /NOBREAK >nul
goto :WCS-daemon-1
:menu-exit
call :logger INFO WCS-daemon "检测到Menu退出"
for /f "usebackq" %%a in ("!_temp!\WCS-Pid.file") do (set "%%a")
for %%a in (!_mepid! !_trpid!) do (taskkill /f /t /pid %%a >nul 2>nul)
del /f /q "!_temp!\WCS-*.file"
warp-cli status|findstr /c:" Connecting">nul&&warp-cli disconnect
if "!_fwstatus!"=="on" netsh AdvFirewall Set AllProfiles State On
exit
:try-exit-signal
call :logger INFO WCS-daemon "检测到Try进程退出"
for /f "usebackq" %%a in ("!_temp!\WCS-Signal.file") do (set "%%a")
if NOT "!_trstatus!"=="exit" (
call :filechange _trstatus error Signal Try-exit-signal
call :logger ERROR Try-exit-signal "Try进程异常退出"
)
call :filechange _trstatus exited Signal Try-exit-signal
goto :eof


:WCS-try
call :logger INFO WCS-try "已确定启动WCS-try"
for /f "usebackq" %%a in ("!_settings!") do (set "%%a" 2>nul)
if "!_ipver!"=="v6" (
	netsh interface ipv6 show interface||set "_ipver=v4"
	ping -6 2001:4860:4860::8888 -n 1 >nul 2>nul||set "_ipver=v4"
	call :logger INFO WCS-try "IPversion Fallback: !_ipver!"
)
for %%t in ("%~dp0%~nx0.%~nx0.%random%.tmp") do > "%%~ft" (wmic process where "name='wmic.exe' and commandline like '%%_%~nx0_%%'" get parentprocessid /value & for /f "tokens=2 delims==" %%a in ('type "%%~ft"') do set "_trpid=%%a") & del /f "%%~ft"
call :filechange _trpid !_trpid! Pid WCS-try
cls
title WCS-Main
for %%# in (DomainProfile PublicProfile StandardProfile) do (
	for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%# /v EnableFirewall 2^>nul') do (
		if /i %%b equ 0x1 (set /a _ena+=1)
	)
)
if "!_ena!"=="3" (
	call :filechange _fwstatus on Signal Firewall
) else (
	call :filechange _fwstatus off Signal Firewall
)
netsh AdvFirewall Set AllProfiles State Off
ipconfig /flushdns >nul 2>nul
warp-cli disconnect
warp-cli mode !_warpmode!
if "!_protocol!"=="MASQUE" (
	for /f "tokens=2 delims= " %%a in ('warp-cli -V') do set "_cliver=%%a"
	for /f "tokens=1-4 delims=." %%a in ("!_cliver!") do (
		set "_cliver_1=%%a"
		set "_cliver_2=%%b"
		set "_cliver_3=%%c"
		set "_cliver_4=%%d"
	)
	if !_cliver_1! LSS 2024 (
		set "_protocol=WireGuard"
	) else if !_cliver_1! EQU 2024 (
		if !_cliver_2! LSS 9 (
			set "_protocol=WireGuard"
		) else if !_cliver_2! EQU 9 (
			if !_cliver_3! LSS 346 (
				set "_protocol=WireGuard"
			) else if !_cliver_3! EQU 346 (
				if !_cliver_4! LSS 0 (
					set "_protocol=WireGuard"
				)
			)
		)
	)
)
warp-cli tunnel protocol set !_protocol!
call :filechange _trstatus renew Signal WCS-try
:WCS-try-1
if NOT !_num! GEQ 100 (call :build!_ipver!ip :WCS-try-1)
call :ResetALL
call :testip
call :logger DEBUG WCS-try-1 "已调用:testip"
if NOT exist ".\!_ipver!result.txt" (goto :WCS-try-1)
set /p _endpoint=<.\!_ipver!result.txt
warp-cli tunnel endpoint reset
warp-cli tunnel endpoint set !_endpoint!
call :logger INFO WCS-try-1 "已设置Endpoint: !_endpoint!"
warp-cli tunnel rotate-keys
call :logger INFO WCS-try-1 "已重置密钥"
del /q ".\*result.txt" >nul 2>nul
set "_fail=0"
set "_loopnum=0"
set "_pha3=0"
warp-cli connect
call :filechange _trstatus running Signal WCS-try-1
:WCS-try-2
if /i !_fail! GEQ !_check! goto :WCS-try-3
if /i !_loopnum! GEQ 80 goto :WCS-try-3
if /i !_pha3! GEQ !_renewnum! (
	mshta vbscript:CreateObject("Shell.Application"^).ShellExecute("%~f0","WCS-try",,"",0^)(window.close^)&&exit
)
warp-cli status|findstr /C:"happy eyeballs" &&set /a "_fail+=1"&&call :logger DEBUG WCS-try-2 "检测到happy eyeballs"&&timeout /t 5 /NOBREAK >nul
warp-cli status|findstr /C:" Connected" &&call :logger INFO WCS-try-2 "检测到WARP连接成功"&&goto :WCS-try-4
set /a "_loopnum+=1"
timeout /t !_loop! /NOBREAK >nul
goto :WCS-try-2
:WCS-try-3
if /i !_fail! GEQ !_check! (
	call :logger DEBUG WCS-try-3 "已触发happy eyeballs失败次数"
	warp-cli disconnect
	warp-cli tunnel rotate-keys
	set "_fail=0"
)
if /i !_loopnum! GEQ 80 (
	call :logger DEBUG WCS-try-3 "已触发等待超时"
	warp-cli disconnect
	set "_loopnum=0"
)
set /a "_pha3+=1"
timeout /t !_loop! /NOBREAK >nul
warp-cli connect
goto :WCS-try-2
:WCS-try-4
if "!_notice!"=="true" (
	for /f "tokens=2 delims= " %%a in ('dotnet --info ^| findstr /i /C:"Microsoft.NETCore.App"') do (
		set "_version=%%a"
		if /i "!_netcore!" leq "!_version!" set "_netcore=!_version!"
	)
	set "_version="
	for /f "tokens=2 delims= " %%a in ('dotnet --info ^| findstr /i /C:"Microsoft.WindowsDesktop.App"') do (
		set "_version=%%a"
		if "!_netdesk!" leq "!_version!" set "_netdesk=!_version!"
	)
	call :logger DEBUG WCS-try-4 "_netcore: !_netcore! - _netdesk: !_netdesk!"
	if NOT defined _netcore if NOT defined _netdesk exit
	powershell -NoProfile -NonInteractive -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms');$objNotify = New-Object System.Windows.Forms.NotifyIcon;$objNotify.Icon = [System.Drawing.SystemIcons]::Information;$objNotify.BalloonTipText = '连接成功！脚本已退出';$objNotify.BalloonTipTitle = 'WARP-Connect-Script';$objNotify.Visible = $true;$objNotify.ShowBalloonTip(8000)" >nul
)
call :filechange _trstatus exit Signal WCS-try-4
call :logger INFO WCS-try-4 "WCS-try已自行退出"
exit


:maincheck
warp-cli status|findstr /c:" Disconnected">nul&&set "_warpstatus=[91m断开连接[30m"
warp-cli status|findstr /c:" Connecting">nul&&set "_warpstatus=[94m正在连接[30m"
warp-cli status|findstr /c:" Connected">nul&&set "_warpstatus=[92m已经连接[30m"
for /f "usebackq" %%a in ("!_temp!\WCS-Signal.file") do (set "%%a")
if "!_trstatus!"=="running" (
	set "_trstatus=[92m正在运行[30m"
) else (
	if "!_trstatus!"=="renew" (
		set "_trstatus=[94m获取端点[30m"
	) else (
		if "!_trstatus!"=="exited" (
			set "_trstatus=[91m已经退出[30m"
		) else (
			set "_trstatus=[91m状态异常[30m"
			)
		)
	)
set "_ena=0"
for %%# in (DomainProfile PublicProfile StandardProfile) do (
	for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%# /v EnableFirewall 2^>nul') do (
		if /i %%b equ 0x1 (set /a _ena+=1)
	)
)
if "!_ena!"=="3" (set "_ena=[92m开启[30m") else (set "_ena=[91m关闭[30m")
goto :eof


:filechange
(for /f "usebackq delims=" %%a in ("!_temp!\WCS-%3.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==%1 (echo.%1=%2) else echo.%%a)))> "!_temp!\WCS-%3.file.tmp"
set "%1=%2"
move /y "!_temp!\WCS-%3.file.tmp" "!_temp!\WCS-%3.file" >nul 2>nul
call :logger DEBUG FileChange "%4 %3: %2"
goto :eof


:logger
if defined _log (
	if NOT "!_log!"=="true" (
		goto :eof
	)
)
>>"!_logfile!" (
	echo.[%time:~0,8%/%1]-%2 %3
)
goto :eof


:updater
curl -V >nul||(call :ErrorWarn "curl不存在 无法执行-检查curl" Updater &pause>nul&goto :eof)
for /f "tokens=2 delims=:," %%i in ('curl -L --connect-timeout 10 https://api.github.com/repos/illusionlie/warp-connect-try-script/releases/latest 2^>nul ^| findstr /R "^[ ]*\"tag_name\": *\"v[0-9]+\.[0-9]+\.[0-9]+\"$"') do (
    set "_ver=%%~i"
    goto :checkupdate
)
goto :eof
:checkupdate
if NOT defined _ver (call :ErrorWarn "Github API 获取到的值为空-检查网络连接" CheckUpdate &pause>nul&goto :eof)
call :logger INFO CheckUpdate "Latest version: !_ver!"
call :logger INFO CheckUpdate "Script version: !warpcs-ver!"
call :checker "!_ver!" "!warpcs-ver!"
if "!_result!"=="true" (
	if "!_update!"=="true" (
		for /f "delims=" %%a in ('mshta vbscript:Execute("On Error Resume Next:Dim ret,fso:ret=MsgBox(Replace(""检测到新版本, 是否进行更新?\n点击'是'打开网站进行更新\n点击'否'继续"",""\n"",vbCrLf),vbExclamation + vbOkCancel,""CheckUpdate""):Set fso=CreateObject(""Scripting.FileSystemObject""):fso.GetStandardStream(1).Write ret:Set fso=Nothing:close"^)') do (if %%a equ 1 (start https://github.com/illusionlie/warp-connect-try-script/releases))
	)
)
goto :eof


:checker
set "_ver1=%~1"
set "_ver2=%~2"
set "_result=false"
if "!_ver1!"=="" (if "!_ver2!"=="" (goto :eof))
for %%a in (1 2) do (
	set "_major%%a="
	set "_minor%%a="
	set "_patch%%a="
)
for %%a in (1 2) do (
	set "_ver%%a=!_ver%%a: =!"
	set "_ver%%a=!_ver%%a:v=!"
	set "_ver%%a=!_ver%%a:"=!"
	echo.!_ver%%a!|findstr /R "^[0-9\.]*$" >nul||(call :ErrorWarn "处理后包含不应该存在的字符-传入的参数错误" Checker &pause>nul&goto :eof)
	for /f "tokens=1-3 delims=." %%x in ("!_ver%%a!") do (
    set "_major%%a=%%x"
    set "_minor%%a=%%y"
    set "_patch%%a=%%z"
)
)
set "_update=false"
if !_major1! GTR !_major2! (
    set "_update=true"
) else if !_major1! EQU !_major2! (
    if !_minor1! GTR !_minor2! (
        set "_update=true"
    ) else if !_minor1! EQU !_minor2! (
        if !_patch1! GTR !_patch2! (
            set "_update=true"
        )
    )
)
if !_major1! EQU !_major2! (
	if !_minor1! EQU !_minor2! (
		if !_patch1! EQU !_patch2! (
			set "_update=same"
		)
	)
)
set "_result=true"
goto :eof