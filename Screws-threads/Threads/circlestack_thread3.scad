/*
circlestack_thread.scad - a smooth thread made from stacked polygons
by A. Matulich, January 2020

See my article describing this approach here:
https://www.nablu.com/2020/01/new-approach-to-screw-threads-in.html
This OpenSCAD source file is on Thingiverse here: https://www.thingiverse.com/thing:4543428

This module generates smooth threads reasonably fast, using an algorithm that connects a vertical stack of polygons.

Rather than using OpenSCAD's linear_extrude on an offset circle and spinning it around with a twist parameter (which generates threads with a lot of surface roughness consisting of highly elongated polygons with razor edges), this module simply generates a stack of offset discs (not necessarily circular) with the same vertices on each disc connected vertically to form a polyhedron. As the discs stack up they are offset and rotated so that the vertices still line up. By deforming the disc appropriately, any thread profile can be created: sinewave, ISO trapezoid, triangle, etc.

The resulting threads have fairly uniform facets resulting in smooth threads, rather than sharp rough surfaces from twisting a circle around with linear_extrude. There is also no need to create a thread profile that twists around a path and combine it with a cylinder; the entire polyhedron is created by the stacked-circle method used here.

This idea was inspired by from sine_thread.scad by Ron Butcher at https://www.thingiverse.com/thing:261244 - which extrudes a circle with a twist, resulting in a sinewave thread having serrated edges. I figured that by pre-calculating the cross-section of the screw thread, a polyhedron can be generated with a smoother thread and any arbitrary thread profile.

Modules:
 threaded_rod() - creates a threaded rod using any profile
 hex_nut(profile, thread_depth, dia, pitch) - creates an ISO-sized hex nut
 hex_screw(profile, thread_depth, length, dia, pitch, rshift) - creates an ISO metric hex head screw with specified threaded length

The defaults for the "nutbolt" demo generate an ISO M6 x 10mm bolt and an ISO M6 nut.

Thread profile functions included (see comments in the functions):
 ISO_ext_thread_profile()
 sine_thread_profile()
 double_sine_thread_profile()
 triangle_thread_profile()
 circlestack_thread_profile()

ISO dimension functions:
 ISO_get_coarse_pitch(dia)
 ISO_hex_dia(dia)
 ISO_hex_nut_hi(dia)
 ISO_hex_bolt_hi(dia)
*/

//=============================================================
// DEMOS
// Set the 'demo' variable to the values "2rods", "rods", "nutbolt", or "baby safety toy" to generate various models. Set to false to display nothing.
//=============================================================

// demo = "baby safety toy";
// demo = "nutbolt";
demo = "nut";

