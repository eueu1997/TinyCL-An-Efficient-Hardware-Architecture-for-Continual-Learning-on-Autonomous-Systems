`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Yigit Suoglu
// 
// Create Date: 07/06/2017 03:21:44 PM
// Design Name: Fixed-Floating-Point-Adder-Multiplier
// Module Name: operatorCore_sim
// Target Devices: Basys 3
// Tool Versions: Vivado 2017.2
// Description: Simulation for all adder subtructor modules in the desing
// 
// Dependencies: adder-mutiplier.v
//////////////////////////////////////////////////////////////////////////////////


module operatorCore_sim();

    reg [15:0] num1, num2;
    wire [15:0] fixM;
    wire [3:0] overflow;
    wire [7:0] num1_int, num1_flo, num2_int, num2_flo, fixM_int, fixM_flo;
    wire num1_sign, num2_sign;
    wire [4:0] num1_exp, num2_exp, floM_exp;
    wire [9:0] num1_frac, num2_frac;
    wire precisionLost;
    
    fixed_multi uut1(num1, num2, fixM, overflow[1], precisionLost,);
    

    assign {num1_int, num1_flo} = num1;
    assign {num2_int, num2_flo} = num2;
    assign {fixM_int, fixM_flo} = fixM;
    assign {num1_sign, num1_exp, num1_frac} = num1;
    assign {num2_sign, num2_exp, num2_frac} = num2;
    
    
    initial //test cases here
        begin
            num1 <= 16'd27;
            num2 <= 16'd42;
            #250
            num1 <= 16'd561;
            num2 <= 16'd158;
            #250
            num1 <=  16'b1010101010001110;
            num2 <= 16'b0101011100100110;
            #250
            num1 <= 16'b1111110110111010;
            num2 <= 16'b0100111001001111;
            //#250
            //$finish;
        end
    initial 
        begin  
            $dumpfile("output_waveform.vcd"); 
            $dumpvars(0, num1);
            $dumpvars(0, num2);
            $dumpvars(0, fixM);
            $dumpvars(0, overflow);
            $dumpvars(0, num1_int);
            $dumpvars(0, num1_flo);
            $dumpvars(0, num2_int);
            $dumpvars(0, num2_flo);
            $dumpvars(0, num1_sign);
            $dumpvars(0, num1_exp);
            $dumpvars(0, num1_frac);
            $dumpvars(0, num2_sign);
            $dumpvars(0, num2_exp);
            $dumpvars(0, num2_frac);
            $dumpvars(0, fixM_int);
            $dumpvars(0, fixM_flo);
        end
endmodule