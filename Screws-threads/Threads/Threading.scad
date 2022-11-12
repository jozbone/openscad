// Threading.scad - library for threadings
// Autor: Rudolf Huttary, Berlin 2016 
// - last revision: Jan, 2021
// - tested for OpenSCAD 2021.01
// - support for multiple threads 

use <Naca_sweep.scad> // http://www.thingiverse.com/thing:900137

// examples 
Threading_example(1);   // choose your example number

module Threading_example(number=0) 
{ 
  help(); 
  module examples(number)  children(number); 
  examples(number)
  {
  // #0 thread with default values
    threading(); 

  // #1 ACME thread
    threading(pitch = 2, d=20, windings = 5, angle = 29, center=true); 

  // #2 threaded rod 20°
    threading(pitch = 2, d=20, windings = 20, angle = 20, full = true); 

  // #3 nut for left-handed threaded rod 20° 
    Threading(pitch = 2, d=20, windings = 10, angle = 20, left = true); 

  // #4 cw nut for threaded rod 20°, own diameter 25 mm, hires 
    Threading(D = 25, pitch = 2, d=20, windings = 10, angle = 20, $fn=100); 

  // #5 triple threaded rod
    threading(pitch = 2, d=20, windings = 10, helices = 3, angle = 20, full = false, $fn=100); 

  // #6 toothed rod (no pitch) 
     threading(pitch = 3, helices = 0, angle = 20, full = true); 

  // #7 toothed cube (no pitch) 
     threading(pitch = 2, helices = 0, angle = 60, full = true, $fn=4); 

  // #8 M8 hex bolt
     union()
     {
       threading(pitch = 1.25, d=7.8, windings=20, full=true); 
       cylinder(d=14.6, h=4, $fn=6);
     } 

  // #9 M8 hex bolt - left hand thread
     union()
     {
       threading(pitch = 1.25, d=7.8, windings=20, full=true, left = true); 
       cylinder(d=14.6, h=4, $fn=6);
     } 

  // #10 M8 hex nut
     Threading(D=14, pitch = 1.25, d=8.014, windings=5, edges=6);  

  // #11 M8 square nut
     Threading(D=16, pitch = 1.25, d=8.014, windings=5, edges=4);  
     
  // #12 Screw compressor
     union()
     {
      translate([0,16,0])
      threading(pitch = 8, d=20, helices=3, angle=60, left=true); 
      threading(pitch = 8, d=20, helices=3, angle=60); 
     }
  }
}
module help_Threading() help(); 
module help_threading() help(); 

module help()
{
  helpstr = str(
  "Thread library - by Rudolf Huttary (2016)", 
  "\n=========================================", 
  "\nMODULES",
  "\n========",
  "\nhelp();              \t// show help in console",
  "\nThreading_example(number=0) \t//example and test code",
  "\nthreading(pitch = 1, d = 12, windings = 10, helices = 1, angle = 60, full = false, left=false, trim=true, center=false)",
  "\nThreading(D = 0, pitch = 1, d = 12, windings = 10, helices = 1, angle = 60, left = false, edges = 0, center=false)",
  "\n\nPARAMETERS",
  "\n============",
  "\nD = {0=auto};  \t// Cyl diameter Threading()",
  "\npitch = 1;     \t// pitch [mm] ensure pitch<d/2",
  "\nd = 6;         \t// outer diameter of threading() ensure d>2*pitch",
  "\nwindings = 10; \t// # windings",
  "\nhelices = 1;   \t// # threads",
  "\nangle = 60;    \t// open angle, bolts: 60°, ACME: 29°, toothed Racks: 20°",  "edges = 40;    <i> resolution of outer cylinder",
  "\nfull = false;  \t// sleeve or filled",
  "\nleft = false;  \t// true -> ccw",
  "\ntrim=true;     \t// true -> cross cut at both sides",
  "\ncenter=false;  \t// true -> centered",
  "\nedges=0;       \t// #edges (default value->30) (Threading only)",
  "\n$fn = 360/$fa; \t// control segments per winding"  
  );
  echo (helpstr);
}

module Threading(D = 0, pitch = 1, d = 12, windings = 10, helices = 1, angle = 60, left = false, edges = 0, center=false)
{
  R = D==0?d/2+pitch/PI:D/2; 
  edges = edges?edges:360/$fa; 
  translate([0,0, center?-(windings+.5)*pitch/2:0])
  difference()
  { 
     cylinder(r=R, h = -0.01+pitch*(windings+.5), $fn=edges); 
      translate([0,0,-.005])  // avoid z-fighting
     threading(pitch=pitch, d=d, windings=windings, helices=helices, angle=angle, full = true, left=left, center=false); 
  }
}

module threading(pitch = 1, d = 12, windings = 10, helices = 1, angle = 60, full = false, left=false, trim = true, center=false)
{  // tricky: glue minimal 2 pieces together to get a proper manifold  
  r = max(d/2, pitch+.1);  
  Steps = $fn?$fn/2:180/$fa; 
  windings = max(1, trim?windings+2:windings); 
  helices = abs(helices); 
  angle = abs(angle); 
  translate([0,0,center? -pitch*(windings-1.5)/2:0])
  intersection()
  {  
    union()
    {
      if(full) 
        cylinder(r = r-2.5*pitch/PI, h=pitch*(windings-1), $fn=2*Steps); 
      scale([left?1:-1,1,1])
      translate([0,0, trim?-pitch:pitch/2])
      {  
      if(helices<=1) 
      {
        sweep(gen_dat(), convexity = 10);   // half screw
        rotate([0,0,180])
        translate([0,0,helices==0?0:-pitch/2]) 
        sweep(gen_dat(), convexity = 10);   // half screw
      }
      else
      { 
        for(i=[0:max(0,helices-1)])
        {
          rotate([0,0,360/helices*i])
          sweep(gen_dat(360/helices), convexity = 10);   // half screw
        }
      }
      }
    }
   if (trim) 
     cylinder(r=r+.2, h = 0.01+pitch*(windings-1.5), center=false); 
  }
  
  function gen_dat(until = 180) = 
    let(ang = 180, bar = R_(180, 90, 0, Ty_(-r, vec3D(pitch/PI * Rack(windings, angle)))))
    [for (i=[Steps:-1:0]) let(w = -i*ang/Steps) if(-w<=until+ang/Steps) Tz(i/2/Steps*pitch*helices, Rz_(w, bar))]; 

  function Rack(w, angle) = 
     concat([[0, 3]], 
            [for (i=[0:windings-1], j=[0:3]) 
                let(t = [ [0, 2], [2*tan(angle/2), 0], [PI/2, 0], [2*tan(angle/2)+PI/2, 2]])
            [t[j][0]+i*PI, t[j][1]]], [[w*PI, 2], [w*PI, 3]]);
}