if (demo == "baby safety toy") { // large nut and bolt with rounded surfaces; should be large enough to prevent choking hazard
    fn=96;
    fnstep=4;
    d=35;       // shaft diameter, min 31.7mm according to https://www.govinfo.gov/content/pkg/CFR-2012-title16-vol2/pdf/CFR-2012-title16-vol2-sec1501-4.pdf
    sp = d/3;   // screw pitch
    sd = d/6;   // screw thread depth
    length=140;
    hh = ISO_hex_bolt_hi(d);
    profile = sine_thread_profile(fn);
    minkowski_r=3;
    dhead = d-2*minkowski_r;

    // bolt
    translate([0,0,minkowski_r]) color("gold")
    union() {
        translate([0,0,hh-0.1]) difference() {
            union() {
                cylinder(h=length, d=d+0.5);
                translate([0,0,length]) scale([1,1,.8]) sphere(d=d+0.2, $fn=fn);
            }
            thole(profile, length+d/3, d, sd, sp, fn, fnstep);
        }

        // hook catch in bolt head
        translate([0,0,1.5*cos(22.5)-minkowski_r+0.03]) rotate([0,22.5,0]) rotate([90,0,0]) cylinder(d/4, d=3, center=true, $fn=8);
        // bolt head with slot for hook catch
        difference() {
            rotate([0,0,30]) hexbody(ISO_hex_dia(dhead), hh, minkowski_r=minkowski_r); // bolt head
            translate([0,0,-minkowski_r]) hull() { // slot
                rotate([90,22.50,0]) rotate_extrude(angle=360, $fn=8) translate([5,0,0]) circle(r=1, $fn=12);
                rotate([90,0,0]) cylinder(4, d=4, center=true, $fn=8);
            }
            efr = 10;
            //translate([0,0,-0.707*efr]) scale([1,0.4,1]) sphere(r=efr); // slot edge flare
        }
    }

    // nuts
    color("orange") translate([ISO_hex_dia(d)+3,0,minkowski_r]) rotate([0,0,30]) hex_nut(profile, sd, d, sp, rshift=0.3, fn=fn, fnstep=fnstep, minkowski_r=minkowski_r);
    color("cyan") translate([(ISO_hex_dia(d)+3)/2,ISO_hex_dia(dhead),minkowski_r]) rotate([0,0,30]) hex_nut(profile, sd, d, sp, rshift=0.3, fn=fn, fnstep=fnstep, minkowski_r=minkowski_r);
}
// mold for bolt -- we could just use a threaded rod, but then it would have a flat instead of rounded end; by making a mold to carve out the threads, we can carve threads out of the rounded end too without having a rounded end sticking out past the threads.
module thole(profile, length, dia, sd, sp, fn, fnstep) {
    difference() {
        cylinder(h=length-1, d=dia+10);
        translate([0,0,-0.5]) threaded_rod(profile, sd, length, dia=dia, pitch=sp, rshift=0, fn=fn, fnstep=fnstep, taper_arc=0.5);
    }
}
if (demo == "1rod") {
    fn=64;    // resolution of stacked polygons (number of sides)
    fnstep=4; // pitch resolution is fn/fnstep per rotation
    dia=10;
    ht=1;
    pitch=0;
    profile=ISO_ext_thread_profile();
    depth=ISO_thread_depth(dia,pitch,30);
    for(angle=[30:2:44]) let(rshift=ISO_thread_rshift(dia,pitch,angle)) translate([(angle-30)*5,0,0])threaded_rod(profile, depth, length=ht, dia=dia, rshift=rshift, pitch=pitch, fn=fn, fnstep=fnstep);
}
if (demo == "2rods") { // 2 threaded rods comparing different pitch resolutions
    fn=64;    // resolution of stacked polygons (number of sides)
    fnstep=4; // pitch resolution is fn/fnstep per rotation
    dia=4;
    ht=6;
    pitch=0;
    profile=sine_thread_profile(fn);
    depth=ISO_thread_depth(dia,pitch,30);
    threaded_rod(profile, depth, length=ht, dia=dia, rshift=0, pitch=pitch, fn=fn, fnstep=fnstep);
    translate([4.5,0,0]) threaded_rod(profile, depth, length=ht, dia=dia, rshift=0, pitch=pitch, fn=fn, fnstep=1);
}
if (demo == "rods") { // basic threaded rods
    pitch=0;   // thread pitch (0=use ISO pitch based on diameter)
    angle=30;  // ISO thread angle (default 30, use 45 for printing)
    dia=4;     // rod diameter
    ht=6;      // rod length (vertical height)
    fn=64;     // number of faces
    fnstep=4;
    depth=ISO_thread_depth(dia,pitch,angle); // thread depth
    rshift=ISO_thread_rshift(dia,pitch,angle);

    translate([5,0,0]) color("gold") threaded_rod(ISO_ext_thread_profile(), depth, length=ht, dia=dia, rshift=rshift, pitch=pitch, fn=fn, fnstep=fnstep);
    translate([10,0,0]) color("red") threaded_rod(sine_thread_profile(fn), depth, length=ht, dia=dia, rshift=rshift, pitch=pitch, fn=fn, fnstep=fnstep);
    translate([15,0,0]) color("green") threaded_rod(double_sine_thread_profile(fn), depth, length=ht, dia=dia, rshift=rshift, pitch=pitch, fn=fn, fnstep=fnstep);
    translate([20,0,0]) color("cyan") threaded_rod(triangle_thread_profile(), depth, length=ht, dia=dia, rshift=rshift, pitch=pitch, fn=fn, fnstep=fnstep);
    translate([25,0,0]) color("silver") threaded_rod(circlestack_thread_profile(dia/2,depth, fn), depth, length=ht, dia=dia, rshift=rshift, pitch=pitch, fn=fn, fnstep=fnstep);
}
if (demo == "nutbolt") { // printable nut and bolt
    pitch=0;   // thread pitch (0=use ISO pitch based on diameter)
    angle=30;  // ISO thread angle (default 30)
    dia=6;     // screw diameter
    ht=16;     // screw length (vertical height)
    fn=64;     // number of faces
    fnstep=4;  // number of steps in pitch stack (fn/fnstep must be >= 16)
    depth=ISO_thread_depth(dia,pitch,angle); // thread depth
    taper_arc=0.25; // lead-in thread length (1=full circle)
    
    color("silver") 
    hex_screw(ISO_ext_thread_profile(), depth, length=ht, dia=dia, rshift=ISO_thread_rshift(dia,pitch,angle)-0.1, pitch=pitch, fn=fn, fnstep=fnstep, taper_arc=taper_arc);
    
    color("silver") 
    translate([dia*2.2,0,0]) hex_nut(ISO_ext_thread_profile(), depth, dia=dia, pitch=pitch, rshift=0.1, fn=fn, fnstep=fnstep);
}

