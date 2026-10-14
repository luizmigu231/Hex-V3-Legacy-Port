#pragma header

uniform float uBeat;
uniform float uGlitch;
uniform float uTaps;

float sat(float t) { return clamp(t, 0.0, 1.0); }
vec2 sat(vec2 t) { return clamp(t, 0.0, 1.0); }
float remap(float t, float a, float b) { return sat((t - a) / (b - a)); }
float linterp(float t) { return sat(1.0 - abs(2.0 * t - 1.0)); }

vec3 spectrum_offset(float t)
{
    float lo = step(t, 0.5);
    float hi = 1.0 - lo;
    float w = linterp(remap(t, 1.0 / 6.0, 5.0 / 6.0));
    float neg_w = 1.0 - w;
    return pow(vec3(lo, 1.0, hi) * vec3(neg_w, w, neg_w), vec3(1.0 / 2.2));
}

float rand(vec2 n) { return fract(sin(dot(n.xy, vec2(12.9898, 78.233))) * 43758.5453); }
float mytrunc(float x, float numLevels) { return floor(x * numLevels) / numLevels; }
vec2 mytrunc(vec2 x, float numLevels) { return floor(x * numLevels) / numLevels; }

void main()
{
    vec2 uv = openfl_TextureCoordv;
    if (uGlitch <= 0.001)
    {
        gl_FragColor = flixel_texture2D(bitmap, uv);
        return;
    }

    float time = mod(uBeat * 100.0, 32.0) / 110.0;
    float gnm = sat(uGlitch);
    float rnd0 = rand(mytrunc(vec2(time, time), 6.0));
    float r0 = sat((1.0 - gnm) * 0.7 + rnd0);
    float rnd1 = rand(vec2(mytrunc(uv.x, 10.0 * r0), time));
    float r1 = 0.5 - 0.5 * gnm + rnd1;
    r1 = 1.0 - max(0.0, ((r1 < 1.0) ? r1 : 0.9999999));
    float rnd2 = rand(vec2(mytrunc(uv.y, 40.0 * r1), time));
    float r2 = sat(rnd2);
    float rnd3 = rand(vec2(mytrunc(uv.y, 10.0 * r0), time));
    float r3 = (1.0 - sat(rnd3 + 0.8)) - 0.1;
    float pxrnd = rand(uv + time);
    float ofs = 0.05 * r2 * uGlitch * (rnd0 > 0.5 ? 1.0 : -1.0);
    ofs += 0.5 * pxrnd * ofs;
    uv.y += 0.1 * r3 * uGlitch;

    const int NUM_SAMPLES = 20;
    float taps = uTaps > 0.5 ? min(uTaps, float(NUM_SAMPLES)) : float(NUM_SAMPLES);
    float recip = 1.0 / taps;
    float spread = 19.0 / max(taps - 1.0, 1.0);
    vec4 sum = vec4(0.0);
    vec3 weightSum = vec3(0.0);
    for (int i = 0; i < NUM_SAMPLES; ++i)
    {
        if (float(i) >= taps) break;
        float t = float(i) * recip;
        vec2 sampleUV = uv;
        sampleUV.x = sat(sampleUV.x + ofs * t * spread);
        vec4 sampleColor = flixel_texture2D(bitmap, sampleUV);
        vec3 spectrum = spectrum_offset(t);
        sampleColor.rgb *= spectrum;
        sum += sampleColor;
        weightSum += spectrum;
    }
    sum.rgb /= max(weightSum, vec3(0.0001));
    sum.a *= recip;
    gl_FragColor = vec4(sum.rgb, sum.a);
}
