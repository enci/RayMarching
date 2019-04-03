#define PI 3.14159265
#define TAU (2.0*PI)
#define PHI (sqrt(5)*0.5 + 0.5)
#define SPEED (PI / 5.0)
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

float sdLine( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float opRound(float d, float r)
{
  return d - r;
}

void opRotate(inout vec2 p, float angle)
{
    mat2 rot = mat2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle));
    p = rot * p;
}

float opUnion( float d1, float d2 )
{
    return min(d1,d2);
}

float opSubtraction( float d1, float d2 )
{
    return max(-d1, d2);
}

float opIntersection( float d1, float d2 )
{
    return max(d1, d2);
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

    opRotate(p, iTime * -SPEED);
    float d = 1.0 / 0.0;
    for(int i = 0; i < 6; i++)
    {
        float c = sdLine(p, vec2(0.15, 0.15), vec2(0.75, 0.0));
        c = opRound(c, 0.08);
        d = opUnion(d, c);
        opRotate(p, TAU / 6.0);
    }

    float s = sdCircle(p, 0.25);
    d = opUnion(d, s);
    vec3 color = distanceColor(d);
    gl_FragColor = vec4(color, 1.0);
}