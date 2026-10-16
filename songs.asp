<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' songs.asp
' PoliMusic - Main Page: Song List
'===============================================================
' Displays the song catalog from SQL Server with:
'   - Song name and associated artists (via TBL_PLAYER + TBL_ARTIST)
'   - Accessible audio player for each song
'   - Search by song name or artist
'   - Admin links (visible only to admins)
'   - Welcome message with session username
'   - Logout link
'===============================================================
%>
<!-- #INCLUDE FILE="config/database.asp" -->
<!-- #INCLUDE FILE="includes/functions.asp" -->
<!-- #INCLUDE FILE="includes/security.asp" -->
<%
' Require authentication
Call RequireAuth()

Dim pageTitle
pageTitle = "Song List"

Dim conn, cmd, rs, rsArtists
Dim searchQuery, hasResults, dbError
Dim songs(), songCount, i

searchQuery = SanitizeString(Request.QueryString("q"), 100)
hasResults = False
dbError = ""
songCount = 0
ReDim songs(4, 0) ' columns: ID_SONG, SONG_NAME, SONG_PATH, PLAYS, ARTISTS_STRING

' Open database connection
On Error Resume Next
Set conn = OpenDatabase()
If Err.Number <> 0 Then
    dbError = "No se pudo conectar a la base de datos. Verifique la configuracion."
    Call LogError("songs.asp:OpenDatabase", Err.Number, Err.Description, "")
    On Error GoTo 0
Else
    On Error GoTo 0

    ' Build query with optional search
    ' Use parametrized query for search term
    ' The query avoids duplicate songs by using a subquery/CTE approach
    ' and aggregates artist names using FOR XML PATH (SQL Server)
    Dim sql
    If searchQuery <> "" Then
        ' Search by song name OR artist name
        ' Using STUFF/FOR XML PATH to concatenate artists per song
        sql = "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, s.PLAYS, " & _
              "(SELECT STUFF((SELECT ', ' + a.ARTIST_NAME + ' ' + a.ARTIST_LASTNAME " & _
              "  FROM TBL_PLAYER p " & _
              "  INNER JOIN TBL_ARTIST a ON p.ID_ARTIST = a.ID_ARTIST " & _
              "  WHERE p.ID_SONG = s.ID_SONG " & _
              "  FOR XML PATH('')), 1, 2, '')) AS ARTISTS " & _
              "FROM TBL_SONG s " & _
              "WHERE s.SONG_NAME LIKE ? " & _
              "   OR EXISTS (SELECT 1 FROM TBL_PLAYER p2 " & _
              "              INNER JOIN TBL_ARTIST a2 ON p2.ID_ARTIST = a2.ID_ARTIST " & _
              "              WHERE p2.ID_SONG = s.ID_SONG " & _
              "              AND (a2.ARTIST_NAME LIKE ? OR a2.ARTIST_LASTNAME LIKE ?)) " & _
              "ORDER BY s.SONG_NAME ASC"

        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = sql
        cmd.CommandType = 1 ' adCmdText

        Dim searchPattern
        searchPattern = "%" & searchQuery & "%"
        Call AddParameter(cmd, "@songName", adVarWChar, adParamInput, 100, searchPattern)
        Call AddParameter(cmd, "@artistName", adVarWChar, adParamInput, 100, searchPattern)
        Call AddParameter(cmd, "@artistLast", adVarWChar, adParamInput, 100, searchPattern)

        On Error Resume Next
        Set rs = cmd.Execute
    Else
        ' No search: list all songs
        sql = "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, s.PLAYS, " & _
              "(SELECT STUFF((SELECT ', ' + a.ARTIST_NAME + ' ' + a.ARTIST_LASTNAME " & _
              "  FROM TBL_PLAYER p " & _
              "  INNER JOIN TBL_ARTIST a ON p.ID_ARTIST = a.ID_ARTIST " & _
              "  WHERE p.ID_SONG = s.ID_SONG " & _
              "  FOR XML PATH('')), 1, 2, '')) AS ARTISTS " & _
              "FROM TBL_SONG s " & _
              "ORDER BY s.SONG_NAME ASC"

        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = sql
        cmd.CommandType = 1 ' adCmdText

        On Error Resume Next
        Set rs = cmd.Execute
    End If

    If Err.Number <> 0 Then
        dbError = "Error al consultar las canciones."
        Call LogError("songs.asp:QuerySongs", Err.Number, Err.Description, "")
        On Error GoTo 0
    Else
        On Error GoTo 0

        If Not rs.EOF Then
            hasResults = True
            Do While Not rs.EOF
                ReDim Preserve songs(4, songCount)
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
                If Not IsNull(rs("ARTISTS").Value) Then
                    songs(4, songCount) = rs("ARTISTS").Value
                Else
                    songs(4, songCount) = ""
                End If
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

