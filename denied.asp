<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' denied.asp
' PoliMusic - Access Denied Page
'===============================================================
' Shown when an authenticated user tries to access admin
' functionality without the admin role.
'
' The page uses the shared header/footer includes, which already
' render the document skeleton (doctype, head, body, sidebar and
' scripts). Do not add a second doctype/head/body here.
'===============================================================
%>
<!-- #INCLUDE FILE="includes/auth.asp" -->
<%
Dim pageTitle
pageTitle = "Acceso Denegado"
%>
<!-- #INCLUDE FILE="includes/header.asp" -->

            <main id="main-content" class="content-area" role="main">
                <div class="content-inner">
                    <div class="denied-container">
                        <h2 class="denied-title">Acceso Denegado</h2>
                        <p>No tiene permisos para acceder a esta pagina.</p>
                        <p>Su rol actual no permite realizar operaciones administrativas.</p>

                        <div class="form-actions denied-actions">
                            <a href="<%= GetAppPath() %>/songs.asp" class="btn btn-primary">
                                Volver a canciones
                            </a>
                            <a href="<%= GetAppPath() %>/logout.asp" class="btn btn-secondary">
                                Cerrar Sesion
                            </a>
                        </div>
                    </div>
                </div>
            </main>

<!-- #INCLUDE FILE="includes/footer.asp" -->
