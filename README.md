<p align="center">
  <img src="docs/icon.png" alt="TDTPlayer Logo" width="128">
</p>

<h1 align="center">TDTPlayer (Tvheadend Native Player)</h1>

<p align="center">
  Reproductor nativo de TDT / IPTV basado en <strong>Python</strong>, <strong>PySide6 (Qt 6 / QML)</strong> y <strong>FFmpeg</strong>, diseñado para flujos MPEG-TS en bruto (<code>?profile=pass</code>) con baja latencia, EPG local en SQLite y compatibilidad total con <strong>Linux</strong> y <strong>Windows</strong>.
</p>

---

## Características principales

* **Multiplataforma real (Linux y Windows):**
  * **Linux:** Aceleración por hardware Intel `VA-API` con integración `xcb_egl`.
  * **Windows:** Aceleración por hardware `Direct3D 11` (`d3d11va`) y filtro de desentrelazado en tiempo real (`WindowsDeinterlacer`) para emisiones TDT `1080i`.
* **Modo Picture-in-Picture (PiP) / Always on Top:** Ventana flotante sin bordes siempre visible en primer plano, arrastrable y redimensionable con controles rápidos al pasar el ratón.
* **Guía EPG integrada:** Precarga asíncrona en SQLite (`epg_cache.db`), barra de progreso en tiempo real y parrilla completa de programación.
* **Caché local de logotipos:** Descarga en segundo plano de iconos de canales (`tvg-logo`).

---

## Controles y atajos de teclado

### Teclado

| Tecla | Acción |
| :--- | :--- |
| **`↑` / `↓`** | Canal anterior / siguiente |
| **`←` / `→`** | Subir / bajar volumen (`±5%`) |
| **`0` – `9`** | Marcación directa por número de canal |
| **`P`** | Activar / desactivar **Modo PiP** (*Siempre encima*) |
| **`E`** | Abrir / cerrar la **parrilla EPG** completa |
| **`M`** | Silenciar / activar audio (*Mute*) |
| **`Esc`** | Salir de PiP o cerrar paneles abiertos |

### Ratón y gestos

| Acción | Resultado |
| :--- | :--- |
| **Clic izquierdo** | Pausar / reanudar reproducción |
| **Doble clic** | Alternar pantalla completa (o salir del modo PiP) |
| **Rueda del ratón** | Cambiar de canal arriba / abajo |
| **Borde derecho** | Desplegar lista de canales (con vista previa EPG al pasar el cursor) |
| **Borde izquierdo** | Abrir menú de configuración y temas visuales |
| **Borde inferior** | Mostrar información del programa actual |
| **Arrastrar en PiP** | Mover la ventana flotante libremente; redimensionar desde la esquina inferior derecha |

---

## Requisitos previos (Windows)

* **Python 3.10+** (instalador oficial disponible en `python.org/downloads/windows/`).
* **Microsoft Visual C++ Redistributable (x64)** (requerido para cargar las librerías nativas de Qt 6: `aka.ms/vc14/vc_redist.x64.exe`).

---

## Instalación y ejecución en desarrollo

1. **Crear y activar el entorno virtual:**
   * **Windows:**
     ```bash
     python -m venv venv
     venv\Scripts\activate
     ```
   * **Linux:**
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

2. **Instalar dependencias:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Ejecutar la aplicación:**
   ```bash
   python main.py
   ```

---

## Compilar ejecutable (Windows y Linux)

1. **Activar el entorno virtual e instalar PyInstaller:**
   * **Windows:** `venv\Scripts\activate`
   * **Linux:** `source venv/bin/activate`

   ```bash
   pip install pyinstaller
   ```

2. **Generar la aplicación empaquetada:**

   * **Windows (CMD):**
     ```bash
     pyinstaller --noconfirm --onedir --windowed --name "TDTPlayer" ^
       --icon="docs/icon.ico" ^
       --add-data "qml;qml" ^
       --add-data "docs/icon.png;docs" ^
       --hidden-import "deinterlace_filter" ^
       --exclude-module "PySide6.QtWebEngineCore" ^
       --exclude-module "PySide6.QtWebEngineQuick" ^
       --exclude-module "PySide6.QtPdf" ^
       main.py
     ```

   * **Linux:**
     ```bash
     pyinstaller --noconfirm --onedir --windowed --name "TDTPlayer" \
       --icon="docs/icon.png" \
       --add-data "qml:qml" \
       --add-data "docs/icon.png:docs" \
       --exclude-module "PySide6.QtWebEngineCore" \
       --exclude-module "PySide6.QtWebEngineQuick" \
       --exclude-module "PySide6.QtPdf" \
       main.py
     ```

3. **Ejecutar el binario generado:**
   * **Windows:** `dist\TDTPlayer\TDTPlayer.exe`
   * **Linux:** `./dist/TDTPlayer/TDTPlayer`

---

## Mantenimiento de dependencias (Opcional)

Si añades nuevas librerías al proyecto y quieres regenerar `requirements.txt`:

```bash
python -m pip install pipreqs
python -m pipreqs.pipreqs . --force --ignore venv
```

---

## ☕ Apoya este proyecto

Si te gusta **TDTPlayer** o mejora tu experiencia viendo la televisión, ¡considera invitarme a un café!  
Tu apoyo me ayuda a mantener y mejorar este reproductor gratuito y de código abierto.

<p align="center">
  <a href="https://ko-fi.com/nekuneko">
    <img
      src="https://img.shields.io/badge/Ko--fi-Support%20me-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white"
      alt="Support me on Ko-fi"
    >
  </a>
</p>

