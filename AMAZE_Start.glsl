///// Defines ///////////////////////////////////////////////////////////////
#define PI 3.14159265
#define TAU (2.0*PI)
#define EPSILON 0.0001
#define MAX_STEPS 364
// Scene defines
#define SPEED 0.5
#define LIGHT_SPEED 10.0
#define LIGHT_RADIUS 0.6


///// Shapes ////////////////////////////////////////////////////////////////
float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdPlane(vec3 p, vec4 n)
{
    return dot(p, n.xyz) + n.w;
}

float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) - r
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdCylinderY(vec3 p, vec3 c)
{
  return length(p.xz-c.xy)-c.z;
}

float sdCylinderZ(vec3 p, vec3 c)
{
  return length(p.xy-c.xy)-c.z;
}

float sdCylinderX(vec3 p, vec3 c)
{
  return length(p.zy-c.xy)-c.z;
}


///// Operators /////////////////////////////////////////////////////////////
float opUnionStairs(float a, float b, float r, float n)
{
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.0 * s)) - s)));
}

void opRepeat(inout float coor, float repeat)
{
  coor = mod(coor + repeat * 0.5, repeat) - repeat * 0.5;
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

///// Scene /////////////////////////////////////////////////////////////////

vec4 getLightPos()
{  
  float x = iTime * SPEED * 12.0 + 18.0;
  return vec4(
    x,
    sin(x * (PI / 6.0)) * 2.0 + 3.0,
    sin(x * (PI / 12.0) + PI * 0.5) * 13.0 + 6.0,
    LIGHT_RADIUS * 0.5 + abs(sin(x * (PI / 3.0))) * LIGHT_RADIUS * 0.5);
}

float pillarsSdf(vec3 pos)
{
    const float repeat = 12.0;
    opRepeat(pos.x, repeat);
    opRepeat(pos.z, repeat);

    float d = 1.0 / 0.0;
    float pillar = sdBox(pos, vec3(1.0, 5.0, 1.0));
    float base = sdBox(pos, vec3(1.5, 0.5, 1.5));
    float top = sdBox(pos - vec3(0.0, 4.5, 0.0), vec3(1.25, 0.2, 1.25));
    d = opUnionStairs(pillar, base, 0.5, 3.0);
    d = opUnionStairs(d, top, 0.3, 2.0);
    return d;
}

float floorSdf(vec3 pos)
{
  opRepeat(pos.x, 1.0);
  opRepeat(pos.z, 1.0);
  return sdRoundBox(pos, vec3(0.45, 0.2, 0.45), 0.05);
}

float ceilingSdf(vec3 pos)
{ 
  pos -= vec3(6.0, 5.0, 6.0);
  float b = sdPlane(pos, vec4(0.0, -1.0, 0.0, 0.0)); 
  const float repeat = 12.0;
  opRepeat(pos.x, repeat);
  opRepeat(pos.z, repeat);
  float cz = sdCylinderZ(pos, vec3(0.0, 0.0, 5.0));
  float cx = sdCylinderX(pos, vec3(0.0, 0.0, 5.0));
  float c = min(cz, cx);   
  return opSubtraction(c, b);
}

float sdf(vec3 pos)
{    
  float d = 1.0 / 0.0;
  d = floorSdf(pos);
  d = min(d, pillarsSdf(pos));
  d = min(d, ceilingSdf(pos));
  vec4 light = getLightPos();
  d = min(d, sdSphere(pos - light.xyz, light.w));
  return d;
}

///// Tracing ///////////////////////////////////////////////////////////////

vec3 getCameraRayDir(vec2 uv, vec3 camPos, vec3 camTarget)
{
    // Calculate camera's "orthonormal basis", i.e. its transform matrix components
    vec3 camForward = normalize(camTarget - camPos);
    vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camForward));
    vec3 camUp = normalize(cross(camForward, camRight));
     
    float fPersp = 2.0;
    vec3 vDir = normalize(uv.x * camRight + uv.y * camUp + camForward * fPersp);
 
    return vDir;
}

float castRay(vec3 rayOrigin, vec3 rayDir)
{
    float t = 0.0; // Stores current distance along ray
     
    for (int i = 0; i < MAX_STEPS; i++)
    {
        float res = sdf(rayOrigin + rayDir * t);
        if (res < (EPSILON * t))
        {
            return t;
        }
        t += res;
    }
     
    return -1.0;
}

vec3 calcNormal(vec3 pos)
{
    // Center sample
    float c = sdf(pos);
    float eps = 0.001;
    return normalize(
        vec3(
            sdf(pos + vec3(eps, 0.0, 0.0)),
            sdf(pos + vec3(0.0, eps, 0.0)),
            sdf(pos + vec3(0.0, 0.0, eps))) - c);
}

vec3 render(vec3 rayOrigin, vec3 rayDir)
{ 
	float t = castRay(rayOrigin, rayDir);

    vec3 color;
    vec3 backColor = vec3(1.0, 1.0, 1.0);

    if (t == -1.0)
    {
        color = backColor;
    }
    else
    {
        vec3 objectSurfaceColour = vec3(1.0, 1.0, 1.0);
        vec3 lightColor =  vec3(1.0, 1.0, 1.0);

        vec3 pos = rayOrigin + rayDir * t;
        vec3 N = calcNormal(pos);
        vec4 lightInfo = getLightPos();
        vec3 light = lightInfo.xyz - pos;
        float d = length(light);
        vec3 L = normalize(light);

        if(d < lightInfo.w * 1.01)
        {
            color = lightColor;        
        } 
        else
        {
        float intensity = 0.4 + (1.0 + sin( iTime * LIGHT_SPEED * 2.0 )) * 0.0;
        intensity *= 0.5 / clamp((d * d), 0.0, 1.0);
        // L is vector from surface point to light, N is surface normal. N and L must be normalized!
        float NoL = max(dot(N, L), 0.0);
        vec3 LDirectional = vec3(0.9, 0.9, 0.8) * NoL;
        vec3 LAmbient = vec3(0.03, 0.04, 0.1);

        float shadowCast = castRay(lightInfo.xyz - L * (lightInfo.w + 0.5), -L);
        if(shadowCast <= (d - (lightInfo.w + 0.51)))
          intensity *= 0.3;

        vec3 diffuse = objectSurfaceColour * (LDirectional + LAmbient);
        diffuse *= intensity * lightColor;

        color = mix(diffuse, backColor, saturate(t / 200.0));
        color = mix(color, mix(diffuse, backColor, 0.5), pow(saturate((3.0 - pos.y) / 6.0), 1.6));
      }
    }

    color = pow(color, vec3(0.4545));

  return color;
}

vec3 calculateCameraPos()
{  
    return vec3(iTime * SPEED * 12.0, 3.0, 6.0);
}


vec2 normalizeScreenCoords(vec2 screenCoord)
{
    vec2 result = 2.0 * (screenCoord/iResolution.xy - 0.5);
    result.x *= iResolution.x/iResolution.y;
    return result;
}

vec2 barrelDistortion(vec2 uv, float k)
{
  float rd = length(uv);    
  float ru = rd * (1.0 + k * rd * rd);
  uv /= rd;
  uv *= ru;
  return uv;
}

void main()
{  
    vec3 cameraPos = calculateCameraPos();
    vec3 lookAt = cameraPos +  vec3(10.0, 0.0, 0.0);

    vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);
    uv = barrelDistortion(uv, 0.25);

    vec3 rayDir = getCameraRayDir(uv, cameraPos, lookAt);
    
    vec3 col = render(cameraPos, rayDir);

    gl_FragColor = vec4(col, 1.0);
}