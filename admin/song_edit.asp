<%@ Language="VBScript" %>
<% Option Explicit %>
<%
'===============================================================
' admin/song_edit.asp
' PoliMusic - Admin: Edit Song
'===============================================================
' Edits an existing song in TBL_SONG using parametrized queries.
' Also manages artist associations via TBL_PLAYER.
' Protected: requires authentication + admin role.
' POST-only for the form submission (CSRF protected).
' GET with valid ID shows the edit form.
'===============================================================
%>
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/config/database.asp" -->
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/functions.asp" -->
<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/security.asp" -->
<%
Call RequireAdmin()

Dim pageTitle
pageTitle = "Editar Cancion"

Dim conn, cmd, rs
Dim dbError, validationErrors
Dim songId, songName, songPath, songPlays
Dim selectedArtists()
Dim allArtists()
Dim allArtistCount, currentArtistIds()
Dim currentArtistCount, j, k
Dim csrfToken

dbError = ""
validationErrors = ""
songId = SanitizeString(Request.QueryString("id"), 20)
allArtistCount = 0
currentArtistCount = 0
ReDim allArtists(2, 0)
ReDim currentArtistIds(-1)

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
    Call LogError("admin/song_edit.asp:OpenDatabase", Err.Number, Err.Description, "")
    On Error GoTo 0
Else
    On Error GoTo 0

    ' Load song data
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = "SELECT ID_SONG, SONG_NAME, SONG_PATH, PLAYS FROM TBL_SONG WHERE ID_SONG = ?"
    cmd.CommandType = 1
    Call AddParameter(cmd, "@id", adInteger, adParamInput, 4, songId)

    On Error Resume Next
    Set rs = cmd.Execute

    If Err.Number <> 0 Then
        dbError = "Error al consultar la cancion."
        Call LogError("admin/song_edit.asp:QuerySong", Err.Number, Err.Description, "")
        On Error GoTo 0
    ElseIf rs.EOF Then
        ' Song not found
        Redirect GetAppPath() & "/admin/songs.asp"
    Else
        On Error GoTo 0
        songName = rs("SONG_NAME").Value
        songPath = rs("SONG_PATH").Value
        songPlays = rs("PLAYS").Value
    End If

    On Error Resume Next
    If Not (rs Is Nothing) Then
        If rs.State = 1 Then rs.Close
        Set rs = Nothing
    End If
    Set cmd = Nothing
    On Error GoTo 0

    ' Load all artists
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = "SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME FROM TBL_ARTIST ORDER BY ARTIST_NAME ASC"
    cmd.CommandType = 1

    On Error Resume Next
    Set rs = cmd.Execute
    On Error GoTo 0
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

    On Error Resume Next
    If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    On Error GoTo 0

    ' Load current artist associations from TBL_PLAYER
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandText = "SELECT ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = ?"
    cmd.CommandType = 1
    Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)

    On Error Resume Next
    Set rs = cmd.Execute
    On Error GoTo 0
    If Not rs.EOF Then
        Do While Not rs.EOF
            ReDim Preserve currentArtistIds(currentArtistCount)
            currentArtistIds(currentArtistCount) = rs("ID_ARTIST").Value
            currentArtistCount = currentArtistCount + 1
            rs.MoveNext
        Loop
    End If

    On Error Resume Next
    If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    On Error GoTo 0
End If

