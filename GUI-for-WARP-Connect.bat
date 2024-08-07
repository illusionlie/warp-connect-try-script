:: GUI-for-WARP-Connect-Script v0.2.0-20240806
:top
endlocal
set "warpcs-ver=v0.2.0"
set "warpcs-date=20240806"
set "warpcs-title= -GUI-for-WARP-Connect-Script- %warpcs-ver%-%warpcs-date%"
@echo off&title %warpcs-title%&cd /D "%~dp0"&color 70&setlocal enabledelayedexpansion&cls&chcp 936&mode con cols=80 lines=24
set "_temp=%cd%\#TempforScript"
set "_settings=%_temp%\settings.ini"
set "_daemonfile=%_temp%\WCS-Daemon.bat"
if NOT exist ".\warp.exe" (
	powershell wget -Uri "https://gitlab.com/Misaka-blog/warp-script/-/raw/main/files/warp-yxip/warp.exe" -OutFile "warp.exe"
)
if NOT exist ".\warp.exe" (
	call :ErrorWarn "warp.exe²»´æÔÚ, ²¢ÇÒÏÂÔØÊ§°Ü-¼ì²éÍøÂçÁ¬½Ó" DownloadFailed &pause>nul&exit
)
for %%i in (v4 v6) do (
    if NOT exist ".\ips-%%i.txt" (
		powershell wget -Uri "https://gitlab.com/Misaka-blog/warp-script/-/raw/main/files/warp-yxip/ips-%%i.txt" -OutFile "ips-%%i.txt"
	)
    if NOT exist ".\ips-%%i.txt" (
		call :ErrorWarn "È±ÉÙ IP%%i Êý¾Ý ips-%%i.txt-¼ì²éÍøÂçÁ¬½Ó" DownloadFailed &pause>nul&exit
	)
)
if "%~1"=="WSC-daemon" (goto :WSC-daemon)
if "%~1"=="WSC-try" (goto :WSC-try)
call :ResetALL
call :bootcheck
fltmc>nul 2>nul||mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~dpnx0",,,"runas",1)(window.close)&&exit
fltmc>nul 2>nul||(call :ErrorWarn "ÌáÈ¨Ê§°Ü, ÐèÒª¹ÜÀíÔ±È¨ÏÞ-ÐèÒªÌáÈ¨" BootCheck &pause>nul&exit)
for %%t in ("%~dp0%~nx0.%~nx0.%random%.tmp") do > "%%~ft" (wmic process where "name='wmic.exe' and commandline like '%%_%~nx0_%%'" get parentprocessid /value & for /f "tokens=2 delims==" %%a in ('type "%%~ft"') do set "_mepid=%%a") & del /f "%%~ft"
(for /f "usebackq delims=" %%a in ("!_temp!\WSC-Pid.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==_mepid (echo._mepid=%_mepid%) else echo.%%a)))> "!_temp!\WSC-Pid.file.tmp"
move /y "!_temp!\WSC-Pid.file.tmp" "!_temp!\WSC-Pid.file" >nul 2>nul
(for /f "usebackq delims=" %%a in ("!_temp!\WSC-Signal.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==_mestatus (echo._mestatus=running) else echo.%%a)))> "!_temp!\WSC-Signal.file.tmp"
move /y "!_temp!\WSC-Signal.file.tmp" "!_temp!\WSC-Signal.file" >nul 2>nul
start mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~dpnx0","WSC-try",,"",0)(window.close)
timeout /t 1 /NOBREAK >nul
start mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~dpnx0","WSC-daemon",,"",0)(window.close)
set /p=<nul
:main
cls
call :maincheck
echo.################################################################################
echo.#                                                                              #
echo.#                !warpcs-title!                #
echo.#                                                                              #
echo.#                                                                              #
echo.#                                                                              #
echo.#      WARPµ±Ç°×´Ì¬:  !_warpstatus!                                                 #
echo.#      Try½ø³Ìµ±Ç°×´Ì¬:  !_trstatus!                                              #
echo.#                                                                              #
echo.#      ·À»ðÇ½µ±Ç°×´Ì¬: !_ena!                                                    #
echo.#                                                                              #
echo.#                                                                              #
echo.################################################################################
timeout /t 2 /NOBREAK >nul
goto :main

:buildv4ip
for /f "delims=" %%i in (.\ips-v4.txt) do (
	set "!random!_%%i=randomsort"
)
for /f "tokens=2,3,4 delims=_.=" %%i in ('set ^| findstr =randomsort ^| sort /m 10240') do (
	set /a "v4cidr=!random! %% 256"
	if NOT defined %%i.%%j.%%k.!v4cidr! (set "%%i.%%j.%%k.!v4cidr!=anycastip" & set /a _num+=1)
)
if !_num! GEQ 100 (goto %~1) else (goto :buildv4ip)
exit

:buildv6ip
for /f "delims=" %%i in (.\ips-v6.txt) do (
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
(echo =-?-=-?-=-?-= &echo %1)|msg %username% /time:3
goto :eof

:ResetALL
set "_num=0"
set _log=
del /q ".\*ip.txt" >nul 2>nul
del /q ".\*fine.txt" >nul 2>nul
goto :eof

:bootcheck
echo.!cd!|findstr /I "%% ^! ^^ ^| ^& ^' ^) ^("&&(call :ErrorWarn "ÎÄ¼þ¼ÐÂ·¾¶°üº¬·Ç·¨×Ö·û-ÐÞ¸ÄÂ·¾¶" BootCheck &pause>nul&exit)
for /f "tokens=2 delims==" %%i in ('wmic os get version /value') do (set "_winver=%%i")
if !_winver! LSS 10.0 (call :ErrorWarn "ÄãµÄWindowsÏµÍ³°æ±¾µÍÓÚWin10-Éý¼¶Windows°æ±¾" BootCheck &pause>nul&exit)
warp-cli -V 2>nul >nul||(call :ErrorWarn "Î´ÕÒµ½warp-cli»òÎÞ·¨ÔËÐÐ-¼ì²éwarp°²×°Ä¿Â¼" BootCheck &pause>nul&exit)
warp-cli settings list|findstr /C:"(user set)"|findstr "Organization">nul 2>nul&&(call :ErrorWarn "ÄãÕýÔÚÊ¹ÓÃZero Trust-ÍË³öZero Trust" BootCheck &pause>nul&exit)
if NOT exist "!_temp!" (md "!_temp!" 2>nul >nul)
2>nul >nul findstr /B /X "#WARP-Connect-Script-SettingsFile" "!_settings!"||call :resetsettings
for /f "usebackq" %%a in ("!_settings!") do (set "%%a" 2>nul)
set "_ver=!_ver:"=!"
set "_ver=!_ver:v=!"
set "_ver=!_ver: =!"
echo.!_ver!|findstr /R "^[0-9\.]*$" >nul||call :resetsettings
for /f "tokens=1-3 delims=." %%a in ("!_ver!") do (
    set "_major=%%a"
    set "_minor=%%b"
    set "_patch=%%c"
)
set "warpcs-ver=!warpcs-ver:v=!"
for /f "tokens=1-3 delims=." %%a in ("!warpcs-ver!") do (
    set "_major-c=%%a"
    set "_minor-c=%%b"
    set "_patch-c=%%c"
)
set "_outdate=false"
if !_major! GTR !_major-c! (
    set "_outdate=true"
) else if !_major! EQU !_major-c! (
    if !_minor! GTR !_minor-c! (
        set "_outdate=true"
    ) else if !_minor! EQU !_minor-c! (
        if !_patch! GTR !_patch-c! (
            set "_outdate=true"
        )
    )
)
if !_major! EQU !_major-c! (
	if !_minor! EQU !_minor-c! (
		if !_patch! EQU !_patch-c! (
			set "_outdate=same"
		)
	)
)
if "!_outdate!"=="true" (
	call :resetsettings
) else (
if "!_outdate!"=="false" (
	call :resetsettings
)
)
if "!_proxydetect!"=="true" (
	for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD^|findstr /c:"ProxyEnable"') do (set "_proxy=%%a")
	if "!_proxy!"=="0x1" (
		for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer') do (set "_proxyserver=%%a")
		if "!_proxyserver:~0,9!"=="127.0.0.1" (set "_ifproxy=true")
		)
	if "!_ifproxy!"=="true" (call :ErrorWarn "ÄãËÆºõÕýÔÚÊ¹ÓÃ´úÀí·þÎñÆ÷-ÇåÀí´úÀí" BootCheck &pause>nul&exit)
)
>"!_temp!\WSC-Pid.file" (
echo._mepid=1
echo._trpid=1
)
>"!_temp!\WSC-Signal.file" (
echo._mestatus=undefined
echo._trstatus=undefined
)
goto :eof


:resetsettings
echo.[[91mERROR[30m]-ResetSettings ÅäÖÃÎÄ¼þÒì³£»ò²»´æÔÚ, ÕýÔÚ´´½¨Ä¬ÈÏÅäÖÃ...
echo.[[94mINFO[30m]-ResetSettings ¾ÉÅäÖÃÎÄ¼þÒÑ±»±¸·Ý
move /y "!_settings!" "!_settings!.bak" >nul 2>nul 
>"!_settings!" (
echo.#WARP-Connect-Script-SettingsFile
echo._ver=!warpcs-ver!
echo._loop=1
echo._check=10
echo._ipver=v4
echo._daemon=true
echo._log=false
echo._warpmode=warp
echo._renewnum=3
echo._proxydetect=true
)
goto :eof

:WSC-daemon
cls
title WCS-Daemon-v0.1.0
:WSC-daemon-1
cls
for /f "usebackq" %%a in ("!_temp!\WSC-Pid.file") do (set "%%a")
tasklist /FI "PID eq !_mepid!" /FI "IMAGENAME eq cmd.exe"|findstr /c:"cmd.exe"||goto :menu-exit
tasklist /FI "PID eq !_trpid!" /FI "IMAGENAME eq cmd.exe"|findstr /c:"cmd.exe"||call :try-exit-signal
timeout /t 1 /NOBREAK >nul
goto :WSC-daemon-1
:menu-exit
for /f "usebackq" %%a in ("!_temp!\WSC-Pid.file") do (set "%%a")
for %%a in (!_mepid! !_trpid!) do (taskkill /f /t /pid %%a >nul 2>nul)
del /f /q "!_temp!\WSC-*.file"
netsh AdvFirewall Set AllProfiles State On
exit
:try-exit-signal
(for /f "usebackq delims=" %%a in ("!_temp!\WSC-Signal.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==_trstatus (echo._trstatus=exited) else echo.%%a)))> "!_temp!\WSC-Signal.file.tmp"
move /y "!_temp!\WSC-Signal.file.tmp" "!_temp!\WSC-Signal.file" >nul 2>nul
goto :eof


:WSC-try
for /f "usebackq" %%a in ("!_settings!") do (set "%%a" 2>nul)
for %%t in ("%~dp0%~nx0.%~nx0.%random%.tmp") do > "%%~ft" (wmic process where "name='wmic.exe' and commandline like '%%_%~nx0_%%'" get parentprocessid /value & for /f "tokens=2 delims==" %%a in ('type "%%~ft"') do set "_trpid=%%a") & del /f "%%~ft"
(for /f "usebackq delims=" %%a in ("!_temp!\WSC-Pid.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==_trpid (echo._trpid=%_trpid%) else echo.%%a)))> "!_temp!\WSC-Pid.file.tmp"
move /y "!_temp!\WSC-Pid.file.tmp" "!_temp!\WSC-Pid.file" >nul 2>nul
cls
title WCS-Main-v0.1.0
netsh AdvFirewall Set AllProfiles State Off
warp-cli disconnect
warp-cli mode !_warpmode!
(for /f "usebackq delims=" %%a in ("!_temp!\WSC-Signal.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==_trstatus (echo._trstatus=renew) else echo.%%a)))> "!_temp!\WSC-Signal.file.tmp"
move /y "!_temp!\WSC-Signal.file.tmp" "!_temp!\WSC-Signal.file" >nul 2>nul
:WSC-try-1
if NOT !_num! GEQ 100 (call :build!_ipver!ip :WSC-try-1)
call :ResetALL
call :testip
if NOT exist ".\!_ipver!result.txt" (goto :WSC-try-1)
set /p _endpoint=<.\!_ipver!result.txt
warp-cli tunnel endpoint reset
warp-cli tunnel endpoint set !_endpoint!
warp-cli tunnel rotate-keys
del /q ".\*result.txt" >nul 2>nul
set "_fail=0"
set "_loopnum=0"
set "_pha3=0"
warp-cli connect
(for /f "usebackq delims=" %%a in ("!_temp!\WSC-Signal.file") do (for /f "delims==" %%b in ("%%a") do (if %%b==_trstatus (echo._trstatus=running) else echo.%%a)))> "!_temp!\WSC-Signal.file.tmp"
move /y "!_temp!\WSC-Signal.file.tmp" "!_temp!\WSC-Signal.file" >nul 2>nul
:WSC-try-2
if /i !_fail! GEQ !_check! goto :WSC-try-3
if /i !_loopnum! GEQ 80 goto :WSC-try-3
if /i !_pha3! GEQ !_renewnum! goto :WSC-try-4
warp-cli status|findstr /C:"happy eyeballs" &&set /a "_fail+=1"&&timeout /t 5 /NOBREAK >nul
warp-cli status|findstr /C:" Connected" &&exit
set /a "_loopnum+=1"
timeout /t !_loop! /NOBREAK >nul
goto :WSC-try-2
:WSC-try-3
if /i !_fail! GEQ !_check! (
	warp-cli disconnect
	warp-cli tunnel rotate-keys
	set "_fail=0"
)
if /i !_loopnum! GEQ 80 (
	warp-cli disconnect
	set "_loopnum=0"
)
set /a "_pha3+=1"
timeout /t !_loop! /NOBREAK >nul
warp-cli connect
goto :WSC-try-2
:WSC-try-4
mshta vbscript:CreateObject("Shell.Application").ShellExecute("%~dpnx0","WSC-try",,"",0)(window.close)&&exit
exit

:maincheck
warp-cli status|findstr /c:" Disconnected.">nul&&set "_warpstatus=[91m¶Ï¿ªÁ¬½Ó[30m"
warp-cli status|findstr /c:" Connecting">nul&&set "_warpstatus=[94mÕýÔÚÁ¬½Ó[30m"
warp-cli status|findstr /c:" Connected">nul&&set "_warpstatus=[92mÒÑ¾­Á¬½Ó[30m"
for /f "usebackq" %%a in ("!_temp!\WSC-Signal.file") do (set "%%a")
if "!_trstatus!"=="running" (
	set "_trstatus=[92mÕýÔÚÔËÐÐ[30m"
) else (
	if "!_trstatus!"=="renew" (
		set "_trstatus=[94m»ñÈ¡¶Ëµã[30m"
	) else (
		if "!_trstatus!"=="exited" (
			set "_trstatus=[91mÒÑ¾­ÍË³ö[30m"
		) else (
			set "_trstatus=[91m×´Ì¬Òì³£[30m"
			)
		)
	)
set "_ena=0"
for %%# in (DomainProfile PublicProfile StandardProfile) do (
	for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%# /v EnableFirewall 2^>nul') do (
		if /i %%b equ 0x1 (set /a _ena+=1)
	)
)
if "!_ena!"=="3" (set "_ena=[92m¿ªÆô[30m") else (set "_ena=[91m¹Ø±Õ[30m")
goto :eof