if (demo == "nut") { // printable nut and bolt
    pitch=0;   // thread pitch (0=use ISO pitch based on diameter)
    angle=30;  // ISO thread angle (default 30)
    dia=5;     // screw diameter
    ht=16;     // screw length (vertical height)
    fn=64;     // number of faces
    fnstep=4;  // number of steps in pitch stack (fn/fnstep must be >= 16)
    depth=ISO_thread_depth(dia,pitch,angle); // thread depth
    taper_arc=0.25; // lead-in thread length (1=full circle)
    
    // color("silver") 
    //hex_screw(ISO_ext_thread_profile(), depth, length=ht, dia=dia, rshift=ISO_thread_rshift(dia,pitch,angle)-0.1, pitch=pitch, fn=fn, fnstep=fnstep, taper_arc=taper_arc);
    
    color("silver") 
    translate([dia*2.2,0,0]) hex_nut(ISO_ext_thread_profile(), depth, dia=dia, pitch=pitch, rshift=0.1, fn=fn, fnstep=fnstep);
}

//=============================================================
// MODULES
// threaded_rod() - create a threaded rod
// hex_nut() - create a hex nut from a threaded rod subtracted from a hexagonal body
// hex_screw() - create a hex screw from a threaded rod and a hexagonal head
// hexbody() - create an ISO-dimensioned hexagonal body, for nuts and screws
//=============================================================

/*
Create a vertical threaded rod object. The rod can be subtracted from a solid to create an inside thread.
Parameters:
thread_profile = array of [x,y] coordinates describing a thread profile, in which x represents pitch (0 to 1) and y represents depth (-1 to 1). The profile is scaled by this module appropriately to render an object with the correct thread depth.
    For ISO threads, use ISO_thread_profile() for this parameter.
thread_depth = depth of thread from minimum to maximum diameter.
    For ISO threads, use ISO_thread_depth(dia,pitch,angle) for this parameter.
length = length of threaded rod.
dia = outer diameter of threaded rod. This can be adjusted higher or lower (for fitting) using the rshift parameter (see below).
pitch = thread pitch.
    For ISO threads, set pitch=0 to get the ISO pitch for the given diameter.
rshift = amount to shift outer diameter, for creating a tolerance to allow parts to fit.
    For ISO EXTERNAL threads using a thread face angle greater than 30 degrees, the inner diameter is critical for fitting into metal ISO threaded holes, so the outer diameter must be adjusted down to fit the angle; pass the value ISO_thread_rshift(dia,pitch,angle) for this parameter.
    For ISO INSIDE threads (threaded holes, i.e. a threaded rod subtracted from a solid, which is probably the most common use case for 3D printing), the outer diameter is critical for metal ISO screws to fit, so set rshift=0 regardless of the thread face angle, retaining the outer diameter size.
fn = number of faces, both for circumference as well as pitch cycle.
fnstep = number of circle vertexes to skip on each layer
taper_arc = portion of a cirle to taper the thread
*/
module threaded_rod(thread_profile, thread_depth, length=6, dia=4, pitch=1, rshift=0, fn=32, fnstep=1, taper_arc=0) {
    fnz = fn / fnstep;
    dz = (pitch==0 ? ISO_get_coarse_pitch(dia) : pitch) / fnz;
    ncircles = floor(length/dz+0.5);
    tapercircles = floor(fnz*taper_arc);
    circlestack = flatten([
        flatten([ for(i=[0:1:ncircles-tapercircles]) xsection3d(thread_profile, thread_depth, (fnstep*i)%fn, i*dz, dia, rshift, fn) ]),
        flatten([ for(n=[1:1:tapercircles], i=ncircles-tapercircles+n, td=(tapercircles-n)*thread_depth/tapercircles, rs=rshift-thread_depth+td) xsection3d(thread_profile, td, (fnstep*i)%fn, i*dz, dia, rs, fn) ])
    ]);

