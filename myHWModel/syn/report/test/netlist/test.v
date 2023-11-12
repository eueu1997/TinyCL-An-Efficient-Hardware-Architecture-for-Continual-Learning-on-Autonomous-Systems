/////////////////////////////////////////////////////////////
// Created by: Synopsys Design Compiler(R)
// Version   : R-2020.09-SP2
// Date      : Sun Nov 12 10:40:10 2023
/////////////////////////////////////////////////////////////


module test ( featureInColumnAddrBWDK, clk, rst, out );
  input [4:0] featureInColumnAddrBWDK;
  input clk, rst;
  output out;
  wire   N0, N1, N2, N3, N4;

  GTECH_OR2 C10 ( .A(featureInColumnAddrBWDK[3]), .B(
        featureInColumnAddrBWDK[4]), .Z(N0) );
  GTECH_OR2 C11 ( .A(featureInColumnAddrBWDK[2]), .B(N0), .Z(N1) );
  GTECH_OR2 C12 ( .A(featureInColumnAddrBWDK[1]), .B(N1), .Z(N2) );
  GTECH_OR2 C13 ( .A(featureInColumnAddrBWDK[0]), .B(N2), .Z(N3) );
  GTECH_NOT I_0 ( .A(N3), .Z(N4) );
  GTECH_BUF B_0 ( .A(N4), .Z(out) );
endmodule

