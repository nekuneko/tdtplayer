// main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 1024
    height: 768
    visible: true
    title: "Tvheadend Native Player"

    property int currentChannelIndex: 0
    property bool isFullScreen: false
    property bool isVoluntarilyStopped: false
    
    property string osdChannelName: ""
    property string osdChannelLogo: ""
    property string osdChannelNo: ""

    // Propiedades optimizadas para el EPG dinámico
    property string epgTitle: "Sintonizando canal..."
    property string epgDescription: "Buscando información del evento actual en el flujo de Tvheadend..."

    function playChannel(index) {
        if (channelModel.rowCount() === 0) return;
        
        if (index < 0) index = channelModel.rowCount() - 1;
        else if (index >= channelModel.rowCount()) index = 0;
        
        currentChannelIndex = index;
        isVoluntarilyStopped = false;
        
        // Reiniciamos los textos de la guía para el nuevo canal sintonizado
        epgTitle = "Sintonizando canal..."
        epgDescription = "Buscando información del evento actual en el flujo de Tvheadend..."
        
        osdChannelName = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 1);
        osdChannelLogo = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 3);
        osdChannelNo = channelModel.data(channelModel.index(index, 0), Qt.UserRole + 4);
        
        osdTimer.restart();
        osdPanel.opacity = 1.0;

        mediaPlayer.source = channelModel.get_url_at(index);
        mediaPlayer.play();
        
        // Arrancamos el escáner del buffer de la guía de televisión
        epgPoller.restart();
    }

    function playChannelByNumber(numberStr) {
        var count = channelModel.rowCount();
        for (var i = 0; i < count; i++) {
            if (channelModel.data(channelModel.index(i, 0), Qt.UserRole + 4) === numberStr) {
                window.playChannel(i);
                return;
            }
        }
        var targetIndex = parseInt(numberStr) - 1;
        if (!isNaN(targetIndex) && targetIndex >= 0 && targetIndex < count) {
            window.playChannel(targetIndex);
        }
    }

    Timer {
        id: osdTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: osdPanel.opacity = 0.0
    }

    // ACTUALIZADO: Consulta la API de Tvheadend usando la IP dinámica extraída por Python
    Timer {
        id: epgPoller
        interval: 300 
        running: false
        repeat: false
        onTriggered: {
            if (window.osdChannelName !== "") {
                // Llamamos a Python para que traiga el arreglo [Título, Descripción]
                var epgData = channelModel.fetch_current_epg(window.osdChannelName);
                
                // Extraemos la posición 0 para el Título y la posición 1 para la sinopsis
                window.epgTitle = epgData[0];
                window.epgDescription = epgData[1];
            }
        }
    }



    Item {
        anchors.fill: parent
        focus: true
        
        Keys.onUpPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onDownPressed: window.playChannel(window.currentChannelIndex + 1)
        Keys.onLeftPressed: window.playChannel(window.currentChannelIndex - 1)
        Keys.onRightPressed: window.playChannel(window.currentChannelIndex + 1)
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Space) {
                if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    window.isVoluntarilyStopped = true;
                    mediaPlayer.stop();
                } else {
                    window.isVoluntarilyStopped = false;
                    mediaPlayer.play();
                }
                event.accepted = true;
            }
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && mediaPlayer.playbackState !== MediaPlayer.PlayingState && !channelNumPopup.opened) {
                window.isVoluntarilyStopped = false;
                mediaPlayer.play();
                event.accepted = true;
            }
            else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !channelNumPopup.opened) {
                channelNumPopup.open();
                numInputField.text = event.text;
                numInputField.forceActiveFocus();
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Escape && window.isFullScreen && !channelNumPopup.opened) {
                if (sidebar.sidebarForceOpen) {
                    sidebar.sidebarForceOpen = false;
                } else {
                    window.visibility = Window.Windowed;
                    window.isFullScreen = false;
                }
                event.accepted = true;
            }
        }
    }

    FocusScope {
        id: mainFocusScope
        anchors.fill: parent

        MediaPlayer {
            id: mediaPlayer
            audioOutput: AudioOutput {}
            videoOutput: videoOutput
        }

        // Capa 1: El Reproductor de Vídeo (Ocupa siempre toda la pantalla o ventana)
        Rectangle {
            id: videoContainer
            anchors.left: parent.left
            anchors.right: (sidebar.visible && !window.isFullScreen) ? sidebar.left : parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: "black"

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit

                TapHandler {
                    onDoubleTapped: {
                        if (window.isFullScreen) {
                            window.visibility = Window.Windowed;
                            window.isFullScreen = false;
                        } else {
                            window.visibility = Window.FullScreen;
                            window.isFullScreen = true;
                        }
                    }
                }

                                // ================= DRWER INFERIOR DE EPG NATIVO =================
                // Zona interactiva invisible en el borde inferior (Hover en pantalla completa)
                MouseArea {
                    id: bottomEdgeArea
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: window.isFullScreen ? 40 : 0 // Zona activa de 40 píxeles abajo
                    hoverEnabled: true
                    
                    // Al posar el ratón abajo, abre la persiana del EPG
                    onEntered: {
                        if (window.isFullScreen) {
                            epgDrawer.epgForceOpen = true
                        }
                    }
                }

                // El contenedor visual del Drawer de EPG (Se comporta como MouseArea para onExited)
                MouseArea {
                    id: epgDrawer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    
                    property bool epgForceOpen: false
                    // Visible en modo ventana o si pasas el ratón abajo en pantalla completa
                    visible: !window.isFullScreen || epgForceOpen
                    height: visible ? 130 : 0 // Altura del Drawer inferior
                    
                    hoverEnabled: true
                    // Al sacar el ratón del panel inferior, se esconde automáticamente
                    onExited: {
                        if (window.isFullScreen) {
                            epgForceOpen = false
                        }
                    }

                    Behavior on height {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }

                    // Fondo translúcido premium Slate 900
                    Rectangle {
                        anchors.fill: parent
                        color: "#0F172A"
                        opacity: 0.95
                        border.color: "#3B82F6"
                        border.width: 1
                    }

                    // Contenido del EPG
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Text {
                                text: "EN ANTEPROYECTO (EPG NATIVO):"
                                color: "#3B82F6"
                                font.bold: true
                                font.pointSize: 9
                            }
                            
                            Text {
                                text: " • Canal " + window.osdChannelNo
                                color: "#64748B"
                                font.pointSize: 9
                                visible: window.osdChannelNo !== ""
                            }
                        }

                        Text {
                            text: window.epgTitle
                            color: "white"
                            font.bold: true
                            font.pointSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: window.epgDescription
                            color: "#94A3B8"
                            font.pointSize: 10
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
                // ===================================================================

                
                // Zona interactiva en el borde derecho: Hover en pantalla completa
                MouseArea {
                    id: rightEdgeSwipeArea
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: window.isFullScreen ? 50 : 0 
                    hoverEnabled: true
                    
                    onEntered: {
                        if (window.isFullScreen) {
                            sidebar.sidebarForceOpen = true
                        }
                    }
                }

                // Zona invisible sobre el vídeo para cerrar el menú haciendo clic fuera
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: sidebar.width
                    visible: window.isFullScreen && sidebar.sidebarForceOpen
                    onClicked: sidebar.sidebarForceOpen = false
                }

                // Cartel de fondo para estados de pausa o buffer
                Text {
                    anchors.centerIn: parent
                    text: window.isVoluntarilyStopped 
                          ? "Stream Detenido\nPulse Espacio o Enter para reanudar" 
                          : "Sintonizando canal...\nCargando flujo de Tvheadend"
                    color: window.isVoluntarilyStopped ? "#94A3B8" : "#3B82F6"
                    font.pointSize: window.isFullScreen ? 18 : 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                    visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
                }
                
                                // Panel flotante del OSD (ACTUALIZADO: Posicionado arriba a la izquierda)
                Rectangle {
                    id: osdPanel
                    
                    // CORRECCIÓN DE ANCLAJES: Movido de la parte inferior a la parte superior izquierda
                    anchors.top: parent.top
                    anchors.left: parent.left
                    
                    // Margen de separación dinámico para que no se pegue al borde del monitor en pantalla completa
                    anchors.topMargin: window.isFullScreen ? 40 : 20
                    anchors.leftMargin: window.isFullScreen ? 40 : 20
                    
                    // Reducimos el ancho para que sea un cuadro compacto arriba a la izquierda en vez de una barra ancha
                    width: 380 
                    height: 85
                    radius: 12
                    color: "#1E293B" 
                    border.color: "#3B82F6" 
                    border.width: 1.5
                    opacity: 0.0 
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        Image {
                            source: window.osdChannelLogo !== "" ? window.osdChannelLogo : ""
                            sourceSize.width: 45 // Escalado ligeramente más compacto para la esquina
                            sourceSize.height: 45
                            Layout.preferredWidth: 45
                            Layout.preferredHeight: 45
                            fillMode: Image.PreserveAspectFit
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "image://theme/media-playback-start"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: window.osdChannelName
                                color: "white"
                                font.bold: true
                                font.pointSize: 14 // Fuente ajustada para balancear el diseño compacto
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: window.osdChannelNo !== "" ? "CH " + window.osdChannelNo : "Tvheadend Stream"
                                color: "#94A3B8"
                                font.pointSize: 10
                            }
                        }
                    }
                } // Fin de osdPanel

            } // Fin de VideoOutput
        } // Fin de videoContainer
        
        // Capa 2: El Panel Lateral de Canales 
        MouseArea {
            id: sidebar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            property bool sidebarForceOpen: false
            visible: !window.isFullScreen || sidebarForceOpen
            width: visible ? 290 : 0

            hoverEnabled: true

            // ACTUALIZADO: Al sacar el ratón del menú lateral, esconde tanto el menú como el EPG inferior
            onExited: {
                if (window.isFullScreen) {
                    sidebarForceOpen = false
                    epgDrawer.epgForceOpen = false // NUEVO: Cierra la persiana del EPG de forma sincronizada
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#111827"
            }

            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }

            ListView {
                id: channelListView
                anchors.fill: parent
                clip: true

                // ACTUALIZADO: Forzamos un número virtual alto fijo para activar el scroll infinito real
                model: 1000000

                // Sincroniza el centrado automático basándose en el desplazamiento virtual intermedio
                Connections {
                    target: window
                    function onCurrentChannelIndexChanged() {
                        var count = channelModel.rowCount();
                        if (count === 0) return;
                        
                        var currentScrollIndex = channelListView.indexAt(0, channelListView.contentY)
                        var baseVirtual = currentScrollIndex - (currentScrollIndex % count)
                        var targetVirtual = baseVirtual + window.currentChannelIndex
                        
                        channelListView.positionViewAtIndex(targetVirtual, ListView.Center)
                    }
                }

                delegate: ItemDelegate {
                    id: channelItemDelegate
                    width: 290
                    height: 60
                    hoverEnabled: true
                    
                    // FÓRMULA ANTIBLOQUEO: Convierte el índice virtual de 1 millón en el índice real de tu M3U
                    property int realIndex: (channelModel && channelModel.rowCount() > 0) ? (index % channelModel.rowCount()) : 0
                    
                    highlighted: window.currentChannelIndex === realIndex

                    background: Rectangle {
                        color: channelItemDelegate.highlighted 
                               ? "#1E3A8A" 
                               : (channelItemDelegate.hovered ? "#334155" : "transparent") 
                        opacity: channelItemDelegate.highlighted ? 0.4 : 0.6
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: RowLayout {
                        width: 270
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Image {
                            // Leemos los datos de Python usando el realIndex circular calculado
                            source: (channelModel && channelModel.rowCount() > 0) 
                                    ? channelModel.data(channelModel.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 3) 
                                    : ""
                            sourceSize.width: 35
                            sourceSize.height: 35
                            Layout.preferredWidth: 35
                            Layout.preferredHeight: 35
                            fillMode: Image.PreserveAspectFit
                            
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = "image://theme/media-playback-start"
                                }
                            }
                        }

                        Text {
                            text: (channelModel && channelModel.rowCount() > 0) 
                                  ? channelModel.data(channelModel.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 1) 
                                  : ""
                            color: channelItemDelegate.highlighted 
                                   ? "#3B82F6" 
                                   : (channelItemDelegate.hovered ? "#FFFFFF" : "#E2E8F0") 
                            font.bold: channelItemDelegate.highlighted
                            font.pointSize: 11
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                                                // ACTUALIZADO: Formatea los números para que siempre muestren dos dígitos (ej: CH 00, CH 01)
                        Text {
                            property string chNoStr: (channelModel && channelModel.rowCount() > 0) 
                                                     ? channelModel.data(channelModel.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 4) 
                                                     : ""
                                                     
                            // Si la cadena está vacía, calculamos el número según su índice real en la lista
                            property string finalChNo: chNoStr !== "" ? chNoStr : channelItemDelegate.realIndex.toString()

                            // Aplica la máscara de dos dígitos agregando ceros a la izquierda de forma automática
                            text: "CH " + finalChNo.padStart(2, '0')
                            
                            color: channelItemDelegate.highlighted 
                                   ? "#3B82F6" 
                                   : (channelItemDelegate.hovered ? "#94A3B8" : "#64748B")
                            font.pointSize: 9
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                    }

                    onClicked: {
                        window.playChannel(channelItemDelegate.realIndex)
                        sidebar.sidebarForceOpen = false 
                    }
                    
                    // ACTUALIZADO: Cambia dinámicamente el EPG inferior al pasar el ratón por encima de la fila
                    onHoveredChanged: {
                        if (hovered && (channelModel && channelModel.rowCount() > 0)) {
                            var hoveredChannelName = channelModel.data(channelModel.index(channelItemDelegate.realIndex, 0), Qt.UserRole + 1);
                            
                            if (hoveredChannelName !== "") {
                                var epgData = channelModel.fetch_current_epg(hoveredChannelName);
                                window.epgTitle = epgData[0];
                                window.epgDescription = epgData[1];
                                
                                // NUEVO: Si estás en pantalla completa y exploras la lista, abre el EPG inferior automáticamente
                                if (window.isFullScreen) {
                                    epgDrawer.epgForceOpen = true
                                }
                            }
                        }
                    }
                } // Fin de ItemDelegate
            } // Fin de ListVi
        }
    } // Fin de mainFocusScope

    // POPUP MODAL: Marcador Numérico Inteligente
    Popup {
        id: channelNumPopup
        anchors.centerIn: parent
        width: 240
        height: 140
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1E293B"
            border.color: "#3B82F6"
            border.width: 2
            radius: 12
        }

        onOpened: {
            numInputField.forceActiveFocus();
        }
        
        onClosed: {
            numInputField.text = "";
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Text {
                text: "Ir al Canal:"
                color: "white"
                font.bold: true
                font.pointSize: 12
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: numInputField
                Layout.fillWidth: true
                horizontalAlignment: TextInput.AlignHCenter
                font.pointSize: 18
                font.bold: true
                color: "white"
                placeholderText: "0"
                
                validator: RegularExpressionValidator { regularExpression: /[0-9]+/ }

                background: Rectangle {
                    color: "#0F172A"
                    radius: 6
                    border.color: numInputField.activeFocus ? "#3B82F6" : "#475569"
                }

                Keys.onReturnPressed: {
                    if (text.length > 0) {
                        window.playChannelByNumber(text);
                    }
                    channelNumPopup.close();
                }
                Keys.onEnterPressed: {
                    if (text.length > 0) {
                        window.playChannelByNumber(text);
                    }
                    channelNumPopup.close();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Cancelar"
                    Layout.fillWidth: true
                    onClicked: channelNumPopup.close()
                    
                    background: Rectangle {
                        color: "#475569"
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Button {
                    text: "Aceptar"
                    Layout.fillWidth: true
                    onClicked: {
                        if (numInputField.text.length > 0) {
                            window.playChannelByNumber(numInputField.text);
                        }
                        channelNumPopup.close();
                    }

                    background: Rectangle {
                        color: "#3B82F6"
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        fileDialog.open()
    }

    // NUEVO: Temporizador de inicialización para forzar el renderizado del scroll infinito
    Timer {
        id: initScrollTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            var count = channelModel.rowCount();
            if (count > 0) {
                // Posiciona la lista justo en el centro del millón virtual para permitir scroll libre
                var middleVirtual = 500000 - (500000 % count);
                channelListView.positionViewAtIndex(middleVirtual, ListView.Beginning);
                window.playChannel(0);
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Carga tu lista Tvheadend"
        nameFilters: ["Archivos M3U (*.m3u *.m3u8)"]
        onAccepted: {
            var request = new XMLHttpRequest();
            request.open("GET", fileDialog.selectedFile, false);
            request.send(null);
            
            // 1. Procesa el archivo en Python de forma asíncrona
            channelModel.parse_m3u_content(request.responseText);
            
            // 2. Dispara el temporizador para calcular el centro de la lista tras el refresco gráfico
            initScrollTimer.restart();
        }
    }
}


