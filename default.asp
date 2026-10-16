<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' default.asp
' PoliMusic - Default page (redirects to login or songs)
'===============================================================
%>
<!-- #INCLUDE FILE="includes/functions.asp" -->
<%
If IsAuthenticated() Then
    Redirect GetAppPath() & "/songs.asp"
Else
    Redirect GetAppPath() & "/login.asp"
End If
%>
