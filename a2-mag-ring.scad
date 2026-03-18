/* [Counter Ring - Main Body] */
// Main body outer diameter
counter_ring_outer_diameter = 159;
// Height of main cylinder
counter_ring_body_height = 10;
// Lower flange diameter
counter_ring_flange_outer_diameter = 185;
// Lower flange thickness
counter_ring_flange_height = 3;
// Main body wall thickness
counter_ring_wall_thickness = 2;
// Radial wall around magnets
counter_ring_magnet_wall_width = 2;
// Base depth under magnets
counter_ring_magnet_base_depth = 2;
// Height of top magnet ring
counter_ring_height = 1.5;

/* [Counter Ring - Screws] */
// Number of screw holes
counter_ring_screw_count = 4;
// Clearance for screw shaft
counter_ring_screw_hole_diameter = 4;
// Diameter for screw head
counter_ring_countersink_diameter = 7;
// Depth of countersink
counter_ring_countersink_depth = 2;
// Positioning radius for screws
counter_ring_screw_circle_diameter = 174;

/* [Plant 1 - Magnet Ring] */
// Outer diameter
plant_1_outer_diameter = 155;
// Radial wall around magnets
plant_1_magnet_wall_width = 1.5;
// Base depth under magnets
plant_1_magnet_base_depth = 1;

/* [Common - Shared Dimensions] */
// Inner hole diameter (shared by counter ring and plant rings)
common_inner_hole_diameter = 138;
// Edge chamfer radius for safety
edge_chamfer_radius = 0.8;

/* [Text Settings] */
// Text label 1 (shared)
text_1 = "WAG";
// Text label 2 (shared)
text_2 = "LSOH";
// Text label 3 for counter
text_3_counter = "COUNTER";
// Text label 3 for plant
text_3_plant = "A2-1";
// Text label 4 (version - shared)
text_4 = "v2";
// Font size for counter ring text
counter_text_size = 4;
// Font size for plant ring text
plant_text_size = 3;
// Emboss depth for all text (shared)
emboss_depth = 0.8;

/* [Magnets - Shared] */
// Number of magnets
magnet_count = 16;
// Physical magnet diameter
magnet_diameter = 6;
// Physical magnet depth
magnet_depth = 2;
// Tolerance margin
magnet_margin = 0.2;

/* [Rendering Quality] */
// Resolution for main geometry (higher = smoother but slower)
fn_main = 100;
// Resolution for detailed features (magnets, screws)
fn_detail = 50;

/* [Hidden] */

// Small overlap for clean CSG operations
overlap = 0.1;

// Calculated values
magnet_cutout_diameter = magnet_diameter + magnet_margin;
magnet_cutout_depth = magnet_depth + magnet_margin;
// Text emboss depth with overlap for clean subtraction
text_emboss_actual_depth = emboss_depth + overlap;
// Calculate plant_1 height based on magnet holder dimensions
plant_1_height = magnet_cutout_depth + plant_1_magnet_base_depth;
// Calculate magnet wall cylinder diameters for both rings
plant_1_wall_cylinder_diameter_calc = magnet_cutout_diameter + plant_1_magnet_wall_width * 2;
counter_ring_wall_cylinder_diameter_calc = magnet_cutout_diameter + counter_ring_magnet_wall_width * 2;
// Find the constraining dimensions: minimum outer diameter and maximum wall cylinder diameter
min_outer_diameter = min(plant_1_outer_diameter, counter_ring_outer_diameter);
max_wall_cylinder_diameter = max(plant_1_wall_cylinder_diameter_calc, counter_ring_wall_cylinder_diameter_calc);
// Position magnets so outer edge of magnet walls doesn't exceed the smaller ring
magnet_circle_radius = min_outer_diameter/2 - max_wall_cylinder_diameter/2;
counter_ring_body_inner_diameter = counter_ring_outer_diameter - (2 * counter_ring_wall_thickness);
counter_ring_total_height = counter_ring_body_height + counter_ring_flange_height;
// Calculate chamfer support dimensions (45° angle from inner hole to inner wall)
chamfer_radial_distance = (counter_ring_body_inner_diameter - common_inner_hole_diameter) / 2;
chamfer_height = chamfer_radial_distance; // 45° = equal height and radial distance

// Module: Create edge chamfer (cone transition)
module edge_chamfer(diameter, chamfer_radius, invert=false) {
    if (invert) {
        // Expanding chamfer (widens outward)
        cylinder(h=chamfer_radius, 
                 d1=diameter, 
                 d2=diameter + 2*chamfer_radius, 
                 $fn=fn_main);
    } else {
        // Contracting chamfer (narrows outward)
        cylinder(h=chamfer_radius, 
                 d1=diameter + 2*chamfer_radius, 
                 d2=diameter, 
                 $fn=fn_main);
    }
}

