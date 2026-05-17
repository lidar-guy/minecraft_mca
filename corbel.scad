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
HEIGHT        = 20.0;  // top to bottom
DEPTH         = 6.0;   // projection from wall (front-to-back)

/* [Top Cap Shelf] */
// Cap is the full DEPTH wide at top, then sweeps inward via a concave
// undercut into the narrower neck below it.
CAP_HEIGHT       = 2.0;   // vertical height of the flat cap shelf
CAP_UNDERCUT_H   = 1.0;   // height of the concave sweep below the cap
NECK_INSET       = 2.2;   // how far the neck is set back from the cap front

/* [Neck and Body] */
// The neck is the narrowest part, directly below the cap.
// Below it, a convex shoulder broadens out into the body.
// Body length is auto-computed to fill HEIGHT minus the cap and
// pendant zones, so the body always meets the pendant arc cleanly.
NECK_HEIGHT      = 3.0;   // straight neck length
SHOULDER_H       = 1.2;   // height of the convex shoulder curve
BODY_INSET       = 0.5;   // body sits slightly back from the cap front

/* [Pendant Drop] */
// Bottom pendant: a rounded lobe that tapers down to a pointed
// finial tip (NOT a plain half-circle).  The lobe is a circle and
// the tip is a separate tapered polygon unioned below it.  The
// whole pendant is clipped to x>=0 so it sits flush with the back.
PENDANT_DIAM         = 3.4;  // main lobe diameter
PENDANT_BACK_OVERLAP = 0.15; // how far past the back wall the lobe extends
PENDANT_TIP_DROP     = 2.4;  // how far below the lobe bottom the tip extends
PENDANT_TIP_X_FRAC   = 0.32; // tip X as fraction of DEPTH (~under lobe, slightly fwd)
UNDERCUT_H           = 1.0;  // concave undercut from body down into pendant lobe

/* [Cap Block (top decorative)] */
CAP_BLOCK_W      = 5.5;   // length along the stack axis
CAP_BLOCK_D      = 3.2;   // depth (front-to-back)
CAP_BLOCK_H      = 2.5;   // height
CAP_BLOCK_CHAMFER = 0.5;  // bottom-front corner chamfer
ROSETTE_DIAM     = 2.0;
ROSETTE_DEPTH    = 0.18;
ROSETTE_DOT_FRAC = 0.22;  // dot diameter / rosette diameter
ROSETTE_ARM_W    = 0.08;  // arm groove width / rosette diameter
ROSETTE_ARM_REACH = 0.36; // dot center distance / rosette diameter

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
//
// Built by walking the silhouette from top-back, across the
// top, down the front through four zones, and back to the
// bottom-back corner.  Zones (top -> bottom):
//   1. Cap shelf  (full width at x=DEPTH)
//   2. Concave undercut  (sweeps front-in toward neck)
//   3. Neck        (narrowest, vertical at x=DEPTH-NECK_INSET)
//   4. Convex shoulder  (broadens back out to body)
//   5. Body        (vertical at x=DEPTH-BODY_INSET)
//   6. Concave undercut  (curves in toward pendant)
//   7. Pendant lobe  (unioned circle)
//---------------------------------------------------------
module corbel_profile() {
    H = HEIGHT;
    D = DEPTH;

    // Vertical landmarks - cap section walks DOWN from y=HEIGHT;
    // pendant section walks UP from y=0; body height is whatever's
    // left in between so the body undercut always meets the lobe arc.
    y_top      = H;
    y_cap_bot  = y_top - CAP_HEIGHT;
    y_neck_top = y_cap_bot - CAP_UNDERCUT_H;
    y_neck_bot = y_neck_top - NECK_HEIGHT;
    y_body_top = y_neck_bot - SHOULDER_H;

    // Pendant lobe.  Place its center so the leftmost arc crosses
    // the back wall (x=0) and its bottom sits PENDANT_TIP_DROP above
    // y=0, leaving room for the tapered tip below.
    pen_r = PENDANT_DIAM / 2;
    pen_c = [pen_r - PENDANT_BACK_OVERLAP, pen_r + PENDANT_TIP_DROP];

