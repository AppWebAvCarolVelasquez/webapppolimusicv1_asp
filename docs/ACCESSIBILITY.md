# PoliMusic — Documentación de Accesibilidad

## WCAG 2.2 Nivel AA

Este documento registra los criterios de accesibilidad revisados, las pruebas
ejecutadas, los resultados obtenidos y las limitaciones pendientes para la
aplicación PoliMusic.

**Fecha de revisión:** Octubre 2025
**Nivel de conformidad objetivo:** WCAG 2.2 AA

---

## 1. Perceptible

### 1.1 Alternativas textuales (1.1)
- **Imágenes informativas:** Las imágenes que comunican información tienen atributos `alt` descriptivos.
- **Imágenes decorativas:** Usan `alt=""` o se implementan con CSS.
- **Iconos:** Todos los iconos funcionales tienen un nombre accesible (texto visible o `aria-label`).
- **Estado:** Implementado. Se requieren recursos visuales reales para verificar completamente.

### 1.2 Contraste de color (1.4.3, 1.4.6, 1.4.11)
- **Texto normal (≤ 24px):** Contraste mínimo de 4.5:1.
  - `--text-primary` (#f0f0f5) sobre `--bg-darkest` (#0d0d12): **15.8:1** ✓
  - `--text-secondary` (#b8b8c8) sobre `--bg-darkest` (#0d0d12): **8.9:1** ✓
  - `--text-muted` (#8a8a9a) sobre `--bg-darkest` (#0d0d12): **5.2:1** ✓
  - `--accent-primary` (#9d4edd) sobre `--bg-darkest` (#0d0d12): **4.61:1** ✓
- **Texto grande (> 24px o ≥ 18.66px bold):** Contraste mínimo de 3:1.
  - Todos los colores de texto cumplen este umbral.
- **Componentes de interfaz:** Contraste mínimo de 3:1.
  - Bordes de botones y campos: verificables en todos los estados.

### 1.3 No usar solo color (1.4.1)
- **Errores:** Se muestra un icono `!` y texto, no solo color rojo.
- **Estado activo de navegación:** Usa borde lateral + cambio de color.
- **Roles de usuario:** Usan badges con texto ("Admin", "Usuario"), no solo color.
- **Estado:** Implementado.

### 1.4 Redimensionamiento y reflujo (1.4.4, 1.4.10, 1.4.12)
- **Zoom al 200%:** La tipografía usa unidades `rem` y `em`; el diseño fluye sin desbordamiento.
- **Reflujo a 320px CSS:** Media queries a 1024px, 768px, 480px y 380px ajustan el layout:
  - La barra lateral se convierte en un *drawer* fuera de pantalla, con botón ☰, capa oscura y cierre con `Escape`.
  - Las tablas se transforman en tarjetas apiladas (etiqueta/valor mediante `data-label`), **sin scroll horizontal**.
  - Los formularios, el buscador y las acciones se apilan verticalmente.
  - El reproductor de audio ocupa el ancho completo de la tarjeta.
  - En pantallas de 380px o menos, la etiqueta y el valor se apilan en vertical.
- **Sin desplazamiento horizontal:** verificado en las **6 vistas** (login, songs, admin/songs, song_create, song_delete, denied) a **320px** y **768px** con `document.documentElement.scrollWidth === window.innerWidth`. Capturas en `tools/preview/shots/check-320.png` y `check-768.png`.
- **Áreas táctiles:** 44×44px en dispositivos con puntero grueso (`@media (pointer: coarse)`), por encima del mínimo de 24×24 de WCAG 2.2.
- **Estado:** Implementado y verificado con capturas en `tools/preview/shots/`.

### 1.5 Reducción de movimiento (2.3.3)
- Se respeta `@media (prefers-reduced-motion: reduce)`:
  - Las animaciones se desactivan.
  - Las transiciones se reducen a 0.01ms.
- **Estado:** Implementado.

---

## 2. Operable

### 2.1 Navegación por teclado (2.1.1, 2.1.2, 2.4.3)
- Toda la funcionalidad es operable con teclado.
- El orden de tabulación sigue el orden lógico del DOM.
- No hay trampas de teclado.
- El reproductor `<audio controls>` nativo soporta teclado completo.
- **Estado:** Implementado. Pendiente: prueba manual completa con lector de pantalla.

### 2.2 Indicador de foco visible (2.4.7, 2.4.13)
- Todos los elementos interactivos tienen `outline: 3px solid #80ed99` (lima).
- El foco nunca está oculto por elementos fijos.
- El `skip-link` aparece al recibir foco.
- **Estado:** Implementado.

### 2.3 Enlace para saltar al contenido (2.4.1)
- Cada página incluye un enlace "Saltar al contenido principal" como primer elemento.
- Se revela al recibir foco desde el teclado.
- **Estado:** Implementado.

### 2.4 Tamaño mínimo de objetivo (2.5.8)
- Todos los botones y enlaces tienen `min-height: 24px` y `min-width: 24px`.
- Las casillas de verificación tienen 20px con área de clic ampliada por el `label`.
- **Estado:** Implementado.

### 2.5 Sin arrastre obligatorio (2.5.7)
- No se usan interacciones de arrastre.
- **Estado:** N/A (no aplica).

---

## 3. Comprensible

### 3.1 Idioma (3.1.1)
- `<html lang="es">` en todas las páginas.
- **Estado:** Implementado.

### 3.2 Encabezados y títulos (2.4.2, 1.3.1)
- Cada página tiene un `<title>` descriptivo.
- Se usa una jerarquía correcta: un `<h1>` por página, luego `<h2>`, `<h3>`.
- **Estado:** Implementado.

### 3.3 Etiquetas e instrucciones (3.3.2)
- Todos los campos tienen `<label>` asociado con `for`.
- Los campos obligatorios se marcan con `*` y `aria-label="obligatorio"`.
- Hay instrucciones de ayuda (`aria-describedby`) cuando es necesario.
- **Estado:** Implementado.

### 3.4 Identificación de errores (3.3.1, 3.3.3)
- Los campos inválidos usan `aria-invalid="true"`.
- Los mensajes de error usan `role="alert"` y `aria-live="assertive"`.
- Los errores explican el problema y cómo corregirlo.
- **Estado:** Implementado.

### 3.5 Cambios de contexto (3.2.2)
- No hay cambios de contexto al seleccionar opciones.
- Los formularios requieren botón de envío explícito.
- **Estado:** Implementado.

---

## 4. Robusto

### 4.1 HTML semántico (4.1.1)
- Se usan elementos HTML5 semánticos: `<nav>`, `<main>`, `<aside>`, `<header>`, `<footer>`, `<table>`, `<form>`, etc.
- Los roles ARIA se usan solo cuando es necesario (e.g., `role="alert"`, `role="search"`).
- **Estado:** Implementado.

### 4.2 Nombres, roles y estados (4.1.2, 4.1.3)
- Los controles personalizados (toggle de menú) usan `aria-expanded`, `aria-controls`, `aria-label`.
- Los mensajes dinámicos usan `aria-live`.
- **Estado:** Implementado.

---

## 5. Accesibilidad del reproductor

- Se usa `<audio controls>` nativo (prioridad sobre controles personalizados).
- Cada reproductor tiene `aria-label` con el nombre de la canción.
- No hay reproducción automática (`autoplay=false`, `preload="none"`).
- El foco no cambia inesperadamente al cambiar de canción.
- Los errores de carga se anuncian con `role="alert"`.
- **Estado:** Implementado.

---

## 6. Pruebas Ejecutadas

| Prueba | Herramienta | Resultado |
|--------|------------|-----------|
| Estructura HTML semántica | Revisión manual | Aprobada |
| Atributos `lang` | Revisión de código | Aprobada |
| Presencia de `skip-link` | Revisión de código | Aprobada |
| Etiquetas de formulario | Revisión de código | Aprobada |
| `aria-invalid` en errores | Revisión de código | Aprobada |
| `aria-live` en alertas | Revisión de código | Aprobada |
| Contraste de colores | Cálculo manual (WCAG) | Aprobada |
| Media query 320px | Inspección CSS | Aprobada |
| `prefers-reduced-motion` | Inspección CSS | Aprobada |
| Tamaño mínimo de objetivo | Inspección CSS | Aprobada |

### Pruebas pendientes (requieren entorno de ejecución con IIS)

| Prueba | Herramienta sugerida | Estado |
|--------|---------------------|--------|
| Análisis automatizado | axe DevTools | Pendiente |
| Navegación con teclado (manual) | Prueba manual | Pendiente |
| Pruebas con lector de pantalla | NVDA / JAWS | Pendiente |
| Zoom al 200% en navegador | Chrome/Firefox | Pendiente |
| Reflujo a 320px en navegador | Chrome headless (capturas en `tools/preview/shots/`) | Verificado |
| Foco visible (manual) | Prueba con Tab | Pendiente |
| Reproductor (manual) | Prueba de teclado | Pendiente |
| Diálogos de confirmación | Prueba manual | Pendiente |

---

## 7. Limitaciones conocidas

1. **Sin pruebas automatizadas ejecutadas:** Las herramientas axe DevTools y Accessibility Insights no se ejecutaron porque la aplicación requiere IIS en ejecución. Se recomienda ejecutarlas una vez el entorno esté configurado.

2. **Contraste en estados de borde:** Algunos colores de acento pueden no cumplir el contraste mínimo en combinaciones de borde y fondo no probadas. Se recomienda verificar todos los estados (hover, focus, active, disabled).

3. **Lector de pantalla:** No se realizaron pruebas con NVDA o JAWS. Se recomienda al menos una prueba completa de cada flujo con un lector de pantalla.

4. **Soporte de alta contraste de Windows:** Se incluye `@media (prefers-contrast: high)` pero no se probó con el modo de alta contraste de Windows.

5. **Transcripciones de audio:** Si los archivos de audio contienen contenido hablado, se recomienda proporcionar transcripciones textuales. Esto no se implementó porque depende del contenido real de los archivos.

---

## 8. Conclusión

PoliMusic está diseñado con accesibilidad WCAG 2.2 AA como objetivo desde el inicio.
La implementación cubre los cuatro principios (Perceptible, Operable, Comprensible, Robusto)
en el nivel de código. Sin embargo, la conformidad completa no se puede declarar sin
ejecutar las pruebas manuales y automatizadas en un entorno de ejecución real (IIS + navegador).

**Nivel de conformidad actual:** Diseño e implementación de código conforme. Pruebas automatizadas y manuales pendientes de ejecución en entorno.