// Module: Basic ring with chamfered inner edges
module chamfered_ring(outer_d, inner_d, height, top_chamfer=true, bottom_chamfer=true, outer_bottom_chamfer=false) {
    difference() {
        cylinder(h=height, d=outer_d, $fn=fn_main);
        
        translate([0, 0, -overlap])
            cylinder(h=height + 2*overlap, d=inner_d, $fn=fn_main);
        
        if (bottom_chamfer) {
            translate([0, 0, -overlap])
                edge_chamfer(inner_d, edge_chamfer_radius, false);
        }
        
        if (top_chamfer) {
            translate([0, 0, height - edge_chamfer_radius])
                edge_chamfer(inner_d, edge_chamfer_radius, true);
        }
        
        if (outer_bottom_chamfer) {
            translate([0, 0, -overlap])
            difference() {
                cylinder(h=edge_chamfer_radius + overlap, d=outer_d + 1, $fn=fn_main);
                cylinder(h=edge_chamfer_radius + 2*overlap, 
                         d1=outer_d - 2*edge_chamfer_radius, 
                         d2=outer_d, 
                         $fn=fn_main);
            }
        }
    }
}

// Module: Create a single magnet holder with rounded top and bottom edges
module magnet_holder(wall_width, base_depth, holder_height) {
    holder_diameter = magnet_cutout_diameter + wall_width * 2;
    
    // Bottom chamfer
    hull() {
        // Bottom edge - smaller diameter for fillet
        cylinder(h=0.01, d=holder_diameter - 2*edge_chamfer_radius, $fn=fn_detail);
        // Top of fillet - full diameter
        translate([0, 0, edge_chamfer_radius])
            cylinder(h=0.01, d=holder_diameter, $fn=fn_detail);
    }
    // Main cylinder in middle
    translate([0, 0, edge_chamfer_radius])
        cylinder(h=holder_height - 2*edge_chamfer_radius, d=holder_diameter, $fn=fn_detail);
    // Top chamfer
    translate([0, 0, holder_height - edge_chamfer_radius])
    hull() {
        // Bottom of top fillet - full diameter
        cylinder(h=0.01, d=holder_diameter, $fn=fn_detail);
        // Top edge - smaller diameter
        translate([0, 0, edge_chamfer_radius])
            cylinder(h=0.01, d=holder_diameter - 2*edge_chamfer_radius, $fn=fn_detail);
    }
}

// Module: Create ring of magnet holders at standard radius
module magnet_holders_ring(wall_width, base_depth) {
    holder_height = magnet_cutout_depth + base_depth;
    for (i = [0:magnet_count-1]) {
        angle = i * 360 / magnet_count;
        rotate([0, 0, angle])
        translate([magnet_circle_radius, 0, 0])
            magnet_holder(wall_width, base_depth, holder_height);
    }
}

// Module: Create ring of magnet cutouts at standard radius
module magnet_cutouts_ring(cutout_z_offset) {
    for (i = [0:magnet_count-1]) {
        angle = i * 360 / magnet_count;
        rotate([0, 0, angle])
        translate([magnet_circle_radius, 0, cutout_z_offset])
            cylinder(h=magnet_cutout_depth + overlap, d=magnet_cutout_diameter, $fn=fn_detail);
    }
}

// Module: Curved text centered at specific angle
module curved_text_at_angle(txt, radius, center_angle, font_size, depth) {
    chars = len(txt);
    // Calculate approximate angular spacing based on font size and radius
    angle_per_char = (font_size * 1 / radius) * (180 / PI);
    total_angle = angle_per_char * chars;
    // Start angle offset to center the text at center_angle
    start_angle = center_angle - total_angle / 2;
    
    for (i = [0:chars-1]) {
        angle = start_angle + i * angle_per_char;
        rotate([0, 0, angle])
        translate([radius, 0, 0])
        rotate([0, 0, 90])
        linear_extrude(height=depth)
        text(txt[i], size=font_size, halign="center", valign="center", font="Liberation Sans:style=Bold");
    }
}

// Module: Render 4 text labels around a ring
module ring_text_labels(labels, text_radius, divisions, font_size) {
    angle_offset = 180 / divisions;
    
    translate([0, 0, -overlap])
    scale([1, -1, 1]) {
        for (i = [0:3]) {
            curved_text_at_angle(labels[i], text_radius, 
                               angle_offset + i*360/divisions, 
                               font_size, text_emboss_actual_depth);
        }
    }
}

// Module: Counter ring text (on outer face of flange)
module counter_text_embossed() {
    text_radius = (counter_ring_outer_diameter + counter_ring_flange_outer_diameter) / 4;
    ring_text_labels([text_1, text_2, text_4, text_3_counter], 
                     text_radius, counter_ring_screw_count, counter_text_size);
}

// Module: Plant 1 ring text (on magnet face)
module plant_text_embossed() {
    text_radius = (plant_1_outer_diameter + common_inner_hole_diameter) / 4;
    ring_text_labels([text_1, text_2, text_4, text_3_plant], 
                     text_radius, magnet_count, plant_text_size);
}

