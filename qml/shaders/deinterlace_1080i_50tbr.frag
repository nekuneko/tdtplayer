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
    vec2 texelSize = vec2(1.0 / texWidth, 1.0 / texHeight);
    float yPos = qt_TexCoord0.y * texHeight;
    float row = floor(yPos);

    // X continuo para filtrado bilineal suave de la GPU + Y alineado a la fila
    vec2 uv = vec2(qt_TexCoord0.x, (row + 0.5) * texelSize.y);
    vec4 center = texture(source, uv);

    // Las líneas pares se mantienen intactas
    if (mod(row, 2.0) < 0.5) {
        fragColor = center * qt_Opacity;
        return;
    }

    vec2 dy = vec2(0.0, texelSize.y);
    vec2 dx = vec2(texelSize.x, 0.0);

    vec4 topC = texture(source, uv - dy);
    vec4 botC = texture(source, uv + dy);

    float lC   = luma(center.rgb);
    float lTop = luma(topC.rgb);
    float lBot = luma(botC.rgb);

    // Prueba de peine (protege marcadores y textos fijos)
    float diffTop = lC - lTop;
    float diffBot = lC - lBot;
    if ((diffTop * diffBot) <= 0.0) {
        fragColor = center * qt_Opacity;
        return;
    }

    float combErr  = abs(lC - 0.5 * (lTop + lBot));
    float vertGrad = 0.5 * abs(lTop - lBot);

    float blend = smoothstep(0.008 + vertGrad * 0.15, 0.025 + vertGrad * 0.30, combErr);

    // Desentrelazado vertical + suavizado horizontal sutil (0.25 / 0.50 / 0.25) para eliminar macrobloques en movimiento
    vec4 topL = texture(source, uv - dy - dx);
    vec4 topR = texture(source, uv - dy + dx);
    vec4 botL = texture(source, uv + dy - dx);
    vec4 botR = texture(source, uv + dy + dx);

    vec4 smoothTop = 0.25 * topL + 0.50 * topC + 0.25 * topR;
    vec4 smoothBot = 0.25 * botL + 0.50 * botC + 0.25 * botR;
    vec4 interp    = 0.5 * (smoothTop + smoothBot);

    fragColor = mix(center, interp, blend) * qt_Opacity;
}
