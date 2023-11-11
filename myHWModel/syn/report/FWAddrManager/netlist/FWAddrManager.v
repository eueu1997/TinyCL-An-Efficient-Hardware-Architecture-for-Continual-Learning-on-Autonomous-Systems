/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : R-2020.09-SP2
// Date      : Wed Nov  1 18:29:07 2023
/////////////////////////////////////////////////////////////


module FWAddrManager ( clk, rst, featureInActChSize, featureOutActChSize, 
        featureOutActRowSize, featureOutActColumnSize, featureOutRowAddr, 
        featureOutColumAddr, featureOutChAddr, NewFeatureOutChAddr, 
        featureInChAddr, NewFeatureInChAddr );
  input [2:0] featureInActChSize;
  input [2:0] featureOutActChSize;
  input [4:0] featureOutActRowSize;
  input [4:0] featureOutActColumnSize;
  output [4:0] featureOutRowAddr;
  output [4:0] featureOutColumAddr;
  output [2:0] featureOutChAddr;
  output [2:0] NewFeatureOutChAddr;
  output [2:0] featureInChAddr;
  output [2:0] NewFeatureInChAddr;
  input clk, rst;
  wire   N10, N11, N12, N13, N14, N21, N22, N23, N24, N38, N39, N40, N41, n32,
         n36, n52, n53, n54, n55, n56, n57, n58, n59, n60, n61, n62, n63, n64,
         n65, n66, n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78,
         n79, n80, n81, n82, n83, n84, n85, n86, n87, n88, n89, n91, n92, n93,
         n94, n95, n96, n97, n98, n99, n100, n101, n102, n103, n104, n105,
         n106, n107, n108, n109, n110, n111, n112, n113, n114, n115, n116,
         n117, n118;
  wire   [4:0] NewFeatureOutRow;
  wire   [4:2] add_58_carry;
  wire   [4:2] add_37_carry;

  XOR2M2RA U23 ( .A(featureOutActColumnSize[1]), .B(n64), .Z(n69) );
  XOR2M2RA U24 ( .A(featureOutActColumnSize[3]), .B(n66), .Z(n68) );
  XOR2M2RA U26 ( .A(featureOutActColumnSize[2]), .B(n65), .Z(n72) );
  XOR2M2RA U27 ( .A(featureOutActColumnSize[0]), .B(n62), .Z(n71) );
  XOR2M2RA U28 ( .A(featureOutActColumnSize[4]), .B(n67), .Z(n70) );
  XNR2M2RA U38 ( .A(featureOutActColumnSize[0]), .B(featureOutColumAddr[0]), 
        .Z(n80) );
  XOR2M2RA U40 ( .A(featureOutColumAddr[4]), .B(featureOutActColumnSize[4]), 
        .Z(n82) );
  XOR2M2RA U41 ( .A(featureOutColumAddr[1]), .B(featureOutActColumnSize[1]), 
        .Z(n81) );
  XNR2M2RA U42 ( .A(featureOutActColumnSize[3]), .B(featureOutColumAddr[3]), 
        .Z(n78) );
  XNR2M2RA U43 ( .A(featureOutActColumnSize[2]), .B(featureOutColumAddr[2]), 
        .Z(n77) );
  XOR2M2RA U54 ( .A(n118), .B(featureOutActChSize[1]), .Z(n93) );
  XOR2M2RA U55 ( .A(n117), .B(featureOutActChSize[0]), .Z(n92) );
  XOR2M2RA U56 ( .A(n32), .B(featureOutActChSize[2]), .Z(n91) );
  XOR2M2RA U64 ( .A(featureOutRowAddr[1]), .B(featureOutActRowSize[1]), .Z(n99) );
  XOR2M2RA U65 ( .A(featureOutRowAddr[2]), .B(featureOutActRowSize[2]), .Z(n98) );
  XOR2M2RA U66 ( .A(featureOutRowAddr[3]), .B(featureOutActRowSize[3]), .Z(n97) );
  XOR2M2RA U67 ( .A(n36), .B(featureOutActRowSize[4]), .Z(n95) );
  XOR2M2RA U70 ( .A(n114), .B(featureOutActRowSize[0]), .Z(n94) );
  DFEQZRM1RA featureInCh_reg_2_ ( .RB(n105), .D(1'b0), .E(n112), .CK(clk), .Q(
        featureInChAddr[2]) );
  DFEQZRM1RA featureInCh_reg_1_ ( .RB(n105), .D(1'b0), .E(n112), .CK(clk), .Q(
        featureInChAddr[1]) );
  DFEQZRM1RA featureInCh_reg_0_ ( .RB(n105), .D(1'b0), .E(n112), .CK(clk), .Q(
        featureInChAddr[0]) );
  DFQM2RA featureOutCh_reg_1_ ( .D(NewFeatureOutChAddr[1]), .CK(clk), .Q(
        featureOutChAddr[1]) );
  DFQBM2RA featureOutCh_reg_2_ ( .D(NewFeatureOutChAddr[2]), .CK(clk), .QB(n32) );
  DFQBM2RA featureOutRow_reg_4_ ( .D(NewFeatureOutRow[4]), .CK(clk), .QB(n36)
         );
  DFQM2RA featureOutCh_reg_0_ ( .D(NewFeatureOutChAddr[0]), .CK(clk), .Q(
        featureOutChAddr[0]) );
  DFQM2RA featureOutRow_reg_2_ ( .D(NewFeatureOutRow[2]), .CK(clk), .Q(
        featureOutRowAddr[2]) );
  DFQM2RA featureOutRow_reg_3_ ( .D(NewFeatureOutRow[3]), .CK(clk), .Q(
        featureOutRowAddr[3]) );
  DFQM2RA featureOutRow_reg_1_ ( .D(NewFeatureOutRow[1]), .CK(clk), .Q(
        featureOutRowAddr[1]) );
  DFQM2RA featureOutColum_reg_4_ ( .D(n111), .CK(clk), .Q(
        featureOutColumAddr[4]) );
  DFQM2RA featureOutRow_reg_0_ ( .D(NewFeatureOutRow[0]), .CK(clk), .Q(
        featureOutRowAddr[0]) );
  DFQM2RA featureOutColum_reg_2_ ( .D(n109), .CK(clk), .Q(
        featureOutColumAddr[2]) );
  DFQM2RA featureOutColum_reg_1_ ( .D(n108), .CK(clk), .Q(
        featureOutColumAddr[1]) );
  DFQM2RA featureOutColum_reg_3_ ( .D(n110), .CK(clk), .Q(
        featureOutColumAddr[3]) );
  DFQM2RA featureOutColum_reg_0_ ( .D(n107), .CK(clk), .Q(
        featureOutColumAddr[0]) );
  ADHM1RA add_58_U1_1_3 ( .A(featureOutRowAddr[3]), .B(add_58_carry[3]), .CO(
        add_58_carry[4]), .S(N40) );
  ADHM1RA add_37_U1_1_3 ( .A(featureOutColumAddr[3]), .B(add_37_carry[3]), 
        .CO(add_37_carry[4]), .S(N13) );
  ADHM1RA add_58_U1_1_2 ( .A(featureOutRowAddr[2]), .B(add_58_carry[2]), .CO(
        add_58_carry[3]), .S(N39) );
  ADHM1RA add_58_U1_1_1 ( .A(featureOutRowAddr[1]), .B(featureOutRowAddr[0]), 
        .CO(add_58_carry[2]), .S(N38) );
  ADHM1RA add_37_U1_1_2 ( .A(featureOutColumAddr[2]), .B(add_37_carry[2]), 
        .CO(add_37_carry[3]), .S(N12) );
  ADHM1RA add_37_U1_1_1 ( .A(featureOutColumAddr[1]), .B(
        featureOutColumAddr[0]), .CO(add_37_carry[2]), .S(N11) );
  OAI33M2R U86 ( .A1(n56), .A2(n57), .A3(n58), .B1(n59), .B2(n113), .B3(n60), 
        .Z(n55) );
  ND2M2R U87 ( .A(n68), .B(n69), .Z(n58) );
  INVM2R U88 ( .A(n63), .Z(n113) );
  ND3M2R U89 ( .A(n70), .B(n71), .C(n72), .Z(n56) );
  ND3B1M2R U90 ( .NA(n55), .B(n54), .C(n105), .Z(n52) );
  NR2B1M2R U91 ( .NA(n76), .B(n57), .Z(n73) );
  ND4M2R U92 ( .A(n64), .B(n65), .C(n66), .D(n67), .Z(n59) );
  INVM2R U93 ( .A(n54), .Z(n112) );
  MOAI22M2RA U94 ( .A1(n116), .A2(n52), .B1(N40), .B2(n53), .Z(
        NewFeatureOutRow[3]) );
  MOAI22M2RA U95 ( .A1(n115), .A2(n52), .B1(N39), .B2(n53), .Z(
        NewFeatureOutRow[2]) );
  AN2M2R U96 ( .A(n76), .B(n57), .Z(n74) );
  INVM2R U97 ( .A(n84), .Z(n106) );
  OAI21M2R U98 ( .A1(n117), .A2(n88), .B(n87), .Z(NewFeatureOutChAddr[0]) );
  AN3M2R U99 ( .A(n54), .B(n105), .C(n55), .Z(n53) );
  INVM2R U100 ( .A(n64), .Z(n108) );
  INVM2R U101 ( .A(n65), .Z(n109) );
  INVM2R U102 ( .A(n66), .Z(n110) );
  INVM2R U103 ( .A(n67), .Z(n111) );
  ND2M2R U104 ( .A(n87), .B(n88), .Z(n86) );
  INVM2R U105 ( .A(n62), .Z(n107) );
  ND2M2R U106 ( .A(n106), .B(n117), .Z(n87) );
  NR3M2R U107 ( .A(n63), .B(rst), .C(n114), .Z(n75) );
  AOI222M1RA U108 ( .A1(n73), .A2(featureOutColumAddr[1]), .B1(N11), .B2(n74), 
        .C1(N21), .C2(n75), .Z(n64) );
  AOI222M1RA U109 ( .A1(n73), .A2(featureOutColumAddr[2]), .B1(N12), .B2(n74), 
        .C1(N22), .C2(n75), .Z(n65) );
  AOI222M1RA U110 ( .A1(n73), .A2(featureOutColumAddr[3]), .B1(N13), .B2(n74), 
        .C1(N23), .C2(n75), .Z(n66) );
  AOI222M1RA U111 ( .A1(n73), .A2(featureOutColumAddr[4]), .B1(N14), .B2(n74), 
        .C1(N24), .C2(n75), .Z(n67) );
  ND4M2R U112 ( .A(n77), .B(n78), .C(n79), .D(n80), .Z(n57) );
  NR2M2R U113 ( .A(n81), .B(n82), .Z(n79) );
  AOI222M1RA U114 ( .A1(n73), .A2(featureOutColumAddr[0]), .B1(N10), .B2(n74), 
        .C1(N10), .C2(n75), .Z(n62) );
  INVM2R U115 ( .A(featureOutColumAddr[0]), .Z(N10) );
  NR4B1M1R U116 ( .NA(n100), .B(featureOutColumAddr[0]), .C(
        featureOutColumAddr[1]), .D(featureOutColumAddr[2]), .Z(n63) );
  NR2M2R U117 ( .A(featureOutColumAddr[4]), .B(featureOutColumAddr[3]), .Z(
        n100) );
  ND4M2R U118 ( .A(n94), .B(n63), .C(n95), .D(n96), .Z(n54) );
  NR3M2R U119 ( .A(n97), .B(n98), .C(n99), .Z(n96) );
  OAI32M2R U120 ( .A1(n83), .A2(n118), .A3(n84), .B1(n85), .B2(n32), .Z(
        NewFeatureOutChAddr[2]) );
  ND2M2R U121 ( .A(featureOutChAddr[0]), .B(n32), .Z(n83) );
  AOI21M2R U122 ( .A1(n106), .A2(n118), .B(n86), .Z(n85) );
  OAI31M2R U123 ( .A1(n61), .A2(featureOutRowAddr[1]), .A3(
        featureOutRowAddr[0]), .B(n62), .Z(n60) );
  ND3M2R U124 ( .A(n116), .B(n36), .C(n115), .Z(n61) );
  OR2M2R U125 ( .A(n112), .B(rst), .Z(n88) );
  OAI22B10M2R U126 ( .NA2(n53), .A1(featureOutRowAddr[0]), .B1(n114), .B2(n52), 
        .Z(NewFeatureOutRow[0]) );
  MOAI22M2RA U127 ( .A1(n36), .A2(n52), .B1(N41), .B2(n53), .Z(
        NewFeatureOutRow[4]) );
  INVM2R U128 ( .A(featureOutChAddr[1]), .Z(n118) );
  INVM2R U129 ( .A(rst), .Z(n105) );
  INVM2R U130 ( .A(featureOutRowAddr[0]), .Z(n114) );
  INVM2R U131 ( .A(featureOutChAddr[0]), .Z(n117) );
  NR2M2R U132 ( .A(featureOutRowAddr[0]), .B(rst), .Z(n76) );
  ND2M2R U133 ( .A(n89), .B(n112), .Z(n84) );
  AOI31M2R U134 ( .A1(n91), .A2(n92), .A3(n93), .B(rst), .Z(n89) );
  INVM2R U135 ( .A(featureOutRowAddr[2]), .Z(n115) );
  INVM2R U136 ( .A(featureOutRowAddr[3]), .Z(n116) );
  AO32M2RA U137 ( .A1(n106), .A2(n118), .A3(featureOutChAddr[0]), .B1(n86), 
        .B2(featureOutChAddr[1]), .Z(NewFeatureOutChAddr[1]) );
  NR2B1M2R U138 ( .NA(featureInChAddr[0]), .B(n88), .Z(NewFeatureInChAddr[0])
         );
  NR2B1M2R U139 ( .NA(featureInChAddr[1]), .B(n88), .Z(NewFeatureInChAddr[1])
         );
  NR2B1M2R U140 ( .NA(featureInChAddr[2]), .B(n88), .Z(NewFeatureInChAddr[2])
         );
  INVM2R U141 ( .A(featureOutColumAddr[2]), .Z(n104) );
  AO22B10M2R U142 ( .B1(N38), .B2(n53), .A1(featureOutRowAddr[1]), .NA2(n52), 
        .Z(NewFeatureOutRow[1]) );
  INVM2R U143 ( .A(n36), .Z(featureOutRowAddr[4]) );
  INVM2R U144 ( .A(n32), .Z(featureOutChAddr[2]) );
  CKXOR2M1RA U145 ( .A(add_37_carry[4]), .B(featureOutColumAddr[4]), .Z(N14)
         );
  NR2M1R U146 ( .A(featureOutColumAddr[1]), .B(featureOutColumAddr[0]), .Z(
        n101) );
  AO21M1RA U147 ( .A1(featureOutColumAddr[0]), .A2(featureOutColumAddr[1]), 
        .B(n101), .Z(N21) );
  CKND2M2R U148 ( .A(n101), .B(n104), .Z(n102) );
  OAI21M1R U149 ( .A1(n101), .A2(n104), .B(n102), .Z(N22) );
  XNR2M1RA U150 ( .A(featureOutColumAddr[3]), .B(n102), .Z(N23) );
  NR2M1R U151 ( .A(featureOutColumAddr[3]), .B(n102), .Z(n103) );
  CKXOR2M1RA U152 ( .A(featureOutColumAddr[4]), .B(n103), .Z(N24) );
  CKXOR2M1RA U153 ( .A(add_58_carry[4]), .B(featureOutRowAddr[4]), .Z(N41) );
endmodule

