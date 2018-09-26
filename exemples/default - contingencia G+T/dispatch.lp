Minimize
 obj: 100 g_1_1 + 150 g_2_1 + 100 rup_1 + 150 rup_2 + 100 rdown_1 + 150 rdown_2 + 1500 delta_1_1 + 1500 delta_1_2 + 1500 delta_1_3 + 1500 delta_1_4 + 1500 delta_1_5 + 1500 delta_2_1 + 1500 delta_2_2 + 1500 delta_2_3 + 1500 delta_2_4 + 1500 delta_2_5 + 1500 delta_3_1 + 1500 delta_3_2 + 1500 delta_3_3 + 1500 delta_3_4 + 1500 delta_3_5
Subject To
 c1: 1 f_1_1 <= 100
 c2: 1 f_1_2 <= 100
 c3: 1 f_1_3 <= 100
 c4: 1 f_1_4 <= 0
 c5: 1 f_1_5 <= 100
 c6: 1 f_1_6 <= 100
 c7: 1 f_2_1 <= 100
 c8: 1 f_2_2 <= 100
 c9: 1 f_2_3 <= 0
 c10: 1 f_2_4 <= 100
 c11: 1 f_2_5 <= 100
 c12: 1 f_2_6 <= 100
 c13: 1 f_3_1 <= 100
 c14: 1 f_3_2 <= 0
 c15: 1 f_3_3 <= 100
 c16: 1 f_3_4 <= 100
 c17: 1 f_3_5 <= 100
 c18: 1 f_3_6 <= 100
 c19: -1 f_1_1 <= 100
 c20: -1 f_1_2 <= 100
 c21: -1 f_1_3 <= 100
 c22: -1 f_1_4 <= 0
 c23: -1 f_1_5 <= 100
 c24: -1 f_1_6 <= 100
 c25: -1 f_2_1 <= 100
 c26: -1 f_2_2 <= 100
 c27: -1 f_2_3 <= 0
 c28: -1 f_2_4 <= 100
 c29: -1 f_2_5 <= 100
 c30: -1 f_2_6 <= 100
 c31: -1 f_3_1 <= 100
 c32: -1 f_3_2 <= 0
 c33: -1 f_3_3 <= 100
 c34: -1 f_3_4 <= 100
 c35: -1 f_3_5 <= 100
 c36: -1 f_3_6 <= 100
 c37: 1 f_1_1 - 1 theta_1_1 + 1 theta_3_1 = 0
 c38: 1 f_1_2 - 1 theta_1_2 + 1 theta_3_2 = 0
 c39: 1 f_1_3 - 1 theta_1_3 + 1 theta_3_3 = 0
 c40: 1 f_1_4 = 0
 c41: 1 f_1_5 - 1 theta_1_5 + 1 theta_3_5 = 0
 c42: 1 f_1_6 - 1 theta_1_6 + 1 theta_3_6 = 0
 c43: 1 f_2_1 - 1 theta_1_1 + 1 theta_2_1 = 0
 c44: 1 f_2_2 - 1 theta_1_2 + 1 theta_2_2 = 0
 c45: 1 f_2_3 = 0
 c46: 1 f_2_4 - 1 theta_1_4 + 1 theta_2_4 = 0
 c47: 1 f_2_5 - 1 theta_1_5 + 1 theta_2_5 = 0
 c48: 1 f_2_6 - 1 theta_1_6 + 1 theta_2_6 = 0
 c49: 1 f_3_1 - 1 theta_2_1 + 1 theta_3_1 = 0
 c50: 1 f_3_2 = 0
 c51: 1 f_3_3 - 1 theta_2_3 + 1 theta_3_3 = 0
 c52: 1 f_3_4 - 1 theta_2_4 + 1 theta_3_4 = 0
 c53: 1 f_3_5 - 1 theta_2_5 + 1 theta_3_5 = 0
 c54: 1 f_3_6 - 1 theta_2_6 + 1 theta_3_6 = 0
 c55: 1 g_1_1 + 1 rup_1 <= 100
 c56: 1 g_2_1 + 1 rup_2 <= 100
 c57: -1 g_1_1 + 1 rdown_1 <= 0
 c58: -1 g_2_1 + 1 rdown_2 <= 0
 c59: 1 rup_1 <= 50
 c60: 1 rup_2 <= 50
 c61: 1 rdown_1 <= 0
 c62: 1 rdown_2 <= 0
 c63: 1 g_1_1 - 1 f_1_1 - 1 f_2_1 = 0
 c64: 1 g_1_2 - 1 f_1_2 - 1 f_2_2 = 0
 c65: 1 g_1_3 - 1 f_1_3 - 1 f_2_3 = 0
 c66: 1 g_1_4 - 1 f_1_4 - 1 f_2_4 = 0
 c67: 1 g_1_5 - 1 f_1_5 - 1 f_2_5 = 0
 c68: 1 g_1_6 - 1 f_1_6 - 1 f_2_6 = 0
 c69: 1 g_2_1 + 1 f_2_1 - 1 f_3_1 = 0
 c70: 1 g_2_2 + 1 f_2_2 - 1 f_3_2 = 0
 c71: 1 g_2_3 + 1 f_2_3 - 1 f_3_3 = 0
 c72: 1 g_2_4 + 1 f_2_4 - 1 f_3_4 = 0
 c73: 1 g_2_5 + 1 f_2_5 - 1 f_3_5 = 0
 c74: 1 g_2_6 + 1 f_2_6 - 1 f_3_6 = 0
 c75: 1 f_1_1 + 1 f_3_1 = 100
 c76: 1 f_1_2 + 1 f_3_2 = 100
 c77: 1 f_1_3 + 1 f_3_3 = 100
 c78: 1 f_1_4 + 1 f_3_4 = 100
 c79: 1 f_1_5 + 1 f_3_5 = 100
 c80: 1 f_1_6 + 1 f_3_6 = 100
 c81: 1 g_1_2 - 1 g_1_1 - 1 rup_1 <= 0
 c82: 1 g_1_3 - 1 g_1_1 - 1 rup_1 <= 0
 c83: 1 g_1_4 - 1 g_1_1 - 1 rup_1 <= 0
 c84: 1 g_1_5 - 1 g_1_1 - 1 rup_1 <= 0
 c85: 1 g_1_6 <= 0
 c86: 1 g_2_2 - 1 g_2_1 - 1 rup_2 <= 0
 c87: 1 g_2_3 - 1 g_2_1 - 1 rup_2 <= 0
 c88: 1 g_2_4 - 1 g_2_1 - 1 rup_2 <= 0
 c89: 1 g_2_5 <= 0
 c90: 1 g_2_6 - 1 g_2_1 - 1 rup_2 <= 0
 c91: 1 g_1_1 - 1 rdown_1 - 1 g_1_2 <= 0
 c92: 1 g_1_1 - 1 rdown_1 - 1 g_1_3 <= 0
 c93: 1 g_1_1 - 1 rdown_1 - 1 g_1_4 <= 0
 c94: 1 g_1_1 - 1 rdown_1 - 1 g_1_5 <= 0
 c95: -1 g_1_6 <= 0
 c96: 1 g_2_1 - 1 rdown_2 - 1 g_2_2 <= 0
 c97: 1 g_2_1 - 1 rdown_2 - 1 g_2_3 <= 0
 c98: 1 g_2_1 - 1 rdown_2 - 1 g_2_4 <= 0
 c99: -1 g_2_5 <= 0
 c100: 1 g_2_1 - 1 rdown_2 - 1 g_2_6 <= 0
