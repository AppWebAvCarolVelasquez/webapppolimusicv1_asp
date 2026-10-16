/*===============================================================
  PoliMusic - player.js
  Audio player helper functions

  Responsibilities:
  - Ensure each audio element has an accessible label
  - Prevent autoplay (safety check)
  - Provide keyboard accessibility enhancements for audio controls
  - Handle audio errors gracefully (show accessible message)
  ================================================================*/

(function () {
    'use strict';

    // --- Get all audio players on the page ---
    var audioPlayers = document.querySelectorAll('audio.audio-player');

    audioPlayers.forEach(function (player) {
        // --- Prevent autoplay (safety) ---
        player.autoplay = false;
        player.preload = 'none'; // Load on demand only

        // --- Handle load errors ---
        player.addEventListener('error', function () {
            var errorDiv = document.createElement('div');
            errorDiv.className = 'no-audio';
            errorDiv.setAttribute('role', 'alert');
            errorDiv.textContent = 'No se pudo cargar el archivo de audio.';
            errorDiv.style.color = '#f47174';
            player.parentNode.insertBefore(errorDiv, player.nextSibling);
        }, true);

        // --- Track play count (optional - server-side via admin) ---
        // We only increment client-side display, not the database
        player.addEventListener('play', function () {
            // Pause all other audio players (one at a time)
            audioPlayers.forEach(function (otherPlayer) {
                if (otherPlayer !== player && !otherPlayer.paused) {
                    otherPlayer.pause();
                }
            });
        });
    });

    // --- Keyboard accessibility for audio controls ---
    // Native <audio controls> already supports keyboard, but we add
    // enhanced focus management when tabbing to the player.
    audioPlayers.forEach(function (player) {
        player.addEventListener('focus', function () {
            // Ensure the player is visible when focused (scroll into view)
            var rect = player.getBoundingClientRect();
            if (rect.bottom > window.innerHeight) {
                player.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
        });
    });
})();
