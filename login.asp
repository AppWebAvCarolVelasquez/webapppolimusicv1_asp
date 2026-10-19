<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' login.asp
' PoliMusic - Login Page
'===============================================================
' Validates user credentials against TBL_USER using parametrized
' queries (ADODB.Command). On success, stores session variables
' and regenerates the session ID (fixation prevention).
'===============================================================
%>
<!-- #INCLUDE FILE="config/database.asp" -->
<!-- #INCLUDE FILE="includes/functions.asp" -->
<!-- #INCLUDE FILE="includes/security.asp" -->
<%
' Set security headers
Call SetSecurityHeaders()

' If already logged in, redirect to songs
If IsAuthenticated() Then
    Redirect GetAppPath() & "/songs.asp"
End If

Dim errorMsg, username, returnUrl

errorMsg   = ""
username   = ""
returnUrl  = Request.QueryString("returnUrl")
If returnUrl = "" Then returnUrl = GetAppPath() & "/songs.asp"

' Process login form submission (POST only)
If IsPostRequest() Then
    Dim submittedUsername, submittedPassword
    Dim conn, cmd, rs

    submittedUsername = SanitizeString(Request.Form("username"), 50)
    submittedPassword = Request.Form("password")  ' Do not sanitize password (keep as-is)

    ' Basic server-side validation
    If submittedUsername = "" Or submittedPassword = "" Then
        errorMsg = "Por favor ingrese su usuario y contrasena."
    Else
        ' Open database connection
        On Error Resume Next
        Set conn = OpenDatabase()
        If Err.Number <> 0 Then
            errorMsg = "Error de conexion. Por favor, intente mas tarde."
            ' Technical details logged in LogError
            On Error GoTo 0
        Else
            On Error GoTo 0

            ' Use parametrized query to prevent SQL injection
            Set cmd = Server.CreateObject("ADODB.Command")
            Set cmd.ActiveConnection = conn
            cmd.CommandText = "SELECT ID_USER, USERNAME, PASSWORD, USER_TYPE " & _
                              "FROM TBL_USER " & _
                              "WHERE USERNAME = ?"
            cmd.CommandType = 1 ' adCmdText

            ' Add parameters (adVarWChar = 202, size = 50)
            Call AddParameter(cmd, "@username", adVarWChar, adParamInput, 50, submittedUsername)

            ' Execute query
            On Error Resume Next
            Set rs = cmd.Execute

            If Err.Number <> 0 Then
                errorMsg = "Error al verificar credenciales. Intente mas tarde."
                Call LogError("login.asp:QueryUser", Err.Number, Err.Description, "")
                On Error GoTo 0
            Else
                On Error GoTo 0

                If Not rs.EOF Then
                    Dim dbPassword, dbUserId, dbUsername, dbUserType

                    dbUserId   = rs("ID_USER").Value
                    dbUsername = rs("USERNAME").Value
                    dbPassword = rs("PASSWORD").Value
                    dbUserType = rs("USER_TYPE").Value

                    ' Compare password (supports both plain text and SHA-1 hashed)
                    If VerifyPassword(submittedPassword, dbPassword) Then
                        ' Reset session state for the newly authenticated user
                        ' (clears pre-login contents and issues a new CSRF token,
                        ' mitigating session fixation).
                        Call ResetSessionForLogin()

                        ' Store session data (do NOT store password)
                        Session("ID_USER")   = dbUserId
                        Session("USERNAME")  = dbUsername
                        Session("USER_TYPE") = dbUserType
                        Session("CSRF_TOKEN") = EnsureCSRFToken()

                        ' Close objects
                        If rs.State = 1 Then rs.Close
                        Set rs = Nothing
                        Set cmd = Nothing
                        Call CloseDatabase(conn)

                        ' Redirect to return URL or songs page
                        Redirect returnUrl
                    Else
                        errorMsg = "Usuario o contrasena incorrectos."
                    End If
                Else
                    ' Use the same message whether username doesn't exist
                    ' or password is wrong (do not reveal account existence)
                    errorMsg = "Usuario o contrasena incorrectos."
                End If
            End If

            ' Cleanup
            On Error Resume Next
            If Not (rs Is Nothing) Then
                If rs.State = 1 Then rs.Close
                Set rs = Nothing
            End If
            Set cmd = Nothing
            Call CloseDatabase(conn)
            On Error GoTo 0
        End If
    End If

    ' Preserve username for convenience
    username = submittedUsername
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="color-scheme" content="dark">
    <meta name="theme-color" content="#0d0d12">
    <title>PoliMusic - Iniciar Sesion</title>
    <link rel="stylesheet" href="<%= GetAppPath() %>/assets/css/styles.css">
</head>
<body class="login-page">
    <a href="#main-content" class="skip-link">Saltar al contenido principal</a>

    <main id="main-content" class="login-container" role="main">
        <div class="login-card">
            <h1 class="login-title">PoliMusic</h1>
            <p class="login-subtitle">Inicia sesion para continuar</p>

            <% If errorMsg <> "" Then %>
                <div class="alert alert-error" role="alert" aria-live="assertive">
                    <span class="alert-icon" aria-hidden="true">!</span>
                    <%= Encode(errorMsg) %>
                </div>
            <% End If %>

            <form method="post" action="login.asp<% If returnUrl <> "" Then Response.Write "?returnUrl=" & EncodeURL(returnUrl) %>" class="login-form" novalidate>
                <div class="form-group">
                    <label for="username" class="form-label">
                        Usuario <span class="required" aria-label="campo obligatorio">*</span>
                    </label>
                    <input
                        type="text"
                        id="username"
                        name="username"
                        value="<%= EncodeAttr(username) %>"
                        maxlength="50"
                        required
                        autocomplete="username"
                        class="form-input"
                        aria-required="true"
                        <% If errorMsg <> "" Then Response.Write "aria-invalid=""true"" aria-describedby=""form-error""" %>
                    >
                </div>

                <div class="form-group">
                    <label for="password" class="form-label">
                        Contrasena <span class="required" aria-label="campo obligatorio">*</span>
                    </label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        maxlength="100"
                        required
                        autocomplete="current-password"
                        class="form-input"
                        aria-required="true"
                        <% If errorMsg <> "" Then Response.Write "aria-invalid=""true"" aria-describedby=""form-error""" %>
                    >
                </div>

                <% If errorMsg <> "" Then %>
                    <p id="form-error" class="sr-only"><%= Encode(errorMsg) %></p>
                <% End If %>

                <button type="submit" class="btn btn-primary btn-full">
                    Iniciar Sesion
                </button>
            </form>

            <p class="login-footer">
                PoliMusic &copy; Aplicaciones Web Avanzadas
            </p>
        </div>
    </main>

    <script src="<%= GetAppPath() %>/assets/js/main.js"></script>
</body>
</html>
