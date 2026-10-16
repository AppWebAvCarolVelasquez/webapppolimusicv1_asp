@echo off
REM ===============================================================
REM  PoliMusic - Prueba END-TO-END con sesion real
REM  Ejecutar como Administrador
REM ===============================================================
setlocal enabledelayedexpansion

set APP=webapppolimusicv1_asp
set BASE=http://localhost/%APP%
set CK=%TEMP%\poli_cookies.txt
set CKADM=%TEMP%\poli_admin.txt

del "%CK%" "%CKADM%" 2>nul

echo ============================================================
echo  PRUEBA END-TO-END - POLIMUSIC
echo ============================================================
echo.

echo [1] Login con userNormal / 12345678 ...
curl -s -c "%CK%" -b "%CK%" -o nul -w "      POST login: HTTP %%{http_code} -> %%{redirect_url}\n" ^
  -d "username=userNormal&password=12345678" "%BASE%/login.asp"
echo     Cookies guardadas:
findstr /C:"ASPSESSIONID" "%CK%" 2>nul
echo.

echo [2] Con sesion de userNormal, pedir songs.asp ...
curl -s -b "%CK%" -o nul -w "      songs.asp: HTTP %%{http_code}\n" "%BASE%/songs.asp"
echo     Contenido (debe aparecer el usuario y las canciones):
curl -s -b "%CK%" "%BASE%/songs.asp" | findstr /C:"userNormal" /C:"Adventure" /C:"Dreams" /C:"Juan Gabriel" /C:"Song List"
echo.

echo [3] userNormal intenta admin/songs.asp (debe redirigir a denied) ...
curl -s -b "%CK%" -o nul -w "      admin/songs.asp: HTTP %%{http_code} -> %%{redirect_url}\n" "%BASE%/admin/songs.asp"
echo.

echo ============================================================
echo [4] Login con userAdmin / 12345678 ...
curl -s -c "%CKADM%" -b "%CKADM%" -o nul -w "      POST login: HTTP %%{http_code} -> %%{redirect_url}\n" ^
  -d "username=userAdmin&password=12345678" "%BASE%/login.asp"
echo.

echo [5] Con sesion de ADMIN, pedir admin/songs.asp (debe ser 200) ...
curl -s -b "%CKADM%" -o nul -w "      admin/songs.asp: HTTP %%{http_code}\n" "%BASE%/admin/songs.asp"
echo     Contenido (debe listar canciones + botones CRUD):
curl -s -b "%CKADM%" "%BASE%/admin/songs.asp" | findstr /C:"Gestion de Canciones" /C:"Adventure" /C:"Nueva Cancion" /C:"Editar" /C:"Eliminar"
echo.

echo [6] Resto de paginas de admin con sesion admin:
curl -s -b "%CKADM%" -o nul -w "      song_create.asp: HTTP %%{http_code}\n" "%BASE%/admin/song_create.asp"
curl -s -b "%CKADM%" -o nul -w "      song_edit.asp?id=1: HTTP %%{http_code}\n" "%BASE%/admin/song_edit.asp?id=1"
curl -s -b "%CKADM%" -o nul -w "      song_delete.asp?id=1: HTTP %%{http_code}\n" "%BASE%/admin/song_delete.asp?id=1"
echo.

echo [7] Busqueda (parametro q) con sesion userNormal ...
curl -s -b "%CK%" -o nul -w "      songs.asp?q=Adventure: HTTP %%{http_code}\n" "%BASE%/songs.asp?q=Adventure"
echo.

del "%CK%" "%CKADM%" 2>nul

echo ============================================================
echo  ESPERADO:
echo    [1] login userNormal   -^> 302 (a songs.asp)
echo    [2] songs.asp          -^> 200 + "userNormal" + nombres de canciones
echo    [3] admin (userNormal) -^> 302 (a denied.asp)
echo    [4] login userAdmin    -^> 302
echo    [5] admin/songs (admin)-^> 200 + "Gestion de Canciones"
echo    [6] crear/editar/borrar-^> 200
echo    [7] busqueda           -^> 200
echo ============================================================
if /I "%~1"=="/nopause" goto :eof
pause
