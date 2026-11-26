#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float texHeight;
    float texWidth;
};

layout(binding = 1) uniform sampler2D source;

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec4 center = texture(source, qt_TexCoord0);
    float yPixel = qt_TexCoord0.y * texHeight;

    // Las líneas pares se mantienen intactas
    if (mod(floor(yPixel), 2.0) < 0.5) {
        fragColor = center * qt_Opacity;
        return;
    }

    vec2 dy = vec2(0.0, 1.0 / texHeight);
    vec2 dx = vec2(1.0 / texWidth, 0.0);

    vec4 topC = texture(source, qt_TexCoord0 - dy);
    vec4 botC = texture(source, qt_TexCoord0 + dy);

    float lC = luma(center.rgb);
    float lTop = luma(topC.rgb);
    float lBot = luma(botC.rgb);

    // Prueba estricta de peine: evita tocar textos fijos (rampas monótonas)
    float diffTop = lC - lTop;
    float diffBot = lC - lBot;
    bool isComb = (diffTop * diffBot) > 0.0;

    float avgLuma = 0.5 * (lTop + lBot);
    float combErr = abs(lC - avgLuma);
    float vertGrad = 0.5 * abs(lTop - lBot);

    if (!isComb || combErr <= (vertGrad * 0.45 + 0.012)) {
        fragColor = center * qt_Opacity;
        return;
    }

    // Interpolación direccional ELA de 3 ángulos
    vec4 topL = texture(source, qt_TexCoord0 - dy - dx);
    vec4 botR = texture(source, qt_TexCoord0 + dy + dx);
    vec4 topR = texture(source, qt_TexCoord0 - dy + dx);
    vec4 botL = texture(source, qt_TexCoord0 + dy - dx);

    float gradC = abs(lTop - lBot);
    float gradL = abs(luma(topL.rgb) - luma(botR.rgb));
    float gradR = abs(luma(topR.rgb) - luma(botL.rgb));

    vec4 interp = 0.5 * (topC + botC);
    if ((gradL + 0.015) < gradC && gradL <= gradR) {
        interp = 0.5 * (topL + botR);
    } else if ((gradR + 0.015) < gradC && gradR < gradL) {
        interp = 0.5 * (topR + botL);
    }

    fragColor = interp * qt_Opacity;
}
