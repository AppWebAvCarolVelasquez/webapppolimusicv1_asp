<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' admin/songs.asp
' PoliMusic - Admin: Song Management Dashboard
'===============================================================
' Displays the administrative song list with CRUD options.
' Protected by server-side authentication AND admin role check.
'===============================================================
%>
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/config/database.asp" -->
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/functions.asp" -->
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/security.asp" -->
<%
' Enforce authentication + admin role on the SERVER
Call RequireAdmin()

Dim pageTitle
pageTitle = "Administrar Canciones"

Dim conn, cmd, rs
Dim dbError, hasResults
Dim songs(), songCount, i
Dim csrfToken

dbError = ""
hasResults = False
songCount = 0
ReDim songs(6, 0) ' ID_SONG, SONG_NAME, SONG_PATH, PLAYS, ARTISTS, ALBUM_COUNT, PLAYLIST_COUNT

' Open database
On Error Resume Next
Set conn = OpenDatabase()
If Err.Number <> 0 Then
    dbError = "No se pudo conectar a la base de datos."
    Call LogError("admin/songs.asp:OpenDatabase", Err.Number, Err.Description, "")
    On Error GoTo 0
Else
    On Error GoTo 0

    ' Get songs with artist names (concatenated) and dependency counts
    Dim sql
    sql = "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, s.PLAYS, " & _
          "ISNULL(" & _
          "  (SELECT STUFF((SELECT ', ' + a.ARTIST_NAME + ' ' + a.ARTIST_LASTNAME " & _
          "    FROM TBL_PLAYER p " & _
          "    INNER JOIN TBL_ARTIST a ON p.ID_ARTIST = a.ID_ARTIST " & _
          "    WHERE p.ID_SONG = s.ID_SONG " & _
          "    FOR XML PATH('')), 1, 2, '')), 'Sin artista') AS ARTISTS, " & _
          "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_SONG = s.ID_SONG) AS ALBUM_COUNT, " & _
          "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_SONG = s.ID_SONG) AS PLAYLIST_COUNT " & _
          "FROM TBL_SONG s " & _
          "ORDER BY s.SONG_NAME ASC"

    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = sql
    cmd.CommandType = 1 ' adCmdText

    On Error Resume Next
    Set rs = cmd.Execute

    If Err.Number <> 0 Then
        dbError = "Error al consultar las canciones."
        Call LogError("admin/songs.asp:QuerySongs", Err.Number, Err.Description, "")
        On Error GoTo 0
    Else
        On Error GoTo 0
        If Not rs.EOF Then
            hasResults = True
            Do While Not rs.EOF
                ReDim Preserve songs(6, songCount)
                songs(0, songCount) = rs("ID_SONG").Value
                songs(1, songCount) = rs("SONG_NAME").Value
                If Not IsNull(rs("SONG_PATH").Value) Then
                    songs(2, songCount) = rs("SONG_PATH").Value
                Else
                    songs(2, songCount) = ""
                End If
                If Not IsNull(rs("PLAYS").Value) Then
                    songs(3, songCount) = rs("PLAYS").Value
                Else
                    songs(3, songCount) = 0
                End If
                songs(4, songCount) = rs("ARTISTS").Value
                songs(5, songCount) = rs("ALBUM_COUNT").Value
                songs(6, songCount) = rs("PLAYLIST_COUNT").Value
                songCount = songCount + 1
                rs.MoveNext
            Loop
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

csrfToken = EnsureCSRFToken()
%>
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/header.asp" -->

            <main id="main-content" class="content-area" role="main">
                <div class="content-inner">
                    <div class="admin-header">
                        <h2 class="section-heading">Gestion de Canciones</h2>
                        <a href="<%= GetAppPath() %>/admin/song_create.asp" class="btn btn-create">
                            <span aria-hidden="true">+</span>
                            Nueva Cancion
                        </a>
                    </div>

                    <% If dbError <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <span class="alert-icon" aria-hidden="true">!</span>
                            <%= Encode(dbError) %>
                        </div>
                    <% End If %>

                    <% If Request.QueryString("msg") = "created" Then %>
                        <div class="alert alert-success" role="status" aria-live="polite">
                            La cancion se creo correctamente.
                        </div>
                    <% ElseIf Request.QueryString("msg") = "updated" Then %>
                        <div class="alert alert-success" role="status" aria-live="polite">
                            La cancion se actualizo correctamente.
                        </div>
                    <% ElseIf Request.QueryString("msg") = "deleted" Then %>
                        <div class="alert alert-success" role="status" aria-live="polite">
                            La cancion se elimino correctamente.
                        </div>
                    <% End If %>

                    <% If hasResults Then %>
                        <div class="table-container" role="region" aria-label="Tabla de canciones administrativas" tabindex="0">
                            <table class="songs-table admin-table">
                                <caption class="sr-only">Lista administrativa de canciones</caption>
                                <thead>
                                    <tr>
                                        <th scope="col">ID</th>
                                        <th scope="col">Cancion</th>
                                        <th scope="col">Artista(s)</th>
                                        <th scope="col">Ruta</th>
                                        <th scope="col">Reproduc.</th>
                                        <th scope="col">Albumes</th>
                                        <th scope="col">Playlists</th>
                                        <th scope="col">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% For i = 0 To songCount - 1 %>
                                        <tr>
                                            <td><%= Encode(songs(0, i)) %></td>
                                            <td><%= Encode(songs(1, i)) %></td>
                                            <td><%= Encode(songs(4, i)) %></td>
                                            <td class="path-cell" title="<%= EncodeAttr(songs(2, i)) %>"><%= Encode(Left(songs(2, i), 30)) %><% If Len(songs(2, i)) > 30 Then Response.Write "..." %></td>
                                            <td><%= Encode(songs(3, i)) %></td>
                                            <td><%= Encode(songs(5, i)) %></td>
                                            <td><%= Encode(songs(6, i)) %></td>
                                            <td class="admin-row-actions">
                                                <a href="<%= GetAppPath() %>/admin/song_edit.asp?id=<%= EncodeURL(songs(0, i)) %>" class="btn btn-sm btn-edit" aria-label="Editar cancion: <%= Encode(songs(1, i)) %>">
                                                    Editar
                                                </a>
                                                <a href="<%= GetAppPath() %>/admin/song_delete.asp?id=<%= EncodeURL(songs(0, i)) %>" class="btn btn-sm btn-delete" aria-label="Eliminar cancion: <%= Encode(songs(1, i)) %>">
                                                    Eliminar
                                                </a>
                                            </td>
                                        </tr>
                                    <% Next %>
                                </tbody>
                            </table>
                        </div>
                    <% Else %>
                        <% If dbError = "" Then %>
                            <div class="alert alert-info" role="status" aria-live="polite">
                                No hay canciones registradas. Haga clic en "Nueva Cancion" para crear la primera.
                            </div>
                        <% End If %>
                    <% End If %>

                    <div class="admin-nav-links">
                        <a href="<%= GetAppPath() %>/songs.asp" class="btn btn-secondary">
                            Volver a Song List
                        </a>
                    </div>
                </div>
            </main>

<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/footer.asp" -->
