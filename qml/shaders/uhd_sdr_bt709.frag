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

    // 1. Expansión suave de rango limitado TV para levantar sombras sin quemar blancos
    c = clamp((c - 0.015) / 0.975, 0.0, 1.0);
    c = pow(c, vec3(0.92));

    // 2. Corrección matricial parcial BT.2020 -> BT.709 (corrige de raíz el rojo de las caras en A3/T5 UHD)
    mat3 gamutFix = mat3(
         0.84,  0.14,  0.02,
         0.04,  0.94,  0.02,
         0.01,  0.05,  0.94
    );
    c = clamp(gamutFix * c, 0.0, 1.0);

    // 3. Reducción selectiva adicional en pieles rojizas sin apagar los rojos puros de gráficos
    float maxGB = max(c.g, c.b);
    float redExcess = max(0.0, c.r - maxGB);
    float skinMask = smoothstep(0.04, 0.38, redExcess) * (1.0 - smoothstep(0.38, 0.65, redExcess));
    c.r -= redExcess * (0.22 * skinMask);
    c.g += redExcess * (0.05 * skinMask);

    // 4. Ajuste sutil de saturación (-6%) para igualar al HD estándar
    float y = luma(c);
    c = mix(vec3(y), c, 0.94);

    fragColor = vec4(clamp(c, 0.0, 1.0), 1.0) * qt_Opacity;
}
