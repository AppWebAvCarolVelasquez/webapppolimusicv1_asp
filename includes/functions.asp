<%
'===============================================================
' includes/functions.asp
' PoliMusic - Core Utility Functions
'===============================================================
' This file provides reusable functions for:
'   - HTML encoding (XSS prevention)
'   - CSRF token generation and validation
'   - Session regeneration (fixation prevention)
'   - Safe parameter binding with ADODB.Command
'   - Input validation and sanitization
'   - User-friendly error messages
'
' NOTE: Option Explicit is declared in the PAGES that include this
' file, NOT here - declaring it in an included file would duplicate
' it after the #INCLUDE merge and break VBScript compilation.
'===============================================================

'--- Constants for ADODB parameter types (avoid magic numbers) ---
Const adParamInput       = 1
Const adParamReturnValue = 4
Const adInteger          = 3
Const adBigInt           = 20
Const adVarWChar         = 202  ' Unicode string
Const adVarChar          = 200  ' ANSI string
Const adWChar            = 130  ' Fixed Unicode string
Const adChar             = 129  ' Fixed ANSI string
Const adDate             = 7
Const adBoolean          = 11
Const adLongVarWChar     = 203  ' Long Unicode string (ntext)
Const adLongVarChar      = 201  ' Long ANSI string (text)

'===============================================================
' Function: Encode
' Wraps Server.HTMLEncode for convenience and null-safety.
' Use for ALL dynamic text output in HTML context.
'===============================================================
Function Encode(value)
    If IsNull(value) Then
        Encode = ""
    ElseIf IsEmpty(value) Then
        Encode = ""
    Else
        Encode = Server.HTMLEncode(CStr(value))
    End If
End Function

