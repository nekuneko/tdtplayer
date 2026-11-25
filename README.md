<p align="center">
  <img src="docs/icon.png" alt="TDTPlayer Logo" width="128">
</p>

<h1 align="center">TDTPlayer</h1>

Reproductor nativo de TDT e IPTV para escritorio basado en **Python**, **PySide6 (Qt 6 / QML)** y **FFmpeg**. Compatible con **cualquier lista M3U / M3U8** (local o por URL) y optimizado especialmente para servidores **Tvheadend** (`?profile=pass`), con baja latencia, guía EPG local en SQLite, desentrelazado por hardware y soporte nativo para **Linux** y **Windows**.


> [!WARNING]
> **🚧 Proyecto en construcción (Work in Progress):** Este repositorio se encuentra en desarrollo activo y **no representa una versión definitiva**. La interfaz, la arquitectura interna, los controles y las funcionalidades están en constante evolución y pueden cambiar o estar sujetos a modificaciones sin previo aviso.

---

## Capturas de pantalla

| Vista principal | Menú de configuración |
| :---: | :---: |
| ![Interfaz principal, lista de canales y guía EPG](docs/interface.png) | ![Panel de configuración y temas visuales](docs/settings.png) |
| *Lista de canales lateral, cajón EPG inferior, reloj y captura rápida* | *Selector de 7 temas visuales, captura e importación M3U* |


---

## Características principales

* **Interfaz moderna y responsiva:** Paneles flotantes redondeados que encogen y desplazan suavemente el reproductor sin tapar la emisión, adaptándose tanto a pantalla completa como a ventanas compactas y 7 paletas visuales personalizables.
* **Multiplataforma real (Linux y Windows):**
  * **Linux:** Aceleración por hardware Intel `VA-API` con integración `xcb_egl`.
  * **Windows:** Aceleración por hardware `Direct3D 11` (`d3d11va`) y filtro de desentrelazado en tiempo real (`WindowsDeinterlacer`) para emisiones TDT `1080i`.
* **Captura de pantalla instantánea:** Extracción del fotograma limpio directamente desde el *sink* de vídeo en máxima calidad PNG (`Imágenes/TdtPlayer`) sin menús superpuestos ni interrupciones en la reproducción.
* **Modo Picture-in-Picture (PiP) / Always on Top:** Ventana flotante sin bordes siempre visible en primer plano, arrastrable y redimensionable desde cualquiera de sus 4 esquinas y 4 bordes manteniendo la relación de aspecto `16:9` sin franjas negras.
* **Guía EPG integrada:** Precarga asíncrona en SQLite (`epg_cache.db`), barra de progreso en tiempo real y parrilla completa de programación (`Ahora` / `A Continuación`).
* **Caché local de logotipos:** Descarga en segundo plano de iconos de canales (`tvg-logo`).

---

## Controles y atajos de teclado

### Teclado

| Tecla | Acción |
| :--- | :--- |
| **`↑` / `↓`** | Canal anterior / siguiente |
| **`←` / `→`** | Subir / bajar volumen (`±5%`) |
| **`0` – `9`** | Marcación directa por número de canal |
| **`Espacio`** | Pausar / reanudar reproducción |
| **`S`** | **Capturar pantalla** del fotograma actual en PNG (`Imágenes/TdtPlayer`) |
| **`P`** | Activar / desactivar **Modo PiP** (*Siempre encima*) |
| **`E`** | Abrir / cerrar la **parrilla EPG** completa |
| **`Tab`** | Alternar entre *Emitiéndose Ahora* y *A Continuación* (dentro de la parrilla EPG) |
| **`M`** | Silenciar / activar audio (*Mute*) |
| **`Esc`** | Salir de PiP o cerrar paneles abiertos |

### Ratón y gestos

| Acción | Resultado |
| :--- | :--- |
| **Clic izquierdo** | Pausar / reanudar reproducción |
| **Doble clic** | Alternar pantalla completa (o salir del modo PiP) |
| **Rueda del ratón** | Cambiar de canal arriba / abajo (o ajustar volumen sobre el cajón inferior) |
| **Borde derecho** | Desplegar lista de canales (con vista previa EPG al pasar el cursor) |
| **Borde izquierdo** | Abrir menú de configuración, temas visuales y captura de pantalla |
| **Borde inferior** | Mostrar información del programa actual, volumen y botón de captura rápida |
| **Arrastrar en PiP** | Mover la ventana flotante libremente; redimensionar desde cualquiera de sus 4 esquinas o bordes |

---

## Requisitos previos (Windows)

* **Python 3.10+** (instalador oficial disponible en `python.org/downloads/windows/`).
* **Microsoft Visual C++ Redistributable (x64)** (requerido para cargar las librerías nativas de Qt 6: `aka.ms/vc14/vc_redist.x64.exe`).

---

## Instalación y ejecución en desarrollo

### Windows (CMD)
```bat
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### Linux (Bash)
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

---

## Compilar ejecutable

### Windows (CMD)
```bat
venv\Scripts\activate
pip install pyinstaller
pyinstaller --noconfirm --onedir --windowed --name "TDTPlayer" ^
  --icon="docs/icon.ico" ^
  --add-data "qml;qml" ^
  --add-data "docs/icon.png;docs" ^
  --hidden-import "deinterlace_filter" ^
  --hidden-import "screenshot_helper" ^
  --exclude-module "PySide6.QtWebEngineCore" ^
  --exclude-module "PySide6.QtWebEngineQuick" ^
  --exclude-module "PySide6.QtPdf" ^
  main.py
```
Ejecutar: `dist\TDTPlayer\TDTPlayer.exe`

### Linux (Bash)
```bash
source venv/bin/activate
pip install pyinstaller
pyinstaller --noconfirm --onedir --windowed --name "TDTPlayer" \
  --icon="docs/icon.png" \
  --add-data "qml:qml" \
  --add-data "docs/icon.png:docs" \
  --hidden-import "screenshot_helper" \
  --exclude-module "PySide6.QtWebEngineCore" \
  --exclude-module "PySide6.QtWebEngineQuick" \
  --exclude-module "PySide6.QtPdf" \
  main.py
```
Ejecutar: `./dist/TDTPlayer/TDTPlayer`

---

## Mantenimiento de dependencias (Opcional)

Si añades nuevas librerías al proyecto y quieres regenerar `requirements.txt`:

```bash
python -m pip install pipreqs
python -m pipreqs.pipreqs . --force --ignore venv
```


---

## Licencia

Este proyecto se distribuye bajo la licencia **GNU General Public License v3.0 (GPL-3.0)**. Consulta el archivo [LICENSE](LICENSE) para más detalles.

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

