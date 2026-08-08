// qml/Theme.qml
import QtQuick
import QtQuick.Window

Item {
    id: root

    property string currentTheme: "CINEMATIC_COLOR"

    // 🚀 MOTOR DE ESCALA DINÁMICA HIDPI (Qt6 Smart Scaler)
    // Captura el escalado nativo del sistema operativo (Wayland/X11) y aplica un multiplicador de densidad elástico
    readonly property real ratio: Screen.devicePixelRatio
    readonly property real scale: root.ratio > 1.0 ? root.ratio : 1.2

    // Función matemática para escalar celdas y márgenes de forma proporcional
    function px(value) { return Math.round(value * root.scale) }
    
    // Función matemática para escalar fuentes vectoriales de alta definición
    function pt(value) { return Math.round(value * root.scale) }

    readonly property list<string> themeKeys: ["CINEMATIC_COLOR", "DARK_ACCESSIBLE", "NORDIC_FROST", "MONOKAI_PRO", "VAMPIRE_BLOOD", "CYBERPUNK_NEON"]

    readonly property var colors: ({
        "DARK_ACCESSIBLE": {
            "name": "Alto Contraste B/N",
            "bgAbsolute": "#000000",
            "bgItemActive": "#FFFFFF",
            "bgItemHover": "#334155",
            "bgItemDefault": "#111827",
            "borderActive": "#FFFFFF",
            "borderHover": "#94A3B8",
            "borderDefault": "#1E293B",
            "textTitle": "#FFFFFF",
            "textTitleActive": "#000000",
            "textDesc": "#CBD5E1",
            "textDescActive": "#111827",
            "badgeTimeBg": "#1E293B",
            "badgeTimeText": "#FFFFFF",
            "liveBg": "#000000",
            "liveBorder": "#FFFFFF",
            "liveText": "#FFFFFF"
        },
        "CINEMATIC_COLOR": {
            "name": "Color Cinemático",
            "bgAbsolute": "#0B0F17",
            "bgItemActive": "#1D4ED8", 
            "bgItemHover": "#1E293B",
            "bgItemDefault": "#0B0F19",
            "borderActive": "#60A5FA",
            "borderHover": "#64748B",
            "borderDefault": "#1E293B",
            "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF",
            "textDesc": "#CBD5E1",
            "textDescActive": "#E2E8F0",
            "badgeTimeBg": "#1E293B",
            "badgeTimeText": "#60A5FA", 
            "liveBg": "#EF4444",        
            "liveBorder": "transparent",
            "liveText": "#FFFFFF"
        },
        "NORDIC_FROST": {
            "name": "Escarcha Nórdica",
            "bgAbsolute": "#0F172A",
            "bgItemActive": "#0D9488", 
            "bgItemHover": "#1E293B",
            "bgItemDefault": "#111827",
            "borderActive": "#2DD4BF",
            "borderHover": "#475569",
            "borderDefault": "#1E293B",
            "textTitle": "#F8FAFC",
            "textTitleActive": "#FFFFFF",
            "textDesc": "#94A3B8",
            "textDescActive": "#F1F5F9",
            "badgeTimeBg": "#1E293B",
            "badgeTimeText": "#2DD4BF",
            "liveBg": "#0D9488",
            "liveBorder": "transparent",
            "liveText": "#FFFFFF"
        },
        "MONOKAI_PRO": {
            "name": "Monokai Ámbar",
            "bgAbsolute": "#1A1A1A",
            "bgItemActive": "#D97706", 
            "bgItemHover": "#2D2D2D",
            "bgItemDefault": "#222222",
            "borderActive": "#FBBF24",
            "borderHover": "#444444",
            "borderDefault": "#2D2D2D",
            "textTitle": "#F3F4F6",
            "textTitleActive": "#FFFFFF",
            "textDesc": "#9CA3AF",
            "textDescActive": "#F9FAFB",
            "badgeTimeBg": "#2D2D2D",
            "badgeTimeText": "#FBBF24",
            "liveBg": "#D97706",
            "liveBorder": "transparent",
            "liveText": "#FFFFFF"
        },
        "VAMPIRE_BLOOD": {
            "name": "Rojo Vampiro",
            "bgAbsolute": "#050505",
            "bgItemActive": "#991B1B", 
            "bgItemHover": "#1A0505",
            "bgItemDefault": "#110303",
            "borderActive": "#EF4444",
            "borderHover": "#3F0707",
            "borderDefault": "#1A0505",
            "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF",
            "textDesc": "#FCA5A5",
            "textDescActive": "#FFE4E6",
            "badgeTimeBg": "#270505",
            "badgeTimeText": "#EF4444",
            "liveBg": "#EF4444",
            "liveBorder": "transparent",
            "liveText": "#FFFFFF"
        },
        "CYBERPUNK_NEON": {
            "name": "Cyberpunk Neón",
            "bgAbsolute": "#08000F",
            "bgItemActive": "#C026D3", 
            "bgItemHover": "#220033",
            "bgItemDefault": "#11001C",
            "borderActive": "#F0ABFC",
            "borderHover": "#4A044E",
            "borderDefault": "#220033",
            "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF",
            "textDesc": "#E879F9",
            "textDescActive": "#FDF4FF",
            "badgeTimeBg": "#3B0764",
            "badgeTimeText": "#F0ABFC",
            "liveBg": "#C026D3",
            "liveBorder": "transparent",
            "liveText": "#FFFFFF"
        }
    })

    property color bgAbsolute: { return colors[currentTheme]["bgAbsolute"] }
    property color bgItemActive: { return colors[currentTheme]["bgItemActive"] }
    property color bgItemHover: { return colors[currentTheme]["bgItemHover"] }
    property color bgItemDefault: { return colors[currentTheme]["bgItemDefault"] }
    property color borderActive: { return colors[currentTheme]["borderActive"] }
    property color borderHover: { return colors[currentTheme]["borderHover"] }
    property color borderDefault: { return colors[currentTheme]["borderDefault"] }
    property color textTitle: { return colors[currentTheme]["textTitle"] }
    property color textTitleActive: { return colors[currentTheme]["textTitleActive"] }
    property color textDesc: { return colors[currentTheme]["textDesc"] }
    property color textDescActive: { return colors[currentTheme]["textDescActive"] }
    property color badgeTimeBg: { return colors[currentTheme]["badgeTimeBg"] }
    property color badgeTimeText: { return colors[currentTheme]["badgeTimeText"] }
    property color liveBg: { return colors[currentTheme]["liveBg"] }
    property color liveBorder: { return colors[currentTheme]["liveBorder"] }
    property color liveText: { return colors[currentTheme]["liveText"] }
}
