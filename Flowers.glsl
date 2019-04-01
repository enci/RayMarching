#define PI 3.14159265
#define TAU (2.0*PI)
#define PHI (sqrt(5)*0.5 + 0.5)

#define SPEED (PI / 5.0)
#define RENDER_DIST 1

float cross2(in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

float sdCircle( vec2 p, float r )
{
  return length(p) - r;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
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

// uneven capsule
float sdUnevenCapsuleY( in vec2 p, in float ra, in float rb, in float h )
{
	p.x = abs(p.x);
    
    float b = (ra-rb)/h;
    vec2  c = vec2(sqrt(1.0-b*b),b);
    float k = cross2(c,p);
    float m = dot(c,p);
    float n = dot(p,p);
    
         if( k < 0.0   ) return sqrt(n)               - ra;
    else if( k > c.x*h ) return sqrt(n+h*h-2.0*h*p.y) - rb;
                         return m                     - ra;
}
    
float sdUnevenCapsule( in vec2 p, in vec2 pa, in vec2 pb, in float ra, in float rb )
{
    p  -= pa;
    pb -= pa;
    float h = dot(pb,pb);
    vec2  q = vec2( dot(p,vec2(pb.y,-pb.x)), dot(p,pb) )/h;
    
    //-----------
    
    q.x = abs(q.x);
    
    float b = ra-rb;
    vec2  c = vec2(sqrt(h-b*b),b);
    
    float k = cross2(c,q);
    float m = dot(c,q);
    float n = dot(q,q);
    
         if( k < 0.0 ) return sqrt(h*(n            )) - ra;
    else if( k > c.x ) return sqrt(h*(n+1.0-2.0*q.y)) - rb;
                       return m                       - ra;
}

float sdEllipse( in vec2 p, in vec2 ab )
{
    p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
    float l = ab.y*ab.y - ab.x*ab.x;
	
    float m = ab.x*p.x/l;      float m2 = m*m; 
    float n = ab.y*p.y/l;      float n2 = n*n; 
    float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
	
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;

    float co;
    if( d < 0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }

    vec2 r = ab * vec2(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}

float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);

    float b = sqrt(r*r-d*d); // can delay this sqrt
    return ((p.y-b)*d > p.x*b) 
            ? length(p-vec2(0.0,b))
            : length(p-vec2(-d,0.0))-r;
}

float sdVesicaX(vec2 p, float r, float d)
{
    p = abs(p);

    float b = sqrt(r*r-d*d); // can delay this sqrt
    return ((p.x-b)*d > p.y*b) 
            ? length(p-vec2(b, 0.0))
            : length(p-vec2(0.0, -d))-r;
}

void opMirror(inout float pos)
{
    if(pos < 0.0)
        pos = -pos;
}

void opRotate(inout vec2 p, float angle)
{
    mat2 rot = mat2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle));
    p = rot * p;
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
void opModPolar(inout vec2 p, float repetitions)
{
	float angle = 2.0 * PI / repetitions;
	float a = atan(p.y, p.x) + angle/2.0;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.0;
	p = vec2(cos(a), sin(a)) * r;
}

float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }


vec3 distanceColor(float d)
{
#if RENDER_DIST
    vec3 col = vec3(1.0) - sign(d)*vec3(0.1,0.4,0.7);
	col *= 1.0 - exp(-3.0*abs(d));
	col *= 0.8 + 0.2*cos(120.0*d);
	col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.015,abs(d)) );
    return col;
#else
    return vec3( 1.0-smoothstep(0.0, 0.055,abs(d)) );
#endif
}

vec3 flowerOne(vec2 p)
{
    opRotate(p, iTime * SPEED);
    opModPolar(p, 6.0);

    p -= vec2(0.5, 0.0);    
    float d = sdVesicaX( p, 0.50, 0.3 );

    return distanceColor(d);
}

vec3 flowerTwo(vec2 p)
{
    opRotate(p, iTime * SPEED);
    opModPolar(p, 6.0);

    float d = sdUnevenCapsule(
        p,
        vec2(0.2, 0.0),
        vec2(0.6, 0.0),
        0.03,
        0.15);
    
    return distanceColor(d);
}

vec3 flowerThree(vec2 p)
{
    opRotate(p, iTime * SPEED);    
    opModPolar(p, 6.0);

    p -= vec2(0.4, 0.0);
    float d = 1.0 / 0.0;
    d = sdVesicaX( p, 0.70, 0.4 );
    d = opSubtraction(sdBox(p - vec2(-0.4, 0.0), vec2(0.4, 0.4)), d);
    d = opUnion(sdCircle(p, 0.3), d);

    return distanceColor(d);
}

vec3 flowerFour(vec2 p)
{
    opRotate(p, iTime * SPEED);
    opModPolar(p, 6.0);

    float d = 1.0 / 0.0;
    float c0 = sdUnevenCapsule(p, vec2(0.2, 0.0), vec2(0.6, 0.1), 0.045, 0.13);
    float c1 = sdUnevenCapsule(p, vec2(0.2, 0.0), vec2(0.6, -0.1), 0.045, 0.13);
    d = opUnion(c0, c1);
    
    return distanceColor(d);
}

