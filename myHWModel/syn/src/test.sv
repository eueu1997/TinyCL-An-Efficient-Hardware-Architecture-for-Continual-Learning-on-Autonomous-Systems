module test #(parameter WIDTH = 16) (input [($clog2(32) -1):0] featureInColumnAddrBWDK,input clk,input rst,output out);

 


assign out = (featureInColumnAddrBWDK == 0)? 1:0;
endmodule
