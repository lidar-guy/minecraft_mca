//=========================================================
// Victorian Corbel - Parameterized Stackable 3D Model
//=========================================================
//
// Reconstructs a corbel built by stacking flat profiles cut
// from wood, of the form:
//
//   [main][spacer][main][spacer][main]
//
// Defaults: 3 main layers at 1-3/4" thick + 2 spacers at
// 1/4" thick, with the spacer profile inset 1/8" to give a
// recessed shadow line between the main layers.
//
// Use MODE (below) to switch between views/exports.
// Tweak the dimension blocks to match your actual template.
//
// Working units: inches (set INCH=1 to work in mm instead).
//---------------------------------------------------------

/* [Render Mode] */
// assembled       - full corbel, all layers glued up + cap on top
// exploded        - layers separated along the stack axis
// main_layer      - one 1-3/4" main piece (lay flat, ready to export)
// spacer_layer    - one 1/4" spacer piece (lay flat)
// cap_block       - the top decorative cap with rosette
// profile_2d      - just the 2D side profile (for DXF / template)
MODE = "assembled"; // [assembled, exploded, main_layer, spacer_layer, cap_block, profile_2d]

/* [Units] */
// 25.4 = inches -> mm.  Set to 1.0 to work entirely in mm.
INCH = 25.4;

/* [Layer Stack] */
N_MAIN        = 3;     // number of thick layers
N_SPACER      = 2;     // number of thin spacers (sit between mains)
T_MAIN        = 1.75;  // thick-layer thickness, inches
T_SPACER      = 0.25;  // spacer thickness, inches
SPACER_INSET  = 0.125; // shadow-line inset of spacer vs main, inches

/* [Overall Profile - inches] */
HEIGHT        = 16.0;  // top to bottom
DEPTH         = 8.0;   // projection from wall (front-to-back)

/* [Top Cap Shelf] */
CAP_HEIGHT    = 1.4;   // height of the upper "shelf" / abacus
CAP_STEP_X    = 1.0;   // how far the front steps back below the cap
CAP_STEP_Y    = 0.5;   // height of that step

/* [Belly / Waist - profile control points, fractions of HEIGHT/DEPTH] */
BELLY_X_FRAC  = 0.62;
BELLY_Y_FRAC  = 0.55;
WAIST_X_FRAC  = 0.26;
WAIST_Y_FRAC  = 0.22;

/* [Bottom Teardrop] */
TEARDROP_DIAM   = 3.0;
TEARDROP_X_FRAC = 0.40;
TEARDROP_Y_FRAC = 0.12;

/* [Cap Block (top decorative)] */
CAP_BLOCK_W     = 6.0;   // length along the stack axis
CAP_BLOCK_D     = 3.5;   // depth (front-to-back)
CAP_BLOCK_H     = 3.2;   // height
ROSETTE_DIAM    = 1.8;
ROSETTE_DEPTH   = 0.20;

/* [Rendering] */
$fn          = 80;
CURVE_STEPS  = 28;
EXPLODE_GAP  = 0.6;   // inches between layers in exploded view


//---------------------------------------------------------
// Bezier helpers
//---------------------------------------------------------
function bez(p0,p1,p2,p3,t) =
      pow(1-t,3)*p0
    + 3*pow(1-t,2)*t*p1
    + 3*(1-t)*pow(t,2)*p2
    + pow(t,3)*p3;

// Sampled points strictly BETWEEN endpoints (exclusive of both)
// so we can chain segments without duplicating shared vertices.
function bez_seg(p0,p1,p2,p3,n) =
    [ for (i = [1 : n-1]) bez(p0,p1,p2,p3, i/n) ];


//---------------------------------------------------------
// 2D Profile (defined in inches)
//---------------------------------------------------------
module corbel_profile() {
    H = HEIGHT;
    D = DEPTH;

    // Key vertices (inches)
    p_top_back     = [0, H];
    p_top_front    = [D, H];
    p_cap_front_b  = [D, H - CAP_HEIGHT];
    p_cap_step_top = [D - CAP_STEP_X, H - CAP_HEIGHT];
    p_cap_step_bot = [D - CAP_STEP_X, H - CAP_HEIGHT - CAP_STEP_Y];

    belly = [D * BELLY_X_FRAC, H * BELLY_Y_FRAC];
    waist = [D * WAIST_X_FRAC, H * WAIST_Y_FRAC];

    td_c = [D * TEARDROP_X_FRAC, H * TEARDROP_Y_FRAC];
    td_r = TEARDROP_DIAM / 2;

    // Smooth point where the profile meets the teardrop circle.
    // Sits on the upper-left side of the circle so the polygon
    // and the circle overlap cleanly when unioned.
    td_meet = [td_c[0] - td_r * 0.55, td_c[1] + td_r * 0.70];

    // Bezier handles for the three S-curve segments.
    // Tuned by eye - tweak if the curve looks wrong.
    h_step_to_belly_a = [p_cap_step_bot[0] + 0.2, p_cap_step_bot[1] - 1.5];
    h_step_to_belly_b = [belly[0] + 0.4, belly[1] + 1.2];

    h_belly_to_waist_a = [belly[0],         (belly[1] + waist[1])/2 - 0.4];
    h_belly_to_waist_b = [waist[0] + 0.6,   (belly[1] + waist[1])/2 + 0.6];

