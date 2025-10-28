// unit in mm
use <metrics.scad>;

module approx_keyboard(l, w, h1, h2, h3, h4, center_y = true) {
    h_cut_delta = 20; // to still let case's roof top be "cut" if kb_z_lift is negative
	profile_pts = [
		[0, h_cut_delta],             // top left
        [0, -h1],           // bottom left
        [w - h4, -h3], // bottom bulge apex
        [w, -h2],           // bottom right
        [w, h_cut_delta],             // top right
	];
	// Build X–Z profile in XY plane (treat Z as Y), extrude along Z then rotate so
	// extrusion aligns with global Y. Centering along Y is optional.
    translate([0, - l / 2, 0])
	    rotate([90, 0, 0])
		    linear_extrude(height = l, center = true, convexity = 10)
			    polygon(points = profile_pts);
}

// -----------------------------
// Rotate children around a point in the XY plane by angle about Z axis
module rotate_about_z(angle, center = [0, 0]) {
    translate(center)
        rotate([0, 0, angle])
            translate(-center)
                children();
}

// Sweep children along an arc (about Z) and approximate the swept volume
// by taking the convex hull of consecutive rotated instances.
// - center: rotation center in XY
// - angle: [ccw, cw] sweep in degrees
// - steps: number of segments (higher = smoother)
module sweep_arc(center = [0, 0], angle = [30, 0], steps = 24) {
    ccw = max(0, angle[0]);
    cw = max(0, angle[1]);
    start_a = -cw;
    end_a = ccw;
    total_span = end_a - start_a;
    step = total_span / steps;
    if (total_span <= 0 || step <= 0) {
        children();
    } else {
        for (a = [start_a : step : end_a - step]) {
            hull() {
                rotate_about_z(a, center) children();
                rotate_about_z(a + step, center) children();
            }
        }
    }
}

// Error-controlled sweep: choose steps from desired max sagitta (chord) error
// radius: distance from rotation center to the furthest relevant point of the shape
// max_err: maximum allowed deviation (e.g., 0.05 mm)
// Ensures the angular step a satisfies: sagitta s = r * (1 - cos(a/2)) <= max_err
// a (in degrees) = 2 * acos(1 - max_err / r)
// Error-controlled sweep with automatic radius:
// If radius is not provided, it will be computed as the maximum distance from
// `center` to the 4 top-face corners of approx_keyboard, assuming the
// top-right corner of the device is at (0,0) on the XY plane and the rectangle
// spans to (-w,0), (-w,-l), (0,-l).
module sweep_arc_tol(center = [0, 0], angle = [30, 0], top_w = undef, top_l = undef, max_err = 0.05, min_steps = 240, max_steps = 720) {
    ccw = max(0, angle[0]);
    cw = max(0, angle[1]);
    total_span = ccw + cw;
    if (total_span <= 0) {
        children();
    } else {
        radius = max_radius_from_top_right(center, top_w, top_l);
        a_step = 2 * acos(1 - max_err / max(1e-6, radius));
        steps = clamp_int(ceil(total_span / max(a_step, 0.1)), min_steps, max_steps);
        // Report the realized chord error using the final step count
        actual_step_angle = total_span / steps; // degrees per segment
        realized_err = radius * (1 - cos(actual_step_angle / 2)); // sagitta
        echo("sweep_arc_tol",
             "radius(mm)=", radius,
             ", steps=", steps,
             ", step_angle(deg)=", actual_step_angle,
             ", realized_err(mm)=", realized_err);
        sweep_arc(center = center, angle = [ccw, cw], steps = steps) children();
    }
}

// Local integer clamp replacement for OpenSCAD
function clamp_int(value, lo, hi) = value < lo ? lo : (value > hi ? hi : value);

// Distance helpers and radius from top-right origin rectangle
function dist2(p, q) = (p[0]-q[0])*(p[0]-q[0]) + (p[1]-q[1])*(p[1]-q[1]);
function max_radius_from_top_right(center, w, l) =
    sqrt(max(
        max(dist2(center, [0, 0]), dist2(center, [-w, 0])),
        max(dist2(center, [-w, -l]), dist2(center, [0, -l]))
    ));

module trapezoid_base_yz(w, l, left_h, right_h) {
    pts = [
        [0, 0],
        [-right_h, 0],
        [-left_h, -l],  // bottom at y=l
        [0, -l]    // bottom at y=0
    ];
    // Extrude YZ profile along +X by width w
    rotate([0, 90, 0])
        linear_extrude(height = w, center = false, convexity = 10)
            polygon(points = pts);
}

