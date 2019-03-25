#define EPSILON 0.0001
#define MAX_STEPS 264

// Shapes

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) - r
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdPlane(vec3 p, vec4 n)
{
    return dot(p, n.xyz) + n.w;
}

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
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

// Combine shapes

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float opUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.0 * s)) - s)));
}

void opRepeat(inout float coor, float repeat)
{
  coor = mod(coor + repeat, repeat * 2.0) - repeat;
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float floorSdf(vec3 pos)
{
  opRepeat(pos.x, 0.5);
  opRepeat(pos.z, 0.5);
  return sdRoundBox(pos, vec3(0.45, 0.2, 0.45), 0.05);
}

float ceilingSdf(vec3 pos)
{ 
  /*
  float b = sdPlane(pos, vec4(0.0, -1.0, 0.0, 5.0)); 
  const float repeat = 12.0;
  opRepeat(pos.x, repeat);
  opRepeat(pos.z, repeat);
  float cz = sdCylinderZ(pos - vec3(6.0, 5.0, 6), vec3(0.0, 0.0, 5.0));
  float cx = sdCylinderX(pos - vec3(6.0, 5.0, 6), vec3(0.0, 0.0, 5.0));
  float c = min(cz, cx);   
  //float b = sdBox(pos - vec3(6.0, 11.0, 6.0) , vec3(6.0, 6.0, 6.0));
  return opSubtraction(c, b);
  */

  const float repeat = 6.0;
  opRepeat(pos.x, repeat);
  opRepeat(pos.z, repeat);
  //float cz = sdCylinderZ(pos /* - vec3(6.0, 5.0, 6)*/, vec3(0.0, 0.0, 5.0));
  //float cx = sdCylinderX(pos /* - vec3(6.0, 5.0, 6) */, vec3(0.0, 0.0, 5.0));
  //float c = min(cz, cx);   
  float b = sdBox(pos - vec3(6.0, 11.0, 6.0), vec3(2.0, 2.0, 2.0));
  return b;
}

float pillarsSdf(vec3 pos)
{
  const float repeat = 6.0;
  opRepeat(pos.x, repeat);
  opRepeat(pos.z, repeat);

  float pillar = sdBox(pos, vec3(1.0, 5.0, 1.0));
  float base = sdBox(pos, vec3(1.5, 0.5, 1.5));
  return opUnionStairs(pillar, base, 0.5, 3.0);
  //return t;
}


float sdf(vec3 pos)
{    
  float t = 1.0 / 0.0;

  t = floorSdf(pos);
  t = min(t, pillarsSdf(pos));
  t = min(t, ceilingSdf(pos));
  return t;
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

vec2 normalizeScreenCoords(vec2 screenCoord)
{
    vec2 result = 2.0 * (screenCoord/iResolution.xy - 0.5);
    result.x *= iResolution.x/iResolution.y;
    return result;
}

vec3 calcNormal(vec3 pos)
{
    // Center sample
    float c = sdf(pos);
    // Use offset samples to compute gradient / normal
    vec2 eps_zero = vec2(0.001, 0.0);
    return normalize(vec3( sdf(pos + eps_zero.xyy), sdf(pos + eps_zero.yxy), sdf(pos + eps_zero.yyx) ) - c);
}

float trPlane(vec3 rayOrigin, vec3 rayDir, vec4 normal)
{  
	float d = dot(normal.xyz, rayDir);

  // Normal and ray perpendicular 
	if (d == 0.0)
		return -1.0;
	
	float t = (normal.w - dot(normal.xyz, rayOrigin)) / d;

	// Behind ray
  if (t <= 0.0)
  	return -1.0;
	
	return t;
}

void debugPlane(inout vec3 color, vec3 rayOrigin, vec3 rayDir, float dist)
{
  vec3 up = vec3(0.0, 1.0, 0.0);
  float t = trPlane(rayOrigin, rayDir, vec4(up, 0.0));  

  if(t > 0.0 && (t < dist || dist == -1.0))
  {
    vec3 pos = rayOrigin + rayDir * t;
    float d = sdf(pos);

    vec3 col = vec3(1.0) - sign(d) * vec3(0.1, 0.4, 0.7);
	  col *= 1.0 - exp(-2.0 * abs(d));
	  col *= 0.8 + 0.2 * cos(20.0 * d);
	  col = mix( col, vec3(1.0), 1.0 - smoothstep(0.0, 0.15, abs(d)) );
    color = col;
  }
}

vec3 render(vec3 rayOrigin, vec3 rayDir)
{ 

	float t = castRay(rayOrigin, rayDir);
	vec3 L = normalize(vec3(sin(iTime)*1.0, cos(iTime*0.5)+0.5, -0.5));
  vec3 color;

  if (t == -1.0)
  {
    color = vec3(0.5, 0.5, 0.5);
    // Skybox color
    //color = vec3(0.5, 0.5, 0.5) - (rayDir.y * 0.7);      
  }
  else
  {
      vec3 pos = rayOrigin + rayDir * t;
      vec3 objectSurfaceColour = vec3(0.9, 0.7, 0.7);
      vec3 ambient = vec3(0.02, 0.021, 0.02);
      vec3 N = calcNormal(pos);

      // L is vector from surface point to light, N is surface normal. N and L must be normalized!
      float NoL = max(dot(N, L), 0.0);
      vec3 LDirectional = vec3(0.9, 0.9, 0.8) * NoL;
      vec3 LAmbient = vec3(0.03, 0.04, 0.1);
      vec3 diffuse = objectSurfaceColour * (LDirectional + LAmbient);
      color = diffuse; // * objectSurfaceColour;

      //color = mix(diffuse, vec3(0.5, 0.5, 0.5), saturate(t / 200.0));      
  }

  color = pow(color, vec3(0.4545));

  debugPlane(color, rayOrigin, rayDir, t);
 	
  return color;
}

vec3 calculateCameraPos()
{  
  float dist = 10.0;
  return vec3(sin(iTime * 0.5) * dist, 3.0, cos(iTime * 0.5) * dist);
}

void main()
{  
  vec3 cameraPos = calculateCameraPos();
  vec3 lookAt =  vec3(0.0, 2.0, 0.0);

  vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);  
  vec3 rayDir = getCameraRayDir(uv, cameraPos, lookAt);
    
  vec3 col = render(cameraPos, rayDir);
    
  gl_FragColor = vec4(col,1.0); // Output to screen
}