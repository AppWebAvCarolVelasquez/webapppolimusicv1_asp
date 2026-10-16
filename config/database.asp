<%
'===============================================================
' config/database.asp
' PoliMusic - Centralized Database Connection Configuration
'===============================================================
' This file centralizes the SQL Server connection string and provides
' a reusable function to open ADO connections.
'
' SECURITY:
'   - Real credentials are loaded from config/secrets.asp (gitignored).
'   - Never hardcode passwords in this file.
'   - The application uses SQL Server Authentication by default (usr_polimusic).
'   - For Windows Authentication, set DB_USE_WINDOWS_AUTH = True in secrets.asp.
'
' ADAPT TO YOUR ENVIRONMENT:
'   - Local SQL Server:     Server=localhost
'   - Named instance:        Server=localhost\SQLEXPRESS
'   - Docker SQL Server:     Server=localhost,1433
'   - Remote server:          Server=192.168.1.100,1433
'===============================================================
' NOTE: Option Explicit is declared in the PAGES that include this
' file, NOT here - declaring it in an included file would duplicate
' it after the #INCLUDE merge and break VBScript compilation.
'===============================================================

' --- Database configuration variables ---
Dim DB_SERVER, DB_NAME, DB_USER, DB_PASS, DB_USE_WINDOWS_AUTH
Dim DB_PORT

' Default values (overridden by secrets.asp if present)
DB_SERVER        = "localhost"       ' SQL Server instance name or IP
DB_NAME          = "BDD_PoliMusic"   ' Database name (from BDD_PoliMusic.sql)
DB_PORT          = ""                ' Empty = default (1433); or specify e.g. "1433"
DB_USE_WINDOWS_AUTH = True            ' Windows Auth (IUSR has db_datareader/db_datawriter)
DB_USER          = ""                ' SQL auth user (if DB_USE_WINDOWS_AUTH = False)
DB_PASS          = ""                ' SQL auth password (if DB_USE_WINDOWS_AUTH = False)

' --- Load secrets.asp at runtime using ExecuteGlobal ---
' NOTE: Classic ASP #INCLUDE is processed at parse time and cannot
' be conditional. We use ExecuteGlobal as a runtime alternative.
Dim fso, secretsPath, ts, secretsContent
Set fso = Server.CreateObject("Scripting.FileSystemObject")
secretsPath = Server.MapPath(".") & "\secrets.asp"
If fso.FileExists(secretsPath) Then
    On Error Resume Next
    Set ts = fso.OpenTextFile(secretsPath, 1) ' 1 = ForReading
    secretsContent = ts.ReadAll
    ts.Close
    Set ts = Nothing
    If Len(secretsContent) > 0 Then
        ' Remove ASP delimiters before executing.
        ' IMPORTANT: the ASP opening and closing delimiters MUST be built
        ' by concatenation (as done below). Writing them literally inside a
        ' string OR inside a comment would make the IIS ASP parser treat
        ' them as real delimiters: it terminates/restarts the script block
        ' at those characters, splitting the statement and causing VBScript
        ' compilation errors (800a0409 / 800a03f6) on every page that
        ' includes this file. Never write those two characters literally.
        secretsContent = Replace(secretsContent, "<" & "%" & vbCrLf, "")
        secretsContent = Replace(secretsContent, "<" & "%" & vbCr, "")
        secretsContent = Replace(secretsContent, "<" & "%" & vbLf, "")
        secretsContent = Replace(secretsContent, "<" & "%", "")
        secretsContent = Replace(secretsContent, vbCrLf & "%" & ">", "")
        secretsContent = Replace(secretsContent, "%" & ">", "")
        ExecuteGlobal secretsContent
    End If
    On Error GoTo 0
End If
Set fso = Nothing

