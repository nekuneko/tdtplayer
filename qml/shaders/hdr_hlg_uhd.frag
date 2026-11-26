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
    vec3 c = clamp(texture(source, qt_TexCoord0).rgb, 0.0, 1.0);

    // 1. Expansión HLG suave y contenida (evita lavar platós luminosos)
    c = pow(max(c - 0.018, vec3(0.0)) / 0.982, vec3(0.74));

    // 2. Anclaje firme de negros y ganancia moderada
    c = clamp(c * 1.15 - 0.025, 0.0, 1.0);

    // 3. Saturación compensada (+26% para recuperar color sin sobresaturar pieles)
    float y = luma(c);
    c = mix(vec3(y), c, 1.26);

    // 4. Contraste final en S para profundidad real en trajes y fondos
    c = clamp(c, 0.0, 1.0);
    c = mix(c, c * c * (3.0 - 2.0 * c), 0.28);

    fragColor = vec4(clamp(c, 0.0, 1.0), 1.0) * qt_Opacity;
}
