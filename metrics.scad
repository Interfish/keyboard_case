delta = 1;
big_delta = 1.5;

// common
round_edge_r = 10;

// middle
tp_case_l = 260;

// trackpad
tp_l = 160 + delta;
tp_w = 115 + 1 + delta; // + 1 for power button
tp_h_high = 8;
tp_h_low = 1.8;
tp_sink = 5;
// tp_hand_rest_w = 50;
tp_offset_x = 30;

// keyboard
kb_case_w = 210;
kb_case_l = 270;
kb_case_h_low = 35;
kb_case_h_high = 52.5;

kb_left_l = 183 + big_delta;
kb_right_l = 187 + big_delta;
kb_w = 118 + big_delta;    // width  (X)
kb_h1 = 17;    // left height
kb_h2 = 19;     // right height (thin edge)
kb_h3 = 32;   // bottom bulge depth (positive means down)
kb_h4 = 107;    // distance from right edge to bulge apex

// keyboard - sweep
kb_sweep_rotate_angle_left = 2;
kb_sweep_rotate_angle_right = 5;
arm_length = 470;
distance_between_two_middle_finger = 540;
// keyboard - sweep - left end on W key
kb_left_rotate_end_to_kb_right = 90;
kb_left_rotate_end_to_kb_top = 40;
// keyboard - sweep - right on middle of O and P key
// symmetric to left keyboard, so to kb_right is actually kb_left
kb_right_rotate_end_to_kb_right = 95;
kb_right_rotate_end_to_kb_top = 40;

kb_left_offset_y = (distance_between_two_middle_finger - tp_case_l) / 2 - kb_left_rotate_end_to_kb_right;
kb_right_offset_y = (distance_between_two_middle_finger - tp_case_l) / 2 - kb_right_rotate_end_to_kb_right;

kb_z_lift = -3;
kb_y_offset = 5;
kb_x_offset = 15;
kb_yz_rot = atan((kb_case_h_high - kb_case_h_low) / kb_case_l); // degrees

// keyboard side notch
notch_w = 38;
notch_l = 155;
notch_h = kb_h3 - kb_h1;
notch_y_offset = -10;
notch_x_offset = 0;
notch_z_offset = -kb_h1 + kb_z_lift ;

// connectors
connector_embed_y = 5;
connector_L = 30 + connector_embed_y;
connector_W = 150;
connector_H = 15;
connector_l1 = 15;
connector_h1 = 15;