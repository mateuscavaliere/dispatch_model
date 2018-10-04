Minimize
 obj: 100 g_1_1_1 + 150 g_2_1_1 + 1 startUpCost_1_1 + 1 shutDownCost_1_1 + 1 startUpCost_2_1 + 1 shutDownCost_2_1
Subject To
 c1: 1 f_1_1_1 <= 100
 c2: 1 f_2_1_1 <= 100
 c3: 1 f_3_1_1 <= 100
 c4: -1 f_1_1_1 <= 100
 c5: -1 f_2_1_1 <= 100
 c6: -1 f_3_1_1 <= 100
 c7: 1 g_1_1_1 <= 100
 c8: 1 g_2_1_1 <= 100
 c9: 1 g_1_1_1 - 1 f_1_1_1 - 1 f_2_1_1 = 0
 c10: 1 g_2_1_1 + 1 f_2_1_1 - 1 f_3_1_1 = 0
 c11: 1 f_1_1_1 + 1 f_3_1_1 = 100
Bounds
 f_1_1_1 free
 f_2_1_1 free
 f_3_1_1 free
 0 <= g_1_1_1 <= +inf
 0 <= g_2_1_1 <= +inf
 0 <= commit_1_1 <= 1
 0 <= commit_2_1 <= 1
 0 <= delta_1_1_1 <= +inf
 0 <= delta_2_1_1 <= +inf
 0 <= delta_3_1_1 <= +inf
 0 <= pot_disp_1_1 <= +inf
 0 <= pot_disp_2_1 <= +inf
 0 <= startUpCost_1_1 <= +inf
 0 <= startUpCost_2_1 <= +inf
 0 <= shutDownCost_1_1 <= +inf
 0 <= shutDownCost_2_1 <= +inf
General
 commit_1_1
 commit_2_1
End
