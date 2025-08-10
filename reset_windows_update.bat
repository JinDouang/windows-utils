@echo off
setlocal EnableExtensions

:: Vérif admin
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [*] Relance en admin...
  powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

echo [1/5] Arrêt des services Windows Update...
net stop wuauserv /y
net stop bits /y
net stop cryptsvc /y
net stop msiserver /y

echo [2/5] Nettoyage des caches Windows Update...
rd /s /q "%windir%\SoftwareDistribution"
rd /s /q "%windir%\System32\catroot2"
mkdir "%windir%\SoftwareDistribution"
mkdir "%windir%\System32\catroot2"

echo [3/5] Réinitialisation BITS/WU et WinHTTP...
bitsadmin /reset
netsh winhttp reset proxy
netsh winsock reset

echo [4/5] Réenregistrement des DLL Windows Update...
for %%i in (
  wuapi.dll wuaueng.dll wuaueng1.dll wucltui.dll wups.dll wups2.dll
  wuwebv.dll qmgr.dll qmgrprxy.dll wucltux.dll muweb.dll wuweb.dll
) do regsvr32 /s "%%i"

echo [5/5] Redémarrage des services...
net start cryptsvc
net start bits
net start msiserver
net start wuauserv

echo.
echo [OK] Reset terminé. Redémarre ton PC puis réessaie Windows Update.
pause