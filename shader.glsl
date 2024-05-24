#version 300 es
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;
out vec4 colour_out;
#define TWO_PI 6.28318530718
#define PI 3.1415926535
// credit: oneAAAIaDayKeepsHairAway
// orchid: Phalaenopsis Orchid Stem Green

// cloud source code is from ShaderToy

vec2 mod289(vec2 x) {
    return x - floor(x * (1. / 289.)) * 289.;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1. / 289.)) * 289.;
}

vec4 mod7(vec4 x) {
    return x - floor(x * (1. / 7.)) * 7.;
}

vec4 permute(vec4 x) {
    return mod289((34. * x + 10.) * x);
}

vec2 cellular2x2(vec2 P) {
    #define K.142857142857// 1/7
    #define K2.0714285714285// K/2
    #define jitter.8// jitter 1.0 makes F1 wrong more often
    vec2 Pi = mod289(floor(P));
    vec2 Pf = fract(P);
    vec4 Pfx = Pf.x + vec4(-.5, -1.5, -.5, -1.5);
    vec4 Pfy = Pf.y + vec4(-.5, -.5, -1.5, -1.5);
    vec4 p = permute(Pi.x + vec4(0., 1., 0., 1.));
    p = permute(p + Pi.y + vec4(0., 0., 1., 1.));
    vec4 ox = mod7(p) * K + K2;
    vec4 oy = mod7(floor(p * K)) * K + K2;
    vec4 dx = Pfx + jitter * ox;
    vec4 dy = Pfy + jitter * oy;
    vec4 d = dx * dx + dy * dy;// d11, d12, d21 and d22, squared
    // Sort out the two smallest distances
    #if 0
    // Cheat and pick only F1
    d.xy = min(d.xy, d.zw);
    d.x = min(d.x, d.y);
    return vec2(sqrt(d.x));// F1 duplicated, F2 not computed
    #else
    // Do it right and find both F1 and F2
    d.xy = (d.x < d.y) ? d.xy : d.yx;// Swap if smaller
    d.xz = (d.x < d.z) ? d.xz : d.zx;
    d.xw = (d.x < d.w) ? d.xw : d.wx;
    d.y = min(d.y, d.z);
    d.y = min(d.y, d.w);
    return sqrt(d.xy);
    #endif
}

float color(vec2 xy) {
    return cellular2x2(xy).x * 2. - 1.;
}
vec4 mainImage(vec2 fragcoord, vec2 uresolution) {
    vec2 p = (fragcoord.xy / uresolution.y) * 2. - 1.;

    vec3 xyz = vec3(p, 0);

    float n = color(xyz.xy * 3.);

    vec4 fragColor = vec4(2. + .2 * vec3(n, n, n), 1.);

    return fragColor;

}

//orchid

mat2 rotate2d(float _angle) {
    return mat2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
}
float orchidSides(vec2 toCenter, float resize, float defX, float defY, float grow, float nPetals, float smoothness, float xfactor) {

    float angle = atan(toCenter.y, toCenter.x / xfactor);
    float deformOnY = abs(toCenter.y) * defY;
    float deformOnX = abs(toCenter.x) * defX;
    float radius = length(toCenter) * resize * (grow + deformOnY + deformOnX) / 1.3;

    float f = cos(angle * nPetals);
    return smoothstep(f, f + smoothness, radius);
}

//cloud

const float timeScale = 10.;
const float cloudScale = .2;
const float softness = .2;
const float brightness = 1.;
const int noiseOctaves = 8;
const float curlStrain = 3.;

float saturate(float num) {
    return clamp(num, 0., 1.);
}

float noise(vec2 uv) {
    return color(uv);
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ap = p - a;
    vec2 ab = b - a;
    float h = clamp(dot(ap, ab) / dot(ab, ab), 0., 1.);
    return length(ap - ab * h);
}
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) *
        43758.5453123);
}

vec2 rotate(vec2 uv) {
    uv = uv + noise(uv * .2) * .005;
    float rot = curlStrain;
    float sinRot = sin(rot);
    float cosRot = cos(rot);
    mat2 rotMat = mat2(cosRot, -sinRot, sinRot, cosRot);
    return uv * rotMat;
}

