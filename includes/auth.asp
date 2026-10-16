<%
'===============================================================
' includes/auth.asp
' PoliMusic - Authentication Helper (included in every protected page)
'===============================================================
' This file must be included at the TOP of every page that requires
' authentication. It checks the session and redirects to login if
' the user is not authenticated.
'
' For admin pages, include this AND call RequireAdmin() in the page.
'===============================================================

' Ensure Option Explicit is set (if not already set by the page)
%>
<!-- #INCLUDE FILE="functions.asp" -->
<!-- #INCLUDE FILE="security.asp" -->
<%

' Set security headers on every page
Call SetSecurityHeaders()

' Session timeout: 20 minutes of inactivity
Session.Timeout = 20

' Enforce authentication on protected pages
Call RequireAuth()
%>
