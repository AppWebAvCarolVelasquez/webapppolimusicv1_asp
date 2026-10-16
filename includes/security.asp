<%
'===============================================================
' includes/security.asp
' PoliMusic - HTTP Security Headers & Common Security Checks
'===============================================================
' This file sets HTTP security headers and provides common
' security validation functions used across all pages.
'===============================================================

'===============================================================
' Sub: SetSecurityHeaders
' Configures HTTP security headers appropriate for the application.
' These headers help mitigate XSS, clickjacking, MIME sniffing,
' and other common web attacks.
'===============================================================
Sub SetSecurityHeaders()
    ' --- Content-Security-Policy ---
    ' Restricts scripts and styles to same-origin.
    ' No unsafe-inline or unsafe-eval.
    ' Allows audio and images from same-origin.
    Response.AddHeader "Content-Security-Policy", _
        "default-src 'self'; " & _
        "script-src 'self'; " & _
        "style-src 'self'; " & _
        "img-src 'self' data:; " & _
        "media-src 'self'; " & _
        "font-src 'self'; " & _
        "connect-src 'self'; " & _
        "frame-ancestors 'none'; " & _
        "base-uri 'self'; " & _
        "form-action 'self'"

    ' --- X-Content-Type-Options ---
    ' Prevents MIME type sniffing
    Response.AddHeader "X-Content-Type-Options", "nosniff"

    ' --- X-Frame-Options ---
    ' Clickjacking prevention (CSP frame-ancestors is the modern approach,
    ' but X-Frame-Options adds defense-in-depth for older browsers)
    Response.AddHeader "X-Frame-Options", "DENY"

    ' --- Referrer-Policy ---
    ' Controls how much referrer information is sent
    Response.AddHeader "Referrer-Policy", "strict-origin-when-cross-origin"

    ' --- X-XSS-Protection ---
    ' Legacy browser XSS protection (modern browsers rely on CSP)
    Response.AddHeader "X-XSS-Protection", "1; mode=block"

    ' --- HSTS (only meaningful over HTTPS) ---
    ' Only set if the request came over HTTPS
    If Request.ServerVariables("HTTPS") = "on" Then
        Response.AddHeader "Strict-Transport-Security", "max-age=31536000; includeSubDomains"
    End If

    ' --- Session cookie attributes ---
    ' Classic ASP sets ASPSESSIONID cookies automatically.
    ' We cannot directly control their attributes, but we can
    ' supplement with our own auth cookie if needed.
    ' Note: ASPSESSIONID HttpOnly is controlled by IIS settings.
    ' For local HTTP development, Secure cannot be enforced.
End Sub

'===============================================================
' Sub: RequireAuth
' Redirects unauthenticated users to the login page.
' Call at the top of every protected page.
'===============================================================
Sub RequireAuth()
    If Not IsAuthenticated() Then
        Dim returnUrl
        returnUrl = EncodeURL(Request.ServerVariables("SCRIPT_NAME") & _
                   "?" & Request.QueryString)
        Redirect GetAppPath() & "/login.asp?returnUrl=" & returnUrl
    End If
End Sub

'===============================================================
' Sub: RequireAdmin
' Redirects authenticated-but-non-admin users to a denied page.
' Call at the top of every admin page (after RequireAuth).
'===============================================================
Sub RequireAdmin()
    RequireAuth()
    If Not IsAdmin() Then
        Redirect GetAppPath() & "/denied.asp"
    End If
End Sub

'===============================================================
' Sub: RequirePost
' Rejects GET requests on pages that only accept POST.
' Prevents CSRF via image tags / GET-based actions.
'===============================================================
Sub RequirePost()
    If Not IsPostRequest() Then
        Response.Status = "405 Method Not Allowed"
        Response.Write "Method not allowed."
        Response.End
    End If
End Sub

'===============================================================
' Sub: RequireCSRF
' Validates the CSRF token from the POST form.
' Combine with RequirePost for write operations.
'===============================================================
Sub RequireCSRF()
    Dim token
    token = Request.Form("csrf_token")
    If Not ValidateCSRFToken(token) Then
        Response.Status = "403 Forbidden"
        Response.Write "Token de seguridad invalido. Por favor, recargue la pagina e intente de nuevo."
        Response.End
    End If
End Sub
%>
