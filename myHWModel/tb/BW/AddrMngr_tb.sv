module tb_BWDKAddrManager;

    // Define parameters
    parameter CHANNEL_OUT_DIM = 8;
    parameter CHANNEL_IN_DIM = 8;
    parameter FEATURE_OUT_DIM = 32;
    parameter FEATURE_IN_DIM = 32;
    parameter KERNEL_SIZE = 3;
    parameter STRIDE = 1;
    parameter N_FEATURE_READ = 8;

    // Define signals
    reg clk;
    reg rst;
    wire [$clog2(FEATURE_IN_DIM) + $clog2(FEATURE_IN_DIM) - 1: 0] convAddr;
    wire [$clog2(CHANNEL_OUT_DIM) + $clog2(CHANNEL_IN_DIM) + $clog2(KERNEL_SIZE) + $clog2(KERNEL_SIZE) - 1: 0] dkAddr;

    // Instantiate the BWDKAddrManager module
    BWDKAddrManager#(
        .CHANNEL_OUT_DIM(CHANNEL_OUT_DIM),
        .CHANNEL_IN_DIM(CHANNEL_IN_DIM),
        .FEATURE_OUT_DIM(FEATURE_OUT_DIM),
        .FEATURE_IN_DIM(FEATURE_IN_DIM),
        .KERNEL_SIZE(KERNEL_SIZE),
        .STRIDE(STRIDE),
        .N_FEATURE_READ(N_FEATURE_READ)
    ) uut (
        .clk(clk),
        .rst(rst),
        .convAddr(convAddr),
        .dkAddr(dkAddr)
    );
    always #5 clk = ~clk;

    // Clock Generation
    initial begin
       
        // Initialize signals
        clk = 0;
        rst = 0;

        // Apply reset
        rst = 1;
        #10 rst = 0;

        // Generate clock signal
    end


endmodule
