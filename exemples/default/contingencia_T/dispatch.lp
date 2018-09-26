Minimize
 obj: 100 g_1_1 + 150 g_2_1
Subject To
 c1: 1 f_1_1 <= 100
 c2: 1 f_2_1 <= 20
 c3: 1 f_3_1 <= 80
 c4: -1 f_1_1 <= 100
 c5: -1 f_2_1 <= 20
 c6: -1 f_3_1 <= 80
 c7: 1 f_1_1 - 1 theta_1_1 + 1 theta_3_1 = 0
 c8: 1 f_2_1 - 1 theta_1_1 + 1 theta_2_1 = 0
 c9: 1 f_3_1 - 1 theta_2_1 + 1 theta_3_1 = 0
 c10: 1 g_1_1 <= 100
 c11: 1 g_2_1 <= 50
 c12: 1 g_1_1 - 1 f_1_1 - 1 f_2_1 = 0
 c13: 1 g_2_1 + 1 f_2_1 - 1 f_3_1 = 0
 c14: 1 f_1_1 + 1 f_3_1 = 120
Bounds
 f_1_1 free
 f_2_1 free
 f_3_1 free
 0 <= g_1_1 <= +inf
 0 <= g_2_1 <= +inf
 0 <= delta_1_1 <= +inf
 0 <= delta_2_1 <= +inf
 0 <= delta_3_1 <= +inf
 theta_1_1 free
 theta_2_1 free
 theta_3_1 free
General
End
