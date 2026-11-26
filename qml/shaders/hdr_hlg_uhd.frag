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

    // 1. Expansión de medios tonos HLG
    c = pow(c, vec3(0.55));

    // 2. Ganancia de blanco difuso y recorte suave de negros
    c = clamp(c * 1.28 - 0.02, 0.0, 1.0);

    // 3. Saturación compensada (+36%)
    float y = luma(c);
    c = mix(vec3(y), c, 1.36);

    // 4. Contraste final en S para profundidad
    c = clamp(c, 0.0, 1.0);
    c = mix(c, c * c * (3.0 - 2.0 * c), 0.22);

    fragColor = vec4(clamp(c, 0.0, 1.0), 1.0) * qt_Opacity;
}
