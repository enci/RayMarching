void main()
{  
    // Test the coordinate system

    // Get normalized screen coordinate
    vec2 spos = gl_FragCoord.xy / iResolution.xy;

    // Bring [0,0] to center
    vec2 p = 2.0 * spos - vec2(1.0, 1.0);

    // Correct aspect ratio
    p.x *= iResolution.x / iResolution.y;

    float d = length(p);
    d = d  < 0.5 ? 1.0 : 0.0;
    gl_FragColor = vec4(d, d, d, 1.0);
}