===================================================================
REQUISITOS FUNCIONALES (QUÉ HACE LA APP)
===================================================================

1. CARGA E IMPORTACIÓN DE CANALES Y PERSISTENCIA
- Abre archivos de listas de canales IPTV con extensión .m3u o .m3u8 o mediante URL remota.
- Usa un cuadro de diálogo nativo del sistema operativo (FileDialog) o campo de URL con persistencia automática en Settings.
- Lee el archivo de texto línea por línea para extraer metadatos mediante expresiones regulares.
- Extrae el nombre del canal de televisión de forma automática.
- Extrae la dirección URL del flujo multimedia del canal (?profile=pass).
- Extrae el enlace de internet con el logotipo (tvg-logo) y los descarga/cachea localmente en disco.
- Extrae el número de dial o posición asignada (tvg-chno).
- Persiste entre sesiones el último canal sintonizado, la posición/tamaño de la ventana, el estado de pantalla completa y el tema visual elegido.

2. REPRODUCCIÓN MULTIMEDIA MULTIPLATAFORMA Y AUTO-RECUPERACIÓN
- Reproduce los canales de televisión usando el motor nativo de Qt 6 Multimedia (MediaPlayer + FFmpeg).
- Soporta aceleración gráfica por hardware multiplataforma:
  * Linux: Intel VA-API con integración EGL (xcb_egl).
  * Windows: Direct3D 11 (d3d11va) y filtro de desentrelazado en tiempo real (WindowsDeinterlacer) para señales TDT 1080i.
- Configura sondas ampliadas de FFmpeg (probesize/analyzeduration) y descarte de paquetes corruptos (fflags=discardcorrupt) para flujos MPEG-TS en bruto sin saturar el procesador.
- Auto-reconexión inteligente (streamReconnectTimer de 800 ms): si el flujo directo sufre un micro-corte o error de red sin haber sido pausado por el usuario, reconecta automáticamente el stream.
- Pausa y reanuda la reproducción con clic izquierdo sobre el vídeo (con filtro de retardo de 220 ms para no interferir con el doble clic) o con la tecla Espacio.
- Alterna pantalla completa haciendo doble clic sobre el vídeo, pulsando las teclas F o F11, o restaura la ventana si está en modo PiP.
- Si se cambia de canal estando el vídeo detenido voluntariamente, mantiene el reproductor pausado mientras actualiza los metadatos OSD y EPG.

3. ZAPPING CONTINUO, PREVISUALIZACIÓN Y CANCELACIÓN
- Implementa navegación circular infinita por todos los canales (↑ / ↓ en cualquier modo, o rueda del ratón sobre el área de vídeo en modo ventana/pantalla completa; desactivada en PiP para evitar cambios accidentales).
- Zapping sin pantalla en negro: mantiene reproduciendo el canal actual de forma fluida hasta que transcurren 750 ms (zappingTimer) sin nuevas pulsaciones o giros de rueda, momento en que sintoniza el flujo definitivo.
- Cancelación inmediata con Esc: si se pulsa Esc durante la ventana de 750 ms antes de sintonizar, cancela el cambio, revierte el selector y los metadatos al canal en emisión y evita cualquier corte de vídeo.
- Con la barra lateral de canales abierta a la derecha: las teclas ↑ / ↓ y el ratón solo previsualizan canales y actualizan la guía EPG sin cortar la emisión en curso; la sintonización definitiva se ejecuta únicamente al pulsar Enter o hacer clic en el canal (si se cierra el panel sin confirmar, se cancela la previsualización).
- Marcación directa por dial: al pulsar teclas numéricas (0–9) abre un popup modal centrado que filtra dígitos y salta directamente al canal al confirmar.