    // Where the body undercut meets the lobe (upper-front of circle)
    pen_meet_top  = [pen_c[0] + pen_r * 0.55, pen_c[1] + pen_r * 0.85];

    // Body bottom snaps to UNDERCUT_H above the lobe meet point.
    y_body_bot    = pen_meet_top[1] + UNDERCUT_H;
    y_pendant_top = pen_meet_top[1];

    // Horizontal landmarks (X, from the back wall)
    x_cap_front  = D;
    x_neck_front = D - NECK_INSET;
    x_body_front = D - BODY_INSET;

    // Pendant tip: a single point below the lobe, offset forward.
    pen_tip = [D * PENDANT_TIP_X_FRAC, 0];

    // Connection points where the tip polygon meets the lobe (well
    // inside the circle on both sides, so the union is seamless).
    tip_attach_front = [pen_c[0] + pen_r * 0.60, pen_c[1] - pen_r * 0.45];
    tip_attach_back  = [pen_c[0] - pen_r * 0.60, pen_c[1] - pen_r * 0.55];

    // Bezier handles for the tapered sides of the tip.
    // Front side: convex sweep from upper-front of lobe down to tip.
    th_front_a = [tip_attach_front[0] + pen_r * 0.20,
                  tip_attach_front[1] - pen_r * 0.60];
    th_front_b = [pen_tip[0] + pen_r * 0.20, pen_tip[1] + pen_r * 0.30];
    // Back side: gentle concave from tip up to lobe back attach,
    // staying close to the back wall so it doesn't bow outward.
    th_back_a  = [pen_tip[0] - pen_r * 0.15, pen_tip[1] + pen_r * 0.25];
    th_back_b  = [tip_attach_back[0] + pen_r * 0.15,
                  tip_attach_back[1] - pen_r * 0.10];

    // Where the back wall closes (just above where the lobe arc
    // intersects x=0, so the back wall meets the lobe seamlessly).
    back_dy       = sqrt(max(0, pen_r * pen_r - pen_c[0] * pen_c[0]));
    pen_meet_back = [0, pen_c[1] + back_dy + 0.15];

    // ------- Bezier control handles (tuned to look right) -------
    // 1. Cap undercut: cap_front_bot -> neck_top
    //    Concave: pulls inward, with handle dipping below cap.
    h1a = [x_cap_front,  y_cap_bot - CAP_UNDERCUT_H * 0.55];
    h1b = [x_neck_front + 0.10, y_neck_top + CAP_UNDERCUT_H * 0.30];

    // 2. Shoulder: neck_bot -> body_top.  Convex broadening.
    h2a = [x_neck_front, y_neck_bot - SHOULDER_H * 0.55];
    h2b = [x_body_front + 0.05, y_body_top + SHOULDER_H * 0.25];

    // 3. Body-to-pendant undercut: body_bot -> pen_meet_top.
    //    Concave: sweeps inward and down to the pendant top.
    h3a = [x_body_front, y_body_bot - UNDERCUT_H * 0.55];
    h3b = [pen_meet_top[0] + 0.30, pen_meet_top[1] + UNDERCUT_H * 0.35];

