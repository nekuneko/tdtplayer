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

    // Mantenemos X continuo para filtrado bilineal suave de la GPU (cero pixelado al escalar)
    // y alineamos Y al centro de la fila actual
    vec2 uv = vec2(qt_TexCoord0.x, (row + 0.5) * texelSize.y);
    vec4 center = texture(source, uv);

    // Las líneas pares se mantienen intactas
    if (mod(row, 2.0) < 0.5) {
        fragColor = center * qt_Opacity;
        return;
    }

    vec2 dy = vec2(0.0, texelSize.y);
    vec2 dx = vec2(texelSize.x, 0.0);

    vec4 top1 = texture(source, uv - dy);
    vec4 bot1 = texture(source, uv + dy);

    float lC  = luma(center.rgb);
    float lT1 = luma(top1.rgb);
    float lB1 = luma(bot1.rgb);

    // Prueba de peine
    float diffT = lC - lT1;
    float diffB = lC - lB1;
    if ((diffT * diffB) <= 0.0) {
        fragColor = center * qt_Opacity;
        return;
    }

    float combErr  = abs(lC - 0.5 * (lT1 + lB1));
    float vertGrad = 0.5 * abs(lT1 - lB1);
    float blend    = smoothstep(0.008 + vertGrad * 0.25, 0.028 + vertGrad * 0.55, combErr);

    if (blend <= 0.001) {
        fragColor = center * qt_Opacity;
        return;
    }

    // Búsqueda direccional suavizada (estilo Yadif espacial) en ±1px y ±2px horizontal
    vec4 topL1 = texture(source, uv - dy - dx);
    vec4 botR1 = texture(source, uv + dy + dx);
    vec4 topR1 = texture(source, uv - dy + dx);
    vec4 botL1 = texture(source, uv + dy - dx);

    vec4 topL2 = texture(source, uv - dy - 2.0 * dx);
    vec4 botR2 = texture(source, uv + dy + 2.0 * dx);
    vec4 topR2 = texture(source, uv - dy + 2.0 * dx);
    vec4 botL2 = texture(source, uv + dy - 2.0 * dx);

    // Evaluamos el gradiente vertical junto con sus vecinos laterales para evitar falsos positivos
    float scoreC  = abs(lT1 - lB1) + 0.5 * (abs(luma(topL1.rgb) - luma(botL1.rgb)) + abs(luma(topR1.rgb) - luma(botR1.rgb)));
    float scoreL1 = abs(luma(topL1.rgb) - luma(botR1.rgb)) + 0.5 * (abs(luma(topL2.rgb) - luma(bot1.rgb)) + abs(lT1 - luma(botR2.rgb))) + 0.012;
    float scoreR1 = abs(luma(topR1.rgb) - luma(botL1.rgb)) + 0.5 * (abs(luma(topR2.rgb) - luma(bot1.rgb)) + abs(lT1 - luma(botL2.rgb))) + 0.012;

    vec4 interp = 0.5 * (top1 + bot1);
    if (scoreL1 < scoreC && scoreL1 <= scoreR1) {
        interp = 0.5 * (topL1 + botR1);
    } else if (scoreR1 < scoreC && scoreR1 < scoreL1) {
        interp = 0.5 * (topR1 + botL1);
    }

    // Mezcla final suave (elimina escalones duros y conserva nitidez)
    fragColor = mix(center, interp, blend) * qt_Opacity;
}
