/*===============================================================
  PoliMusic - main.js
  General UI helpers

  Responsibilities:
  - Off-canvas sidebar drawer (accessible): scroll lock, backdrop,
    focus management, Escape/outside-click closing, resize reset
  - Focus management for dynamic content
  - Announce dynamic messages to screen readers
  - Prevent double form submission

  Responsive breakpoints live in styles.css:
    <= 1024px -> drawer mode (the toggle button is visible)
  ================================================================*/

(function () {
    'use strict';

    var DRAWER_BREAKPOINT = 1024;
    var ICON_MENU = '\u2630'; // hamburger
    var ICON_CLOSE = '\u2715'; // multiplication x

    // --- Off-canvas sidebar ---
    var menuToggle = document.getElementById('menuToggle');
    var sidebar = document.getElementById('sidebar');
    var backdrop = document.getElementById('sidebarBackdrop');
    var menuIcon = menuToggle ? menuToggle.querySelector('.menu-toggle-icon') : null;

    function isDrawerMode() {
        return window.matchMedia('(max-width: ' + DRAWER_BREAKPOINT + 'px)').matches;
    }

    function isOpen() {
        return sidebar ? sidebar.classList.contains('open') : false;
    }

    /**
     * Keep the drawer out of the tab order while it is closed.
     * `inert` is supported by modern browsers; ignored elsewhere.
     */
    function syncInert() {
        if (!sidebar || !('inert' in sidebar)) {
            return;
        }
        sidebar.inert = isDrawerMode() && !isOpen();
    }

    function setToggleState(open) {
        if (!menuToggle) {
            return;
        }
        menuToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        menuToggle.setAttribute(
            'aria-label',
            open ? 'Cerrar menu de navegacion' : 'Abrir menu de navegacion'
        );
        if (menuIcon) {
            menuIcon.textContent = open ? ICON_CLOSE : ICON_MENU;
        }
    }

    function openSidebar() {
        if (!sidebar || !isDrawerMode()) {
            return;
        }
        sidebar.classList.add('open');
        document.body.classList.add('nav-open');
        if (backdrop) {
            backdrop.classList.add('visible');
        }
        setToggleState(true);
        syncInert();

        // Move focus into the drawer so keyboard users can navigate it
        var firstFocusable = sidebar.querySelector('a[href], button');
        if (firstFocusable) {
            firstFocusable.focus();
        }
    }

    function closeSidebar(restoreFocus) {
        if (!sidebar) {
            return;
        }
        var wasOpen = isOpen();

        sidebar.classList.remove('open');
        document.body.classList.remove('nav-open');
        if (backdrop) {
            backdrop.classList.remove('visible');
        }
        setToggleState(false);
        syncInert();

        if (wasOpen && restoreFocus && menuToggle) {
            menuToggle.focus();
        }
    }

    if (menuToggle && sidebar) {
        syncInert();

        menuToggle.addEventListener('click', function () {
            if (isOpen()) {
                closeSidebar(true);
            } else {
                openSidebar();
            }
        });

        // Close when tapping the backdrop
        if (backdrop) {
            backdrop.addEventListener('click', function () {
                closeSidebar(true);
            });
        }

        // Close after choosing a destination (the page will navigate anyway)
        sidebar.addEventListener('click', function (event) {
            var link = event.target.closest ? event.target.closest('a[href]') : null;
            if (link) {
                closeSidebar(false);
            }
        });

        // Close on Escape and return focus to the toggle
        document.addEventListener('keydown', function (event) {
            if ((event.key === 'Escape' || event.key === 'Esc') && isOpen()) {
                closeSidebar(true);
            }
        });

        // Reset the drawer state when resizing back to desktop
        var resizeTimer = null;
        window.addEventListener('resize', function () {
            if (resizeTimer) {
                window.clearTimeout(resizeTimer);
            }
            resizeTimer = window.setTimeout(function () {
                if (!isDrawerMode()) {
                    closeSidebar(false);
                }
                syncInert();
            }, 150);
        });

        // Also reset when the device rotates
        window.addEventListener('orientationchange', function () {
            closeSidebar(false);
            syncInert();
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
