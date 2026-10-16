<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' denied.asp
' PoliMusic - Access Denied Page
'===============================================================
' Shown when an authenticated user tries to access admin
' functionality without the admin role.
'===============================================================
%>
<!-- #INCLUDE FILE="includes/auth.asp" -->
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PoliMusic - Acceso Denegado</title>
    <link rel="stylesheet" href="<%= GetAppPath() %>/assets/css/styles.css">
</head>
<body>
    <a href="#main-content" class="skip-link">Saltar al contenido principal</a>

    <!-- #INCLUDE FILE="includes/header.asp" -->

    <main id="main-content" class="content-area" role="main">
        <div class="denied-container">
            <h1>Acceso Denegado</h1>
            <p>No tiene permisos para acceder a esta pagina.</p>
            <p>Su rol actual no permite realizar operaciones administrativas.</p>

            <div class="form-actions">
                <a href="<%= GetAppPath() %>/songs.asp" class="btn btn-primary">
                    Volver a canciones
                </a>
                <a href="<%= GetAppPath() %>/logout.asp" class="btn btn-secondary">
                    Cerrar Sesion
                </a>
            </div>
        </div>
    </main>

    <!-- #INCLUDE FILE="includes/footer.asp" -->

    <script src="<%= GetAppPath() %>/assets/js/main.js"></script>
</body>
</html>
