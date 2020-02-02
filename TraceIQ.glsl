#version 430 core
#define FLT_MAX 1000000000.0

struct Intersection
{
    float distance;
    int objectID;
};

struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct Sphere
{
    vec3 origin;
    float radius;
};

struct Camera
{
    vec3 origin;
	vec3 lowerLeftCorner;
	vec3 horizontal;
	vec3 vertical;
};

/*
struct Seed
{
    float seed;
};
*/

#define SPHERE_COUNT 4
const Sphere spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT](
	Sphere(vec3(0.0, 2.0, 0.0), 2.0)
	, Sphere(vec3(3.0, 1.0, 0.0), 1.0)
    , Sphere(vec3(2.0, 0.5, 2.0), 0.5)
    , Sphere(vec3(0.0, -10000.0, 0.0), 10000.0)
);

const vec3 background = vec3(1.0f, 0.96, 0.92);

const uint k = 1103515245U;  // GLIB C
vec3 hash( uvec3 x )
{
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    return vec3(x)*(1.0/float(0xffffffffU));
}

float hash(float seed)
{
    return fract(sin(seed)*43758.5453 );
}

vec3 cosineDirection( in float seed, in vec3 nor)
{
    // compute basis from normal
    // see http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
    // (link provided by nimitz)
    vec3 tc = vec3( 1.0+nor.z-nor.xy*nor.xy, -nor.x*nor.y)/(1.0+nor.z);
    vec3 uu = vec3( tc.x, tc.z, -nor.x );
    vec3 vv = vec3( tc.z, tc.y, -nor.y );
    
    float u = hash( 78.233 + seed);
    float v = hash( 10.873 + seed);
    float a = 6.283185 * v;

    return  sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
}

float sphereTest(in Ray ray, in Sphere sphere)
{
    float t = -1.0;
	vec3 rc = ray.origin - sphere.origin;
	float c = dot(rc, rc) - (sphere.radius * sphere.radius);
	float b = dot(ray.direction, rc);
	float d = b*b - c;
    if(d > 0.0)
    {
	    t = -b - sqrt(abs(d));
        return t;
	    float st = step(0.0, min(t,d));
    } else  
    {
        return -1.0;
    }
}

Intersection intersect(in Ray ray)
{
    float minD = FLT_MAX;
    Intersection intersection;
    for(int i = 0; i < SPHERE_COUNT; i++)
    {
        Sphere s = spheres[i];
        float t = sphereTest(ray, s);
        //float t = sphereTest(ray, s);
        if(t > 0.0 && t < minD)
        {
            minD = t;
            intersection.distance = t;
            intersection.objectID = i;
        }
    }
    return intersection;
}

vec3 getNormal(in vec3 position, in int objectID)
{
    Sphere s = spheres[objectID];
    return normalize(position - s.origin);
}

vec3 getColor(in vec3 position, in int objectID)
{
    int idx = objectID;

    /*
    switch(idx)
    {
        case 0 : return vec3(0.2, 0.6, 0.4);
        case 1 : return vec3(0.7, 0.2, 0.4);
        case 2 : return vec3(0.2, 0.2, 0.7);
        case 3 : return vec3(0.2, 0.6, 0.4);
    }*/

    switch(idx)
    {
        case 0 : return vec3(0.0, 0.6, 0.0);
        case 1 : return vec3(0.7, 0.0, 0.0);
        case 2 : return vec3(0.0, 0.0, 0.7);
        case 3 : return vec3(0.2, 0.6, 0.4);
    }
}

vec3 getBackground(in vec3 direction)
{
    return vec3(0.9, 0.85, 1.0);
}

Camera MakeCamera(  in vec3 origin,
                    in vec3 lookAt,
                    in vec3 up,
	                float fov,
	                float aspect)
{
    Camera camera;
    vec3 u, v, w;
	float theta = radians(fov);
	float halfHeight = tan(theta * 0.5f);
	float halfWidth = aspect * halfHeight;
	w = normalize(origin - lookAt);
	u = normalize(cross(normalize(up), w));
	v = normalize(cross(w, u));
    camera.origin = origin;
	camera.lowerLeftCorner =  origin - halfWidth * u - halfHeight * v - w;
	camera.horizontal = 2.0f * halfWidth * u;
	camera.vertical = 2.0f * halfHeight * v;
    return camera;
}

Ray MakeRay(in Camera camera,float s, float t)
{
    vec3 direction = camera.lowerLeftCorner + s * camera.horizontal + (1.0f -  t) * camera.vertical - camera.origin;
    direction = normalize(direction);
	return Ray(camera.origin, direction);
}

vec3 lightDirection()
{
    float x = sin(0.5 * 5.0);
    float y = 1.0;
    float z = cos(0.5 * 5.0) - 3.0;
    return normalize(vec3(x, y, z));
}

