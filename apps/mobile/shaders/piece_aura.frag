#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

out vec4 fragColor;

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;
uniform float uIntensity;

void main() {
    vec2 uv = (FlutterFragCoord().xy) / uResolution;
    vec2 center = vec2(0.5);
    vec2 diff = uv - center;
    float dist = length(diff);

    // Subtle 6-fold radial wave perturbation
    float angle = atan(diff.y, diff.x);
    float wave = sin(angle * 6.0 + uTime * 3.0) * 0.035;
    float effectiveDist = dist + wave;

    // Organic pulsing glow envelope
    float pulse = 0.8 + 0.2 * sin(uTime * 4.5);
    float ring = smoothstep(0.5, 0.25, effectiveDist) * smoothstep(0.05, 0.22, effectiveDist);
    float glow = ring * uIntensity * pulse;

    // Output vibrant premultiplied color
    fragColor = vec4(uColor.rgb * glow, uColor.a * glow);
}