4. INTERFAZ MODERNA DE PANELES FLOTANTES, OSD Y RELOJ
- Diseño responsivo basado en tarjetas flotantes redondeadas (radius: 16) que encogen y desplazan suavemente el reproductor de vídeo sin tapar la emisión, adaptándose tanto a pantalla completa como a ventanas compactas.
- Persiana inferior unificada (EpgDrawer): muestra logotipo, dial, nombre del canal, reloj digital en píldora (HH:MM), píldora vectorial de estado PAUSADO cuando la emisión está detenida, píldora horaria del programa actual ([HH:MM ➔ HH:MM]), barra de progreso en tiempo real fija sobre la sinopsis desplazable, botón vectorial de mute/silencio, control deslizante de volumen y botón rápido de captura.
- Se despliega automáticamente durante 3 segundos al hacer zapping o al acercar el ratón al borde inferior, y permanece fija mientras el cursor esté dentro del cajón o de la barra lateral.
- Muestra un indicador OSD translúcido centrado al modificar el volumen (← / →, slider o rueda sobre el cajón) o alternar silencio (M).
- Oculta automáticamente el cursor del ratón a nivel de sistema operativo (CursorHelper / QGuiApplication.setOverrideCursor) tras 5 segundos (5000 ms) de inactividad en modo ventana/pantalla completa cuando no hay paneles desplegados, reapareciendo al instante al mover el puntero.

5. BARRA LATERAL DE CANALES Y TEMAS VISUALES
- Barra lateral derecha (ChannelSidebar): oculta por defecto y desplegable al acercar el ratón al borde derecho (50 px); muestra cada canal en tarjeta individual con logotipo, dial, nombre, programa actual y barra de progreso.
- Sincroniza automáticamente el centrado de la lista sobre el canal activo tanto en navegación por teclado como con rueda sobre el vídeo, y permite exploración libre con rueda sobre el propio panel con vista previa EPG tras 150 ms de reposo del cursor (debounce).
- Panel izquierdo de configuración (ConfigSidebar): desplegable desde el borde izquierdo (50 px) con selector de 7 temas visuales (Color Cinemático, Alto Contraste B/N, Escarcha Nórdica, Monokai Ámbar, Rojo Vampiro, Cyberpunk Neón y Estilo Cine Rojo), captura de pantalla, importación de listas M3U y cierre de aplicación.
- Motor de escala dinámica HiDPI (Theme.qml) que adapta fuentes, márgenes y radios al factor de escala de pantalla (Screen.devicePixelRatio).

6. PARRILLA EPG COMPLETA Y MODO PICTURE-IN-PICTURE (PiP)
- Parrilla EPG completa (tecla E): superposición a pantalla completa con reloj digital, búsqueda/listado de todos los canales y conmutación instantánea con Tab entre "Emitiéndose Ahora" y "A Continuación", permitiendo sintonizar con clic o Enter y cerrar con E o Esc.
- Modo Picture-in-Picture (tecla P): ventana flotante sin bordes siempre encima (WindowStaysOnTopHint), arrastrable desde cualquier punto, redimensionable desde sus 4 esquinas y 4 bordes manteniendo bloqueada la relación de aspecto 16:9 sin franjas negras ni encogimiento de ventana al restaurar, con controles vectoriales flotantes (restaurar, silenciar y pausar/reanudar iluminados con el color de alerta del tema cuando están activos) y salida mediante P, doble clic o botón restaurar.

7. CAPTURA DE PANTALLA INSTANTÁNEA
- Permite capturar el fotograma limpio de vídeo (sin menús ni OSD superpuestos) pulsando la tecla S, el botón de cámara en el cajón inferior o el botón en el menú de configuración.
- Extrae la imagen directamente desde QVideoSink y la guarda en máxima calidad PNG sin pérdida en un hilo secundario (para evitar congelaciones en el vídeo) dentro de la carpeta multiplataforma Imágenes/TdtPlayer (Pictures/TdtPlayer).
- Muestra un aviso flotante instantáneo en pantalla (ScreenshotToast) confirmando el nombre del archivo guardado.


===================================================================
REQUISITOS TÉCNICOS Y ARQUITECTURA (CÓMO LO HACE)
===================================================================

1. DIVISIÓN DE CAPAS Y MODULARIDAD
- Separa estrictamente la lógica de datos, red, hardware, cursor y captura en Python de la máquina de estados y presentación en QML.
- Componentes QML atómicos y especializados (< 180 líneas por archivo) con carga diferida (Loader) para vistas pesadas.

