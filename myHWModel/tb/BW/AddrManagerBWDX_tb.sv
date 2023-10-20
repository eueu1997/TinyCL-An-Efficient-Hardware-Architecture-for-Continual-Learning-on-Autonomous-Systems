module tb_AddrManagerBWDX;

    // Parameters
    parameter FEATURE_OUT_ROW_SIZE = 32;
    parameter FEATURE_OUT_COLUMN_SIZE = 32;
    parameter FEATURE_OUT_CH_SIZE = 8;
    parameter FEATURE_IN_CH_SIZE = 8;

    // Signals
    reg clk, rst;
    reg [1:0] stride;
    reg [$clog2(FEATURE_IN_CH_SIZE)-1:0] gradientInActChSize;
    reg [$clog2(FEATURE_OUT_CH_SIZE)-1:0] gradientOutActChSize;
    reg [$clog2(FEATURE_OUT_ROW_SIZE)-1:0] gradientOutActRowSize;
    reg [$clog2(FEATURE_OUT_COLUMN_SIZE)-1:0] gradientOutActColumnSize;
    reg [$clog2(FEATURE_OUT_ROW_SIZE)-1:0] gradientOutRowAddr;
    reg [$clog2(FEATURE_OUT_COLUMN_SIZE)-1:0] gradientOutColumAddr;
    reg [$clog2(FEATURE_OUT_CH_SIZE)-1:0] gradientOutChAddr;
    reg [$clog2(FEATURE_IN_CH_SIZE)-1:0] gradientInChAddr;

    // Instantiate the AddrManagerBWDX module
    AddrManagerBWDX #(FEATURE_OUT_ROW_SIZE, FEATURE_OUT_COLUMN_SIZE, FEATURE_OUT_CH_SIZE, FEATURE_IN_CH_SIZE) uut (
        .clk(clk),
        .rst(rst),
        .stride(stride),
        .gradientInActChSize(gradientInActChSize),
        .gradientOutActChSize(gradientOutActChSize),
        .gradientOutActRowSize(gradientOutActRowSize),
        .gradientOutActColumnSize(gradientOutActColumnSize),
        .gradientOutRowAddr(gradientOutRowAddr),
        .gradientOutColumAddr(gradientOutColumAddr),
        .gradientOutChAddr(gradientOutChAddr),
        .gradientInChAddr(gradientInChAddr)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        stride = 2'b10; // Example value, change as needed
        gradientInActChSize = 3; // Example value, change as needed
        gradientOutActChSize = 5; // Example value, change as needed
        gradientOutActRowSize = 16; // Example value, change as needed
        gradientOutActColumnSize = 16; // Example value, change as needed

        // Apply reset
        rst = 1;
        #10;
        rst = 0;

        // Generate some activity
        // Set inputs and let the module process them

        // Finish simulation
    end

endmodule
