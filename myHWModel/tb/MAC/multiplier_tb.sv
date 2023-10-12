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

parameter  TEST_CASE = 100 ;
module operatorCore_sim();

    reg [15:0] num1, num2;
    wire [15:0] fixM;
    wire [3:0] overflow;
    wire [7:0] num1_int, num1_flo, num2_int, num2_flo, fixM_int, fixM_flo;
    wire num1_sign, num2_sign;
    wire [4:0] num1_exp, num2_exp, floM_exp;
    wire [9:0] num1_frac, num2_frac;
    wire precisionLost;
    wire [31:0] result_full; //32-bit results

    fixed_multi uut1(num1, num2, fixM, overflow[1], precisionLost,result_full);
    

    assign {num1_int, num1_flo} = num1;
    assign {num2_int, num2_flo} = num2;
    assign {fixM_int, fixM_flo} = fixM;
    assign {num1_sign, num1_exp, num1_frac} = num1;
    assign {num2_sign, num2_exp, num2_frac} = num2;
    
    
    reg [(16-1):0]kernel[0:(TEST_CASE-1)];
    reg [(16-1):0]featureIn[0:(TEST_CASE-1)];
    reg [(16-1):0]result[0:(TEST_CASE-1)];
    initial //test cases here
        begin
        $readmemh("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/kernel.txt",kernel);
        $readmemh("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/featureIn1.txt", featureIn);
        for (int i =0; i <TEST_CASE ; i++)begin
            num1 = kernel[i];
            num2 = featureIn[i];
            result[i] = fixM;
            #5;
        end
        
        $writememh("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/result.txt",result);

        $finish;
        end

endmodule
