#pragma header

uniform float uBeat;
uniform float uGlitch;
uniform float uGray;
uniform float uInvert;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    float amount = clamp(uGlitch, 0.0, 1.0);
    if (amount > 0.001)
    {
        float band = step(0.82, fract(sin(floor(uv.y * 92.0) + floor(uBeat * 4.0) * 13.17) * 43758.5453));
        uv.x = clamp(uv.x + (band - 0.5) * amount * 0.025, 0.0, 1.0);
    }
    vec4 color = flixel_texture2D(bitmap, uv);
    if (color.a > 0.0)
    {
        float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
        color.rgb = mix(color.rgb, vec3(gray), clamp(uGray, 0.0, 1.0));
        color.rgb = mix(color.rgb, vec3(1.0) - color.rgb, clamp(uInvert, 0.0, 1.0));
    }
    gl_FragColor = color;
}
