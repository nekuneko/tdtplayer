// qml/Theme.qml
import QtQuick
import QtQuick.Window

Item {
    id: root

    property string currentTheme: "CINEMATIC_COLOR"

    readonly property real ratio: Screen.devicePixelRatio
    readonly property real factorScale: root.ratio > 1.0 ? root.ratio : 1.2

    function px(value) { return Math.round(value * root.factorScale); }
    function pt(value) { return Math.round(value * root.factorScale); }

    readonly property list<string> themeKeys: [
        "CINEMATIC_COLOR", "DARK_ACCESSIBLE", "NORDIC_FROST",
        "MONOKAI_PRO", "VAMPIRE_BLOOD", "CYBERPUNK_NEON", "NETFLIX_DARK"
    ]

    readonly property var colors: ({
        "DARK_ACCESSIBLE": {
            "name": "Alto Contraste B/N", "bgCanvas": "#18181B", "bgAbsolute": "#000000", "bgItemActive": "#FFFFFF",
            "bgItemHover": "#334155", "bgItemDefault": "#111827", "borderActive": "#FFFFFF",
            "borderHover": "#94A3B8", "borderDefault": "#1E293B", "textTitle": "#FFFFFF",
            "textTitleActive": "#000000", "textDesc": "#CBD5E1", "textDescActive": "#111827",
            "badgeTimeBg": "#1E293B", "badgeTimeText": "#FFFFFF", "liveBg": "#000000",
            "liveBorder": "#FFFFFF", "liveText": "#FFFFFF", "logoBg": "#111827"
        },
        "CINEMATIC_COLOR": {
            "name": "Color Cinemático", "bgCanvas": "#1E2430", "bgAbsolute": "#0B0F17", "bgItemActive": "#1D4ED8",
            "bgItemHover": "#1E293B", "bgItemDefault": "#0B0F19", "borderActive": "#60A5FA",
            "borderHover": "#64748B", "borderDefault": "#1E293B", "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF", "textDesc": "#CBD5E1", "textDescActive": "#E2E8F0",
            "badgeTimeBg": "#1E293B", "badgeTimeText": "#60A5FA", "liveBg": "#EF4444",
            "liveBorder": "transparent", "liveText": "#FFFFFF", "logoBg": "transparent"
        },
        "NORDIC_FROST": {
            "name": "Escarcha Nórdica", "bgCanvas": "#1E293B", "bgAbsolute": "#0F172A", "bgItemActive": "#0D9488",
            "bgItemHover": "#1E293B", "bgItemDefault": "#111827", "borderActive": "#2DD4BF",
            "borderHover": "#475569", "borderDefault": "#1E293B", "textTitle": "#F8FAFC",
            "textTitleActive": "#FFFFFF", "textDesc": "#94A3B8", "textDescActive": "#F1F5F9",
            "badgeTimeBg": "#1E293B", "badgeTimeText": "#2DD4BF", "liveBg": "#0D9488",
            "liveBorder": "transparent", "liveText": "#FFFFFF", "logoBg": "transparent"
        },
        "MONOKAI_PRO": {
            "name": "Monokai Ámbar", "bgCanvas": "#262626", "bgAbsolute": "#1A1A1A", "bgItemActive": "#D97706",
            "bgItemHover": "#2D2D2D", "bgItemDefault": "#222222", "borderActive": "#FBBF24",
            "borderHover": "#444444", "borderDefault": "#2D2D2D", "textTitle": "#F3F4F6",
            "textTitleActive": "#FFFFFF", "textDesc": "#9CA3AF", "textDescActive": "#F9FAFB",
            "badgeTimeBg": "#2D2D2D", "badgeTimeText": "#FBBF24", "liveBg": "#D97706",
            "liveBorder": "transparent", "liveText": "#FFFFFF", "logoBg": "#2D2D2D"
        },
        "VAMPIRE_BLOOD": {
            "name": "Rojo Vampiro", "bgCanvas": "#1C1214", "bgAbsolute": "#050505", "bgItemActive": "#991B1B",
            "bgItemHover": "#1A0505", "bgItemDefault": "#110303", "borderActive": "#EF4444",
            "borderHover": "#3F0707", "borderDefault": "#1A0505", "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF", "textDesc": "#FCA5A5", "textDescActive": "#FFE4E6",
            "badgeTimeBg": "#270505", "badgeTimeText": "#EF4444", "liveBg": "#EF4444",
            "liveBorder": "transparent", "liveText": "#FFFFFF", "logoBg": "transparent"
        },
        "CYBERPUNK_NEON": {
            "name": "Cyberpunk Neón", "bgCanvas": "#191224", "bgAbsolute": "#08000F", "bgItemActive": "#C026D3",
            "bgItemHover": "#220033", "bgItemDefault": "#11001C", "borderActive": "#F0ABFC",
            "borderHover": "#4A044E", "borderDefault": "#220033", "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF", "textDesc": "#E879F9", "textDescActive": "#FDF4FF",
            "badgeTimeBg": "#3B0764", "badgeTimeText": "#F0ABFC", "liveBg": "#C026D3",
            "liveBorder": "transparent", "liveText": "#FFFFFF", "logoBg": "transparent"
        },
        "NETFLIX_DARK": {
            "name": "Estilo Cine Rojo", "bgCanvas": "#202022", "bgAbsolute": "#141414", "bgItemActive": "#E50914",
            "bgItemHover": "#2F2F2F", "bgItemDefault": "#1F1F1F", "borderActive": "#E50914",
            "borderHover": "#555555", "borderDefault": "#222222", "textTitle": "#FFFFFF",
            "textTitleActive": "#FFFFFF", "textDesc": "#AAAAAA", "textDescActive": "#E5E5E5",
            "badgeTimeBg": "#2F2F2F", "badgeTimeText": "#FFFFFF", "liveBg": "#E50914",
            "liveBorder": "transparent", "liveText": "#FFFFFF", "logoBg": "transparent"
        }
    })

    readonly property var currentColors: colors[currentTheme] ? colors[currentTheme] : colors["CINEMATIC_COLOR"]

    readonly property color bgCanvas: root.currentColors["bgCanvas"]
    readonly property color bgAbsolute: Qt.alpha(root.currentColors["bgAbsolute"], 0.85)
    readonly property color bgItemActive: root.currentColors["bgItemActive"]
    readonly property color bgItemHover: Qt.alpha(root.currentColors["bgItemHover"], 0.85)
    readonly property color bgItemDefault: Qt.alpha(root.currentColors["bgItemDefault"], 0.85)
    readonly property color borderActive: root.currentColors["borderActive"]
    readonly property color borderHover: root.currentColors["borderHover"]
    readonly property color borderDefault: root.currentColors["borderDefault"]
    readonly property color textTitle: root.currentColors["textTitle"]
    readonly property color textTitleActive: root.currentColors["textTitleActive"]
    readonly property color textDesc: root.currentColors["textDesc"]
    readonly property color textDescActive: root.currentColors["textDescActive"]
    readonly property color badgeTimeBg: root.currentColors["badgeTimeBg"]
    readonly property color badgeTimeText: root.currentColors["badgeTimeText"]
    readonly property color liveBg: root.currentColors["liveBg"]
    readonly property color liveBorder: root.currentColors["liveBorder"]
    readonly property color liveText: root.currentColors["liveText"]
    readonly property color logoBg: root.currentColors["logoBg"]

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
        return (((r * 299) + (g * 587) + (b * 114)) / 1000 >= 128) ? "#000000" : "#FFFFFF";
    }
}
