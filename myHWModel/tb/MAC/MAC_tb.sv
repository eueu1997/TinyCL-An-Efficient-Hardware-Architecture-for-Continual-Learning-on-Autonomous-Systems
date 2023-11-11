module tb_MAC;

    // Define parameters for the module
    parameter NBit = 16;
    parameter NOperands = 8;

    // Define time scale and resolution
    `timescale 1ns/1ps

    // Define signals for the testbench
    reg select;
    reg [0:(NOperands-1)][(NBit-1):0] featureIn;
    reg [(NOperands*NBit-1):0] partialSumIn;
    reg [0:(NOperands-1)][(NBit-1):0] Kernel;
    reg [(NBit-1):0] featureOut;
    reg [(NOperands*NBit-1):0] featureOutDk;

    // Instantiate the MAC# module
    MAC# (NBit,  NOperands) uut (
        .select(select),
        .featureIn(featureIn),
        .partialSumIn(partialSumIn),
        .Kernel(Kernel),
        .featureOut(featureOut),
        .featureOutDk(featureOutDk)
    );

    // Clock generation
    reg clk = 0;
    always #5 clk = ~clk;

    // Test vectors
    initial begin
        // Initialize signals
        select = 0;
        Kernel = '{16'h1800, 16'h1800, 16'h1000, 16'h1000, 16'h1000, 16'h1000, 16'h1000, 16'h1000};
        featureIn = '{16'h1800, 16'h2000, 16'h3000, 16'h4000, 16'h5000, 16'h6000, 16'h7000, 16'h8000};
        partialSumIn[(1*NBit-1):0*NBit]=16'h1000;
        partialSumIn[(2*NBit-1):1*NBit]=16'h1000;
        partialSumIn[(3*NBit-1):2*NBit]=16'h1000;
        partialSumIn[(4*NBit-1):3*NBit]=16'h1000;
        partialSumIn[(5*NBit-1):4*NBit]=16'h1000;
        partialSumIn[(6*NBit-1):5*NBit]=16'h1000;
        partialSumIn[(7*NBit-1):6*NBit]=16'h1000;
        partialSumIn[(8*NBit-1):7*NBit]=16'h1000;
        // Test with select = 0
        #10
        select = 1;
        Kernel = '{16'h1800, 16'h1800, 16'h1000, 16'h1000, 16'h1000, 16'h1000, 16'h1000, 16'h1000};
        featureIn = '{16'h1800, 16'h2000, 16'h3000, 16'h4000, 16'h5000, 16'h6000, 16'h7000, 16'h8000};
        partialSumIn[(1*NBit-1):0*NBit]=16'h1000;
        partialSumIn[(2*NBit-1):1*NBit]=16'h1000;
        partialSumIn[(3*NBit-1):2*NBit]=16'h1000;
        partialSumIn[(4*NBit-1):3*NBit]=16'h1000;
        partialSumIn[(5*NBit-1):4*NBit]=16'h1000;
        partialSumIn[(6*NBit-1):5*NBit]=16'h1000;
        partialSumIn[(7*NBit-1):6*NBit]=16'h1000;
        partialSumIn[(8*NBit-1):7*NBit]=16'h1000;
    end
endmodule

