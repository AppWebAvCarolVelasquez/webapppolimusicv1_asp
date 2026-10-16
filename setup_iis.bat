@echo off
REM ===============================================================
REM  PoliMusic - Configuracion IIS
REM  Ejecutar como Administrador (clic derecho > Ejecutar como administrador)
REM ===============================================================

echo ============================================================
echo  PoliMusic - Configuracion de IIS
echo ============================================================
echo.

set APP_NAME=webapppolimusicv1_asp
set APP_PATH=C:\Users\User\Desktop\APLICACIONES WEB AVANZADAS\webapppolimusicv1_asp

echo [1/4] Verificando IIS...
%windir%\System32\inetsrv\appcmd.exe list app /site.name:"Default Web Site" /path:"/%APP_NAME%" 2>nul
if %errorlevel%==0 (
    echo    La aplicacion ya existe. Actualizando ruta fisica...
    %windir%\System32\inetsrv\appcmd.exe set app "Default Web Site/%APP_NAME%" /physicalPath:"%APP_PATH%"
) else (
    echo    Creando aplicacion IIS: /%APP_NAME%
    %windir%\System32\inetsrv\appcmd.exe add app /site.name:"Default Web Site" /path:"/%APP_NAME%" /physicalPath:"%APP_PATH%"
)

echo.
echo [2/4] Habilitando Classic ASP...
%windir%\System32\inetsrv\appcmd.exe set config "Default Web Site/%APP_NAME%" /section:asp /enable:true /commit:apphost 2>nul

echo.
echo [3/4] Permisos de carpeta...
icacls "%APP_PATH%" /grant "IIS_IUSRS:(OI)(CI)RX" /T 2>nul
icacls "%APP_PATH%" /grant "IUSR:(OI)(CI)RX" /T 2>nul
icacls "%APP_PATH%\logs" /grant "IIS_IUSRS:(OI)(CI)M" /T 2>nul
icacls "%APP_PATH%\logs" /grant "IUSR:(OI)(CI)M" /T 2>nul

echo.
echo [4/4] Reiniciando IIS...
iisreset

echo.
echo ============================================================
echo  Configuracion completa!
echo.
echo  Abre en el navegador:
echo    http://localhost/%APP_NAME%/login.asp
echo.
echo  Usuarios de prueba:
echo    userNormal / 12345678  (usuario normal)
echo    userAdmin  / 12345678  (administrador)
echo ============================================================
echo.
pause
