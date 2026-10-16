# PoliMusic Project Memory

## Project Overview
- **Name:** PoliMusic - Classic ASP music web application
- **Type:** University workshop project (Aplicaciones Web Avanzadas)
- **Stack:** Classic ASP (VBScript), IIS, SQL Server 2017, ADO, HTML5/CSS3/JS
- **GitHub:** https://github.com/AppWebAvCarolVelasquez/webapppolimusicv1_asp.git
- **DB script:** BDD_PoliMusic.sql (UTF-16LE encoded, creates BDD_PoliMusic database)

## Database
- **DB name:** BDD_PoliMusic (NOT "BDD" as the prompt stated)
- **SQL login:** usr_polimusic / password in secrets.asp
- **USER_TYPE:** int field: 0 = normal user, 1 = admin
- **Test users:** userNormal/12345678 (type 0), userAdmin/12345678 (type 1)
- **Song paths:** format ~/songFiles/bensound-*.mp3 (5 songs: Adventure, Dreams, Energy, Scifi, Tomorrow)
- **Passwords:** Plain text for test users; SHA-1 hash for username1

## Key Technical Decisions
- ExecuteGlobal used for runtime loading of secrets.asp (Classic ASP #INCLUDE is parse-time only)
- STUFF/FOR XML PATH used to concatenate artist names per song (avoids duplicates)
- ResolveAudioPath() maps ~/songFiles/ → assets/audio/ automatically
- CSP: no unsafe-inline or unsafe-eval; all scripts/styles are external files
- CSRF tokens validated server-side for all POST operations
- **Session fixation mitigation**: `ResetSessionForLogin()` (includes/functions.asp) clears pre-login session contents and issues a fresh CSRF token. **DO NOT reintroduce `Session.Abandon` + `Set-Cookie` cookie-clearing at login** — that combination destroys the session and logs the user out immediately (verified bug). Classic ASP cannot reliably regenerate the session ID mid-request.
- logout.asp correctly uses Session.Abandon (there we DO want destruction) and reads the real ASPSESSIONID cookie name from HTTP_COOKIE instead of hardcoding it
- Delete operations: child records (TBL_PLAYER, TBL_TRACKLIST, TBL_PLAYLIST_SONG) deleted first, then TBL_SONG

## Classic ASP Hard-Won Lessons (IIS parse-time)
- **NEVER write the characters `<` `%` or `%` `>` ANYWHERE in an .asp file except as real block delimiters** — including inside VBScript string literals **AND inside `'` comments**. The IIS ASP tokenizer is delimiter-based, NOT string-aware and NOT comment-aware. It sees them mid-line, terminates/restarts the script block there, and splits the statement → unterminated string (800a0409) or unbalanced block (800a03f6) on every page that includes the file. Build them by concatenation when a literal value is genuinely needed: `"<" & "%"`, `"%" & ">"` (see config/database.asp). To *describe* them in a comment, spell them out in words ("ASP opening/closing delimiters") — never paste the raw characters.
- The same applies to an explanatory comment ABOUT the bug: the first fix for database.asp failed because the comment itself contained the literal `<%` and `%>` (error changed 800a0409 → 800a03f6). Lesson learned and documented.
- **`#INCLUDE FILE` with `..` is BLOCKED by IIS by default** (`AspEnableParentPaths=False`) → error **ASP 0131 "Ruta de directorio primario no autorizada"**. ALL pages in `admin/` broke on this. Decision: use **`#INCLUDE VIRTUAL="/webapppolimusicv1_asp/config/database.asp"`** (Opción B, chosen by the user as the more correct fix) instead of enabling parent paths. VIRTUAL is absolute from the app virtual root and works under default IIS config. If the app's virtual path changes, the prefix in those VIRTUAL includes must change too.
- `Option Explicit` must be declared ONLY in pages, never in included files — #INCLUDE is a textual parse-time merge, so a duplicate = compile error
- Static checker: `tools/asp_parse_check.py <pages...>` emulates the IIS tokenizer + VBScript quote balance AND flags `#INCLUDE FILE="../..."` parent-path includes, before deploying (negative-control tested)
- `appcmd set config /section:asp` has NO `/enabled` attribute (use `/scriptErrorSentToBrowser:true`); revert it when debugging ends
- ibad physicalPath: a trailing backslash in the app physicalPath breaks web.config reads (500.19 / 0x8007007b); fix with `appcmd set app /physicalPath` (no trailing `\`)
- wwwroot deployment must sync `config\database.asp` etc. via robocopy, then `iisreset` to flush the ASP compile cache
- Deployment dir `C:\inetpub\wwwroot\...` is not writable by the agent (needs Administrator) — ship a .bat for the user to run elevated
- IIS detailed ASP errors print the exact error code + line — the fastest way to tell ASP 0131 (include) from 800a0409 (string) from 800a03f6 (block)

## Environment
- IIS installed with Classic ASP support (asp.dll present)
- SQL Server 2017 (MSSQL17.MSSQLSERVER instance)
- ADO available at C:\Program Files\Common Files\System\ado\
- Project deployed at virtual path: /webapppolimusicv1_asp
- **STATUS: fully working** (all 11 routes return 200/302, no 500). Deploy with `deploy_final.bat`, e2e test with `test_e2e.bat` (both as Administrator).
- IIS detailed ASP errors (`scriptErrorSentToBrowser:true`) were enabled during debugging — must be reverted to `false` for the final delivery.
- Agent can READ but not WRITE `C:\inetpub\wwwroot\...`; ship .bat scripts for the user to run elevated.
