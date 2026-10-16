<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' logout.asp
' PoliMusic - Logout / Session Destruction
'===============================================================
' Invalidates the session completely:
'   1. Clears all session variables
'   2. Calls Session.Abandon
'   3. Expires the session cookie
'   4. Redirects to login page
'===============================================================
%>
<!-- #INCLUDE FILE="includes/functions.asp" -->
<!-- #INCLUDE FILE="includes/security.asp" -->
<%
' Set security headers
Call SetSecurityHeaders()

' Expire the actual ASP session cookie on the client.
' The cookie name is dynamic (ASPSESSIONID + a per-app suffix), so we
' read it from the incoming Cookie header instead of hardcoding names.
Dim rawCookie, cookieParts, ci, cookieName, nameValue
rawCookie = Request.ServerVariables("HTTP_COOKIE")
If rawCookie <> "" Then
    cookieParts = Split(rawCookie, ";")
    For ci = 0 To UBound(cookieParts)
        nameValue = Split(Trim(cookieParts(ci)), "=")
        If UBound(nameValue) >= 0 Then
            cookieName = Trim(nameValue(0))
            If InStr(1, cookieName, "ASPSESSIONID", vbTextCompare) = 1 Then
                Response.AddHeader "Set-Cookie", cookieName & "=; Path=/; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
            End If
        End If
    Next
End If

' Clear all session contents and destroy the session
Session.Contents.RemoveAll()
Session.Abandon()

' Redirect to login
Redirect GetAppPath() & "/login.asp?logout=1"
%>
