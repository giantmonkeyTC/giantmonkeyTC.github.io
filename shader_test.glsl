#version 300 es
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
out vec4 colour_out;
#define TWO_PI 6.28318530718
#define PI 3.1415926535

float radioactive(vec2 st) {

    return clamp(st.x, cos(u_time), 1.0);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ap = p - a;
    vec2 ab = b - a;
    float h = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    return length(ap - ab * h);
}
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) *
        43758.5453123);
}
mat2 rotate2d(float _angle) {
    return mat2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
}
void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    vec2 stTrans = (st * 2.0 - 1.0);
    float angle = atan(stTrans.y, stTrans.x);
    vec2 a = vec2(0.0, 0.0);
    vec2 b = vec2(0.5, 0.4) * random(stTrans);

    // float angle = tanh(stTrans.y / stTrans.x);

    vec2 rotateSt1 = vec2(rotate2d(angle * 100. * random(stTrans)));
    for(int i = 0; i <= 15; i++) {
        b *= rotate2d(PI / 8.);
        if(sdSegment(stTrans.xy, a, b) <= 0.01) {
            colour_out = vec4(0.478, 0.768, 0.176, 1.0) * (1. - distance(stTrans, vec2(0.0)));
        }

    }

    // colour_out = vec4(0.0,0.0,1.0* angle,1.0);
    // *radioactive(gl_FragCoord.xy,u_resolution.xy);
}