Bounds
 f_1_1 free
 f_1_2 free
 f_1_3 free
 f_1_4 free
 f_1_5 free
 f_1_6 free
 f_2_1 free
 f_2_2 free
 f_2_3 free
 f_2_4 free
 f_2_5 free
 f_2_6 free
 f_3_1 free
 f_3_2 free
 f_3_3 free
 f_3_4 free
 f_3_5 free
 f_3_6 free
 0 <= g_1_1 <= +inf
 0 <= g_1_2 <= +inf
 0 <= g_1_3 <= +inf
 0 <= g_1_4 <= +inf
 0 <= g_1_5 <= +inf
 0 <= g_1_6 <= +inf
 0 <= g_2_1 <= +inf
 0 <= g_2_2 <= +inf
 0 <= g_2_3 <= +inf
 0 <= g_2_4 <= +inf
 0 <= g_2_5 <= +inf
 0 <= g_2_6 <= +inf
 0 <= delta_1_1 <= +inf
 0 <= delta_1_2 <= +inf
 0 <= delta_1_3 <= +inf
 0 <= delta_1_4 <= +inf
 0 <= delta_1_5 <= +inf
 0 <= delta_1_6 <= +inf
 0 <= delta_2_1 <= +inf
 0 <= delta_2_2 <= +inf
 0 <= delta_2_3 <= +inf
 0 <= delta_2_4 <= +inf
 0 <= delta_2_5 <= +inf
 0 <= delta_2_6 <= +inf
 0 <= delta_3_1 <= +inf
 0 <= delta_3_2 <= +inf
 0 <= delta_3_3 <= +inf
 0 <= delta_3_4 <= +inf
 0 <= delta_3_5 <= +inf
 0 <= delta_3_6 <= +inf
 theta_1_1 free
 theta_1_2 free
 theta_1_3 free
 theta_1_4 free
 theta_1_5 free
 theta_1_6 free
 theta_2_1 free
 theta_2_2 free
 theta_2_3 free
 theta_2_4 free
 theta_2_5 free
 theta_2_6 free
 theta_3_1 free
 theta_3_2 free
 theta_3_3 free
 theta_3_4 free
 theta_3_5 free
 theta_3_6 free
 0 <= rup_1 <= +inf
 0 <= rup_2 <= +inf
 0 <= rdown_1 <= +inf
 0 <= rdown_2 <= +inf
General
End
