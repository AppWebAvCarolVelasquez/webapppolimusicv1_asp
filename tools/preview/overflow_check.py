# Generates chk-*.html copies (preview + overflow probe) and check.html harness.
import io
import os

BASE = os.path.dirname(os.path.abspath(__file__))

PAGES = [
    ("login", "preview-login.html"),
    ("denied", "preview-denied.html"),
    ("songs", "preview-songs.html"),
    ("admin", "preview-admin.html"),
    ("form", "preview-form.html"),
    ("delete", "preview-delete.html"),
]

PROBE = """
<script>
window.addEventListener('load', function () {
  var iw = window.innerWidth;
  var sw = document.documentElement.scrollWidth;
  var payload = { name: '%s', iw: iw, sw: sw, over: sw > iw };
  try { parent.postMessage(JSON.stringify(payload), '*'); } catch (e) {}
  var d = document.createElement('div');
  d.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:99999;background:#000;color:#0f0;font:16px monospace;padding:6px';
  d.textContent = '%s  iw=' + iw + '  sw=' + sw + (sw > iw ? '  OVERFLOW' : '  OK');
  document.body.appendChild(d);
});
</script>
"""

for name, src in PAGES:
    with io.open(os.path.join(BASE, src), encoding="utf-8") as f:
        html = f.read()
    probe = PROBE % (name, name)
    html = html.replace("</body>", probe + "\n</body>")
    with io.open(os.path.join(BASE, "chk-%s.html" % name), "w", encoding="utf-8") as f:
        f.write(html)

HARNESS = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>Overflow check</title>
<style>
  body { margin: 0; background: #111; color: #0f0; font: 18px monospace; }
  #out { white-space: pre; padding: 10px; background: #000; position: sticky; top: 0; z-index: 10; }
  iframe { display: block; border: 0; }
</style>
</head>
<body>
<div id="out">waiting...</div>
<div id="frames"></div>
<script>
var files = %s;
var results = [];
var out = document.getElementById('out');
window.addEventListener('message', function (e) {
  try {
    var d = JSON.parse(e.data);
    results.push(d);
    out.textContent = results.map(function (r) {
      return r.name + ': iw=' + r.iw + ' sw=' + r.sw + ' ' + (r.over ? 'OVERFLOW' : 'OK');
    }).join('\\n');
  } catch (err) {}
});
files.forEach(function (f) {
  var i = document.createElement('iframe');
  i.src = f; i.width = 320; i.height = 2400;
  document.getElementById('frames').appendChild(i);
});
</script>
</body>
</html>
"""

files_js = "[" + ", ".join("'chk-%s.html'" % n for n, _ in PAGES) + "]"
with io.open(os.path.join(BASE, "check.html"), "w", encoding="utf-8") as f:
    f.write(HARNESS % files_js)

print("generated %d chk pages + check.html" % len(PAGES))