    faces = [
        [ for(i=[0:1:fn-1]) i ], // bottom cap
        for(h=[0:1:ncircles-1])  // stack of discs
            for(i=[0:1:fn-1], c1=h*fn, c2=(h+1)*fn)
                [ c1+i, c2+i, c2+(i+1)%fn, c1+(i+1)%fn ],
        [ for(i=[fn-1:-1:0]) ncircles*fn+i ] // top cap
    ];

    polyhedron(circlestack, faces, convexity=4);
}

/*
Create a hex nut, using ISO nut dimensions.
See parameter description for threaded_rod() above.
*/
module hex_nut(thread_profile, thread_depth, dia=4, pitch=0, rshift=0, fn=32, fnstep=1, minkowski_r=0) {
	span = ISO_hex_dia(dia-2*minkowski_r);
	height = ISO_hex_nut_hi(dia)-2*minkowski_r;
    r = 0.5*dia;
	difference() {
        hexbody(span, height, minkowski_r=minkowski_r);
        translate([0,0,-minkowski_r-0.1]) threaded_rod(thread_profile, thread_depth, height+2*(minkowski_r+0.2), dia, pitch, rshift, fn, fnstep);
        // bevel the hole in the nut
        translate([0,0,height-r+minkowski_r]) cylinder(h=r+1+minkowski_r/2, r1=0, r2=r+1+minkowski_r/2, $fn=fn);
        translate([0,0,-1-1.5*minkowski_r]) cylinder(h=r+1+minkowski_r/2, r1=r+1+minkowski_r/2, r2=0, $fn=fn);
	}
}

/*
Create a hex-head screw, using ISO screw head dimensions.
See parameter description for threaded_rod() above.
*/
module hex_screw(thread_profile, thread_depth, length=6, dia=4, pitch=0, rshift=0, fn=32, fnstep=1, taper_arc=0) {
	span = ISO_hex_dia(dia);
	height = ISO_hex_bolt_hi(dia);
    translate([0,0,height]) threaded_rod(thread_profile, thread_depth, length, dia, pitch, rshift, fn, fnstep, taper_arc);
	hexbody(span, height, false);
}

/*
Create a beveled hexagonal cylinder for the body of a nut or bolt head.
The ISO bevel is 30 degrees or less but we use 45 degrees for 3D printing.
Parameters:
span = corner-to-corner span, from ISO_hex_dia() below
height = hexagonal cylinder height, from ISO_hex_nut_hi() or ISO_hex_bolt_hi() below
beveltop = bevel the top side (true for nuts, optional for bolts)
bevelbot = bevel the bottom side (true for both nuts and bolts)
*/
module hexbody(span, height, beveltop=true, bevelbot=true, minkowski_r=0) {
    rs = span/2;
    if (minkowski_r > 0) {
        minkowski() {
            intersection() {
                cylinder(h=height, d=span, $fn=6); // hexagon
                nutcutout(span, height, beveltop, bevelbot);
            }
            sphere(r=minkowski_r, $fn=24);
        }
    } else {
        intersection() {
            cylinder(h=height, d=span, $fn=6); // hexagon
            nutcutout(span, height, beveltop, bevelbot);
        }
    }    
}

module nutcutout(span, height, beveltop, bevelbot) {
    width=0.5*span*cos(30);
    rcone=width+0.5*height;
    union() {
        translate([0,0,0.5*height]) cylinder(h=rcone, r1=rcone, r2=beveltop?0:rcone, $fn=36);
        translate([0,0,0.5*height-rcone]) cylinder(h=rcone, r1=bevelbot?0:rcone, r2=rcone, $fn=36);
    }
}

//=============================================================
// HELPER FUNCTIONS
//=============================================================

// flatten a nested array (used by threaded_rod above)
function flatten(lst) = [ for (a = lst) for (b = a) b ] ;

/*    
return fn 3-D coordinates of a radial cross section of a threaded screw of a given thread profile
 thread_profile = lookup array of thread profile coordinates (x=0...1 pitch axis, y=-1...1 thread axis)
 thread_depth = different between maximum and minimum thread radius, use ISO_thread_depth() value for ISO threads
 j = rotation number; the rotation_angle is 360*j/fn
 z = z coordinate of layer
 dia = outer diameter of thread
 rshift (ISO external threads only) = amount to grow or shrink radius to account for nonstandard thread angle, determined by ISO_thread_rshift()
 fn = number of steps
*/
function xsection3d(thread_profile, thread_depth, j, z, dia, rshift, fn) =
        let(dp=0.5*thread_depth, Rp=0.5*dia-dp+rshift)
        [
            for(i=[0:1:fn-1], k=(i-(j%fn)+fn)%fn, r = Rp+dp*lookup(k/fn,thread_profile))
                [r*cos(360*i/fn), r*sin(360*i/fn), z]
        ];

