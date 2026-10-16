<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' admin/song_create.asp
' PoliMusic - Admin: Create Song
'===============================================================
' Creates a new song in TBL_SONG using parametrized queries.
' Also allows linking artists via TBL_PLAYER.
' Protected: requires authentication + admin role.
' POST-only for the form submission (CSRF protected).
'===============================================================
%>
<!-- #INCLUDE FILE="../config/database.asp" -->
<!-- #INCLUDE FILE="../includes/functions.asp" -->
<!-- #INCLUDE FILE="../includes/security.asp" -->
<%
Call RequireAdmin()

Dim pageTitle
pageTitle = "Nueva Cancion"

Dim conn, cmd, rs
Dim dbError, successMsg, validationErrors
Dim songName, songPath, songPlays
Dim selectedArtists()
Dim artistCount, artistIdx
Dim allArtists()
Dim allArtistCount, j
Dim csrfToken

dbError = ""
successMsg = ""
validationErrors = ""
songName = ""
songPath = ""
songPlays = 0
artistCount = 0
ReDim selectedArtists(-1)

' Load available artists for the form (always needed)
On Error Resume Next
Set conn = OpenDatabase()
If Err.Number <> 0 Then
    dbError = "No se pudo conectar a la base de datos."
    Call LogError("admin/song_create.asp:OpenDatabase", Err.Number, Err.Description, "")
    On Error GoTo 0
Else
    On Error GoTo 0

    ' Get all artists for the dropdown
    Dim sqlArtists
    sqlArtists = "SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME FROM TBL_ARTIST ORDER BY ARTIST_NAME ASC"

    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = sqlArtists
    cmd.CommandType = 1 ' adCmdText

    On Error Resume Next
    Set rs = cmd.Execute

    If Err.Number <> 0 Then
        dbError = "Error al cargar los artistas."
        Call LogError("admin/song_create.asp:LoadArtists", Err.Number, Err.Description, "")
        On Error GoTo 0
    Else
        On Error GoTo 0
        allArtistCount = 0
        ReDim allArtists(2, 0)
        If Not rs.EOF Then
            Do While Not rs.EOF
                ReDim Preserve allArtists(2, allArtistCount)
                allArtists(0, allArtistCount) = rs("ID_ARTIST").Value
                allArtists(1, allArtistCount) = rs("ARTIST_NAME").Value
                allArtists(2, allArtistCount) = rs("ARTIST_LASTNAME").Value
                allArtistCount = allArtistCount + 1
                rs.MoveNext
            Loop
        End If
    End If

    On Error Resume Next
    If Not (rs Is Nothing) Then
        If rs.State = 1 Then rs.Close
        Set rs = Nothing
    End If
    Set cmd = Nothing
    On Error GoTo 0
End If

' Process form submission (POST + CSRF)
If IsPostRequest() Then
    Call RequireCSRF()

    ' Get and validate form data
    songName  = SanitizeString(Request.Form("song_name"), 100)
    songPath  = SanitizeString(Request.Form("song_path"), 255)
    songPlays = SanitizeString(Request.Form("plays"), 10)

    ' Get selected artists
    Dim rawArtists
    rawArtists = Request.Form("artists")
    If rawArtists <> "" Then
        selectedArtists = Split(rawArtists, ",")
        artistCount = UBound(selectedArtists) + 1
    End If

    ' Server-side validation
    If songName = "" Then
        validationErrors = validationErrors & "<li>El nombre de la cancion es obligatorio.</li>"
    End If
    If songPath = "" Then
        validationErrors = validationErrors & "<li>La ruta del archivo de audio es obligatoria.</li>"
    End If
    If Not IsNumeric(songPlays) Then
        songPlays = 0
    Else
        songPlays = CLng(songPlays)
        If songPlays < 0 Then songPlays = 0
    End If

    ' Validate path: prevent directory traversal
    If InStr(1, songPath, "..", vbBinaryCompare) > 0 Then
        validationErrors = validationErrors & "<li>La ruta del archivo contiene caracteres no permitidos.</li>"
    End If

    If validationErrors = "" And dbError = "" Then
        ' Insert the song with parametrized query
        On Error Resume Next
        If conn Is Nothing Then Set conn = OpenDatabase()

        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = "INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, ?)"
        cmd.CommandType = 1 ' adCmdText

        Call AddParameter(cmd, "@songName", adVarWChar, adParamInput, 100, songName)
        Call AddParameter(cmd, "@songPath", adVarWChar, adParamInput, 255, songPath)
        Call AddParameter(cmd, "@plays", adInteger, adParamInput, 4, songPlays)

        cmd.Execute

        If Err.Number <> 0 Then
            dbError = "Error al crear la cancion."
            Call LogError("admin/song_create.asp:InsertSong", Err.Number, Err.Description, "")
            On Error GoTo 0
        Else
            On Error GoTo 0

            ' Get the new song ID using SCOPE_IDENTITY
            Set cmd = Server.CreateObject("ADODB.Command")
            Set cmd.ActiveConnection = conn
            cmd.CommandText = "SELECT SCOPE_IDENTITY() AS NEW_ID"
            cmd.CommandType = 1 ' adCmdText

            On Error Resume Next
            Set rs = cmd.Execute

            Dim newSongId
            If Not rs.EOF Then
                newSongId = rs("NEW_ID").Value
            Else
                ' Fallback: get the latest ID by song name
                rs.Close
                cmd.CommandText = "SELECT TOP 1 ID_SONG FROM TBL_SONG WHERE SONG_NAME = ? ORDER BY ID_SONG DESC"
                Call AddParameter(cmd, "@songName", adVarWChar, adParamInput, 100, songName)
                Set rs = cmd.Execute
                If Not rs.EOF Then newSongId = rs("ID_SONG").Value
            End If
            On Error GoTo 0

            ' Link selected artists via TBL_PLAYER
            If artistCount > 0 And Not IsEmpty(newSongId) Then
                For artistIdx = 0 To artistCount - 1
                    Dim artistId
                    artistId = Trim(selectedArtists(artistIdx))
                    If IsValidId(artistId) Then
                        Set cmd = Server.CreateObject("ADODB.Command")
                        Set cmd.ActiveConnection = conn
                        cmd.CommandText = "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (?, ?)"
                        cmd.CommandType = 1
                        Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, CLng(newSongId))
                        Call AddParameter(cmd, "@artistId", adInteger, adParamInput, 4, CLng(artistId))
                        On Error Resume Next
                        cmd.Execute
                        If Err.Number <> 0 Then
                            Call LogError("admin/song_create.asp:InsertPlayer", Err.Number, Err.Description, "artistId=" & artistId)
                        End If
                        On Error GoTo 0
                    End If
                Next
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

            ' Redirect to admin list with success message
            Redirect GetAppPath() & "/admin/songs.asp?msg=created"
        End If
    End If