    // Clip the union with the back-wall half-plane (x >= 0) so the
    // pendant circle is flush with the back instead of bulging past it.
    intersection() {
    union() {
        polygon(points = concat(
            // Top edge: back -> front, then down cap front
            [[0, y_top],
             [x_cap_front, y_top],
             [x_cap_front, y_cap_bot]],

            // 1. Concave undercut into neck
            bez_seg([x_cap_front, y_cap_bot], h1a, h1b,
                    [x_neck_front, y_neck_top], CURVE_STEPS),

            // 2. Neck (straight)
            [[x_neck_front, y_neck_top],
             [x_neck_front, y_neck_bot]],

            // 3. Convex shoulder out to body
            bez_seg([x_neck_front, y_neck_bot], h2a, h2b,
                    [x_body_front, y_body_top], CURVE_STEPS),

            // 4. Body (straight)
            [[x_body_front, y_body_top],
             [x_body_front, y_body_bot]],

            // 5. Concave undercut down into pendant
            bez_seg([x_body_front, y_body_bot], h3a, h3b,
                    pen_meet_top, CURVE_STEPS),

            // 6. Close to the back wall just above the pendant arc.
            //    The pendant circle (unioned below) covers everything
            //    below this point on the front; the back wall closes
            //    from pen_meet_back up to [0, y_top].
            [pen_meet_top,
             pen_meet_back]
        ));

        // Pendant lobe (main rounded body)
        translate(pen_c) circle(r = pen_r);

        // Pendant tip: tapered polygon extending from the lobe down
        // to a single point.  Sides are bezier-sampled so the taper
        // is curved (concave on the back, convex on the front).
        polygon(points = concat(
            [tip_attach_front],
            bez_seg(tip_attach_front, th_front_a, th_front_b,
                    pen_tip, CURVE_STEPS),
            [pen_tip],
            bez_seg(pen_tip, th_back_a, th_back_b,
                    tip_attach_back, CURVE_STEPS),
            [tip_attach_back]
        ));
    }
    // Back-wall clipping rectangle
    translate([0, -1]) square([D + 5, H + 5]);
    } // end intersection
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
// 2D footprint of the rosette carving: a center dot + four
// corner dots arranged diagonally, connected by thin grooves.
// All sizes in inches; caller scales by INCH.
module rosette_2d(d) {
    dot_r       = d * ROSETTE_DOT_FRAC * 0.5;
    arm_w       = d * ROSETTE_ARM_W;
    arm_reach   = d * ROSETTE_ARM_REACH;

    union() {
        // center dot
        circle(r = dot_r);

        // 4 diagonal arms (thin grooves) and 4 corner dots
        for (a = [45, 135, 225, 315]) {
            rotate([0, 0, a]) {
                // arm groove: thin rectangle from near center out to corner
                translate([arm_reach / 2, 0])
                    square([arm_reach, arm_w], center = true);
                // corner dot
                translate([arm_reach, 0])
                    circle(r = dot_r * 0.85);
            }
        }
    }
}

// Cap block: rectangular block with a bottom-front chamfer and
// the rosette carved into the front face.
//   - centered on Z (stack axis)
//   - base at Y = 0
//   - depth runs along +X, front face at X = CAP_BLOCK_D
module cap_block() {
    cw  = CAP_BLOCK_W       * INCH;  // length along Z
    cd  = CAP_BLOCK_D       * INCH;  // depth along X
    ch  = CAP_BLOCK_H       * INCH;  // height along Y
    cf  = CAP_BLOCK_CHAMFER * INCH;
    rd  = ROSETTE_DIAM      * INCH;
    rz  = ROSETTE_DEPTH     * INCH;

    // The base block, then SUBTRACT a triangular prism off the
    // bottom-front edge for the chamfer, then SUBTRACT the rosette.
    difference() {
        translate([0, 0, -cw/2])
            cube([cd, ch, cw]);

        // Chamfer: triangular prism running along the Z axis,
        // taking a 45-degree bite out of the bottom-front edge.
        translate([cd - cf, -0.01, -cw/2 - 0.01])
            rotate([0, 0, 0])
                linear_extrude(height = cw + 0.02)
                    polygon(points = [[0, 0], [cf + 0.01, 0], [cf + 0.01, cf + 0.01]]);
        // (The polygon is in the XY plane; after extrude along Z it
        //  carves a wedge along the full length of the bottom-front.)

        // Rosette carving on the front face
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
//
// The corbel is modeled with its height along +Y and its
// stack axis along Z.  For preview/assembled views we rotate
// so height is along +Z (OpenSCAD's natural "up"), so the
// default isometric camera shows the corbel standing upright.
// For single-piece exports (main_layer / spacer_layer / cap)
// the part is left flat in the XY plane, which is what a CAM
// program wants for laser/CNC import.
//---------------------------------------------------------
module stand_upright() { rotate([90, 0, 0]) children(); }

if      (MODE == "assembled")    stand_upright() corbel_assembly(explode = false);
else if (MODE == "exploded")     stand_upright() corbel_assembly(explode = true);
else if (MODE == "main_layer")   main_layer();
else if (MODE == "spacer_layer") spacer_layer();
else if (MODE == "cap_block")    cap_block();
else if (MODE == "profile_2d")   scale(INCH) corbel_profile();
else                             echo("Unknown MODE: ", MODE);
