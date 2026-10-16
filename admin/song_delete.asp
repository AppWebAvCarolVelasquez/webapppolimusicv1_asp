<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' admin/song_delete.asp
' PoliMusic - Admin: Delete Song
'===============================================================
' Deletes a song from TBL_SONG after:
'   - Checking all foreign key dependencies (TBL_PLAYER, TBL_TRACKLIST,
'     TBL_PLAYLIST_SONG)
'   - Requiring confirmation (POST + CSRF)
'   - Deleting child records first (to maintain referential integrity)
'
' GET: Shows the confirmation form.
' POST: Validates CSRF and deletes the song + dependencies.
'===============================================================
%>
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/config/database.asp" -->
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/functions.asp" -->
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/security.asp" -->
<%
Call RequireAdmin()

Dim pageTitle
pageTitle = "Eliminar Cancion"

Dim conn, cmd, rs
Dim dbError, validationErrors
Dim songId, songName, songPath, songPlays, artistsStr
Dim playerCount, tracklistCount, playlistCount
Dim csrfToken
Dim confirmDelete

dbError = ""
validationErrors = ""
songId = SanitizeString(Request.QueryString("id"), 20)

' Validate ID
If Not IsValidId(songId) Then
    Redirect GetAppPath() & "/admin/songs.asp"
End If
songId = CLng(songId)

' Open database
On Error Resume Next
Set conn = OpenDatabase()
If Err.Number <> 0 Then
    dbError = "No se pudo conectar a la base de datos."
    Call LogError("admin/song_delete.asp:OpenDatabase", Err.Number, Err.Description, "")
    On Error GoTo 0
Else
    On Error GoTo 0

    ' Load song data for display
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = "SELECT ID_SONG, SONG_NAME, SONG_PATH, PLAYS FROM TBL_SONG WHERE ID_SONG = ?"
    cmd.CommandType = 1
    Call AddParameter(cmd, "@id", adInteger, adParamInput, 4, songId)

    On Error Resume Next
    Set rs = cmd.Execute

    If Err.Number <> 0 Then
        dbError = "Error al consultar la cancion."
        Call LogError("admin/song_delete.asp:QuerySong", Err.Number, Err.Description, "")
        On Error GoTo 0
    ElseIf rs.EOF Then
        Redirect GetAppPath() & "/admin/songs.asp"
    Else
        On Error GoTo 0
        songName  = rs("SONG_NAME").Value
        songPath  = rs("SONG_PATH").Value
        songPlays = rs("PLAYS").Value
    End If

    On Error Resume Next
    If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    On Error GoTo 0

    ' Load artist names for display
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = "SELECT STUFF((SELECT ', ' + a.ARTIST_NAME + ' ' + a.ARTIST_LASTNAME " & _
                      "FROM TBL_PLAYER p INNER JOIN TBL_ARTIST a ON p.ID_ARTIST = a.ID_ARTIST " & _
                      "WHERE p.ID_SONG = ? FOR XML PATH('')), 1, 2, '') AS ARTISTS"
    cmd.CommandType = 1
    Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)

    On Error Resume Next
    Set rs = cmd.Execute
    On Error GoTo 0
    If Not rs.EOF Then
        If Not IsNull(rs("ARTISTS").Value) Then
            artistsStr = rs("ARTISTS").Value
        Else
            artistsStr = "Sin artista"
        End If
    End If

    On Error Resume Next
    If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    On Error GoTo 0

    ' Check dependency counts
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = "SELECT " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYER WHERE ID_SONG = ?) AS PLAYER_COUNT, " & _
                      "(SELECT COUNT(*) FROM TBL_TRACKLIST WHERE ID_SONG = ?) AS TRACKLIST_COUNT, " & _
                      "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?) AS PLAYLIST_COUNT"
    cmd.CommandType = 1
    Call AddParameter(cmd, "@s1", adInteger, adParamInput, 4, songId)
    Call AddParameter(cmd, "@s2", adInteger, adParamInput, 4, songId)
    Call AddParameter(cmd, "@s3", adInteger, adParamInput, 4, songId)

    On Error Resume Next
    Set rs = cmd.Execute
    On Error GoTo 0
    If Not rs.EOF Then
        playerCount     = rs("PLAYER_COUNT").Value
        tracklistCount  = rs("TRACKLIST_COUNT").Value
        playlistCount  = rs("PLAYLIST_COUNT").Value
    Else
        playerCount = 0
        tracklistCount = 0
        playlistCount = 0
    End If

    On Error Resume Next
    If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    On Error GoTo 0
End If

