# TdtPlayer (Tvheadend Native Player)

Reproductor nativo de TDT / IPTV basado en **Python**, **PySide6 (Qt 6 / QML)** y **FFmpeg**, diseñado para reproducir flujos MPEG-TS en bruto (`?profile=pass`) de Tvheadend con baja latencia, EPG local en SQLite y compatibilidad total con **Linux** y **Windows**.

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

* **Python 3.10+** (recomendado usar el instalador oficial de [python.org](https://python.org)).
* **[Microsoft Visual C++ Redistributable (x64)](https://aka.ms)** (requerido para cargar las librerías nativas de Qt 6).

---

## Instalación y ejecución en desarrollo

1. **Crear y activar el entorno virtual:**
   ```bash
   python -m venv venv
   venv\Scripts\activate
   ```
   *(En Linux: `python3 -m venv venv && source venv/bin/activate`)*

2. **Instalar dependencias:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Ejecutar la aplicación:**
   ```bash
   python main.py
   ```

---

## Compilar ejecutable (`.exe`) para Windows

1. **Activar el entorno virtual e instalar PyInstaller:**
   ```bash
   venv\Scripts\activate
   pip install pyinstaller
   ```

2. **Generar la aplicación empaquetada (sin ventana de consola):**
   ```bash
   pyinstaller --noconfirm --onedir --windowed --name "TdtPlayer" ^
     --add-data "main.qml;." ^
     --add-data "qml;qml" ^
     --hidden-import "deinterlace_filter" ^
     --exclude-module "PySide6.QtWebEngineCore" ^
     --exclude-module "PySide6.QtWebEngineQuick" ^
     --exclude-module "PySide6.QtPdf" ^
     main.py
   ```

3. **Ejecutar el binario generado:**
   ```bash
   dist\TdtPlayer\TdtPlayer.exe
   ```

---

## Mantenimiento de dependencias (Opcional)

Si añades nuevas librerías al proyecto y quieres regenerar `requirements.txt`:

```bash
python -m pip install pipreqs
python -m pipreqs.pipreqs . --force --ignore venv
```
