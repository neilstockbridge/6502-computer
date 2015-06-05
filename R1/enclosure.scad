
$fs = 0.5; // This is the shortest that any such polygonal edge can be ( to avoid too many edges in small circles)
$fa = 360 / 180; // This is the maximum number of edges in a polygon ( to avoid too many edges in large circles)

clearance = 0.15;

wall_thickness = 2;

pcb_size = [ 53.54, 86.62 ];
pcb_thickness = 1.55;
pcb_hole_radius = 3.14 / 2;
left_edge = - pcb_size[0] / 2;
far_edge = pcb_size[1] / 2;
near_edge = - far_edge;
pcb_hole_locations = [
  [ left_edge + 26.58 + pcb_hole_radius, far_edge - 9.84 - pcb_hole_radius ],
  [ left_edge +  8.81 + pcb_hole_radius, near_edge + 3.66 + pcb_hole_radius ],
  [ left_edge + 41.82 + pcb_hole_radius, near_edge + 3.66 + pcb_hole_radius ],
];
component_height_under_pcb = 3.65;


module at_locations( locations )
{
  for( location= locations )
    translate( location )
      child();
}


module at_corners( size )
{
  for( y= [ -1, +1 ])
    for( x= [ -1, +1 ])
      translate([ size[0] / 2 * x, size[1] / 2 * y ])
        child();
}


module board()
{
  color("green")
  linear_extrude( height= pcb_thickness )
  {
    difference()
    {
      square( pcb_size, center=true );
      //translate( -pcb_size/2 )
      at_locations( pcb_hole_locations )
        circle( r= pcb_hole_radius );
    }
  }
  %mirror([0,0,1])
  linear_extrude( height= component_height_under_pcb )
    square( pcb_size, center=true );
}


module base()
{
  support_wall_thickness = 2;

  module section( offset, height, hollow, supports )
  {
    translate([0,0, offset ])
    linear_extrude( height= height )
    {
      difference()
      {
        hull()
          at_corners( pcb_size )
            circle( r= wall_thickness );
        if ( hollow )
          square( pcb_size + [clearance,clearance]*2, center=true );
      }
      if ( supports )
        at_locations( pcb_hole_locations )
          difference()
          {
            circle( r= pcb_hole_radius + support_wall_thickness );
            circle( r= pcb_hole_radius );
          }
    }
  }

  mirror([0,0,1])
  {
    section( component_height_under_pcb, wall_thickness, false, false );
    section( 0, component_height_under_pcb, true, true );
  }
  section( 0, pcb_thickness, true, false );
}


%board();
base();

