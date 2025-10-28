delta = 1;
big_delta = 1.5;

// common
round_edge_r = 5;

// middle
tp_case_l = 180;

// trackpad
tp_l = 160 + delta;
tp_w = 115 + 1 + delta; // + 1 for power button
tp_h_high = 10;
tp_h_low = 4;
tp_sink = 3;
// tp_hand_rest_w = 50;
tp_offset_x = 30;

// keyboard
kb_case_w = 240;
kb_case_l = 260;
kb_case_h_low = 40;
kb_case_h_high = 40;

kb_left_l = 183 + big_delta;
kb_right_l = 187 + big_delta;
kb_w = 118 + big_delta;    // width  (X)
kb_h1 = 17;    // left height
kb_h2 = 19;     // right height (thin edge)
kb_h3 = 32;   // bottom bulge depth (positive means down)
kb_h4 = 107;    // distance from right edge to bulge apex

// keyboard - sweep
kb_sweep_rotate_angle_left = 3;
kb_sweep_rotate_angle_right = 5;
arm_length = 400;
distance_between_two_middle_finger = 577;
// keyboard - sweep - when arm is vetical to body, left middle finger end on volume button
// then arm rotate a little bit to get a comfortable posture, the left middle finger hit on W key
kb_left_rotate_end_to_kb_right = 163;
kb_left_rotate_end_to_kb_top = 17;
// keyboard - sweep - Same as left. when arm is vertical to body, right middle finger on Backspace key, rotate to find comfortable posture ends on O key.
// symmetric to left keyboard, so to kb_right is actually kb_left
kb_right_rotate_end_to_kb_right = 160;
kb_right_rotate_end_to_kb_top = 17;

kb_left_offset_y = (distance_between_two_middle_finger - tp_case_l) / 2 - kb_left_rotate_end_to_kb_right;
kb_right_offset_y = (distance_between_two_middle_finger - tp_case_l) / 2 - kb_right_rotate_end_to_kb_right;

kb_z_lift = -5;
kb_y_offset = 5;
kb_x_offset = 15;
kb_yz_rot = atan((kb_case_h_high - kb_case_h_low) / kb_case_l); // degrees

// keyboard side notch
notch_w = 45;
notch_l = 160;
notch_h = kb_h3 - kb_h1 + 15; // +11 to make it more wide and open
notch_y_offset = -10;
notch_x_offset = 0;
notch_z_offset = -kb_h1 + kb_z_lift + 15;

// connectors
connector_embed_y = 3;
connector_L = 40 + connector_embed_y;
connector_W = 150;
connector_H = 15;
connector_l1 = 15;
connector_h1 = 10;