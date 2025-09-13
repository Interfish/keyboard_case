use <common.scad>;

cube([100, 10, 10]);
cube([10, 100, 10]);
cube([10, 10, 100]);

difference() {
    cube([kb_case_w, tp_case_l, kb_case_right_h])
}