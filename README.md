# PoliMusic

Aplicación web de gestión y reproducción de canciones, desarrollada con Classic ASP (VBScript), IIS y Microsoft SQL Server, como proyecto del Taller de Aplicaciones Web Avanzadas.

## Descripción

PoliMusic es una plataforma musical que permite a los usuarios consultar el catálogo de canciones, ver los artistas asociados y reproducir archivos de audio reales. Los administradores pueden crear, editar y eliminar canciones. La aplicación cumple con prácticas de seguridad web (OWASP Top 10) y accesibilidad (WCAG 2.2 AA).

## Tecnologías

| Componente | Tecnología |
|------------|------------|
| Backend | Classic ASP (VBScript) |
| Servidor web | IIS con soporte para Classic ASP |
| Base de datos | Microsoft SQL Server 2017 |
| Conexión a datos | ADO (`ADODB.Connection`, `ADODB.Command`, `ADODB.Recordset`) |
| Frontend | HTML5 semántico, CSS3, JavaScript (vanilla) |
| Sesiones | Mecanismo de sesión nativo de Classic ASP |
| Control de versiones | Git + GitHub |

## Requisitos previos

1. **Windows** con IIS instalado (incluye soporte para Classic ASP).
2. **SQL Server** (2017 o superior) con la base de datos `BDD_PoliMusic` creada (ejecute el script `BDD_PoliMusic.sql` incluido en el proyecto).
3. **ADO** registrado en el sistema (incluido con Windows: `C:\Program Files\Common Files\System\ado\msado15.dll`).
4. **Git** instalado para control de versiones.

## Configuración de IIS

### 1. Habilitar Classic ASP

1. Abra **Panel de Control > Programas y características > Activar o desactivar las características de Windows**.
2. Active **Internet Information Services**.
3. Dentro de **World Wide Web Services > Application Development Features**, marque **ASP**.
4. Asegúrese de que **Directory Browsing** esté desactivado para directorios de recursos.

### 2. Crear el sitio en IIS

**IMPORTANTE:** El proyecto debe ejecutarse fuera de la carpeta de perfil de usuario (`C:\Users\...`). La carpeta de perfil solo permite acceso a `SYSTEM`, `Administradores` y el propio usuario, por lo que IIS no puede leer los archivos si el proyecto está en el Escritorio o Documentos (error **HTTP 401.3 - Unauthorized**). Use una ruta como `C:\inetpub\wwwroot\webapppolimusicv1_asp`.

1. Abra **Administrador de IIS** (`inetmgr`).
2. Haga clic derecho en **Sitios > Agregar sitio web**.
3. **Nombre del sitio:** `PoliMusic`
4. **Ruta física:** `C:\inetpub\wwwroot\webapppolimusicv1_asp`
5. **Enlace:** Tipo `http`, Puerto `80`, Nombre de host según su preferencia.
6. Haga clic en **Aceptar**.

> **Script automático:** El repositorio incluye `setup_iis.bat` (crea la aplicación IIS) y `move_to_wwwroot.bat` (copia el proyecto a `C:\inetpub\wwwroot\webapppolimusicv1_asp`, actualiza la ruta física de la aplicación, aplica permisos NTFS y reinicia IIS). Ejecútelos **como Administrador**.

### 3. Configurar permisos

1. Asegúrese de que el usuario `IIS_IUSRS` tenga permisos de **lectura** en todo el proyecto.
2. Otorgue permisos de **escritura** en la carpeta `logs/` (para registro de errores).
3. Otorgue permisos de **lectura** en `assets/audio/` y `assets/images/`.

### 4. Configurar ASP

1. En el Administrador de IIS, seleccione el sitio.
2. Abra **Restricciones de ISAPI y CGI** y asegúrese de que ASP esté permitido.
3. En **ASP > Propiedades de depuración**, habilite los mensajes de error solo en desarrollo.

> **Nota sobre los `#INCLUDE` (importante):** Las páginas de `admin/` incluyen los archivos compartidos con `#INCLUDE VIRTUAL="/webapppolimusicv1_asp/..."` en lugar de `#INCLUDE FILE="../..."`. IIS **bloquea por defecto las rutas primarias** (`..`) en los `#INCLUDE` y devuelve el error **ASP 0131 - Ruta de directorio primario no autorizada**. Usar `VIRTUAL` evita este error sin necesidad de habilitar `AspEnableParentPaths`, por lo que la aplicación funciona con la configuración de IIS por defecto. Si en algún momento se despliega bajo otra ruta virtual, ajuste el prefijo `/webapppolimusicv1_asp` en los `#INCLUDE VIRTUAL` de los archivos de `admin/`.

## Configuración de SQL Server

### Conexión por Windows Authentication (recomendado para desarrollo local)

