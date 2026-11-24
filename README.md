# TdtPlayer (Tvheadend Native Player)

Reproductor nativo de TDT / IPTV basado en Python, PySide6 (Qt 6 / QML) y FFmpeg, compatible con **Linux** y **Windows**.

## Requisitos previos (Windows)

* **Python 3.10+** (recomendado usar el instalador oficial de [python.org](https://python.org)).
* **[Microsoft Visual C++ Redistributable (x64)](https://aka.ms)** (necesario para cargar las librerías nativas de Qt 6).

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
   *(Nota: En PowerShell sustituye el carácter de salto de línea `^` por `` ` `` o ejecútalo en una sola línea).*

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