' CSRF token for admin actions on this page
Dim csrfToken
If IsAdmin() Then
    csrfToken = EnsureCSRFToken()
End If
%>
<!-- #INCLUDE FILE="includes/header.asp" -->

            <main id="main-content" class="content-area" role="main">
                <div class="content-inner">
                    <!-- Welcome message -->
                    <div class="welcome-banner">
                        <p class="welcome-text">
                            Bienvenido(a), <strong><%= Encode(Session("USERNAME")) %></strong>
                        </p>
                    </div>

                    <!-- Search bar -->
                    <form method="get" action="songs.asp" class="search-form" role="search">
                        <div class="search-group">
                            <label for="search-q" class="sr-only">Buscar canciones o artistas</label>
                            <input
                                type="search"
                                id="search-q"
                                name="q"
                                value="<%= EncodeAttr(searchQuery) %>"
                                placeholder="Buscar por cancion o artista..."
                                class="search-input"
                                maxlength="100"
                                aria-label="Buscar canciones o artistas"
                            >
                            <button type="submit" class="btn btn-search" aria-label="Buscar">
                                <span aria-hidden="true">&#128269;</span>
                                Buscar
                            </button>
                            <% If searchQuery <> "" Then %>
                                <a href="<%= GetAppPath() %>/songs.asp" class="btn btn-secondary btn-clear-search">
                                    Limpiar
                                </a>
                            <% End If %>
                        </div>
                    </form>

                    <% If IsAdmin() Then %>
                        <div class="admin-actions">
                            <a href="<%= GetAppPath() %>/admin/songs.asp" class="btn btn-admin">
                                <span aria-hidden="true">&#9881;</span>
                                Gestionar Canciones
                            </a>
                        </div>
                    <% End If %>

                    <!-- Error message -->
                    <% If dbError <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <span class="alert-icon" aria-hidden="true">!</span>
                            <%= Encode(dbError) %>
                        </div>
                    <% End If %>

                    <!-- Song List Table -->
                    <h2 class="section-heading" id="song-list-heading">Song List</h2>

                    <% If hasResults Then %>
                        <div class="table-container" role="region" aria-labelledby="song-list-heading" tabindex="0">
                            <table class="songs-table">
                                <caption class="sr-only">Lista de canciones disponibles en PoliMusic</caption>
                                <thead>
                                    <tr>
                                        <th scope="col">#</th>
                                        <th scope="col">Cancion</th>
                                        <th scope="col">Artista(s)</th>
                                        <th scope="col">Reproducciones</th>
                                        <th scope="col">Reproductor</th>
                                        <% If IsAdmin() Then %>
                                            <th scope="col">Acciones</th>
                                        <% End If %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% For i = 0 To songCount - 1 %>
                                        <tr>
                                            <td class="song-index"><%= i + 1 %></td>
                                            <td class="song-name">
                                                <span id="song-title-<%= songs(0, i) %>"><%= Encode(songs(1, i)) %></span>
                                            </td>
                                            <td class="song-artists">
                                                <%= Encode(songs(4, i)) %>
                                            </td>
                                            <td class="song-plays"><%= Encode(songs(3, i)) %></td>
                                            <td class="song-player">
                                                <% If songs(2, i) <> "" Then %>
                                                    <% Dim audioPath %>
                                                    <% audioPath = ResolveAudioPath(songs(2, i)) %>
                                                    <audio
                                                        controls
                                                        preload="none"
                                                        class="audio-player"
                                                        aria-label="Reproductor de: <%= Encode(songs(1, i)) %>"
                                                    >
                                                        <source src="<%= EncodeAttr(audioPath) %>" type="audio/mpeg">
                                                        <p>
                                                            Tu navegador no soporta la reproduccion de audio.
                                                            <a href="<%= EncodeAttr(audioPath) %>">Descargar <%= Encode(songs(1, i)) %></a>
                                                        </p>
                                                    </audio>
                                                <% Else %>
                                                    <span class="no-audio" aria-label="Archivo de audio no disponible">
                                                        No disponible
                                                    </span>
                                                <% End If %>
                                            </td>
                                            <% If IsAdmin() Then %>
                                                <td class="song-actions">
                                                    <a href="<%= GetAppPath() %>/admin/song_edit.asp?id=<%= EncodeURL(songs(0, i)) %>" class="btn btn-sm btn-edit" aria-label="Editar cancion <%= Encode(songs(1, i)) %>">
                                                        Editar
                                                    </a>
                                                    <a href="<%= GetAppPath() %>/admin/song_delete.asp?id=<%= EncodeURL(songs(0, i)) %>" class="btn btn-sm btn-delete" aria-label="Eliminar cancion <%= Encode(songs(1, i)) %>">
                                                        Eliminar
                                                    </a>
                                                </td>
                                            <% End If %>
                                        </tr>
                                    <% Next %>
                                </tbody>
                            </table>
                        </div>
                    <% Else %>
                        <% If dbError = "" Then %>
                            <div class="alert alert-info" role="status" aria-live="polite">
                                <% If searchQuery <> "" Then %>
                                    No se encontraron canciones que coincidan con "<%= Encode(searchQuery) %>".
                                <% Else %>
                                    No hay canciones disponibles en el catalogo.
                                <% End If %>
                            </div>
                        <% End If %>
                    <% End If %>
                </div>
            </main>