module connector_tenon(L, W, H, l1, h1) {
    pts = [
        [0, 0],  [0, L], [-H - h1, L],
        [-H - h1, L - l1], [-H, L - l1], [-H, 0]
    ];
    // Create polygon in XY (treat second coord as Z), extrude along Z then rotate so Z->Y
    rotate([0, 90, 0])
        linear_extrude(height = W, center = false, convexity = 10)
            polygon(points = pts);
}

module round_edge_removal(l, r) {
    rotate([0, 90, 90])
        difference() {
            linear_extrude(height = l, center = false, convexity = 10)
                polygon(points = [[0, 0], [r, 0], [0, r]]);
            translate([r, r, 0])
                cylinder(h = l, r = r, center = false);
    }
}

module kb_left_case(kb_l, rotate_end_to_kb_right, rotate_end_to_kb_top, kb_offset_y) {
    kb_sweep_rotate_center = [
        rotate_end_to_kb_top + arm_length,
        -rotate_end_to_kb_right
    ];
    difference() {
        // case base
        translate([0, 0, -kb_case_h_high])
            trapezoid_base_yz(kb_case_w, kb_case_l, kb_case_h_low, kb_case_h_high);
        // keyboard approx
        translate([kb_x_offset, -kb_offset_y, 0])
            rotate([kb_yz_rot, 0, 0])
                sweep_arc_tol(center = kb_sweep_rotate_center, angle = [kb_sweep_rotate_angle_left, kb_sweep_rotate_angle_right], top_w = kb_w, top_l = kb_l, max_err = 0.05)
                    translate([0, -kb_y_offset, kb_z_lift])
                        approx_keyboard(kb_l, kb_w, kb_h1, kb_h2, kb_h3, kb_h4);
        // notch
        rotate([kb_yz_rot, 0, 0])
            translate([notch_x_offset, -notch_l + notch_y_offset, -notch_h + notch_z_offset])
                cube([notch_w, notch_l, notch_h]);
        // round edge
        // +1, - 0.5 for extra length to "difference" the whole edge
        translate([kb_case_w, -kb_case_l - 0.5, kb_case_h_low - kb_case_h_high])
            rotate([kb_yz_rot, 0, 0])
                round_edge_removal(sqrt(pow(kb_case_h_high - kb_case_h_low, 2) + pow(kb_case_l, 2)) + 1, round_edge_r);

    }
    // connector
    translate([(kb_case_w - connector_W) / 2, -connector_embed_y, -kb_case_h_high])
        connector_tenon(connector_L, connector_W, connector_H,
                        connector_l1, connector_h1);
}

module kb_right_case(kb_l) {
    translate([0, tp_case_l, 0])
        mirror([0, 1, 0])
            kb_left_case(kb_l, kb_right_rotate_end_to_kb_right, kb_right_rotate_end_to_kb_top, kb_right_offset_y);
}

module middle_case_slope_removal() {
    far_end = tp_sink;
    pts = [
        [0, -far_end],  [0, tp_h_high - tp_h_low],
        [kb_case_w, 0], [kb_case_w, -far_end]
    ];
    rotate([-90, 0, 0])
        linear_extrude(height = tp_l, center = false, convexity = 10)
            polygon(points = pts);
}

module trackpad() {
    far_end = tp_sink;
    pts = [
        [0, -far_end], [0, tp_h_high],
        [tp_w + delta, tp_h_low], [tp_w + delta, -far_end]
    ];
    rotate([-90, 0, 0])
        linear_extrude(height = tp_l, center = false, convexity = 10)
            polygon(points = pts);
}

module middle_case() {
    difference() {
        // base
        translate([0, 0, -kb_case_h_high])
            cube([kb_case_w, tp_case_l, kb_case_h_high]);


        translate([tp_offset_x, (tp_case_l - tp_l) / 2, -tp_sink])
            trackpad();

        // connector
        translate([(kb_case_w - connector_W - big_delta) / 2, -connector_embed_y, -kb_case_h_high])
            connector_tenon(connector_L, connector_W + big_delta, connector_H,
                            connector_l1 + big_delta, connector_h1);

        translate([(kb_case_w - connector_W - big_delta) / 2, tp_case_l + connector_embed_y, -kb_case_h_high])
            mirror([0, 1, 0])
                connector_tenon(connector_L, connector_W + big_delta, connector_H,
                            connector_l1 + big_delta, connector_h1);

        // round edge
        translate([kb_case_w, 0, 0])
            round_edge_removal(tp_case_l, round_edge_r);
    }
}

// x y z marker
// cube([100, 10, 10]);
// cube([10, 100, 10]);
// cube([10, 10, 100]);

kb_left_case(kb_left_l, kb_left_rotate_end_to_kb_right, kb_left_rotate_end_to_kb_top, kb_left_offset_y);
middle_case();
kb_right_case(kb_right_l);