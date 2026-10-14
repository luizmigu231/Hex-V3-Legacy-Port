#pragma header

uniform float uGray;
uniform float uInvert;

void main()
{
    vec2 p = (openfl_TextureCoordv - vec2(0.5)) * 2.0;
    float r2 = dot(p, p);
    if (r2 >= 1.0)
    {
        gl_FragColor = vec4(0.0);
        return;
    }

    float z = sqrt(max(0.0001, 1.0 - r2));
    vec3 dir = normalize(vec3(p.x, -p.y, z));
    float across = atan(dir.x, -dir.z) / 6.28318530718 + 0.5;
    float down = asin(clamp(dir.y, -1.0, 1.0)) / 3.14159265359 + 0.5;
    vec4 texel = flixel_texture2D(bitmap, vec2(across, down));
    float gray = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
    texel.rgb = mix(texel.rgb, vec3(gray), clamp(uGray, 0.0, 1.0));
    texel.rgb = mix(texel.rgb, vec3(1.0) - texel.rgb, clamp(uInvert, 0.0, 1.0));
    gl_FragColor = texel;
}
