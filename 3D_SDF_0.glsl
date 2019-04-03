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

vec3 render(vec3 rayOrigin, vec3 rayDir)
{ 
    /*
	float t = castRay(rayOrigin, rayDir);

	//vec3 L = normalize(vec3(sin(iTime)*1.0, cos(iTime*0.5)+0.5, -0.5));
  vec3 color;
  vec3 backColor = vec3(0.35, 0.35, 0.35);

  if (t == -1.0)
  {
    color = backColor;
  }
  else
  {
      vec3 pos = rayOrigin + rayDir * t;
      //vec3 objectSurfaceColour = vec3(0.9, 0.7, 0.7);
      vec3 objectSurfaceColour = vec3(1.0, 1.0, 1.0);
      vec3 ambient = vec3(0.02, 0.021, 0.02);
      vec3 N = calcNormal(pos);

      vec4 lightInfo = getLightPos();
      vec3 light = lightInfo.xyz - pos;
      float d = length(light);
      vec3 L = normalize(light);

      if(d < lightInfo.w * 1.01)
      {
        color = vec3(1.0, 1.0, 1.0);        
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

        vec3 diffuse = objectSurfaceColour * (LDirectional + LAmbient) * intensity;

        color = mix(diffuse, backColor, saturate(t / 200.0));
      }
  }

  //color = pow(color, vec3(0.4545));
  // debugPlane(color, rayOrigin, rayDir, t);
 	
  return color;
  */

  return vec3(1.0, 0.0, 1.0);
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