#define EPSILON 0.0001
#define MAX_STEPS 264
#define SPEED 5.0
#define LIGHT_SPEED 10.0
#define LIGHT_RADIUS 0.6

///// Shapes /////////////////////////////////////////////////////////////////////////////////////////
float sdSphere(vec3 p, float r)
{
    return length(p)-r;
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

float sdPlane(vec3 p, vec4 n)
{
    return dot(p, n.xyz) + n.w;
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

void opRepeat(inout float coor, float repeat)
{
  coor = mod(coor + repeat * 0.5, repeat) - repeat * 0.5;
  //coor = mod(coor, repeat);
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }


// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float opUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.0 * s)) - s)));
}


vec4 getLightPos()
{  
  float x = iTime * SPEED + 18.0;
  return vec4(x, sin(iTime) * 2.0 + 3.0, sin(x / 3.14) * 16.0 + 6.0,
  LIGHT_RADIUS * 0.5 + abs(sin(iTime * LIGHT_SPEED)) * LIGHT_RADIUS * 0.5);
}

float floorSdf(vec3 pos)
{
  opRepeat(pos.x, 1.0);
  opRepeat(pos.z, 1.0);
  return sdRoundBox(pos, vec3(0.45, 0.1, 0.45), 0.05);
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

vec3 calculateCameraPos()
{  
  float dist = 10.0;
  float speed = 0.5;
  return vec3(iTime * SPEED, 3.0, 6.0);
}

vec2 normalizeScreenCoords(vec2 screenCoord)
{
    vec2 result = 2.0 * (screenCoord/iResolution.xy - 0.5);
    result.x *= iResolution.x/iResolution.y;
    return result;
}

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

vec3 calcNormal(vec3 pos)
{
    // Center sample
    float c = sdf(pos);
    vec2 eps_zero = vec2(0.001, 0.0);
    return normalize(vec3( sdf(pos + eps_zero.xyy), sdf(pos + eps_zero.yxy), sdf(pos + eps_zero.yyx) ) - c);
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

vec3 render(vec3 rayOrigin, vec3 rayDir)
{ 
  
	float t = castRay(rayOrigin, rayDir);

  vec3 color;
  vec3 backColor = vec3(0.35, 0.35, 0.35);

  if (t == -1.0)
  {
    color = backColor;
  }
  else
  {
    vec3 pos = rayOrigin + rayDir * t;
    vec3 N = calcNormal(pos);

    vec3 objectSurfaceColour = vec3(1.0, 1.0, 1.0);
    //vec3 ambient = vec3(0.02, 0.021, 0.02);

    vec4 lightInfo = getLightPos();
    vec3 light = lightInfo.xyz - pos;
    float d = length(light);
    vec3 L = normalize(light);
    float intensity = 1.0 / clamp((d * d), 0.0, 1.0);

    if(d < lightInfo.w * 1.01)
      {
        color = vec3(1.0, 1.0, 1.0);        
      } 
      else
      {
        float NoL = max(dot(N, L), 0.0);
        vec3 LDirectional = vec3(0.9, 0.9, 0.8) * NoL;
        vec3 LAmbient = vec3(0.03, 0.04, 0.1);
        float shadowCast = castRay(lightInfo.xyz - L * (lightInfo.w + 0.5), -L);
        if(shadowCast <= (d - (lightInfo.w + 0.51)))
          intensity *= 0.3;
        vec3 diffuse = objectSurfaceColour * (LDirectional + LAmbient) * intensity;
        color = mix(diffuse, backColor, saturate(t / 200.0));
      }
  }

  return color;
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
  vec3 lookAt =  cameraPos + vec3(10.0, 0.0, 0.0);

  vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);  
  uv = barrelDistortion(uv, 0.25);

  vec3 rayDir = getCameraRayDir(uv, cameraPos, lookAt);
    
  vec3 col = render(cameraPos, rayDir);
    
  gl_FragColor = vec4(col,1.0); // Output to screen
}