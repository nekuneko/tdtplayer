// qml/Theme.qml
import QtQuick
import QtQuick.Window

Item {
    id: root

    property string currentTheme: "CINEMATIC_COLOR"

    // MOTOR DE ESCALA DINÁMICA HIDPI (Qt6 Smart Scaler)
    readonly property real ratio: Screen.devicePixelRatio
    readonly property real factorScale: root.ratio > 1.0 ? root.ratio : 1.2

    function px(value) {
        return Math.round(value * root.factorScale);
    }

    function pt(value) {
        return Math.round(value * root.factorScale);
    }

    // 🚀 LISTA ACTUALIZADA: Se añade la clave para el nuevo tema de Samsung
    readonly property list<string> themeKeys: ["CINEMATIC_COLOR", "DARK_ACCESSIBLE", "NORDIC_FROST", "MONOKAI_PRO", "VAMPIRE_BLOOD", "CYBERPUNK_NEON", "NETFLIX_DARK", "SAMSUNG_ONEUI"]

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
                "liveText": "#FFFFFF",
                "logoBg": "#111827"
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
                "liveText": "#FFFFFF",
                "logoBg": "transparent"
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
                "liveText": "#FFFFFF",
                "logoBg": "transparent"
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
                "liveText": "#FFFFFF",
                "logoBg": "#2D2D2D"
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
                "liveText": "#FFFFFF",
                "logoBg": "transparent"
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
                "liveText": "#FFFFFF",
                "logoBg": "transparent"
            },
            "NETFLIX_DARK": {
                "name": "Estilo Cine Rojo",
                "bgAbsolute": "#141414",
                "bgItemActive": "#E50914",
                "bgItemHover": "#2F2F2F",
                "bgItemDefault": "#1F1F1F",
                "borderActive": "#E50914",
                "borderHover": "#555555",
                "borderDefault": "#222222",
                "textTitle": "#FFFFFF",
                "textTitleActive": "#FFFFFF",
                "textDesc": "#AAAAAA",
                "textDescActive": "#E5E5E5",
                "badgeTimeBg": "#2F2F2F",
                "badgeTimeText": "#FFFFFF",
                "liveBg": "#E50914",
                "liveBorder": "transparent",
                "liveText": "#FFFFFF",
                "logoBg": "transparent"
            },
            // 🚀 NUEVA PALETA: "Estilo Samsung One UI" oscuro moderno
            "SAMSUNG_ONEUI": {
                "name": "Samsung One UI",
                "bgAbsolute": "#0A0E1A"    // Azul noche muy profundo oscuro
                ,
                "bgItemActive": "#0377FF"  // El icónico azul eléctrico de One UI
                ,
                "bgItemHover": "#252D3A"   // Gris azulado intermedio para el hover
                ,
                "bgItemDefault": "#121926" // Fondo de las tarjetas individuales
                ,
                "borderActive": "#0377FF",
                "borderHover": "#4C5A6F",
                "borderDefault": "#1C2635",
                "textTitle": "#F8FAFC"     // Blanco nítido
                ,
                "textTitleActive": "#FFFFFF",
                "textDesc": "#94A3B8"      // Gris Slate suave para la sinopsis
                ,
                "textDescActive": "#E2E8F0",
                "badgeTimeBg": "#252D3A"   // Cápsulas de tiempo integradas
                ,
                "badgeTimeText": "#0377FF" // Texto horaria resaltado en azul de One UI
                ,
                "liveBg": "#0377FF",
                "liveBorder": "transparent",
                "liveText": "#FFFFFF",
                "logoBg": "transparent"
            }
        })

    readonly property var currentColors: colors[currentTheme] ? colors[currentTheme] : colors["CINEMATIC_COLOR"]

    property color bgAbsolute: {
        return Qt.alpha(root.currentColors["bgAbsolute"], 0.80);
    }
    property color bgItemActive: {
        return root.currentColors["bgItemActive"];
    }
    property color bgItemHover: {
        return Qt.alpha(root.currentColors["bgItemHover"], 0.85);
    }
    property color bgItemDefault: {
        return Qt.alpha(root.currentColors["bgItemDefault"], 0.85);
    }
    property color borderActive: {
        return root.currentColors["borderActive"];
    }
    property color borderHover: {
        return root.currentColors["borderHover"];
    }
    property color borderDefault: {
        return root.currentColors["borderDefault"];
    }
    property color textTitle: {
        return root.currentColors["textTitle"];
    }
    property color textTitleActive: {
        return root.currentColors["textTitleActive"];
    }
    property color textDesc: {
        return root.currentColors["textDesc"];
    }
    property color textDescActive: {
        return root.currentColors["textDescActive"];
    }
    property color badgeTimeBg: {
        return root.currentColors["badgeTimeBg"];
    }
    property color badgeTimeText: {
        return root.currentColors["badgeTimeText"];
    }
    property color liveBg: {
        return root.currentColors["liveBg"];
    }
    property color liveBorder: {
        return root.currentColors["liveBorder"];
    }
    property color liveText: {
        return root.currentColors["liveText"];
    }
    property color logoBg: {
        return root.currentColors["logoBg"];
    }

    function getW3cContrast(hexColor) {
        if (!hexColor)
            return "#FFFFFF";
        var str = hexColor.toString().replace("#", "");
        if (str.length === 3)
            str = str + str + str + str + str + str;
        if (str.length === 8)
            str = str.substring(2);

        var r = parseInt(str.substring(0, 2), 16);
        var g = parseInt(str.substring(2, 4), 16);
        var b = parseInt(str.substring(4, 6), 16);
        var yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;
        return (yiq >= 128) ? "#000000" : "#FFFFFF";
    }
}