2. COMPONENTES DEL NÚCLEO (PYTHON)
- main.py: configura variables de entorno nativas antes de inicializar PySide6, aloja la clase CursorHelper (que controla QGuiApplication.setOverrideCursor(Qt.BlankCursor) y restoreOverrideCursor() a nivel de sistema operativo), registra contextos QML (channelModel, screenshotHelper, cursorHelper) y enlaza QMediaPlayer y QVideoSink.
- channel_model.py: hereda de QAbstractListModel e indexa los canales en RAM exponiendo roles (NameRole, UrlRole, LogoRole, ChNoRole); detecta host/puerto de Tvheadend, ejecuta precarga asíncrona en segundo plano (EpgPreloaderWorker) con caché persistente en SQLite (epg_cache.db) y responde consultas EPG en 0 ms (fetch_current_epg y fetch_next_epg).
- deinterlace_filter.py: aplica desentrelazado por hardware/software en tiempo real sobre QVideoSink en Windows.
- screenshot_helper.py: captura QVideoFrame desde QVideoSink, lo convierte a QImage en memoria y delega la escritura PNG a un hilo daemon en segundo plano emitiendo señales de confirmación/error a QML.

3. CONTROLADORES Y GESTORES LÓGICOS (QML)
- PlaybackController.qml: QtObject central de estados y temporizadores (zappingTimer de 750 ms, epgAutoHideTimer de 3000 ms, osdTimer de 3000 ms, volumeOsdTimer de 2000 ms); gestiona sintonización continua, previsualización (previewChannel), cancelación (cancelPendingZapping) y control de volumen/mute en hardware.
- KeyboardHandler.qml: captura global de teclado (focus: true) con aislamiento para popups, parrilla EPG, navegación/confirmación en el sidebar y alternancia de pantalla completa (F / F11).
- VideoGesturesLayer.qml: orquesta gestos de ratón mediante MouseArea con temporizador de clic simple (singleClickTimer de 220 ms) para evitar pausas accidentales en doble clic, DragHandler para mover PiP, WheelHandler para zapping (desactivado en PiP) y áreas sensibles de bordes.
- PipWindowController.qml: gestiona la transición a modo PiP, persistencia y restauración exacta de geometría de ventana en Settings (protegida con isAdjustingAspect y Qt.callLater) y bloqueo de proporción 16:9 al redimensionar.
- SidebarHoverSync.qml y EpgBootstrapper.qml: desacoplan el debounce de hover (150 ms) del sidebar y la sincronización de arranque/temporizadores del EPG.

4. COMPONENTES VISUALES MODULARES (QML)
- main.qml: ventana raíz con Theme, Settings, FocusScope principal y Loader asíncrono para EpgGridOverlay.
- VideoPlayerView.qml: contenedor del MediaPlayer y VideoOutput con animación fluida de márgenes y radios al abrir paneles laterales o inferiores, temporizador de auto-reconexión ante micro-cortes de stream (streamReconnectTimer de 800 ms) y capa superior pasiva (cursorShield) con temporizador de inactividad de ratón de 5000 ms conectado a cursorHelper.
- EpgDrawer.qml, EpgHeaderRow.qml, EpgProgramContent.qml, EpgProgressRow.qml, EpgVolumeSlider.qml y ClockWidget.qml: componen la tarjeta inferior de información con seguimiento por HoverHandler, reloj en píldora, píldora vectorial de estado PAUSADO, progreso en directo fijo sobre la sinopsis, botón vectorial de mute y control de audio.
- ChannelSidebar.qml y ChannelDelegate.qml: lista virtualizada con reciclaje de ítems (reuseItems: true, cacheBuffer: 0) para minimizar consumo de VRAM.
- ConfigSidebar.qml, ConfigThemeList.qml y ConfigActionButton.qml: panel izquierdo flotante con muestra de colores reales por tema e iconos vectoriales dibujados en Canvas/QML.
- EpgGridOverlay.qml, EpgGridDelegate.qml y EpgGridProgramColumn.qml: parrilla EPG completa de dos pestañas con soporte de teclado y rueda.
- PipOverlayHud.qml, PipIconButton.qml y PipResizeHandles.qml: HUD vectorial del modo PiP con estado de alerta semántico del tema (isAlert) para pausa/mute y 8 zonas de redimensionamiento en bordes y esquinas.
- VolumeIndicator.qml, ChannelNumPopup.qml, EpgDataLoader.qml y ScreenshotToast.qml: superposiciones modales y notificaciones instantáneas.