// Module: Complete counter ring assembly (base at Z=0)
module counter_ring_assembly() {
    difference() {
        union() {
            // Main body with flange
            difference() {
                union() {
                    // Lower flange at base (Z=0)
                    cylinder(h=counter_ring_flange_height, d=counter_ring_flange_outer_diameter, $fn=fn_main);
                    
                    // Main body cylinder
                    translate([0, 0, counter_ring_flange_height])
                        cylinder(h=counter_ring_body_height, d=counter_ring_outer_diameter, $fn=fn_main);
                }
                
                // Subtract inner cylinder to leave wall thickness
                translate([0, 0, -overlap])
                    cylinder(h=counter_ring_body_height + counter_ring_flange_height + 2*overlap, d=counter_ring_body_inner_diameter, $fn=fn_main);
                
                // Subtract chamfer at bottom inner edge for safety
                translate([0, 0, -overlap])
                    edge_chamfer(counter_ring_body_inner_diameter, edge_chamfer_radius, false);
                
                // Subtract outer bottom edge chamfer on flange for safety
                translate([0, 0, -overlap])
                difference() {
                    cylinder(h=edge_chamfer_radius + overlap, d=counter_ring_flange_outer_diameter + 1, $fn=fn_main);
                    cylinder(h=edge_chamfer_radius + 2*overlap, 
                             d1=counter_ring_flange_outer_diameter - 2*edge_chamfer_radius, 
                             d2=counter_ring_flange_outer_diameter, 
                             $fn=fn_main);
                }
                
                // Subtract screw holes with countersinks
                for (i = [0:counter_ring_screw_count-1]) {
                    angle = i * 360 / counter_ring_screw_count;
                    rotate([0, 0, angle])
                    translate([counter_ring_screw_circle_diameter/2, 0, 0]) {
                        // Screw shaft hole
                        translate([0, 0, -overlap])
                            cylinder(h=counter_ring_flange_height + 2*overlap, d=counter_ring_screw_hole_diameter, $fn=fn_detail);
                        
                        // Countersink chamfer (underneath the flange)
                        // Slopes from countersink_diameter at bottom to screw_hole_diameter at top
                        translate([0, 0, -overlap])
                            cylinder(h=counter_ring_countersink_depth, d1=counter_ring_countersink_diameter, d2=counter_ring_screw_hole_diameter, $fn=fn_detail);
                    }
                }
                
                // Subtract text emboss
                counter_text_embossed();
            }
            
            // Counter magnet ring on top of main body
            translate([0, 0, counter_ring_flange_height + counter_ring_body_height - counter_ring_height])
                magnet_ring_counter();
            
            // Chamfered support structure (added as separate element)
            translate([0, 0, counter_ring_flange_height + counter_ring_body_height - counter_ring_height - chamfer_height])
            difference() {
                // Solid cylinder at inner wall diameter
                cylinder(h=chamfer_height, d=counter_ring_body_inner_diameter, $fn=fn_main);
                
                // Subtract narrowing cone to create 45° inward slopes (wide at bottom, narrow at top)
                translate([0, 0, -overlap])
                cylinder(h=chamfer_height + 2*overlap, 
                         d1=counter_ring_body_inner_diameter, 
                         d2=common_inner_hole_diameter, 
                         $fn=fn_main);
            }
        }
        
        // Subtract magnet cutouts from entire assembly (cuts through support if needed)
        translate([0, 0, counter_ring_flange_height + counter_ring_body_height - magnet_cutout_depth])
            magnet_cutouts_ring(0);
    }
}

// Module: Counter magnet ring (attached to desk grommet)
module magnet_ring_counter() {
    magnet_wall_cylinder_height = magnet_cutout_depth + counter_ring_magnet_base_depth;
    
    union() {
        // Build outer ring with top chamfer only (bottom chamfer provided by support structure)
        difference() {
            cylinder(h=counter_ring_height, d=counter_ring_outer_diameter, $fn=fn_main);
            
            translate([0, 0, -overlap])
                cylinder(h=counter_ring_height + 2*overlap, d=common_inner_hole_diameter, $fn=fn_main);
            
            // Subtract chamfer at top inner edge for safety
            translate([0, 0, counter_ring_height - edge_chamfer_radius])
                edge_chamfer(common_inner_hole_diameter, edge_chamfer_radius, true);
        }
        
        // Add magnet wall cylinders with rounded bottom edges
        translate([0, 0, counter_ring_height - magnet_wall_cylinder_height])
            magnet_holders_ring(counter_ring_magnet_wall_width, counter_ring_magnet_base_depth);
    }
}

// Module: Plant 1 magnet ring (separate piece for plant pot, base at Z=0 with magnets)
module magnet_ring_plant1() {
    difference() {
        union() {
            // Build outer ring with chamfered inner edges
            chamfered_ring(plant_1_outer_diameter, common_inner_hole_diameter, 
                          plant_1_height, true, true, true);
            
            // Add magnet wall cylinders at base with rounded bottom edges
            magnet_holders_ring(plant_1_magnet_wall_width, plant_1_magnet_base_depth);
        }
        
        // Subtract magnet cutouts at base (open to bottom)
        magnet_cutouts_ring(-overlap);
        
        // Subtract text emboss
        plant_text_embossed();
    }
}

// Counter ring assembly
counter_ring_assembly();

// Plant 1 magnet ring - offset for separate printing
translate([counter_ring_outer_diameter + 20, 0, 0])
magnet_ring_plant1();