1. Ejecute el script `BDD_PoliMusic.sql` en SQL Server Management Studio para crear la base de datos, tablas, usuario SQL (`usr_polimusic`) y datos iniciales.
2. Verifique que el servicio SQL Server esté en ejecución.
3. El script crea el login `usr_polimusic` con los permisos necesarios sobre la base de datos `BDD_PoliMusic`.
4. Para Windows Authentication: cree un inicio de sesión de Windows para el usuario del grupo de aplicaciones de IIS.

### Conexión por SQL Server Authentication

1. Cree un usuario SQL Server con privilegios mínimos (solo SELECT, INSERT, UPDATE, DELETE sobre las tablas de `BDD`).
2. No use la cuenta `sa` para la aplicación.

### Adaptar la conexión

Edite el archivo `config/secrets.asp` (copiado desde `secrets.asp.example`) con los valores de su entorno:

```vbscript
DB_SERVER = "localhost"           ' Servidor o instancia
DB_NAME = "BDD_PoliMusic"         ' Nombre de la base de datos
DB_PORT = ""                      ' Puerto (vacío = 1433 por defecto)
DB_USE_WINDOWS_AUTH = False        ' False = SQL Auth (usr_polimusic); True = Windows Auth
DB_USER = "usr_polimusic"         ' Login SQL creado por BDD_PoliMusic.sql
DB_PASS = ""                      ' Contraseña del login (establecida al ejecutar el script)
```

**Docker:** Si SQL Server corre en Docker, use `DB_SERVER = "localhost"` y `DB_PORT = "1433"`.

## Configuración de la conexión

El archivo `config/database.asp` centraliza la lógica de conexión. Utiliza ADO con el proveedor `SQLOLEDB` y expone:

- `OpenDatabase()`: Abre y devuelve una conexión activa.
- `CloseDatabase(conn)`: Cierra y destruye una conexión de forma segura.
- `LogError(...)`: Registra errores técnicos en `logs/error_log.txt` (sin exponer datos al usuario).

**Seguridad de credenciales:** Las credenciales se cargan desde `config/secrets.asp`, que está excluido de Git mediante `.gitignore`. Nunca se publican en el repositorio.

## Instalación de los recursos

1. Descomprima `SongFilesAndImages_resources.zip` (proporcionado por el taller).
2. Coloque los archivos de audio (`.mp3`, `.wav`) en `assets/audio/`.
3. Coloque las imágenes (`.jpg`, `.png`) en `assets/images/`.
4. Verifique que las rutas almacenadas en `TBL_SONG.SONG_PATH` coincidan con la estructura de carpetas. Las rutas en la base de datos usan el formato `~/songFiles/bensound-*.mp3`. La función `ResolveAudioPath()` en `songs.asp` convierte `~/songFiles/` a `assets/audio/` automáticamente. Asegúrese de que los archivos de audio del ZIP estén en `assets/audio/`.

## Estructura del proyecto

```
webapppolimusicv1_asp/
├── config/
│   ├── database.asp           # Configuración de conexión centralizada
│   ├── secrets.asp.example    # Plantilla de credenciales (copiar a secrets.asp)
│   └── secrets.asp             # Credenciales reales (gitignored)
├── includes/
│   ├── auth.asp               # Inclusión de autenticación para páginas protegidas
│   ├── functions.asp          # Funciones utilitarias (encoding, CSRF, etc.)
│   ├── security.asp           # Cabeceras HTTP de seguridad y controles de acceso
│   ├── header.asp             # Layout compartido: sidebar y top bar
│   └── footer.asp             # Layout compartido: cierre y scripts
├── admin/
│   ├── songs.asp              # Panel administrativo (listado CRUD)
│   ├── song_create.asp        # Crear canción (POST + CSRF)
│   ├── song_edit.asp          # Editar canción (POST + CSRF)
│   └── song_delete.asp        # Eliminar canción (POST + CSRF, confirmación)
├── assets/
│   ├── css/
│   │   └── styles.css         # Estilos completos (tema oscuro, responsive, accesible)
│   ├── js/
│   │   ├── player.js          # Funcionalidad del reproductor de audio
│   │   └── main.js            # Helpers de UI (menú móvil, foco, formularios)
│   ├── audio/                 # Archivos de audio (del ZIP del taller)
│   └── images/                # Imágenes (del ZIP del taller)
├── docs/
│   └── ACCESSIBILITY.md       # Documentación de accesibilidad WCAG 2.2 AA
├── tools/
│   └── asp_parse_check.py     # Verificador estático de errores de parseo en Classic ASP
├── logs/                      # Registros de error (no versionado)
├── login.asp                  # Página de inicio de sesión
├── logout.asp                 # Cierre de sesión (invalidación completa)
├── songs.asp                   # Página principal: Song List con reproductor
├── denied.asp                  # Página de acceso denegado
├── .gitignore
└── README.md
```

