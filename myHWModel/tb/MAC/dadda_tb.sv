module tb_dadda_top;
    // Define parameters
    parameter int NBitIn = 16;
    parameter int NBitOut = 20;
    parameter int NOps = 8;
    
    // Define time units and precision
    `timescale 1ns/1ps
    
    
    
    
    // Define signals
    logic [1:NOps][NBitIn:1] DataIn;
    logic [NBitOut:1] DataOut;

// Instantiate the dadda_top module
    dadda_top#(
        .NBitIn(NBitIn),
        .NBitOut(NBitOut),
        .NOps(NOps)
    ) u_dadda_top (
        .DataIn(DataIn),
        .DataOut(DataOut)
    );
    // Initialize variables
    initial begin
        DataIn[1] = 'b1111111111111101; //-3
        DataIn[2] = 'b0000000000000011; // +3
        DataIn[3] = 'b1111111111100101; //-27
        DataIn[4] = 'b0000000000011011; // +27
        DataIn[5] = 'b0000000000110111; // 55
        DataIn[6] = 'b1111111111001001; //- 55
        DataIn[7] = 'b0000000000000000;
        DataIn[8] = 'b0000000000000000;

        
        #10
        DataIn[1] = 'b0000000000000000;
        DataIn[2] = 'b1111111111111111;
        DataIn[3] = 'b0000000000000000;
        DataIn[4] = 'b0000000000000000;
        DataIn[5] = 'b1111111111111111;
        DataIn[6] = 'b0000000000000000;
        DataIn[7] = 'b0000000000000000;
        DataIn[8] = 'b1111111111111111;
        
        
       
    end
endmodule
