@echo off
:: Script de réparation Windows - SFC & DISM
:: Doit être exécuté en mode administrateur

:: Vérifier si on est admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Ce script doit être lancé en mode administrateur.
    echo [*] Relancement avec élévation des privilèges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ========================================
echo [1/2] Vérification des fichiers système
echo ========================================
sfc /scannow

echo.
echo ========================================
echo [2/2] Réparation de l'image Windows
echo ========================================
DISM /Online /Cleanup-Image /RestoreHealth

echo.
echo [OK] Opérations terminées. Redémarrez votre PC si nécessaire.
pause