float fbm(vec2 uv) {
    float rot = 1.57;
    float f = 0.;
    float total = 0.;
    float mul = .5;

    for(int i = 0; i < noiseOctaves; i++) {
        f += noise(uv + u_time * .00015 * timeScale * (1. - mul)) * mul;
        total += mul;
        uv *= 3.;
        uv = rotate(uv);
        mul *= .5;
    }
    return f / total;
}

float easeOutCubic(float number) {
    return 1. - pow(1. - number, 3.);
}

void main() {

    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    vec2 uv = gl_FragCoord.xy / (4000. * cloudScale);

    vec2 stTrans = (st * 2. - 1.);
    float angle = atan(stTrans.y / stTrans.x);
    vec2 a = vec2(0., 0.);
    vec2 b = vec2(.35, .35) * random(stTrans);

    vec2 rotateSt1 = vec2(rotate2d(angle * 100. * random(stTrans)));

    float cover = 1.1 + .1;

    float bright = brightness * (1.8 - cover);

    float color1 = fbm(uv - .5 + u_time * .004 * timeScale);
    float color2 = fbm(uv - 10.5 + u_time * .002 * timeScale);

    float clouds1 = smoothstep(1. - cover, min((1. - cover) + softness * 2., 1.), color1);
    float clouds2 = smoothstep(1. - cover, min((1. - cover) + softness, 1.), color2);

    float cloudsFormComb = saturate(clouds1 + clouds2);

    vec4 skyCol = vec4(.6, .8, 1., 1.);
    float cloudCol = saturate(saturate(1. - pow(color1, 1.) * .2) * bright);
    vec4 clouds1Color = vec4(cloudCol, cloudCol, cloudCol, 1.);
    vec4 clouds2Color = mix(clouds1Color, skyCol, .25);
    vec4 cloudColComb = 1.5 * mix(clouds1Color, clouds2Color, saturate(clouds2 - clouds1));

    vec4 cloud_colour = mix(skyCol, cloudColComb, cloudsFormComb);

    //orchid
    float mask = 1.;
    mask *= orchidSides(st - .5, 1., 0., 0., 3., 2., .1, .5);
    mask *= orchidSides(rotate2d(PI / 2.) * (st - .5), 1., 0., 3., 3., 1., .05, 1.);
    mask *= orchidSides(rotate2d(PI * 6. / 4.) * (st - .5), 1.2, 1., 3., 3., 1., .05, 1.);
    float fun = 1. * exp(-1. * sqrt(pow(st.x - .5, 2.) + pow(st.y - .5, 2.)));

    vec4 objcolor = mix(vec4(1.), vec4(.478, .568, .176, 1.), fun);

    colour_out = mainImage(gl_FragCoord.xy, u_resolution.xy) * objcolor;

    if(1. - mask == 1.) {
        colour_out *= (1. - mask);
        if(distance(0., rotateSt1.x) <= .03) {
            colour_out *= vec4(0.4431, 1., 0.1941, 1.0);
        }
        float t = 0.;
        for(int i = 0; i <= 55; i++) {
            t += 1.;
            b.y += pow(-1., t) * .1 * abs(cos(t));
            b *= rotate2d(PI / 27.);
            if(sdSegment(stTrans.xy, a, b) <= .01) {
                if(i > 12 && i < 28)
                    colour_out = vec4(.478, .768, .176, .9) * (2. - distance(stTrans, vec2(0.)));
                else if(i > 38 && i < 55)
                    colour_out = vec4(.478, .768, .176, .9) * (2. - distance(stTrans, vec2(0.)));
            // else
            //     colour_out = vec4(0.4431, 1., 0.1941, 1.0) * (2. - distance(stTrans, vec2(0.0)));
            }

        }
        if(distance(vec2(0.), stTrans) < .05 * cos(stTrans.y * 15. * PI)) {
            colour_out = vec4(.9608, .8902, .2627, 1.);
        }

    } else
        colour_out = cloud_colour;

// colour_out = objcolor*orchids;

}