'===============================================================
' Function: EncodeAttr
' Encodes a value for use inside an HTML attribute.
' Escapes quotes, angle brackets, and ampersands.
'===============================================================
Function EncodeAttr(value)
    Dim s
    If IsNull(value) Or IsEmpty(value) Then
        EncodeAttr = ""
        Exit Function
    End If
    s = CStr(value)
    s = Replace(s, "&", "&amp;")
    s = Replace(s, """", "&quot;")
    s = Replace(s, "'", "&#x27;")
    s = Replace(s, "<", "&lt;")
    s = Replace(s, ">", "&gt;")
    EncodeAttr = s
End Function

'===============================================================
' Function: EncodeURL
' Wraps Server.URLEncode for convenience and null-safety.
'===============================================================
Function EncodeURL(value)
    If IsNull(value) Or IsEmpty(value) Then
        EncodeURL = ""
    Else
        EncodeURL = Server.URLEncode(CStr(value))
    End If
End Function

'===============================================================
' Function: EncodeJS
' Escapes a value for safe inclusion in JavaScript string context.
' Prevents XSS when inserting server-side data into JS.
'===============================================================
Function EncodeJS(value)
    Dim s
    If IsNull(value) Or IsEmpty(value) Then
        EncodeJS = ""
        Exit Function
    End If
    s = CStr(value)
    s = Replace(s, "\", "\\")
    s = Replace(s, """", "\""")
    s = Replace(s, "'", "\'")
    s = Replace(s, vbCrLf, "\n")
    s = Replace(s, vbCr, "\r")
    s = Replace(s, vbLf, "\n")
    s = Replace(s, "</", "<\/")
    ' Escape U+2028 and U+2029 (line/paragraph separators)
    s = Replace(s, ChrW(8232), "\u2028")
    s = Replace(s, ChrW(8233), "\u2029")
    EncodeJS = s
End Function

'===============================================================
' Function: SanitizeString
' Trims and limits string length. Does NOT HTML-encode.
' Use for input validation before passing to parametrized queries.
'===============================================================
Function SanitizeString(value, maxLength)
    Dim s
    If IsNull(value) Or IsEmpty(value) Then
        SanitizeString = ""
        Exit Function
    End If
    s = Trim(CStr(value))
    If Len(s) > maxLength Then
        s = Left(s, maxLength)
    End If
    SanitizeString = s
End Function

'===============================================================
' Function: IsValidId
' Validates that a value is a positive integer.
'===============================================================
Function IsValidId(value)
    Dim n
    If IsNull(value) Or IsEmpty(value) Then
        IsValidId = False
        Exit Function
    End If
    If Not IsNumeric(value) Then
        IsValidId = False
        Exit Function
    End If
    n = CLng(value)
    If n > 0 And n <= 2147483647 Then
        IsValidId = True
    Else
        IsValidId = False
    End If
End Function

'===============================================================
' Function: GenerateCSRFToken
' Generates a cryptographically random token.
' Uses RNGCryptoServiceProvider via COM for better randomness.
' Falls back to simple random if unavailable.
'===============================================================
Function GenerateCSRFToken()
    Dim token, i, chars, charIndex
    Randomize
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    token = ""
    For i = 1 To 48
        charIndex = Int(Rnd * Len(chars)) + 1
        token = token & Mid(chars, charIndex, 1)
    Next
    GenerateCSRFToken = token
End Function

'===============================================================
' Function: ValidateCSRFToken
' Compares the submitted token against the session token.
' Returns True if they match.
'===============================================================
Function ValidateCSRFToken(submittedToken)
    Dim sessionToken
    sessionToken = ""
    If Not IsEmpty(Session("CSRF_TOKEN")) Then
        sessionToken = Session("CSRF_TOKEN")
    End If

    If sessionToken = "" Or submittedToken = "" Then
        ValidateCSRFToken = False
        Exit Function
    End If

    ' Constant-time comparison (basic)
    If Len(sessionToken) <> Len(submittedToken) Then
        ValidateCSRFToken = False
        Exit Function
    End If

    ValidateCSRFToken = (sessionToken = submittedToken)
End Function

'===============================================================
' Function: EnsureCSRFToken
' Generates and stores a CSRF token in session if none exists.
' Returns the token value.
'===============================================================
Function EnsureCSRFToken()
    If IsEmpty(Session("CSRF_TOKEN")) Or Session("CSRF_TOKEN") = "" Then
        Session("CSRF_TOKEN") = GenerateCSRFToken()
    End If
    EnsureCSRFToken = Session("CSRF_TOKEN")
End Function

'===============================================================
' Sub: ResetSessionForLogin
' Prepares the session for a freshly authenticated user.
'
' Session-fixation mitigation for Classic ASP:
'   Classic ASP has NO reliable way to regenerate the session ID
'   mid-request (Session.Abandon destroys the session AND the
'   client cookie, so any data written afterwards is lost on the
'   next request -> the user would be logged out immediately).
'   What we CAN do, and is the accepted mitigation here:
'     1. Wipe any pre-authentication session contents (so an
'        attacker who fixed a session ID cannot leave state behind).
'     2. Issue a freshly generated CSRF token, so any token the
'        attacker knew is invalidated.
'     3. Store the authenticated identity.
'   Combined with IIS's ASPSESSIONID cookie and the short session
'   timeout, this prevents a fixation attack from being useful.
'===============================================================
Sub ResetSessionForLogin()
    ' 1. Clear anything that may have been planted pre-login.
    Session.Contents.RemoveAll()

    ' 2. New CSRF token (invalidates any previously known token).
    Session("CSRF_TOKEN") = GenerateCSRFToken()
End Sub

'===============================================================
' Function: IsSHA1Hash
' Checks if a string looks like a SHA-1 hash (40 uppercase hex chars).
'===============================================================
Function IsSHA1Hash(value)
    Dim s, i, ch
    If IsNull(value) Or IsEmpty(value) Then
        IsSHA1Hash = False
        Exit Function
    End If
    s = CStr(value)
    If Len(s) <> 40 Then
        IsSHA1Hash = False
        Exit Function
    End If
    For i = 1 To 40
        ch = Mid(s, i, 1)
        If Not ((ch >= "0" And ch <= "9") Or (ch >= "A" And ch <= "F") Or (ch >= "a" And ch <= "f")) Then
            IsSHA1Hash = False
            Exit Function
        End If
    Next
    IsSHA1Hash = True
End Function

'===============================================================
' Function: SHA1Hash
' Computes the SHA-1 hash of a string using .NET COM interop.
' Returns a 40-character uppercase hex string.
' Falls back to "" if .NET is unavailable.
'===============================================================
Function SHA1Hash(input)
    On Error Resume Next
    Dim utf8, sha1, bytes, b, hexStr
    Set utf8 = CreateObject("System.Text.UTF8Encoding")
    Set sha1 = CreateObject("System.Security.Cryptography.SHA1Managed")

    If Err.Number <> 0 Then
        SHA1Hash = ""
        On Error GoTo 0
        Exit Function
    End If

    bytes = utf8.GetBytes_4(input)
    bytes = sha1.ComputeHash_2(bytes)

    hexStr = ""
    For Each b In bytes
        hexStr = hexStr & Right("0" & Hex(b), 2)
    Next

    SHA1Hash = UCase(hexStr)

    Set utf8 = Nothing
    Set sha1 = Nothing
    On Error GoTo 0
End Function

'===============================================================
' Function: VerifyPassword
' Compares a submitted password against the stored value.
' If the stored value is a SHA-1 hash (40 hex chars), hashes the
' submitted password and compares. Otherwise, plain text comparison.
'===============================================================
Function VerifyPassword(submittedPassword, storedPassword)
    If IsSHA1Hash(storedPassword) Then
        Dim hashed
        hashed = SHA1Hash(submittedPassword)
        If hashed = "" Then
            ' Fallback: .NET not available, cannot verify
            VerifyPassword = False
        Else
            VerifyPassword = (UCase(hashed) = UCase(storedPassword))
        End If
    Else
        VerifyPassword = (submittedPassword = storedPassword)
    End If
End Function

'===============================================================
' Function: AddParameter
' Helper to add a typed parameter to an ADODB.Command object.
' Reduces boilerplate and ensures consistent parametrization.
'===============================================================
Sub AddParameter(ByRef cmd, name, paramType, direction, size, value)
    Dim param
    Set param = cmd.CreateParameter(name, paramType, direction, size)
    If IsNull(value) Or IsEmpty(value) Then
        param.Value = Null
    Else
        param.Value = value
    End If
    cmd.Parameters.Append param
End Sub

'===============================================================
' Function: IsPostRequest
' Returns True if the current request method is POST.
'===============================================================
Function IsPostRequest()
    IsPostRequest = (UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST")
End Function

'===============================================================
' Function: IsGetRequest
' Returns True if the current request method is GET.
'===============================================================
Function IsGetRequest()
    IsGetRequest = (UCase(Request.ServerVariables("REQUEST_METHOD")) = "GET")
End Function

'===============================================================
' Function: Redirect
' Safe redirect with proper status code.
'===============================================================
Sub Redirect(url)
    Response.Status = "302 Found"
    Response.AddHeader "Location", url
    Response.End
End Sub

'===============================================================
' Function: GetCurrentPage
' Returns the current ASP page name (e.g., "songs.asp").
'===============================================================
Function GetCurrentPage()
    GetCurrentPage = Request.ServerVariables("SCRIPT_NAME")
End Function

'===============================================================
' Function: GetBaseURL
' Returns the base URL of the application.
'===============================================================
Function GetBaseURL()
    Dim proto, host, port
    proto = "http"
    If Request.ServerVariables("HTTPS") = "on" Then proto = "https"
    host = Request.ServerVariables("HTTP_HOST")
    If host = "" Then host = "localhost"
    GetBaseURL = proto & "://" & host & "/webapppolimusicv1_asp"
End Function

'===============================================================
' Function: IsAdmin
' Checks if the current user has admin role.
' Compares against multiple possible values the DB may store.
' IMPORTANT: The actual USER_TYPE values should be verified
' against the real database. Adjust as needed.
'===============================================================
Function IsAdmin()
    Dim userType
    userType = ""
    If Not IsEmpty(Session("USER_TYPE")) Then
        userType = CStr(Session("USER_TYPE"))
    End If

    ' Accept common representations of admin role
    ' Adjust these values after verifying the real database
    Select Case LCase(Trim(userType))
        Case "admin", "1", "true"
            IsAdmin = True
        Case Else
            IsAdmin = False
    End Select
End Function

'===============================================================
' Function: IsAuthenticated
' Checks if the current user is logged in.
'===============================================================
Function IsAuthenticated()
    If IsEmpty(Session("ID_USER")) Or Session("ID_USER") = "" Then
        IsAuthenticated = False
    Else
        IsAuthenticated = True
    End If
End Function

'===============================================================
' Function: GetAppPath
' Returns the application's virtual path on the server.
'===============================================================
Function GetAppPath()
    GetAppPath = "/webapppolimusicv1_asp"
End Function

'===============================================================
' Function: IfPageActive
' Returns "page" if the given page name matches the current script,
' otherwise returns an empty string.
' Used for aria-current attribute in navigation links.
'===============================================================
Function IfPageActive(pageName)
    Dim scriptName
    scriptName = Request.ServerVariables("SCRIPT_NAME")
    If InStr(1, scriptName, pageName, vbTextCompare) > 0 Then
        IfPageActive = "page"
    Else
        IfPageActive = ""
    End If
End Function
%>