float sphereTest(   vec3 ray,
                    vec3 dir,
                    vec3 center,
                    float radius,
                    out vec3 normal,
                    out float t)
{
	vec3 rc = ray-center;
	float c = dot(rc, rc) - (radius*radius);
	float b = dot(dir, rc);
	float d = b*b - c;
	t = -b - sqrt(abs(d));
	float st = step(0.0, min(t,d));
    
    vec3 pos = ray + dir * t;
    normal = pos - center;
    normal = normalize(normal);
    return mix(-1.0, t, st);
}

/*
float hit(in Ray ray, in Sphere sphere, out float t, out vec3 normal)
{
    if(sphereTest(ray.origin, ray.direction, sphere.origin, sphere.radius, normal, t) >= 0.0)
		return t;
    else
        return -1.0;
}
*/

/*
vec3 trace(in Ray ray, int levels)
{
    vec3 color = vec3(0.0);
    vec3 fcol = vec3(1.0);
    for(int i = 0; i < levels; i++)
    {
        float mint = 100000000.0;
        vec3 normal;
        for(int i = 0; i < SPHERE_COUNT; i++)
        {
            Sphere s = sp[i];
            float t;
            vec3 tnorm;
            float c = hit(ray, s, t, tnorm);
            if(c != -1.0 && t < mint)
            {
                //vec3 col = vec3(1,1,1);
                normal = tnorm;            
                mint = t;
                //color = col * c;
            }
        }
        if(mint != 100000000.0)
        {
            color += dot(normal, lightDirection());
        }   
        //return color;
    }

    return color;
}
*/

vec3 applyLighting(in vec3 position, in vec3 normal, int objectID)
{
    return vec3(0.0);
    vec3 light = normalize(vec3(1.0, 1.0, 1.0));
    return vec3(max(dot(normal, light), 0.0));
}

vec3 getBRDFRay(in vec3 position, in vec3 normal, int objectID, float seed)
{
    return cosineDirection(seed, normal);
}


// create light paths iteratively
vec3 rendererCalculateColor(Ray ray, in int bounces, float seed)
{
    vec3 tcol = vec3(0.0);  // accumulator - should get brighter
    vec3 fcol = vec3(1.0);  // mask - should get darker

    for( int i = 0; i < bounces; i++)
    {
        // intersect scene
        Intersection intersection = intersect(ray);

        /*
        if(intersection.distance > 0.0)
        {
            tcol = vec3(1.0, 0.0, 1.0);
        }
        else
        {
            tcol = vec3(1.0, 0.0, 0.0);
        }
        break;
        */

        // if nothing found, return background color or break
        if(intersection.distance <= 0.0) 
        {
            tcol = getBackground(ray.direction);
            break;

            //if(i == 0)
            //{
            //    fcol = getBackground(ray.direction);
            //    //tcol = getBackground(ray.direction);
            //}
            //else
            //    break;
            //break;
        }

        
        // get position and normal at the intersection point
        vec3 pos = ray.origin + ray.direction * intersection.distance;
        vec3 nor = getNormal(pos, intersection.objectID);

        // Debug
        // tcol = pos / 10.0;
        // break;
        
        // get color for the surface
        vec3 scol = getColor(pos, intersection.objectID);
        tcol = scol;
        //break;

        // compute direct lighting
        vec3 dcol = applyLighting(pos, nor, intersection.objectID);
        // tcol = dcol;

        // prepare ray for indirect lighting gathering
        ray.origin = pos;
        //seed += .021;
        ray.direction = getBRDFRay(pos, nor, intersection.objectID, seed);

        // surface * lighting
        fcol *= scol;
        tcol += fcol * dcol;
    }

    return tcol;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    float x = fragCoord.x;
    float y = fragCoord.y;
    float width = iResolution.x;
    float height = iResolution.y;
    
    float cx = sin(iTime * 2.0) * 10.0;
    float cy = 1.0;
    float cz = cos(iTime * 2.0) * 10.0; 

    Camera camera = MakeCamera(
        vec3(cx, cy, cz),
        vec3(0.0, 0.0, 0.0),
        vec3(0.0, 1.0, 0.0),
        60.0, 1.6);

    Ray ray = MakeRay(camera, x / width, 1.0 - (y / height));

    //float sa = hash( dot( fragCoord, vec2(12.9898, 78.233) ) + 1113.1*float(iFrame) );
    vec3 sa = hash( uvec3(x, y, iTime * 10.0) );
    float seed = sa.x; 
    vec3 color = vec3(0.0);
    const int samples = 16;
    for( int i = 0; i < samples; i++)
    {
        color += rendererCalculateColor(ray, 2, seed);
        seed += 1.0;
    }
    color /= float(samples);

	// vec3 color = trace(ray, 1);
    // vec3 color = vec3(x / width, y / width, 0.0);
    
    fragColor = vec4(color, 1.0);
}