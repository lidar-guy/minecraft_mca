// =============================================================
// Victorian Corbel - parameterized, layer-stacked
// =============================================================
// Reconstructs a corbel that was originally built by stacking
// flat profile cut-outs horizontally:
//
//   [ main ][spacer][ main ][spacer][ main ]
//
// Defaults match the field measurements: 3 main layers at
// 1-3/4" thick + 2 spacer layers at 1/4" thick = 5-3/4" total.
// All dimensions are in inches.
//
// Adjust profile control points to match the cardboard template.

/* [Render Mode] */
// What to draw. "assembly" stacks everything; "exploded" pulls the
// layers apart for inspection; "layout" lays the unique parts flat
// side-by-side (good for STL export of a single part); "main" or
// "spacer" renders just one layer at the origin.
mode = "assembly";  // [assembly, exploded, layout, main, spacer, profile_2d]

/* [Stack-up] */
main_thickness   = 1.75;   // thickness of each main layer
spacer_thickness = 0.25;   // thickness of each spacer layer
num_main         = 3;
num_spacer       = 2;      // spacers sit between main layers
exploded_gap     = 1.0;    // gap between layers in exploded view

/* [Spacer Profile] */
// Spacer is the main profile offset inward by this much, which is
// what creates the recessed "shadow line" between the thick layers.
spacer_inset     = 0.375;

/* [Overall Size] */
height           = 14;     // overall height of the corbel
depth            = 7;      // projection from wall at the top
top_thickness    = 1.0;    // height of the upper abacus / cap shelf
top_step_in      = 0.5;    // how far the front steps back below the cap
top_step_drop    = 0.5;    // height of that step

/* [Front S-Curve Control Points] */
// The front profile sweeps from the upper step, down through a
// "neck", out to a "belly" bulge, in to a "waist", and finishes in
// the round bottom drop.  Tweak these to match the template.
neck_x           = 2.2;
neck_y           = 10.0;
belly_x          = 4.6;
belly_y          = 7.0;
waist_x          = 1.8;
waist_y          = 3.6;

/* [Bottom Drop / Scroll] */
drop_center_x    = 2.6;
drop_center_y    = 1.6;
drop_radius      = 1.5;

/* [Smoothing] */
bezier_segments  = 24;
$fn              = 96;

// -------------------------------------------------------------
//  PROFILE
// -------------------------------------------------------------

// Cubic Bezier sampler returning a list of points (excluding p0,
// including p3) so consecutive segments can be concatenated cleanly.
function bezier(p0, p1, p2, p3, n) =
    [ for (i = [1 : n]) let (t = i/n)
        (1-t)*(1-t)*(1-t) * p0
      + 3*(1-t)*(1-t)*t   * p1
      + 3*(1-t)*t*t       * p2
      + t*t*t             * p3 ];

// Coordinate frame: x is projection from wall (wall at x=0, front
// at +x), y is height from the bottom of the corbel (top at y=H).
// Polygon points run clockwise from the top-back corner.
function profile_points() =
    let (
        p_top_back   = [0,                              height],
        p_top_front  = [depth,                          height],
        p_cap_front  = [depth,                          height - top_thickness],
        p_step_top   = [depth - top_step_in,            height - top_thickness],
        p_step_bot   = [depth - top_step_in,            height - top_thickness - top_step_drop],
        p_neck       = [neck_x,                         neck_y],
        p_belly      = [belly_x,                        belly_y],
        p_waist      = [waist_x,                        waist_y],
        // tangent into the round drop, biased toward the wall side
        p_drop_in    = [drop_center_x - drop_radius * 0.4, drop_center_y - 0.2],
        p_bot_back   = [0,                              0]
    )
    concat(
        [p_top_back, p_top_front, p_cap_front, p_step_top, p_step_bot],
        // step -> neck: gentle inward curve
        bezier(p_step_bot,
               [p_step_bot.x,           neck_y + 2.0],
               [neck_x + 0.3,           neck_y + 1.5],
               p_neck, bezier_segments),
        // neck -> belly: swell outward
        bezier(p_neck,
               [neck_x,                 belly_y + 1.8],
               [belly_x,                belly_y + 2.0],
               p_belly, bezier_segments),
        // belly -> waist: tuck back in
        bezier(p_belly,
               [belly_x,                waist_y + 1.5],
               [waist_x + 1.0,          waist_y + 0.4],
               p_waist, bezier_segments),
        // waist -> top of drop circle (overlaps with the circle)
        bezier(p_waist,
               [waist_x,                drop_center_y + drop_radius * 0.4],
               [drop_center_x - drop_radius, drop_center_y + 0.4],
               p_drop_in, bezier_segments),
        [p_bot_back]
    );

module corbel_profile() {
    union() {
        polygon(points = profile_points());
        translate([drop_center_x, drop_center_y]) circle(r = drop_radius);
    }
}

module spacer_profile() {
    // Inset for the recessed shadow line between main layers.
    offset(r = -spacer_inset) corbel_profile();
}

// -------------------------------------------------------------
//  LAYERS
// -------------------------------------------------------------

module main_layer() {
    linear_extrude(height = main_thickness) corbel_profile();
}

module spacer_layer() {
    linear_extrude(height = spacer_thickness) spacer_profile();
}

// -------------------------------------------------------------
//  ASSEMBLY
// -------------------------------------------------------------

// Stack alternates: main, spacer, main, spacer, ..., main.
// Returns the cumulative z-offset for layer index i.
function layer_offset(i, gap = 0) =
    let (full_main   = floor((i + 1) / 2),
         full_spacer = floor(i / 2))
    full_main * main_thickness
    + full_spacer * spacer_thickness
    + i * gap;

module corbel_assembly(gap = 0) {
    n = num_main + num_spacer;
    for (i = [0 : n - 1]) {
        translate([0, 0, layer_offset(i, gap)])
            if (i % 2 == 0) main_layer();
            else            spacer_layer();
    }
}

// -------------------------------------------------------------
//  FLAT LAYOUT (for STL export of unique parts)
// -------------------------------------------------------------

module flat_layout() {
    // Lay the two unique profiles side by side on the XY plane.
    main_layer();
    translate([depth + 1, 0, 0]) spacer_layer();
}

// -------------------------------------------------------------
//  TOP-LEVEL DISPATCH
// -------------------------------------------------------------

if      (mode == "assembly")   corbel_assembly(gap = 0);
else if (mode == "exploded")   corbel_assembly(gap = exploded_gap);
else if (mode == "layout")     flat_layout();
else if (mode == "main")       main_layer();
else if (mode == "spacer")     spacer_layer();
else if (mode == "profile_2d") corbel_profile();
else                           corbel_assembly();
