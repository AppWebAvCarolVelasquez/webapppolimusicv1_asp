@echo off
REM ===============================================================
REM  PoliMusic - Despliegue y verificacion FINAL
REM  Opcion B: includes con #INCLUDE VIRTUAL (sin depender de
REM  AspEnableParentPaths). Ejecutar como Administrador.
REM ===============================================================
setlocal

set APCMD=%windir%\System32\inetsrv\appcmd.exe
set SITE=Default Web Site
set APP=webapppolimusicv1_asp
set ROOT=C:\inetpub\wwwroot\%APP%
set DESK=C:\Users\User\Desktop\APLICACIONES WEB AVANZADAS\webapppolimusicv1_asp

echo ============================================================
echo  DESPLIEGUE FINAL - POLIMUSIC
echo ============================================================
echo.

echo [1/5] Sincronizando proyecto a wwwroot...
robocopy "%DESK%\config"   "%ROOT%\config"   /MIR /XF secrets.asp
robocopy "%DESK%\includes" "%ROOT%\includes" /MIR
robocopy "%DESK%\admin"    "%ROOT%\admin"    /MIR
copy /Y "%DESK%\default.asp" "%ROOT%\default.asp" >nul 2>&1
copy /Y "%DESK%\login.asp"   "%ROOT%\login.asp"   >nul 2>&1
copy /Y "%DESK%\songs.asp"   "%ROOT%\songs.asp"   >nul 2>&1
copy /Y "%DESK%\logout.asp"  "%ROOT%\logout.asp"  >nul 2>&1
copy /Y "%DESK%\denied.asp"  "%ROOT%\denied.asp"  >nul 2>&1
echo     Sincronizado.
echo.

echo [2/5] Confirmando que la app IIS existe con la ruta correcta...
%APCMD% list app "%SITE%/%APP%"
echo.

echo [3/5] Reiniciando IIS...
iisreset >nul
echo.

echo [4/5] PRUEBAS SIN SESION:
echo.
echo    --- login.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/login.asp
echo    --- default.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/default.asp
echo    --- songs.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/songs.asp
echo    --- logout.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/logout.asp
echo    --- denied.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/denied.asp
echo    --- ADMIN/songs.asp (sin sesion: debe ser 302, no 500) ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/admin/songs.asp
echo    --- ADMIN/song_create.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/admin/song_create.asp
echo    --- ADMIN/song_edit.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/admin/song_edit.asp
echo    --- ADMIN/song_delete.asp ---
curl -s -o nul -w "      HTTP: %%{http_code}\n" http://localhost/%APP%/admin/song_delete.asp
echo    --- estaticos ---
curl -s -o nul -w "      styles.css: HTTP %%{http_code}\n" http://localhost/%APP%/assets/css/styles.css
curl -s -o nul -w "      mp3:        HTTP %%{http_code}\n" http://localhost/%APP%/assets/audio/bensound-adventure.mp3
echo.
echo    (sin ningun 500 = OK)

echo [5/5] PRUEBA CON SESION REAL (login end-to-end):
call "%DESK%\test_e2e.bat" /nopause
echo.
echo ============================================================
pause
