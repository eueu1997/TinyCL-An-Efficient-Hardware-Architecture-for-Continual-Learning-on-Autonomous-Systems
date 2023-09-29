module tb_BW_PU;

    // Define parameters
    parameter N_OF_MAC_ROWS = 3;
    parameter N_OF_MAC_CLMN = 3;
    parameter NBITS = 16;
    parameter N_FEATURE_READ = 8;
    parameter FEATURE_IN_DIM = 32;
    parameter FEATURE_OUT_DIM = 32;
    parameter CHANNEL_OUT_DIM = 8;
    parameter CHANNEL_IN_DIM = 8;
    parameter KERNEL_SIZE = 3;

    // Define signals
    reg [($clog2(CHANNEL_IN_DIM) + $clog2(FEATURE_IN_DIM) + $clog2(FEATURE_IN_DIM) -1):0] tb_featureInAddr;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] tb_featureIn;
    reg [($clog2(CHANNEL_OUT_DIM) + $clog2(FEATURE_OUT_DIM) + $clog2(FEATURE_OUT_DIM) -1):0] tb_dyAddr;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] tb_dy;
    reg [($clog2(CHANNEL_OUT_DIM) + $clog2(CHANNEL_IN_DIM) -1):0] tb_dkAddr;
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] tb_dk;
    reg clk;
    reg rst;
    reg valid;

    // Instantiate the BW_PU module
    BW_PU#(
        .N_OF_MAC_ROWS(N_OF_MAC_ROWS),
        .N_OF_MAC_CLMN(N_OF_MAC_CLMN),
        .NBITS(NBITS),
        .N_FEATURE_READ(N_FEATURE_READ),
        .FEATURE_IN_DIM(FEATURE_IN_DIM),
        .FEATURE_OUT_DIM(FEATURE_OUT_DIM),
        .CHANNEL_OUT_DIM(CHANNEL_OUT_DIM),
        .CHANNEL_IN_DIM(CHANNEL_IN_DIM),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) uut (
        .featureInAddr(tb_featureInAddr),
        .featureIn(tb_featureIn),
        .dyAddr(tb_dyAddr),
        .dy(tb_dy),
        .dkAddr(tb_dkAddr),
        .dk(tb_dk),
        .clk(clk),
        .rst(rst),
        .valid(valid)
    );

    // Clock Generation
    initial begin
        
        // Initialize signals
        clk = 0;
        rst = 1;

        // Apply reset
        #10 rst = 0;

    end

    always #5 clk = ~ clk;

    // Apply Stimulus
    initial begin
        // Set featureIn and dy inputs with random values
        foreach(tb_featureIn[i]) tb_featureIn[i] = $random;
        foreach(tb_dy[i]) tb_dy[i] = $random;

        // Apply stimulus and wait for some time
        // ...

        // Add more test cases as needed
        #100; // Simulation time

        // Finish simulation
        
    end

    

endmodule
