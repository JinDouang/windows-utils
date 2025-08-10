@echo off
setlocal EnableExtensions EnableDelayedExpansion
title BSOD - Recuperer le dernier bugcheck (log + verbeux)

:: ===== 1) ELEVATION ADMIN =====
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [*] Elevation requise - relance en administrateur...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo [OK] Droits admin confirmes.
echo.

:: ===== 2) PREP LOG + TEST POWERSHELL =====
for /f "usebackq tokens=2,*" %%A in (`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Desktop 2^>nul ^| find /i "Desktop"`) do set "DESKTOP=%%B"
if not defined DESKTOP set "DESKTOP=%USERPROFILE%\Desktop"
set "LOG=%DESKTOP%\BSOD_log.txt"

echo [INFO] Journal: "%LOG%"
echo [INFO] Debut: %DATE% %TIME%> "%LOG%"
echo [INFO] Script: %~f0>> "%LOG%"
echo.>> "%LOG%"

where powershell >nul 2>&1
if errorlevel 1 (
  echo [ERREUR] PowerShell introuvable.>> "%LOG%"
  echo PowerShell introuvable. Abandon.
  pause
  exit /b 1
)

echo [OK] PowerShell detecte.>> "%LOG%"
echo [OK] PowerShell detecte.
echo.

:: ===== 3) EXECUTION POWERSHELL EN LIGNE =====
echo [INFO] Execution PowerShell en cours...
echo [PS] -------------------------------------------------->> "%LOG%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "$desk=[Environment]::GetFolderPath('Desktop');" ^
  "$out=Join-Path $desk 'Dernier_BSOD.txt';" ^
  "$rep=@(); $rep+='=== Dernier BSOD (Event ID 1001) ===';" ^
  "function Get-LastBugcheckEvent { " ^
  "  $e1=Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WER-SystemErrorReporting';Id=1001} -MaxEvents 200 | Sort-Object TimeCreated -Descending | Select-Object -First 1; if($e1){return $e1};" ^
  "  $e2=Get-WinEvent -FilterHashtable @{LogName='System';Id=1001} -MaxEvents 500 | Where-Object { $_.ProviderName -eq 'BugCheck' -or $_.ProviderName -eq 'Microsoft-Windows-WER-SystemErrorReporting' } | Sort-Object TimeCreated -Descending | Select-Object -First 1; if($e2){return $e2};" ^
  "  return $null" ^
  "};" ^
  "$evt=Get-LastBugcheckEvent;" ^
  "if($evt){" ^
  "  $msg=$evt.Message; $code=($msg|Select-String -Pattern '0x[0-9A-Fa-f]+' -AllMatches).Matches|Select-Object -First 1 -ExpandProperty Value;" ^
  "  $rep+='Date      : '+$evt.TimeCreated;" ^
  "  $rep+='Provider  : '+$evt.ProviderName;" ^
  "  if($code){$rep+='BugCheck  : '+$code}else{$rep+='BugCheck  : (non detecte)'};" ^
  "  $rep+='Message brut :'; $rep+=$msg;" ^
  "} else {" ^
  "  $rep+='Aucun event 1001 trouve dans System. On tente d''autres pistes...';" ^
  "};" ^
  "$dump=$null; if(Test-Path 'C:\Windows\Minidump'){ $dump=Get-ChildItem 'C:\Windows\Minidump' -Filter *.dmp -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 };" ^
  "if(-not $dump -and (Test-Path 'C:\Windows\MEMORY.DMP')){ $dump=Get-Item 'C:\Windows\MEMORY.DMP' };" ^
  "if($dump){ $rep+=''; $rep+='Dernier dump : '+$dump.FullName; $rep+='Taille       : '+([math]::Round($dump.Length/1MB,2))+' Mo'; $rep+='Date         : '+$dump.LastWriteTime } else { $rep+=''; $rep+='Aucun fichier dump trouve.' };" ^
  "$rep | Tee-Object -FilePath $out -Encoding UTF8; " ^
  "\"[OK] Rapport enregistre dans: $out\"" ^
  " | Tee-Object -FilePath '%LOG%' -Append -Encoding UTF8"

set "RC=%ERRORLEVEL%"
echo [INFO] Retour PowerShell: %RC% >> "%LOG%"
echo [INFO] Retour PowerShell: %RC%
echo.

:: ===== 4) OUVERTURE DU RESULTAT =====
if exist "%DESKTOP%\Dernier_BSOD.txt" (
  echo [OK] Ouverture du rapport...
  echo [OK] Rapport: "%DESKTOP%\Dernier_BSOD.txt">> "%LOG%"
  start notepad "%DESKTOP%\Dernier_BSOD.txt"
) else (
  echo [ATTENTION] Le fichier "Dernier_BSOD.txt" n'a pas ete cree. >> "%LOG%"
  echo [ATTENTION] Aucune sortie detectee. Ouvre le log pour diagnostic.
  start notepad "%LOG%"
)

echo.
echo Termine. (Un log est dispo ici:)
echo %LOG%
echo.
pause
