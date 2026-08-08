// qml/ClockWidget.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    // 🚀 MAQUETACIÓN PREMIUM AMPLIADA: Se incrementa drásticamente la escala del recuadro
    width: typeof appTheme !== "undefined" && appTheme.px ? appTheme.px(130) : 130
    height: typeof appTheme !== "undefined" && appTheme.px ? appTheme.px(48) : 48

    // Coherencia de píldora: Radio proporcional al nuevo tamaño ampliado
    radius: typeof appTheme !== "undefined" && appTheme.px ? appTheme.px(6) : 6

    // Color de acento sólido sincronizado dinámicamente con el tema activo
    color: typeof appTheme !== "undefined" ? appTheme.bgItemActive : "#1E293B"
    border.width: 0

    property string timeString: "00:00"

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            // 🚀 PURGA DE SEGUNDOS: Formateo limpio omitiendo el bloque de segundos
            root.timeString = date.toLocaleTimeString(Qt.locale("es_ES"), "hh:mm");
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Text {
            id: timeText
            text: root.timeString

            // Algoritmo YIQ aplicado: El texto cambia automáticamente según el color del tema
            color: typeof appTheme !== "undefined" ? appTheme.getW3cContrast(root.color) : "#FFFFFF"

            font.bold: true
            // 🚀 FUENTE VECORIAL MAXIMIZADA: Salto de 11pt a 18pt de alta definición
            font.pointSize: typeof appTheme !== "undefined" && appTheme.pt ? appTheme.pt(18) : 18
            font.family: "Monospace"
            renderType: Text.NativeRendering

            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
