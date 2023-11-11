/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : R-2020.09-SP2
// Date      : Wed Nov  1 18:58:31 2023
/////////////////////////////////////////////////////////////


module test ( data_in, clk, rst, data_out );
  input [15:0] data_in;
  output [15:0] data_out;
  input clk, rst;
  wire   n1;

  DFQZRM2RA data_out_reg_15_ ( .D(data_in[15]), .RB(n1), .CK(clk), .Q(
        data_out[15]) );
  DFQZRM2RA data_out_reg_14_ ( .D(data_in[14]), .RB(n1), .CK(clk), .Q(
        data_out[14]) );
  DFQZRM2RA data_out_reg_13_ ( .D(data_in[13]), .RB(n1), .CK(clk), .Q(
        data_out[13]) );
  DFQZRM2RA data_out_reg_12_ ( .D(data_in[12]), .RB(n1), .CK(clk), .Q(
        data_out[12]) );
  DFQZRM2RA data_out_reg_11_ ( .D(data_in[11]), .RB(n1), .CK(clk), .Q(
        data_out[11]) );
  DFQZRM2RA data_out_reg_10_ ( .D(data_in[10]), .RB(n1), .CK(clk), .Q(
        data_out[10]) );
  DFQZRM2RA data_out_reg_9_ ( .D(data_in[9]), .RB(n1), .CK(clk), .Q(
        data_out[9]) );
  DFQZRM2RA data_out_reg_8_ ( .D(data_in[8]), .RB(n1), .CK(clk), .Q(
        data_out[8]) );
  DFQZRM2RA data_out_reg_7_ ( .D(data_in[7]), .RB(n1), .CK(clk), .Q(
        data_out[7]) );
  DFQZRM2RA data_out_reg_6_ ( .D(data_in[6]), .RB(n1), .CK(clk), .Q(
        data_out[6]) );
  DFQZRM2RA data_out_reg_5_ ( .D(data_in[5]), .RB(n1), .CK(clk), .Q(
        data_out[5]) );
  DFQZRM2RA data_out_reg_4_ ( .D(data_in[4]), .RB(n1), .CK(clk), .Q(
        data_out[4]) );
  DFQZRM2RA data_out_reg_3_ ( .D(data_in[3]), .RB(n1), .CK(clk), .Q(
        data_out[3]) );
  DFQZRM2RA data_out_reg_2_ ( .D(data_in[2]), .RB(n1), .CK(clk), .Q(
        data_out[2]) );
  DFQZRM2RA data_out_reg_1_ ( .D(data_in[1]), .RB(n1), .CK(clk), .Q(
        data_out[1]) );
  DFQZRM2RA data_out_reg_0_ ( .D(data_in[0]), .RB(n1), .CK(clk), .Q(
        data_out[0]) );
  INVM2R U4 ( .A(rst), .Z(n1) );
endmodule