' Process deletion (POST + CSRF)
If IsPostRequest() And dbError = "" Then
    Call RequireCSRF()

    confirmDelete = Request.Form("confirm")
    If confirmDelete <> "yes" Then
        validationErrors = "<li>Debe confirmar la eliminacion.</li>"
    Else
        ' Delete child records first (maintain referential integrity)
        ' Then delete the song itself.
        ' We do NOT disable foreign key constraints.
        On Error Resume Next

        ' 1. Delete from TBL_PLAYER
        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?"
        cmd.CommandType = 1
        Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)
        cmd.Execute

        ' 2. Delete from TBL_TRACKLIST
        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?"
        cmd.CommandType = 1
        Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)
        cmd.Execute

        ' 3. Delete from TBL_PLAYLIST_SONG
        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?"
        cmd.CommandType = 1
        Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)
        cmd.Execute

        ' 4. Delete the song itself
        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = "DELETE FROM TBL_SONG WHERE ID_SONG = ?"
        cmd.CommandType = 1
        Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)
        cmd.Execute

        If Err.Number <> 0 Then
            dbError = "Error al eliminar la cancion."
            Call LogError("admin/song_delete.asp:DeleteSong", Err.Number, Err.Description, "")
            On Error GoTo 0
        Else
            On Error GoTo 0
            Call CloseDatabase(conn)
            Set conn = Nothing
            Redirect GetAppPath() & "/admin/songs.asp?msg=deleted"
        End If
    End If
End If

' Cleanup
On Error Resume Next
If Not (rs Is Nothing) Then
    If rs.State = 1 Then rs.Close
    Set rs = Nothing
End If
If Not (cmd Is Nothing) Then Set cmd = Nothing
If Not (conn Is Nothing) Then Call CloseDatabase(conn)
On Error GoTo 0

csrfToken = EnsureCSRFToken()
%>
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/header.asp" -->

            <main id="main-content" class="content-area" role="main">
                <div class="content-inner">
                    <h2 class="section-heading">Eliminar Cancion</h2>

                    <% If dbError <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <span class="alert-icon" aria-hidden="true">!</span>
                            <%= Encode(dbError) %>
                        </div>
                    <% End If %>

                    <% If validationErrors <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <ul><%= validationErrors %></ul>
                        </div>
                    <% End If %>

                    <div class="delete-confirmation">
                        <div class="alert alert-warning" role="status" aria-live="polite">
                            <strong>Esta a punto de eliminar la siguiente cancion:</strong>
                        </div>

                        <table class="info-table" aria-label="Detalles de la cancion a eliminar">
                            <tbody>
                                <tr>
                                    <th scope="row">ID:</th>
                                    <td><%= Encode(songId) %></td>
                                </tr>
                                <tr>
                                    <th scope="row">Nombre:</th>
                                    <td><%= Encode(songName) %></td>
                                </tr>
                                <tr>
                                    <th scope="row">Artista(s):</th>
                                    <td><%= Encode(artistsStr) %></td>
                                </tr>
                                <tr>
                                    <th scope="row">Ruta:</th>
                                    <td><%= Encode(songPath) %></td>
                                </tr>
                                <tr>
                                    <th scope="row">Reproducciones:</th>
                                    <td><%= Encode(songPlays) %></td>
                                </tr>
                            </tbody>
                        </table>

                        <div class="dependency-info" role="region" aria-label="Dependencias de la cancion">
                            <h3>Dependencias que se eliminaran:</h3>
                            <ul>
                                <li>Asociaciones con artistas (TBL_PLAYER): <%= Encode(playerCount) %></li>
                                <li>Asociaciones con albumes (TBL_TRACKLIST): <%= Encode(tracklistCount) %></li>
                                <li>Asociaciones con playlists (TBL_PLAYLIST_SONG): <%= Encode(playlistCount) %></li>
                            </ul>
                            <p class="form-help">
                                <strong>Nota:</strong> Los artistas, albumes y playlists NO se eliminaran.
                                Solo se eliminaran las asociaciones con esta cancion y la cancion misma.
                            </p>
                        </div>

                        <form method="post" action="song_delete.asp?id=<%= EncodeURL(songId) %>" class="admin-form" novalidate>
                            <input type="hidden" name="csrf_token" value="<%= EncodeAttr(csrfToken) %>">

                            <div class="form-group form-checkbox-group">
                                <input
                                    type="checkbox"
                                    id="confirm"
                                    name="confirm"
                                    value="yes"
                                    required
                                    class="form-checkbox"
                                    aria-required="true"
                                    aria-describedby="confirm_help"
                                >
                                <label for="confirm" class="form-label-inline">
                                    Si, deseo eliminar la cancion "<%= Encode(songName) %>" permanentemente.
                                </label>
                                <p id="confirm_help" class="form-help">
                                    Esta accion no se puede deshacer.
                                </p>
                            </div>

                            <div class="form-actions">
                                <button type="submit" class="btn btn-danger">
                                    <span aria-hidden="true">&#128465;</span>
                                    Eliminar Definitivamente
                                </button>
                                <a href="<%= GetAppPath() %>/admin/songs.asp" class="btn btn-secondary">
                                    Cancelar
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </main>

<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/footer.asp" -->
