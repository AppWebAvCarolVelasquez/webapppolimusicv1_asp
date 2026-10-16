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
- Session regeneration implemented for fixation prevention
- Delete operations: child records (TBL_PLAYER, TBL_TRACKLIST, TBL_PLAYLIST_SONG) deleted first, then TBL_SONG

## Environment
- IIS installed with Classic ASP support (asp.dll present)
- SQL Server 2017 (MSSQL17.MSSQLSERVER instance)
- ADO available at C:\Program Files\Common Files\System\ado\
- Project deployed at virtual path: /webapppolimusicv1_asp