// return metric ISO thread depth based on diameter, pitch, and thread face angle from horizontal
function ISO_thread_depth(dia=4, pitch=0, angle=30) =
    let(p = pitch == 0 ? ISO_get_coarse_pitch(dia) : pitch, H=p/(2*tan(angle)))
        5*H/8;

// return difference between standard 30-degree ISO thread depth and a nonstandard angle thread depth
function ISO_thread_rshift(dia=4, pitch=0, angle=30) =
    let(p = pitch == 0 ? ISO_get_coarse_pitch(dia) : pitch,
            depth=ISO_thread_depth(dia,pitch,angle),
            ISOdepth = ISO_thread_depth(dia,p,30))
        depth-ISOdepth;

            
//=============================================================
// THREAD PROFILES
// Each thread profile is an array of [x,y] coordinates, with x (pitch) ranging from 0 to 1, representing the fraction of thread pitch (or rotation), and y (depth) ranging from -1 to 1, representing the minimum to maximum depth profile. Where y=-1, the thread will have its minimum radius, and where y=1, the thread will have its maximum radius.
//=============================================================

// ISO metric thread profile
function ISO_ext_thread_profile() = [
    [0, 1],          // middle of outer edge
    [1/16, 1],       // top of outer edge
    [0.5-1/8, -1],   // bottom of inner edge
    [0.5+1/8, -1],   // top of inner edge
    [1-1/16, 1],     // bottom of next higher outer edge
    [1, 1]           // middle of next higher outer edge
];

function sine_thread_profile(fn=32) = [
    for(i=[0:1:fn]) [i/fn, cos(360*i/fn)]
];
 
function double_sine_thread_profile(fn=32) = [
    for(i=[0:1:fn]) [i/fn, cos(720*i/fn)]
];

function triangle_thread_profile() = [
    [0,1], [0.5,-1], [1,1]
];

// this creates a perfect circle cross-section, which looks like a sinewave thread but isn't, quite.
function circlestack_thread_profile(r,d,fn=32) = 
    let(r0=d/2, a=r-r0, a2=a*a, Rp=r-r0) [
        for(i=[0:1:fn], t=360*i/fn, ct=cos(t), st=sin(t))
            [t/360, (r0*ct+sqrt(a2-r0*r0*st*st)-Rp)/r0]
];


//=============================================================
// ISO DATA LOOKUPS
//=============================================================

// from https://en.wikipedia.org/wiki/ISO_metric_screw_thread

function ISO_get_coarse_pitch(dia) = lookup(dia, [
[1,0.25],[1.2,0.25],[1.4,0.3],[1.6,0.35],[1.8,0.35],[2,0.4],[2.5,0.45],[3,0.5],[3.5,0.6],[4,0.7],[5,0.8],[6,1],[7,1],[8,1.25],[10,1.5],[12,1.75],[14,2],[16,2],[18,2.5],[20,2.5],[22,2.5],[24,3],[27,3],[30,3.5],[33,3.5],[36,4],[39,4],[42,4.5],[45,4.5],[48,5],[52,5],[56,5.5],[60,5.5],[64,6]]);

// from https://www.engineersedge.com/hardware/standard_metric_hex_nuts_13728.htm
// and ISO 4014 from https://www.engineersedge.com/iso_hex_head_screw.htm

function ISO_hex_dia(dia) = lookup(dia, [ // nut & screw head diameters
[3,6.35],[4,8.08],[5,9.24],[6,11.55],[8,15.01],[10,18.48],[12,20.78],[14,24.25],[16,27.71],[20,34.64],[24,41.57],[30,53.12],[36,63.51],[42,75.06],[48,86.6]]);

function ISO_hex_nut_hi(dia) = lookup(dia, [ // ISO hex nut height
[3,2.4],[4,3.2],[5,4.7],[6,5.2],[8,6.8],[10,8.4],[12,10.8],[14,12.8],[16,14.8],[20,18],[24,21.5],[30,25.6],[36,31]]);

function ISO_hex_bolt_hi(dia) = lookup(dia, [ // ISO hex bolt head height
[3,2.125],[4,2.925],[5,3.65],[6,4.15],[8,5.45],[10,6.58],[12,7.68],[16,10.18],[20,12.715],[24,15.215],[30,19.12],[36,22.92],[42,26.42],[48,30.42]]);