    h_waist_to_td_a    = [waist[0] - 0.1,   (waist[1] + td_meet[1])/2 + 0.2];
    h_waist_to_td_b    = [td_meet[0] + 0.2, td_meet[1] + 0.3];

    union() {
        polygon(points = concat(
            // Top edge: back -> front -> down the cap -> step
            [p_top_back, p_top_front, p_cap_front_b,
             p_cap_step_top, p_cap_step_bot],

            // S-curve down to the belly
            bez_seg(p_cap_step_bot, h_step_to_belly_a,
                    h_step_to_belly_b, belly, CURVE_STEPS),

            [belly],

            // Reverse curve from belly to waist
            bez_seg(belly, h_belly_to_waist_a,
                    h_belly_to_waist_b, waist, CURVE_STEPS),

            [waist],

            // Run into the teardrop
            bez_seg(waist, h_waist_to_td_a,
                    h_waist_to_td_b, td_meet, CURVE_STEPS),

            [td_meet,
             // Bottom-back corner; back edge auto-closes to top-back.
             [0, 0]]
        ));

        // Rounded teardrop, unioned with polygon so the join is seamless.
        translate(td_c) circle(r = td_r);
    }
}

module spacer_profile() {
    // Negative offset produces the inset shadow-line shape.
    offset(r = -SPACER_INSET) corbel_profile();
}


//---------------------------------------------------------
// 3D layers (extruded along Z = stack axis)
//---------------------------------------------------------
module main_layer() {
    linear_extrude(height = T_MAIN * INCH, convexity = 4)
        scale(INCH) corbel_profile();
}

module spacer_layer() {
    linear_extrude(height = T_SPACER * INCH, convexity = 4)
        scale(INCH) spacer_profile();
}


//---------------------------------------------------------
// Cap block (top decorative block with carved rosette)
//
// Sits centered on the stack axis (Z), base at Y=0 (so it
// rests on top of the corbel body when translated up by
// HEIGHT), depth along +X with front face at X = CAP_BLOCK_D.
//---------------------------------------------------------
module rosette_2d(d) {
    petal_r      = d * 0.22;
    petal_offset = d * 0.26;
    union() {
        circle(r = petal_r * 1.15);          // center hub
        for (a = [0, 90, 180, 270])
            rotate([0, 0, a])
                translate([petal_offset, 0])
                    circle(r = petal_r);     // four petals
    }
}

module cap_block() {
    cw = CAP_BLOCK_W  * INCH;
    cd = CAP_BLOCK_D  * INCH;
    ch = CAP_BLOCK_H  * INCH;
    rd = ROSETTE_DIAM * INCH;
    rz = ROSETTE_DEPTH * INCH;

    difference() {
        // block centered on Z, base at Y=0, +X is forward (toward front face)
        translate([0, 0, -cw/2])
            cube([cd, ch, cw]);

        // Rosette carved into the front face (X = cd)
        translate([cd - rz + 0.01, ch/2, 0])
            rotate([0, 90, 0])
                linear_extrude(height = rz + 0.1)
                    rosette_2d(rd);
    }
}


//---------------------------------------------------------
// Stack assembly
//
// Z is the stack-up axis (horizontal, parallel to the wall
// when installed).  Stack is centered on Z=0.
//---------------------------------------------------------

// z-offset (in mm) of the bottom face of layer i, where layers
// alternate main(0), spacer(1), main(2), spacer(3), main(4), ...
function layer_z(i) =
    let (n_main_before   = ceil(i / 2),
         n_spacer_before = floor(i / 2))
        n_main_before   * T_MAIN   * INCH
      + n_spacer_before * T_SPACER * INCH;

module corbel_assembly(explode = false) {
    gap          = explode ? EXPLODE_GAP * INCH : 0;
    total_layers = N_MAIN + N_SPACER;

    stack_total  = N_MAIN   * T_MAIN   * INCH
                 + N_SPACER * T_SPACER * INCH;

    // center the stack along Z
    translate([0, 0, -stack_total/2]) {
        for (i = [0 : total_layers - 1]) {
            translate([0, 0, layer_z(i) + i * gap])
                if (i % 2 == 0)
                    color("burlywood") main_layer();
                else
                    color("saddlebrown") spacer_layer();
        }
    }

    // cap block: rests on top of the corbel body, front face
    // aligned with the top cap shelf's front
    cap_y_gap = explode ? EXPLODE_GAP * INCH : 0;
    cap_x_front = DEPTH * INCH;          // align front face with corbel front
    translate([cap_x_front - CAP_BLOCK_D * INCH,
               HEIGHT * INCH + cap_y_gap,
               0])
        color("tan") cap_block();
}


//---------------------------------------------------------
// Dispatch
//---------------------------------------------------------
if      (MODE == "assembled")    corbel_assembly(explode = false);
else if (MODE == "exploded")     corbel_assembly(explode = true);
else if (MODE == "main_layer")   main_layer();
else if (MODE == "spacer_layer") spacer_layer();
else if (MODE == "cap_block")    cap_block();
else if (MODE == "profile_2d")   scale(INCH) corbel_profile();
else                             echo("Unknown MODE: ", MODE);