<!-- #INCLUDE FILE="includes/footer.asp" -->
<%
'===============================================================
' Function: ResolveAudioPath
' Converts a database SONG_PATH to a servable URL.
' Handles the path formats used in BDD_PoliMusic.sql:
'   ~/songFiles/bensound-adventure.mp3
'   assets/audio/song.mp3
'   song.mp3
'===============================================================
Function ResolveAudioPath(songPath)
    Dim cleanPath, pos

    ' Guard against empty paths
    If IsNull(songPath) Or songPath = "" Then
        ResolveAudioPath = ""
        Exit Function
    End If

    ' Normalize backslashes to forward slashes
    cleanPath = Replace(songPath, "\", "/")

    ' Handle ~ prefix (represents application root in the DB)
    If Left(cleanPath, 2) = "~/" Then
        ' ~/songFiles/bensound-adventure.mp3
        ' Map songFiles -> assets/audio
        If InStr(1, cleanPath, "songFiles/", vbTextCompare) > 0 Then
            pos = InStr(1, cleanPath, "songFiles/", vbTextCompare)
            cleanPath = "assets/audio/" & Mid(cleanPath, pos + 10)
        ElseIf InStr(1, cleanPath, "songFiles\", vbTextCompare) > 0 Then
            pos = InStr(1, cleanPath, "songFiles\", vbTextCompare)
            cleanPath = "assets/audio/" & Mid(cleanPath, pos + 10)
        Else
            ' Other ~ paths: strip the ~/ prefix and use as-is
            cleanPath = Mid(cleanPath, 3)
        End If
    End If

    ' Remove leading slashes (already handled ~, now strip any remaining /)
    Do While Left(cleanPath, 1) = "/"
        cleanPath = Mid(cleanPath, 2)
    Loop

    ' If the path already contains "assets/audio/", use as-is
    If InStr(1, cleanPath, "assets/audio/", vbTextCompare) > 0 Then
        ' Already correct relative path
    ElseIf InStr(1, cleanPath, "/", vbBinaryCompare) = 0 Then
        ' Just a filename: prepend the audio directory
        cleanPath = "assets/audio/" & cleanPath
    End If

    ' Build the full URL
    ResolveAudioPath = GetAppPath() & "/" & cleanPath
End Function
%>
