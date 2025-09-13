// unit in mm

// -----------------------------
// Approx device by 6 params: w, l, h1, h2, h3, h4
// Geometry interpretation (from your sketch):
// - l: plan-view length (Y extent of the side profile)
// - w: plan-view width (extrusion distance along X)
// - h1: left side height (at x = 0)
// - h2: right side height (at x = l)
// - h3: height at the single bottom bulge point (downwards, so it extends below
//       the baseline). Use positive value; it will be modeled as -h3 in Z.
// - h4: horizontal distance from the RIGHT side to that bulge point, along X
//       (so bulge x-position is x = l - h4)
// The 2D side profile is a simple polygon in the X–Z plane with vertices:
//   (0,0) -> (l-h4,-h3) -> (l,0) -> (l,h2) -> (0,h1) -> back to (0,0)
// Then we extrude that profile along Y by distance w.
module approx_keyboard(l, w, h1, h2, h3, h4, center_y = true) {
	profile_pts = [
		[0, 0],             // top left
        [0, -h1],           // bottom left
        [w - h4, -h1 - h3], // bottom bulge apex
        [w, -h2],           // bottom right
        [w, 0],             // top right
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
// - angle: total sweep in degrees (positive = CCW)
// - steps: number of segments (higher = smoother)
module sweep_arc(center = [0, 0], angle = 30, steps = 24) {
    step = angle / steps;
    for (a = [0 : step : angle - step]) {
        hull() {
            rotate_about_z(a, center) children();
            rotate_about_z(a + step, center) children();
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
module sweep_arc_tol(center = [0, 0], angle = 30, top_w = undef, top_l = undef, max_err = 0.05, min_steps = 240, max_steps = 720) {
    radius = max_radius_from_top_right(center, top_w, top_l);
    a_step = 2 * acos(1 - max_err / max(1e-6, radius));
    steps = clamp_int(ceil(angle / max(a_step, 0.1)), min_steps, max_steps);
    // Report the realized chord error using the final step count
    actual_step_angle = angle / steps; // degrees per segment
    realized_err = radius * (1 - cos(actual_step_angle / 2)); // sagitta
    echo("sweep_arc_tol", 
         "radius(mm)=", radius, 
         ", steps=", steps, 
         ", step_angle(deg)=", actual_step_angle, 
         ", realized_err(mm)=", realized_err);
    sweep_arc(center = center, angle = angle, steps = steps) children();
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

module kb_left_case(kb_l) {
    difference() {
        translate([0, 0, -kb_case_right_h])
            trapezoid_base_yz(kb_case_w, kb_case_l, kb_case_left_h, kb_case_right_h);
        translate([kb_x_offset, 0, 0])
            rotate([kb_yz_rot, 0, kb_xy_rot])
                sweep_arc_tol(center = kb_sweep_rotate_center, angle = kb_sweep_rotate_angle, top_w = kb_w, top_l = kb_l, max_err = 0.05)
                    translate([0, 0, kb_z_lift])
                        approx_keyboard(kb_l, kb_w, kb_h1, kb_h2, kb_h3, kb_h4);
        rotate([kb_yz_rot, 0, 0])
            translate([notch_x_offset, -notch_l + notch_y_offset, -notch_h + notch_z_offset])
                cube([notch_w, notch_l, notch_h]);
    }
    translate([(kb_case_w - connector_W) / 2, -connector_embed_y, -kb_case_right_h])
        connector_tenon(connector_L, connector_W, connector_H,
                        connector_l1, connector_h1);
}

module middle_case() {
    difference() {
        translate([0, 0, -kb_case_right_h])
            cube([kb_case_w, tp_case_l, kb_case_right_h]);

        translate([])
            cube(tp_w, tp_l, tp_h)

        translate([(kb_case_w - connector_W) / 2, -connector_embed_y, -kb_case_right_h])
            connector_tenon(connector_L, connector_W, connector_H,
                            connector_l1, connector_h1);

        translate([(kb_case_w - connector_W) / 2, tp_case_l + connector_embed_y, -kb_case_right_h])
            mirror([1, 0, 0])
                connector_tenon(connector_L, connector_W, connector_H,
                            connector_l1, connector_h1);
    }
}

// x y z marker
cube([100, 10, 10]);
cube([10, 100, 10]);
cube([10, 10, 100]);

// kb_left_case(200);
middle_case();
