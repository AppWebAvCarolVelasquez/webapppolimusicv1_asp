/*===============================================================
  PoliMusic - main.js
  General UI helpers

  Responsibilities:
  - Mobile sidebar toggle (accessible)
  - Focus management for dynamic content
  - Announce dynamic messages to screen readers
  ================================================================*/

(function () {
    'use strict';

    // --- Mobile sidebar toggle ---
    var menuToggle = document.getElementById('menuToggle');
    var sidebar = document.getElementById('sidebar');

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', function () {
            var expanded = menuToggle.getAttribute('aria-expanded') === 'true';
            if (expanded) {
                sidebar.classList.remove('open');
                menuToggle.setAttribute('aria-expanded', 'false');
                menuToggle.setAttribute('aria-label', 'Abrir menu de navegacion');
            } else {
                sidebar.classList.add('open');
                menuToggle.setAttribute('aria-expanded', 'true');
                menuToggle.setAttribute('aria-label', 'Cerrar menu de navegacion');
            }
        });

        // Close sidebar when clicking outside (on mobile)
        document.addEventListener('click', function (e) {
            if (window.innerWidth <= 1024) {
                if (!sidebar.contains(e.target) &&
                    !menuToggle.contains(e.target) &&
                    sidebar.classList.contains('open')) {
                    sidebar.classList.remove('open');
                    menuToggle.setAttribute('aria-expanded', 'false');
                    menuToggle.setAttribute('aria-label', 'Abrir menu de navegacion');
                }
            }
        });

        // Close sidebar on Escape
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && sidebar.classList.contains('open')) {
                sidebar.classList.remove('open');
                menuToggle.setAttribute('aria-expanded', 'false');
                menuToggle.setAttribute('aria-label', 'Abrir menu de navegacion');
                menuToggle.focus();
            }
        });
    }

    // --- Auto-focus the first error field on form pages ---
    var errorFields = document.querySelectorAll('[aria-invalid="true"]');
    if (errorFields.length > 0) {
        errorFields[0].focus();
    }

    // --- Auto-dismiss success messages after 5 seconds ---
    var successAlerts = document.querySelectorAll('.alert-success');
    successAlerts.forEach(function (alert) {
        setTimeout(function () {
            alert.style.transition = 'opacity 0.5s';
            alert.style.opacity = '0';
            setTimeout(function () {
                alert.remove();
            }, 500);
        }, 5000);
    });

    // --- Prevent form double submission ---
    var forms = document.querySelectorAll('form');
    forms.forEach(function (form) {
        var submitted = false;
        form.addEventListener('submit', function (e) {
            if (submitted) {
                e.preventDefault();
                return;
            }
            submitted = true;
            // Re-enable after 3 seconds (in case of validation failure)
            setTimeout(function () {
                submitted = false;
            }, 3000);
        });
    });
})();