'===============================================================
' Function: OpenDatabase
' Returns: ADODB.Connection object (open and ready)
' Throws:  Raises a user-friendly error if connection fails
'===============================================================
Function OpenDatabase()
    Dim conn, connStr, serverPart

    ' Build server part (include port if specified)
    serverPart = DB_SERVER
    If DB_PORT <> "" Then
        serverPart = serverPart & "," & DB_PORT
    End If

    ' Build connection string
    If DB_USE_WINDOWS_AUTH Then
        connStr = "Provider=SQLOLEDB;" & _
                  "Data Source=" & serverPart & ";" & _
                  "Initial Catalog=" & DB_NAME & ";" & _
                  "Integrated Security=SSPI;"
    Else
        connStr = "Provider=SQLOLEDB;" & _
                  "Data Source=" & serverPart & ";" & _
                  "Initial Catalog=" & DB_NAME & ";" & _
                  "User ID=" & DB_USER & ";" & _
                  "Password=" & DB_PASS & ";"
    End If

    Set conn = Server.CreateObject("ADODB.Connection")

    ' Connection timeout (seconds)
    conn.ConnectionTimeout = 15
    ' Command timeout (seconds)
    conn.CommandTimeout = 30

    On Error Resume Next
    conn.Open connStr

    If Err.Number <> 0 Then
        ' Log technical error details (not shown to user)
        Call LogError("database.asp:OpenDatabase", Err.Number, Err.Description, connStr)
        On Error GoTo 0
        Set conn = Nothing
        ' Raise a user-friendly error
        Err.Raise vbObjectError + 1001, "OpenDatabase", _
            "No se pudo conectar a la base de datos. Verifique la configuracion."
    End If
    On Error GoTo 0

    Set OpenDatabase = conn
End Function

'===============================================================
' Function: CloseDatabase
' Safely closes and destroys a connection
'===============================================================
Sub CloseDatabase(ByRef conn)
    On Error Resume Next
    If Not (conn Is Nothing) Then
        If conn.State = 1 Then conn.Close  ' adStateOpen = 1
        Set conn = Nothing
    End If
    On Error GoTo 0
End Sub

'===============================================================
' Sub: LogError
' Logs technical error details to a protected file.
' Never exposes these details to the end user.
'===============================================================
Sub LogError(source, errNumber, errDescription, contextInfo)
    Dim logPath, logFile, fsoLog, ts
    On Error Resume Next

    Set fsoLog = Server.CreateObject("Scripting.FileSystemObject")
    logPath = Server.MapPath(".") & "\..\logs"
    If Not fsoLog.FolderExists(logPath) Then
        fsoLog.CreateFolder(logPath)
    End If

    logFile = logPath & "\error_log.txt"
    Set ts = fsoLog.OpenTextFile(logFile, 8, True) ' 8 = ForAppending

    ts.WriteLine "=== " & Now() & " ==="
    ts.WriteLine "Source: " & source
    ts.WriteLine "Error #" & errNumber & ": " & errDescription
    ' Do NOT log full connection strings or passwords
    ts.WriteLine "---"
    ts.WriteLine ""

    ts.Close
    Set ts = Nothing
    Set fsoLog = Nothing
    On Error GoTo 0
End Sub

'===============================================================
' Function: GetConfiguredConnString (for debugging only)
' Returns a sanitized connection string WITHOUT credentials.
' Use only during development.
'===============================================================
Function GetConfiguredConnString()
    Dim s
    If DB_USE_WINDOWS_AUTH Then
        s = "Provider=SQLOLEDB; Data Source=" & DB_SERVER
        If DB_PORT <> "" Then s = s & "," & DB_PORT
        s = s & "; Initial Catalog=" & DB_NAME & "; Integrated Security=SSPI;"
    Else
        s = "Provider=SQLOLEDB; Data Source=" & DB_SERVER
        If DB_PORT <> "" Then s = s & "," & DB_PORT
        s = s & "; Initial Catalog=" & DB_NAME & "; User ID=***; Password=***;"
    End If
    GetConfiguredConnString = s
End Function
%>
