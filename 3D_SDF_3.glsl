#define EPSILON 0.0001
#define MAX_STEPS 264

float sdSphere(vec3 p, float r)
{
    return length(p)-r;
}

float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdf(vec3 pos)
{    
  float d = 1.0 / 0.0;
  d = sdBox(pos, vec3(1.0,1.0, 1.0));
  //d = floorSdf(pos);
  //d = min(d, pillarsSdf(pos));
  //d = min(d, ceilingSdf(pos));
  //vec4 light = getLightPos();
  //d = min(d, sdSphere(pos - light.xyz, light.w));
  return d;
}

vec3 calculateCameraPos()
{  
  float dist = 10.0;
  float speed = 0.5;
  return vec3(sin(iTime * speed) * dist, 3.0, cos(iTime * speed) * dist);
  //return vec3(iTime * SPEED, 3.0, 6.0);
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

    vec3 light = normalize(vec3(1.0, 2.0, 5.0));
    vec3 L = normalize(light);
    float NoL = max(dot(N, L), 0.0);
    vec3 LDirectional = vec3(0.9, 0.9, 0.8) * NoL;
    vec3 LAmbient = vec3(0.03, 0.04, 0.1);
    vec3 diffuse = objectSurfaceColour * (LDirectional + LAmbient);
    color = diffuse;
  }

  return color;
}

void main()
{  
  vec3 cameraPos = calculateCameraPos();
  //vec3 lookAt =  cameraPos + vec3(10.0, 0.0, 0.0);
  vec3 lookAt =  vec3(0.0, 0.0, 0.0);


  vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);  
  //uv = barrelDistortion(uv, 0.25);

  vec3 rayDir = getCameraRayDir(uv, cameraPos, lookAt);
    
  vec3 col = render(cameraPos, rayDir);
    
  gl_FragColor = vec4(col,1.0); // Output to screen
}