module NN_tb;

    // Parameters
    parameter NBITS = 16;
    parameter N_FEATURE_READ = 8;

    // Signals
    reg clk, rst;
    wire [0:9] featureInReadAddrFWGDUMB;
    wire featureInReadEnFWGDUMB;
    reg [0:7][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFWGDUMB;

    // Instantiate feature_module
    NN uut (
        .clk(clk),
        .rst(rst),
        .featureInReadAddrFWGDUMB(featureInReadAddrFWGDUMB),
        .featureInReadEnFWGDUMB(featureInReadEnFWGDUMB),
        .featureInReadValueFWGDUMB(featureInReadValueFWGDUMB)
    );
    // Clock generation
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;

        // Apply reset
        rst = 1;
        #10;
        rst = 0;

        // Generate some activity
        featureInReadValueFWGDUMB[0] = 'h10001000100010001000100010001000 ; // Set feature address
        featureInReadValueFWGDUMB[1] = 'h10001000100010001000100010001000; // Set feature address
        featureInReadValueFWGDUMB[2] = 'h10001000100010001000100010001000; // Set feature address
        featureInReadValueFWGDUMB[3] = 'h10001000100010001000100010001000; // Set feature address
        featureInReadValueFWGDUMB[4] = 'h10001000100010001000100010001000; // Set feature address
        featureInReadValueFWGDUMB[5] = 'h10001000100010001000100010001000; // Set feature address
        featureInReadValueFWGDUMB[6] = 'h10001000100010001000100010001000; // Set feature address
        featureInReadValueFWGDUMB[7] = 'h10001000100010001000100010001000; // Set feature address

        #10;

        
    end
endmodule