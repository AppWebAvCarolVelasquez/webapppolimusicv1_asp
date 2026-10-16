<%
'===============================================================
' includes/header.asp
' PoliMusic - Shared Page Header (Sidebar Navigation)
'===============================================================
' This file is included after auth.asp on protected pages.
' It renders the sidebar, skip link, and top bar.
'
' Required variables from the page:
'   pageTitle - the <title> text
'===============================================================
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="PoliMusic - Plataforma de musica universitaria">
    <title><%= Encode(pageTitle) %> - PoliMusic</title>
    <link rel="stylesheet" href="<%= GetAppPath() %>/assets/css/styles.css">
</head>
<body>
    <a href="#main-content" class="skip-link">Saltar al contenido principal</a>

    <div class="app-layout">
        <!-- Sidebar Navigation -->
        <aside class="sidebar" id="sidebar" aria-label="Navegacion principal">
            <div class="sidebar-header">
                <a href="<%= GetAppPath() %>/songs.asp" class="logo-link">
                    <span class="logo-text">PoliMusic</span>
                </a>
            </div>

            <nav class="sidebar-nav" aria-label="Menu de navegacion">
                <ul class="nav-list">
                    <li class="nav-item">
                        <a href="<%= GetAppPath() %>/songs.asp" class="nav-link" aria-current="<%= IfPageActive("songs.asp") %>">
                            <span class="nav-icon" aria-hidden="true">&#9835;</span>
                            <span>Canciones</span>
                        </a>
                    </li>
                    <% If IsAdmin() Then %>
                        <li class="nav-item">
                            <a href="<%= GetAppPath() %>/admin/songs.asp" class="nav-link" aria-current="<%= IfPageActive("admin/songs.asp") %>">
                                <span class="nav-icon" aria-hidden="true">&#9881;</span>
                                <span>Administrar</span>
                            </a>
                        </li>
                    <% End If %>
                </ul>
            </nav>

            <div class="sidebar-footer">
                <div class="user-info">
                    <span class="user-label" id="user-display" <%= "aria-label='Usuario: " & Encode(Session("USERNAME")) & "'" %>>
                        <span class="user-icon" aria-hidden="true">&#9679;</span>
                        <%= Encode(Session("USERNAME")) %>
                    </span>
                    <% If IsAdmin() Then %>
                        <span class="user-role badge badge-admin">Admin</span>
                    <% Else %>
                        <span class="user-role badge badge-user">Usuario</span>
                    <% End If %>
                </div>
                <a href="<%= GetAppPath() %>/logout.asp" class="btn btn-logout btn-full">
                    Cerrar Sesion
                </a>
            </div>
        </aside>

        <!-- Mobile menu toggle -->
        <button class="menu-toggle" id="menuToggle" aria-expanded="false" aria-controls="sidebar" aria-label="Abrir menu de navegacion">
            <span class="menu-toggle-icon" aria-hidden="true">&#9776;</span>
        </button>

        <!-- Main Content Area -->
        <div class="main-area">
            <header class="top-bar" role="banner">
                <h1 class="page-heading"><%= Encode(pageTitle) %></h1>
            </header>
