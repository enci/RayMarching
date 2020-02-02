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

struct Material
{
    vec3 color;
    float emmisive;
    float roughness;
};

struct Sphere
{
    vec3 origin;
    float radius;
    int material;    
};

struct Camera
{
    vec3 origin;
	vec3 lowerLeftCorner;
	vec3 horizontal;
	vec3 vertical;
};

// From Lighthouse
uint RandomInt(inout uint s)
{
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return s;
}

float RandomFloat(inout uint s)
{
    //return float(RandomInt(s)) * 2.3283064365387e-10;    
    return fract(float(RandomInt(s)) / 3141.592653);
}

vec3 RandomVec3(inout uint s)
{
    vec3 v = vec3(
        (RandomFloat(s) - 0.5f) * 2.0,
        (RandomFloat(s) - 0.5f) * 2.0,
        (RandomFloat(s) - 0.5f) * 2.0);

    // The line bellow does not work
    // vec3 v = vec3(
    //   RandomFloat(s),
    //   RandomFloat(s),
    //   RandomFloat(s));
    // v *= 2.0;
    // v -= vec3(-0.5, -1.0, -1.0);
    return v;
}

vec3 RandomUnitSphere(inout uint s)
{
    vec3 v = vec3(1.0);
    for(int i = 0; i < 16; i++)
	{
        v = RandomVec3(s);
        if(length(v) <= 1.0)
            break;
	}    
    //return v;
    return normalize(v);
}

#define MATERIAL_COUNT 7
const Material materials[MATERIAL_COUNT] = Material[MATERIAL_COUNT](
	Material(vec3(0.5, 0.5, 0.5), 0.0, 1.0)                  // Grey
	, Material(vec3(0.2, 1.0, 0.2), 1.0, 1.0)                // Green
    , Material(vec3(1.0, 1.0, 1.0), 0.0, 1.0)                // White
    , Material(vec3(1.0, 1.0, 1.0), 1.2, 1.0)                // Light 
    , Material(vec3(1.0, 0.0, 1.0), 0.0, 0.0)                // Pink light 
    , Material(vec3(1.0, 1.0, 1.0), 0.0, 0.3)                // Mirror 
    , Material(vec3(1.0, 0.2, 0.2), 1.0, 1.0)                // Red
);

#define SPHERE_COUNT 11
const Sphere spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT](
	Sphere(vec3(0.0, 2.0, 0.0), 2.0, 0)
	, Sphere(vec3(3.0, 1.0, 0.0), 1.0, 3)
    , Sphere(vec3(0.0, 0.5, 2.6), 0.5, 4)
    , Sphere(vec3(0.0, -10000.0, 0.0), 10000.0, 2)          // Bottom
    , Sphere(vec3(0.0, 10009.0, 0.0), 10000.0, 3)           // Top
    , Sphere(vec3(10009.0, 0.0, 0.0), 10000.0, 1)
    , Sphere(vec3(-10009.0, 0.0, 0.0), 10000.0, 6)
    , Sphere(vec3(0.0, 0.0, 10009.0), 10000.0, 2)
    , Sphere(vec3(0.0, 0.0, -10009.0), 10000.0, 2)
    , Sphere(vec3(0.0, 1.0, -4.0), 1.0, 5)
    , Sphere(vec3(-3.0, 0.7, 0.0), 0.7, 2)
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

Material getMaterial(in vec3 position, in int objectID)
{
    int idx = spheres[objectID].material;
    return materials[idx];
}

vec3 getColor(in vec3 position, in int objectID)
{
    int idx = spheres[objectID].material;
    return materials[idx].color;
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

vec3 applyLighting(in vec3 position, in vec3 normal, int objectID)
{
    return vec3(0.0);
    vec3 light = normalize(vec3(1.0, 1.0, 1.0));
    return vec3(max(dot(normal, light), 0.0));
}

vec3 getBRDFRay(in vec3 position, in vec3 normal, in vec3 incident, int objectID, uint seed)
{    
    vec3 ref = reflect(incident, normal);
    Sphere sphere = spheres[objectID];
    Material material = materials[sphere.material];
    return normalize(RandomUnitSphere(seed) * material.roughness + ref);

    //return normalize(RandomUnitSphere(seed) + normal);

    //return RandomVec3(seed);
    // return RandomUnitSphere(seed);  
    return ref;
    //return cosineDirection2(seed, normal);
    }


// create light paths iteratively
vec3 rendererCalculateColor(Ray ray, in int bounces, uint seed)
{
    vec3 accumulator = vec3(0.0);  // accumulator - should get brighter
    vec3 mask = vec3(1.0);  // mask - should get darker

    for( int i = 0; i < bounces; i++)
    {
        // intersect scene
        Intersection intersection = intersect(ray);
        
        // if nothing found, return background color or break
        if(intersection.distance <= 0.01) 
            break;
        
        // get position and normal at the intersection point
        vec3 pos = ray.origin + ray.direction * intersection.distance;
        vec3 nor = getNormal(pos, intersection.objectID);
        
        // get color for the surface
        Material material = getMaterial(pos, intersection.objectID);

        // compute direct lighting
        //vec3 dcol = applyLighting(pos, nor, intersection.objectID);
        // tcol = dcol;
        vec3 emmisive = material.emmisive * material.color;

        // prepare ray for indirect lighting gathering
        ray.origin = pos + nor * 0.01;
        ray.direction = getBRDFRay(pos, nor, ray.direction, intersection.objectID, seed);

        // surface * lighting
        mask *= material.color;
        accumulator += mask * emmisive;
    }

    return accumulator;
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
        vec3(0.0, 2.0, 0.0),
        vec3(0.0, 0.1, 0.0),
        60.0, 1.6);

    Ray ray = MakeRay(camera, x / width, 1.0 - (y / height));

    vec3 sa = hash( uvec3(x, y, iTime * 100.0) );

    //uint seed = (uint(x) + uint(y) * uint(width)) ^ uint(iTime * 10000000.0);

    uint seed = uint(sa.x * 1000.0);

    //float f = float(RandomVec3(seed).y >= 1.0);
    //vec3 color = vec3(f);
    //vec3 color = (RandomVec3(seed) + vec3(1.0)) * 0.5;
    //vec3 color = RandomVec3(seed);
    // vec3 r = RandomUnitSphere(seed);
    //vec3 color = vec3(abs(length(r)) - 1.0 < 0.01);

    vec3 color = vec3(0.0);
    const int samples = 64;
    for( int i = 0; i < samples; i++)
    {
        color += rendererCalculateColor(ray, 3, seed);
        seed += uint(hash(float(i)) * 100.0);
    }
    color /= float(samples);

    fragColor = vec4(pow(color, vec3(0.45)), 1.0);
}