vec3 flowerFive(vec2 p)
{
    opRotate(p, iTime * SPEED);
    opModPolar(p, 6.0);

    float d = 1.0 / 0.0;

    float e0 = sdEllipse(p - vec2(0.5, 0.0), vec2(0.4, 0.15));
    float e1 = sdEllipse(p - vec2(0.25, 0.0), vec2(0.2, 0.08));

    d = opSubtraction(e1, e0);    
    return distanceColor(d);
}

vec3 flowerSix(vec2 p)
{
    opRotate(p, iTime * SPEED);
    opModPolar(p, 6.0);

    float d = 1.0 / 0.0;

    float e0 = sdEllipse(p - vec2(0.5, 0.0), vec2(0.3, 0.18));
    float e1 = sdEllipse(p - vec2(0.57, 0.0), vec2(0.2, 0.11));
    float e3 = sdEllipse(p - vec2(0.40, 0.0), vec2(0.2, 0.03));

    d = opSubtraction(e1, e0); 
    d = opUnion(d, e3);
    return distanceColor(d);
}

vec3 flowerSeven(vec2 p)
{
    opRotate(p, iTime * SPEED);
    p *= 1.15;

    vec2 p0 = p;
    opModPolar(p0, 6.0);
    p0 -= vec2(0.6, 0.0);
    float d = 1.0 / 0.0;
    d = sdVesicaX( p0, 0.60, 0.4 );
    d = opSubtraction(sdBox(p0 - vec2(-0.4, 0.0), vec2(0.4, 0.4)), d);
    d = opUnion(sdCircle(p0, 0.2), d);

    vec2 p1 = p;
    opRotate(p1, TAU / (2.0 * 6.0));
    opModPolar(p1, 6.0);
    p1 -= vec2(0.25, 0.0);
    float d1 = 1.0 / 0.0;
    d1 = sdVesicaX( p1, 0.25, 0.16 );
    d1 = opSubtraction(sdBox(p1 - vec2(-0.11, 0.0), vec2(0.11, 0.2)), d1);
    d1 = opUnion(sdCircle(p1, 0.09), d1);

    return distanceColor(opUnion(d, d1));
}

vec3 flowerEight(vec2 p)
{
    opRotate(p, iTime * SPEED);
    
    float d = 1.0 / 0.0;
    for(int i = 0; i < 6; i++)
    {
        opRotate(p, TAU / 6.0);
        float c = sdLine(p, vec2(0.25, 0.15), vec2(0.75, 0.0));
        c = opRound(c, 0.08);
        d = opUnion(d, c);
    }
    
    d = opUnion(d, sdCircle(p, 0.1));
    
    return distanceColor(d);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
float opUnionRound(float a, float b, float r) {
	vec2 u = max(vec2(r - a,r - b), vec2(0));
	return max(r, min (a, b)) - length(u);
}

vec3 flowerTen(vec2 p)
{
    float d = 1.0 / 0.0;
    for(float i = 0.0; i < 6.0; i += 1.0)
    {
        opRotate(p, iTime * SPEED);
        float c = sdLine(p, vec2(0.25, 0.1), vec2(0.75, 0.0));
        //c = opRound(d, 0.2);
        d = opUnion(d, c);
    }
    
    return distanceColor(d);
}

vec3 flowerNine(vec2 p)
{
    opRotate(p, iTime * -SPEED);
    opModPolar(p, 6.0);

    float c = sdCircle(p - vec2(0.4, 0.0), 0.18);
    p -= vec2(0.68, 0.0);
    opRotate(p, PI * 0.25);
    float b = sdBox(p, vec2(0.15, 0.15));

    float d = opUnionRound(c, b, 0.1);
    return distanceColor(d);
}

void main()
{  
    // Test the coordinate system
    // float v = gl_FragCoord.x / iResolution.x;
    // gl_FragColor = vec4(v, v, v, 1.0);

    vec2 spos = gl_FragCoord.xy / iResolution.xy;
    float rep = 3.0;
    float i = floor(spos.x * rep);
    float j = floor(spos.y * rep);
    spos.x = mod(spos.x, 1.0 / rep) * rep;
    spos.y = mod(spos.y, 1.0 / rep) * rep;
    gl_FragColor = vec4(i, j, 0.0, 1.0);
    vec2 p = 2.0 * spos - vec2(1.0, 1.0);
    p.x *= iResolution.x / iResolution.y;

    int idx = int(i * rep + j);
    vec3 color;
    switch(idx)
    {
        case 0:
            color = flowerOne(p);
            break;
        case 1:
            color = flowerTwo(p);
            break;
        case 2:
            color = flowerThree(p);
            break;
        case 3:
            color = flowerFour(p);
            break;
        case 4:
            color = flowerFive(p);
            break;
        case 5:
            color = flowerSix(p);
            break;
        case 6:
            color = flowerSeven(p);
            break;
        case 7:
            color = flowerEight(p);
            break;
        case 8:
            color = flowerNine(p);
            break;
    }

    gl_FragColor = vec4(color, 1.0);
}