## Instrucciones de ejecución

1. Ejecute `BDD_PoliMusic.sql` en SQL Server para crear la base de datos y los datos iniciales.
2. Copie `config/secrets.asp.example` a `config/secrets.asp` y complete los valores (o use los valores por defecto con Windows Authentication).
3. Coloque los archivos de audio en `assets/audio/` (los MP3 de bensound).
4. Ejecute `setup_iis.bat` **como Administrador** (crea la aplicación IIS `/webapppolimusicv1_asp`).
5. Ejecute `move_to_wwwroot.bat` **como Administrador** (copia el proyecto a `C:\inetpub\wwwroot\webapppolimusicv1_asp`, actualiza la ruta física de la aplicación, aplica permisos NTFS con `IIS_IUSRS` e `IUSR`, y reinicia IIS).
6. Abra `http://localhost/webapppolimusicv1_asp/login.asp` en su navegador.
7. Inicie sesión con un usuario de prueba (ver tabla abajo).

> **Verificación rápida:** ejecute `deploy_final.bat` **como Administrador** para sincronizar el proyecto a `wwwroot`, reiniciar IIS y comprobar por HTTP que todas las páginas responden (200/302) sin errores 500.

### Usuarios de prueba (creados por `BDD_PoliMusic.sql`)

| Usuario | Contraseña | Tipo | Rol |
|---------|-----------|------|-----|
| `userNormal` | `12345678` | 0 | Usuario normal |
| `userAdmin` | `12345678` | 1 | Administrador |
| `username1` | (hash SHA-1) | 0 | Usuario normal |

## Roles de usuario

| Funcionalidad | Usuario Normal | Administrador |
|--------------|:--------------:|:--------------:|
| Iniciar/cerrar sesión | ✓ | ✓ |
| Consultar catálogo de canciones | ✓ | ✓ |
| Ver artistas asociados | ✓ | ✓ |
| Reproducir canciones | ✓ | ✓ |
| Buscar canciones/artistas | ✓ | ✓ |
| Crear canciones | ✗ | ✓ |
| Editar canciones | ✗ | ✓ |
| Eliminar canciones | ✗ | ✓ |

**Nota sobre `USER_TYPE`:** En `BDD_PoliMusic.sql`, `USER_TYPE` es un campo `int` donde `0` = usuario normal y `1` = administrador. La función `IsAdmin()` en `includes/functions.asp` acepta `1` o `"admin"` como valor de administrador, lo cual es compatible con el esquema real.

## Instrucciones de prueba

### Funcionalidad

1. Inicie sesión con credenciales válidas → debe redirigir a `songs.asp`.
2. Inicie sesión con credenciales inválidas → debe mostrar mensaje de error genérico.
3. Verifique que la página muestre el nombre del usuario y "Song List".
4. Consulte la tabla de canciones con nombres y artistas.
5. Reproduzca un archivo de audio con el reproductor nativo.
6. Como administrador, cree una canción y verifique que aparezca en el listado.
7. Como administrador, edite una canción y verifique los cambios.
8. Como administrador, elimine una canción (con confirmación) y verifique la eliminación.
9. Como usuario normal, intente acceder a `/admin/songs.asp` → debe redirigir a `denied.asp`.
10. Sin sesión, intente acceder a `songs.asp` → debe redirigir a `login.asp`.
11. Cierre sesión → no debe poder acceder a páginas protegidas con la sesión anterior.

### Seguridad

1. Intente inyección SQL en el login (ej: `' OR 1=1 --`) → debe fallar (consultas parametrizadas).
2. Ingrese caracteres HTML en campos de búsqueda → deben mostrarse codificados (XSS).
3. Como usuario normal, acceda directamente a `admin/song_delete.asp` → acceso denegado.
4. Modifique el ID en la URL de edición → solo puede editar canciones existentes.
5. Envíe un POST sin token CSRF → debe rechazarse.
6. Después del logout, use el botón de retroceso → no debe mostrar datos de sesión.
7. Verifique que los errores no revelen rutas, credenciales ni consultas SQL.
8. Verifique las cabeceras HTTP: CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy.

### Accesibilidad

1. Navegue con solo teclado (Tab, Shift+Tab, Enter, Space, flechas).
2. Verifique que el indicador de foco sea visible en todos los elementos interactivos.
3. Verifique el contraste de colores con una herramienta de verificación.
4. Pruebe el zoom al 200% sin pérdida de contenido.
5. Pruebe el reflujo a 320px en Chrome DevTools.
6. Use un lector de pantalla (NVDA) para recorrer cada flujo.
7. Verifique que las alertas se anuncien (`role="alert"`, `aria-live`).

## Consideraciones de seguridad

