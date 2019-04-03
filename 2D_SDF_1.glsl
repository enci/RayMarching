#define RENDER_DIST 1

float sdCircle(vec2 p, float r)
{
  return length(p) - r;
}

float sdBox( in vec2 p, in vec2 b )
{
    // Bring to first quadrant
    vec2 d = abs(p)-b;
    return  length(max(d,vec2(0.0))) + min(max(d.x,d.y),0.0);
}

vec3 distanceColor(float d)
{
#if RENDER_DIST
    vec3 col = vec3(1.0) - sign(d)*vec3(0.1,0.4,0.7);
	col *= 1.0 - exp(-3.0*abs(d));
	col *= 0.8 + 0.2*cos(120.0*d);
	col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.015,abs(d)) );
    return col;
#else
    return vec3( 1.0-smoothstep(0.0, 0.015,abs(d)) );
#endif
}

void main()
{  
    // Test the coordinate system

    // Get normalized screen coordinate
    vec2 spos = gl_FragCoord.xy / iResolution.xy;

    // Bring [0,0] to center
    vec2 p = 2.0 * spos - vec2(1.0, 1.0);

    // Correct aspect ratio
    p.x *= iResolution.x / iResolution.y;

    float d = sdBox(p, vec2(0.5, 0.3));
    vec3 color = distanceColor(d);
    gl_FragColor = vec4(color, 1.0);
}