' Process form submission (POST + CSRF)
If IsPostRequest() And dbError = "" Then
    Call RequireCSRF()

    Dim submittedName, submittedPath, submittedPlays
    Dim rawArtists, newArtistIds(), newArtistCount

    submittedName  = SanitizeString(Request.Form("song_name"), 100)
    submittedPath  = SanitizeString(Request.Form("song_path"), 255)
    submittedPlays = SanitizeString(Request.Form("plays"), 10)

    rawArtists = Request.Form("artists")
    If rawArtists <> "" Then
        newArtistIds = Split(rawArtists, ",")
        newArtistCount = UBound(newArtistIds) + 1
    Else
        ReDim newArtistIds(-1)
        newArtistCount = 0
    End If

    ' Validation
    If submittedName = "" Then
        validationErrors = validationErrors & "<li>El nombre de la cancion es obligatorio.</li>"
    End If
    If submittedPath = "" Then
        validationErrors = validationErrors & "<li>La ruta del archivo de audio es obligatoria.</li>"
    End If
    If InStr(1, submittedPath, "..", vbBinaryCompare) > 0 Then
        validationErrors = validationErrors & "<li>La ruta contiene caracteres no permitidos.</li>"
    End If
    If Not IsNumeric(submittedPlays) Then
        submittedPlays = 0
    Else
        submittedPlays = CLng(submittedPlays)
        If submittedPlays < 0 Then submittedPlays = 0
    End If

    If validationErrors = "" Then
        ' Update the song
        On Error Resume Next
        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandText = "UPDATE TBL_SONG SET SONG_NAME = ?, SONG_PATH = ?, PLAYS = ? WHERE ID_SONG = ?"
        cmd.CommandType = 1
        Call AddParameter(cmd, "@songName", adVarWChar, adParamInput, 100, submittedName)
        Call AddParameter(cmd, "@songPath", adVarWChar, adParamInput, 255, submittedPath)
        Call AddParameter(cmd, "@plays", adInteger, adParamInput, 4, submittedPlays)
        Call AddParameter(cmd, "@id", adInteger, adParamInput, 4, songId)

        cmd.Execute

        If Err.Number <> 0 Then
            dbError = "Error al actualizar la cancion."
            Call LogError("admin/song_edit.asp:UpdateSong", Err.Number, Err.Description, "")
            On Error GoTo 0
        Else
            On Error GoTo 0

            ' Update artist associations:
            ' 1. Delete all existing TBL_PLAYER entries for this song
            Set cmd = Server.CreateObject("ADODB.Command")
            Set cmd.ActiveConnection = conn
            cmd.CommandText = "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?"
            cmd.CommandType = 1
            Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)
            cmd.Execute

            ' 2. Insert new associations
            For j = 0 To newArtistCount - 1
                Dim aId
                aId = Trim(newArtistIds(j))
                If IsValidId(aId) Then
                    Set cmd = Server.CreateObject("ADODB.Command")
                    Set cmd.ActiveConnection = conn
                    cmd.CommandText = "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (?, ?)"
                    cmd.CommandType = 1
                    Call AddParameter(cmd, "@songId", adInteger, adParamInput, 4, songId)
                    Call AddParameter(cmd, "@artistId", adInteger, adParamInput, 4, CLng(aId))
                    On Error Resume Next
                    cmd.Execute
                    If Err.Number <> 0 Then
                        Call LogError("admin/song_edit.asp:InsertPlayer", Err.Number, Err.Description, "")
                    End If
                    On Error GoTo 0
                End If
            Next

            Call CloseDatabase(conn)
            Set conn = Nothing

            ' Redirect with success message
            Redirect GetAppPath() & "/admin/songs.asp?msg=updated"
        End If
    End If

    ' Update local variables to show user's input in form
    songName = submittedName
    songPath = submittedPath
    songPlays = submittedPlays

    ' Update current artist IDs to show selected
    If newArtistCount > 0 Then
        ReDim currentArtistIds(newArtistCount - 1)
        For j = 0 To newArtistCount - 1
            currentArtistIds(j) = CLng(Trim(newArtistIds(j)))
        Next
        currentArtistCount = newArtistCount
    Else
        ReDim currentArtistIds(-1)
        currentArtistCount = 0
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
                    <h2 class="section-heading">Editar Cancion</h2>

                    <% If dbError <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <span class="alert-icon" aria-hidden="true">!</span>
                            <%= Encode(dbError) %>
                        </div>
                    <% End If %>

                    <% If validationErrors <> "" Then %>
                        <div class="alert alert-error" role="alert" aria-live="assertive">
                            <span class="alert-icon" aria-hidden="true">!</span>
                            <div class="alert-body">
                                <p>Se detectaron los siguientes errores:</p>
                                <ul><%= validationErrors %></ul>
                            </div>
                        </div>
                    <% End If %>

                    <form method="post" action="song_edit.asp?id=<%= EncodeURL(songId) %>" class="admin-form" novalidate>
                        <input type="hidden" name="csrf_token" value="<%= EncodeAttr(csrfToken) %>">
                        <input type="hidden" name="id" value="<%= EncodeAttr(songId) %>">

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
                            >
                            <p id="song_path_help" class="form-help">
                                Ingrese la ruta relativa (ej: assets/audio/cancion.mp3).
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
                            >
                        </div>

                        <div class="form-group">
                            <span class="form-label" id="artists-label">
                                Artistas asociados
                            </span>
                            <p class="form-help" id="artists_help">
                                Mantenga Ctrl (Cmd en Mac) para seleccion multiple.
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
                                    <%
                                    Dim isSelected
                                    isSelected = False
                                    For k = 0 To currentArtistCount - 1
                                        If CLng(allArtists(0, j)) = CLng(currentArtistIds(k)) Then
                                            isSelected = True
                                            Exit For
                                        End If
                                    Next
                                    %>
                                    <option value="<%= EncodeAttr(allArtists(0, j)) %>"<% If isSelected Then Response.Write " selected" %>>
                                        <%= Encode(allArtists(1, j)) & " " & Encode(allArtists(2, j)) %>
                                    </option>
                                <% Next %>
                            </select>
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-primary">
                                Guardar Cambios
                            </button>
                            <a href="<%= GetAppPath() %>/admin/songs.asp" class="btn btn-secondary">
                                Cancelar
                            </a>
                        </div>
                    </form>
                </div>
            </main>

<!-- #INCLUDE VIRTUAL="/webapppolimusicv1_asp/includes/footer.asp" -->