End If

' Cleanup if still open
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
<!-- #INCLUDE FILE="../includes/header.asp" -->

            <main id="main-content" class="content-area" role="main">
                <div class="content-inner">
                    <h2 class="section-heading">Crear Nueva Cancion</h2>

                    <% If dbError <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <span class="alert-icon" aria-hidden="true">!</span>
                            <%= Encode(dbError) %>
                        </div>
                    <% End If %>

                    <% If validationErrors <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <p>Se detectaron los siguientes errores:</p>
                            <ul><%= validationErrors %></ul>
                        </div>
                    <% End If %>

                    <form method="post" action="song_create.asp" class="admin-form" novalidate>
                        <input type="hidden" name="csrf_token" value="<%= EncodeAttr(csrfToken) %>">

                        <div class="form-group">
                            <label for="song_name" class="form-label">
                                Nombre de la cancion <span class="required" aria-label="obligatorio">*</span>
                            </label>
                            <input
                                type="text"
                                id="song_name"
                                name="song_name"
                                value="<%= EncodeAttr(songName) %>"
                                maxlength="100"
                                required
                                class="form-input"
                                aria-required="true"
                                <% If validationErrors <> "" And songName = "" Then Response.Write "aria-invalid=""true""" %>
                            >
                        </div>

                        <div class="form-group">
                            <label for="song_path" class="form-label">
                                Ruta del archivo de audio <span class="required" aria-label="obligatorio">*</span>
                            </label>
                            <input
                                type="text"
                                id="song_path"
                                name="song_path"
                                value="<%= EncodeAttr(songPath) %>"
                                maxlength="255"
                                required
                                class="form-input"
                                aria-required="true"
                                aria-describedby="song_path_help"
                                <% If validationErrors <> "" And songPath = "" Then Response.Write "aria-invalid=""true""" %>
                            >
                            <p id="song_path_help" class="form-help">
                                Ingrese la ruta relativa (ej: assets/audio/cancion.mp3).
                                No use rutas absolutas ni caracteres como ..
                            </p>
                        </div>

                        <div class="form-group">
                            <label for="plays" class="form-label">
                                Numero de reproducciones
                            </label>
                            <input
                                type="number"
                                id="plays"
                                name="plays"
                                value="<%= EncodeAttr(songPlays) %>"
                                min="0"
                                class="form-input"
                                aria-describedby="plays_help"
                            >
                            <p id="plays_help" class="form-help">Valor predeterminado: 0</p>
                        </div>

                        <div class="form-group">
                            <span class="form-label" id="artists-label">
                                Artistas asociados
                            </span>
                            <p class="form-help" id="artists_help">
                                Seleccione uno o mas artistas para esta cancion.
                                Use Ctrl+Clic (Cmd+Clic en Mac) para seleccion multiple.
                            </p>
                            <select
                                name="artists"
                                id="artists"
                                multiple
                                size="6"
                                class="form-select"
                                aria-labelledby="artists-label"
                                aria-describedby="artists_help"
                            >
                                <% For j = 0 To allArtistCount - 1 %>
                                    <option value="<%= EncodeAttr(allArtists(0, j)) %>">
                                        <%= Encode(allArtists(1, j)) & " " & Encode(allArtists(2, j)) %>
                                    </option>
                                <% Next %>
                            </select>
                            <% If allArtistCount = 0 Then %>
                                <p class="form-help">No hay artistas registrados en la base de datos.</p>
                            <% End If %>
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-primary">
                                Crear Cancion
                            </button>
                            <a href="<%= GetAppPath() %>/admin/songs.asp" class="btn btn-secondary">
                                Cancelar
                            </a>
                        </div>
                    </form>
                </div>
            </main>

<!-- #INCLUDE FILE="../includes/footer.asp" -->
