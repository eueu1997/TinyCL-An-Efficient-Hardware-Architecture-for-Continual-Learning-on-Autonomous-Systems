module tb_gradientInRegisterBWDK;
    // Define parameters for the module
    parameter N_CH_READ = 8;
    parameter N_MAC_COLUMN = 3;
    parameter N_MAC_ROW = 3;
    parameter NBITS = 16;
    
    // Define time scale and resolution
    `timescale 1ns/1ps

    // Define signals for the testbench
    reg clk, rst;
    reg [(N_CH_READ*NBITS-1):0] dy;
    wire [0:(N_MAC_COLUMN-1)][(N_CH_READ*NBITS-1):0] dy_out;

    // Instantiate the module under test
    gradientInRegisterBWDK #(N_CH_READ, N_MAC_COLUMN, N_MAC_ROW, NBITS) uut (
        .clk(clk),
        .rst(rst),
        .dy(dy),
        .dy_out(dy_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test vectors
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        dy = 32'h12345678123456781234567812345678; // Example input value

        // Apply reset
        #10 rst = 0;

        // Apply input and simulate for some time
        #10 dy = 32'h87654321876543218765432187654321; // Example input value
        #10 dy = 32'hABCDEF00ABCDEF00ABCDEF00ABCDEF00; // Example input value
        #10 dy = 32'h12345678123456781234567812345678; // Example input value
   
    end
endmodule
