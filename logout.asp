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

' Clear all session contents
Session.Contents.RemoveAll()

' Abandon the session (IIS will destroy it)
Session.Abandon()

' Expire the ASP session cookie on the client side
' (ASPSESSIONID cookies vary by name, but we attempt to clear common ones)
Response.AddHeader "Set-Cookie", "ASPSESSIONID=; Path=/; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
Response.AddHeader "Set-Cookie", "ASPSESSIONIDCQTTQSDB=; Path=/; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT"

' Redirect to login
Redirect GetAppPath() & "/login.asp?logout=1"
%>