- **Inyección SQL:** Todas las consultas usan `ADODB.Command` con parámetros tipados.
- **XSS:** Toda salida dinámica se codifica con `Server.HTMLEncode` o funciones de codificación específicas (`EncodeAttr`, `EncodeJS`).
- **CSRF:** Tokens CSRF validados en el servidor para todas las operaciones de escritura.
- **Sesiones:** `Session.Abandon` en logout; en el login se limpia el estado previo y se rota el token CSRF (`ResetSessionForLogin()`) como mitigación de fijación de sesión. *(Nota: en Classic ASP no es posible regenerar el ID de sesión de forma fiable; se documenta la alternativa aplicada.)*
- **Errores:** Los detalles técnicos se registran en `logs/error_log.txt`; el usuario ve mensajes genéricos. Los errores detallados de ASP (`scriptErrorSentToBrowser`) deben permanecer **desactivados** en producción.
- **Rutas:** Validación contra directory traversal (`..` en rutas).
- **Cabeceras HTTP:** CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy.
- **Principio de mínimo privilegio:** No usar cuentas `sa`; usar usuario con permisos mínimos.

## Verificación estática (herramienta incluida)

El proyecto incluye `tools/asp_parse_check.py`, un verificador que detecta —antes de desplegar— los errores de parseo típicos de Classic ASP:

```bash
python tools/asp_parse_check.py default.asp login.asp songs.asp logout.asp denied.asp \
  admin/songs.asp admin/song_create.asp admin/song_edit.asp admin/song_delete.asp
```

Comprueba:
1. Caracteres delimitadores ASP (`<%` / `%>`) escritos dentro de cadenas o comentarios (provocan los errores 800a0409 / 800a03f6).
2. `#INCLUDE FILE` con `..` (IIS lo bloquea → error ASP 0131; por eso se usa `#INCLUDE VIRTUAL`).
3. Cadenas sin terminar y bloques de script sin cerrar.

Salida esperada: `[ OK ] <página> parses cleanly` para cada archivo.

## Consideraciones de accesibilidad

Consulte `docs/ACCESSIBILITY.md` para el detalle completo. Resumen:

- WCAG 2.2 AA como objetivo de conformidad.
- HTML semántico, ARIA cuando es necesario.
- Contraste de color verificado (mínimo 4.5:1 para texto).
- Navegación por teclado completa, foco visible, skip link.
- Diseño responsive con reflujo a 320px.
- `prefers-reduced-motion` respetado.
- Reproductor nativo `<audio controls>` accesible.

## Limitaciones conocidas

1. **Contraseñas en texto plano:** El script `BDD_PoliMusic.sql` inserta usuarios con contraseñas en texto plano (`userNormal` y `userAdmin` con `12345678`). El usuario `username1` usa un hash SHA-1. Esto es un riesgo de seguridad. Se recomienda migrar a hashing (ej: SHA-256 con sal) de forma compatible. **No se modificaron las cuentas existentes sin autorización.**

2. **Sin recursos verificados:** Los archivos `SongFilesAndImages_resources.zip` no estaban disponibles en el entorno de desarrollo. Las rutas de audio se resuelven dinámicamente con `ResolveAudioPath()`, pero debe verificar que coincidan con los archivos reales.

3. **Sin pruebas automatizadas ejecutadas:** Las herramientas axe DevTools y Accessibility Insights requieren que la aplicación esté ejecutándose en IIS. Ejecute las pruebas una vez configurado el entorno.

4. **`USER_TYPE` verificado:** El script `BDD_PoliMusic.sql` confirma que `USER_TYPE` es `int`: `0` = normal, `1` = admin. La función `IsAdmin()` ya está adaptada.

5. **Cookies de sesión Classic ASP:** Classic ASP gestiona las cookies de sesión automáticamente. Los atributos `HttpOnly`, `Secure` y `SameSite` requieren configuración a nivel de IIS o servidor, no directamente desde el código ASP.

6. **HTTPS en desarrollo local:** La aplicación funciona sobre HTTP en desarrollo local. No proporciona confidencialidad de transporte en este modo.

7. **`SCOPE_IDENTITY()` en SQL Server:** La inserción de canciones usa `SCOPE_IDENTITY()` para obtener el ID recién creado. Si la versión de SQL Server no soporta esta función, use `@@IDENTITY` como alternativa.

## Git y GitHub

### Estado del repositorio

```
git status
```

Antes de hacer commit:
- Verifique que `config/secrets.asp` esté en `.gitignore`.
- No incluya credenciales ni archivos sensibles.
- Los recursos (audio/imágenes) pueden omitirse del repositorio si son licenciados.

### Mensaje de commit propuesto

```
First version: PoliMusic ASP web application 1.0
```

**Importante:** No hacer `push` ni publicar el proyecto sin autorización explícita.
