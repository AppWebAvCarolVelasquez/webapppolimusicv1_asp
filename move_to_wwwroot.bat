@echo off
REM ===============================================================
REM  PoliMusic - Mover proyecto a wwwroot y reconfigurar IIS
REM  Ejecutar como Administrador (clic derecho > Ejecutar como administrador)
REM
REM  Motivo: La carpeta del perfil C:\Users\User solo permite acceso
REM  a SYSTEM/Administradores/Usuario, por lo que IIS no puede leer
REM  archivos en el Escritorio (error HTTP 401.3).
REM ===============================================================

echo ============================================================
echo  PoliMusic - Mover proyecto a wwwroot
echo ============================================================
echo.

set APP_NAME=webapppolimusicv1_asp
set SRC=C:\Users\User\Desktop\APLICACIONES WEB AVANZADAS\webapppolimusicv1_asp
set DST=C:\inetpub\wwwroot\webapppolimusicv1_asp

echo [1/5] Verificando carpeta origen...
if not exist "%SRC%" (
    if exist "%DST%" (
        echo    El proyecto ya esta en wwwroot. Continuando...
    ) else (
        echo    ERROR: No se encontro el proyecto ni en Escritorio ni en wwwroot.
        pause
        exit /b 1
    )
) else (
    echo    Origen encontrado: %SRC%
)

echo.
echo [2/5] Copiando proyecto a wwwroot...
if exist "%DST%" (
    echo    El destino ya existe. Sincronizando archivos...
    robocopy "%SRC%" "%DST%" /E /XO
) else (
    robocopy "%SRC%" "%DST%" /E
)
if %errorlevel% GEQ 8 (
    echo    ERROR: Robocopy fallo con codigo %errorlevel%
    pause
    exit /b 1
)
echo    Copia completada: %DST%

echo.
echo [3/5] Actualizando ruta fisica de la aplicacion IIS...
%windir%\System32\inetsrv\appcmd.exe set app "Default Web Site/%APP_NAME%" /physicalPath:"%DST%"

echo.
echo [4/5] Configurando permisos NTFS...
REM IIS_IUSRS = identidad del application pool (worker process)
REM IUSR = cuenta de autenticacion anonima (impersonacion del hilo)
icacls "%DST%" /grant "IIS_IUSRS:(OI)(CI)RX" /T
icacls "%DST%" /grant "IUSR:(OI)(CI)RX" /T
icacls "%DST%\logs" /grant "IIS_IUSRS:(OI)(CI)M" /T
icacls "%DST%\logs" /grant "IUSR:(OI)(CI)M" /T
echo    Permisos aplicados.

echo.
echo [5/5] Reiniciando IIS...
iisreset

echo.
echo ============================================================
echo  Verificando sitio...
echo ============================================================
echo.
curl -s -o nul -w "  login.asp  -^> HTTP %%{http_code}" http://localhost/%APP_NAME%/login.asp
echo.
curl -s -o nul -w "  songs.asp  -^> HTTP %%{http_code}" http://localhost/%APP_NAME%/songs.asp
echo.
curl -s -o nul -w "  audio mp3  -^> HTTP %%{http_code}" http://localhost/%APP_NAME%/assets/audio/bensound-adventure.mp3
echo.
echo ============================================================
echo  Listo! Abre en el navegador:
echo    http://localhost/%APP_NAME%/login.asp
echo.
echo  Usuarios de prueba:
echo    userNormal / 12345678  (usuario normal)
echo    userAdmin  / 12345678  (administrador)
echo.
echo  NOTA: La carpeta original en el Escritorio sigue intacta.
echo  Borrala manualmente cuando confirmes que todo funciona.
echo ============================================================
echo.
pause
