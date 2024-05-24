#version 300 es
precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
out vec4 colour_out;
#define TWO_PI 6.28318530718
const float PI = acos(-1.0);

// _ _ _
//  _ _ 
//
float square(float x) {
    return sign(sin(x * PI)) * 0.5 + 0.5;
}
//
// /_/_/
//
float ramps(float x) {
    return mod(x, 1.0) * square(x);
}
// 
// S_S_S
//
float smoothed_ramps(float x) {
    return smoothstep(0.0, 1.0, ramps(x));
}
//      
//    __
//  __
// _
//
float steps(float x) {
    return floor(x / 2.0 + 0.5);
}
//
//    _/
//  _/
// /
//
float ramps_step(float x) {
    return ramps(x) + steps(x);
}
//
//    _S
//  _S
// S
//
float smoothed_ramps_step(float x) {
    return smoothed_ramps(x) + steps(x);
}

float sphere(vec3 o, float r) {
    return length(o) - r;
}

float cylinder(vec3 o, float r) {
    return length(o.xz) - r;
}

mat2 rotate(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec3 fetch(vec3 o) {
//    float deform = linear_steps(iTime + 1.5) * 2.0;
    float deform = u_time / 0.35;
    o.yz *= rotate(smoothed_ramps_step(u_time + 1.0) * PI / 4.0);
    o.xy *= rotate(smoothed_ramps_step(u_time + 0.5) * PI / 4.0);
    o.zx *= rotate(smoothed_ramps_step(u_time) * PI / 4.0);
    o.z += 0.1 * sin(o.y * 10.0 + deform);
    o.x += 0.1 * sin(o.z * 10.0 + deform);
    o.y += 0.1 * sin(o.x * 10.0 + deform);

    float object = sphere(o, 0.5);
    if(object < 0.0) {
        vec3 color = vec3((sin(o.x * 10.0 + u_time) + 1.0) * 0.02 + 0.01, (sin(o.y * 10.0 + u_time) + 1.0) * 0.01 + 0.02, (sin(o.z * 10.0 + u_time) + 1.0) * 0.01 + 0.01);
        color /= 4.0;
        return color;
    } else {
        return vec3(0.0);
    }
}

//orchid
// bool ops
float merge(float d1, float d2) {
    return min(d1, d2);
}

float smoothMerge(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

float substract(float d1, float d2) {
    return max(-d1, d2);
}

float ellipseDist(vec2 p, float radius, vec2 dim) {
    vec2 pos = p;
    pos.x = p.x / dim.x;
    pos.y = p.y / dim.y;
    return length(pos) - radius;
}

float fill(float sdfVal, float w) {
    return step(w, sdfVal);
}

mat2 rotate2d(float _angle) {
    return mat2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
}

float orcSepals(vec2 toCenter, float resize, float defX, float defY, float grow, float nPetals, float smoothness) {

    float angle = atan(toCenter.y, toCenter.x) + 0.5;
    float deformOnY = toCenter.y * defY;
    float deformOnX = abs(toCenter.x) * defX;
    float radius = length(toCenter) * resize * (grow + deformOnY + deformOnX);

    float f = cos(angle * nPetals);
    return smoothstep(f, f + smoothness, radius);
}

float lip(vec2 pos, vec2 oval, vec2 ovalSub, float radius, float offset) {
    float A = ellipseDist(pos, radius, oval);
    vec2 posB = pos;
    posB.y += offset;
    float B = ellipseDist(posB, radius, ovalSub);
    float p = smoothMerge(B, A, 0.4);
    return p;
}

float orcColumn(vec2 pos, vec2 oval, vec2 ovalSub, float radius, float offset) {
    float A = ellipseDist(pos, radius, ovalSub);
    vec2 posB = pos;
    posB.y -= offset;
    float B = ellipseDist(posB, radius, oval);
    float p = substract(B, A);
    posB.y += 0.035;
    float cone = ellipseDist(posB, radius, vec2(0.08, 0.55));
    p = smoothMerge(cone, p, 0.3);
    return p;
}

void main() {

    //shaderToy 1
    // vec2 p = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;
    // vec3 light = vec3(0.0);

    // vec3 o = vec3(0.0,0.0,-1.0);
    // vec3 d = normalize(vec3(p.xy, 2.0));

    // float t = 0.0;
    // for (int i = 0; i < 200; i++) {
    //     t += 0.01;
    //     light += fetch(d * t + o);
    // }

    // colour_out = vec4(light,1.0);
    // http://www.pouet.net/prod.php?which=57245
// If you intend to reuse this shader, please add credits to 'Danilo Guanabara'

    //shaderToy 2
    // vec3 c;
	// float l,z=u_time;
	// for(int i=0;i<3;i++) {
	// 	vec2 uv,p=gl_FragCoord.xy/u_resolution;
	// 	uv=p;
	// 	p-=.5;
	// 	p.x*=u_resolution.x/u_resolution.y;
	// 	z+=.07;
	// 	l=length(p);
	// 	uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z-z));
	// 	c[i]=.01/length(mod(uv,1.)-.5);
	// }
	// colour_out=vec4(c/l,u_time);

    //orchid shadertoy
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y;
  // general parameters
    float smoothness = 0.02;
    float addSmoothnessToSetals = 2.9;
    st *= 1.;
    st = fract(st);
    st += vec2(-0.5, -0.5);
  //column parameters
    float colResize = 0.55;
    vec2 posCol = st;
    posCol.y += 0.07;
    float colYoffset = -0.04;
    float powerCol = 2.;
    vec2 colRatio = vec2(0.4 * colResize, 0.4 * colResize);
    vec2 colSubRatio = vec2(0.9 * colResize, 0.9 * colResize);
    float colRadius = 0.52 * colResize;
  // sepals parameters
    float deformX = 0.;
    float deformY = 0.;
    float resizePetals = 11.9;
    float powerSepals = 2.0;
    float nPetals = 3.;
//   float growSepals = pow(length(st), 2.0);
//   try out different functions for different shapes
//   float growSepals = exp(length(st)) * 0.15;
    float growSepals = exp2(length(st)) * 0.19;
//   float growSepals = sqrt(length(st)) * 0.35;
//   float growSepals = sin(length(st)) * 0.58;
  // lateral petals parameter
    float nPetalsLat = 2.;
    float deformXLat = 0.0;
    float deformYLat = -0.0;
    float resizePetalsLat = 21.9;
    float powerLat = 2.3;
    vec2 latPos = st * rotate2d(TWO_PI / 2.4);
    float growLaterals = pow(length(st), powerLat);
  // lip parameter
    vec2 posLip = st;
    posLip.y += 0.18;
    float lipResize = 0.6;
    float lipYoffset = 0.05;
    vec2 lipRatio = vec2(0.19 * lipResize, 0.35 * lipResize);
    vec2 smallLipRatio = vec2(0.32 * lipResize, 0.15 * lipResize);
    float lipRadius = 1. * lipResize;

    float column = orcColumn(posCol * rotate2d(TWO_PI / 2.), colRatio, colSubRatio, colRadius, colYoffset);
    float sepals = orcSepals(st, resizePetals, deformX, deformY, growSepals, nPetals, smoothness + addSmoothnessToSetals);
    float latPetals = orcSepals(latPos, resizePetalsLat, deformXLat, deformYLat, growLaterals, nPetalsLat, smoothness + addSmoothnessToSetals);
    float lip = lip(posLip, lipRatio, smallLipRatio, lipRadius, lipYoffset);

    float orchids = merge(latPetals, sepals);

    orchids = merge(orchids, lip);
    orchids = substract(column, orchids);
  // add smoothness
    orchids = smoothstep(orchids, orchids + smoothness, 0.09);
    colour_out = vec4(vec3(orchids), 1.);
}
