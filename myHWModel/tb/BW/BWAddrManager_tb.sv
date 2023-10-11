module tb_BWAddrManager;

    // Parameters
    parameter FEATURE_OUT_ROW_SIZE = 32;
    parameter FEATURE_OUT_COLUMN_SIZE = 32;
    parameter FEATURE_OUT_CH_SIZE = 32;
    parameter FEATURE_IN_CH_SIZE = 32;

    // Signals
    logic clk;
    logic rst;
    logic [$clog2(FEATURE_IN_CH_SIZE)-1:0] featureInActChSize;
    logic [$clog2(FEATURE_OUT_CH_SIZE)-1:0] featureOutActChSize;
    logic [$clog2(FEATURE_OUT_ROW_SIZE)-1:0] featureOutActRowSize;
    logic [$clog2(FEATURE_OUT_COLUMN_SIZE)-1:0] featureOutActColumnSize;
    logic [$clog2(FEATURE_OUT_ROW_SIZE)-1:0] featureOutRowAddr;
    logic [$clog2(FEATURE_OUT_COLUMN_SIZE)-1:0] featureOutColumAddr;
    logic [$clog2(FEATURE_OUT_CH_SIZE)-1:0] featureOutChAddr;
    logic [$clog2(FEATURE_IN_CH_SIZE)-1:0] featureInChAddr;

    // Instantiate the FWAddrManager module
    BWDKAddrManager #(FEATURE_OUT_ROW_SIZE, FEATURE_OUT_COLUMN_SIZE, FEATURE_OUT_CH_SIZE, FEATURE_IN_CH_SIZE) uut (
        .clk(clk),
        .rst(rst),
        .featureInActChSize(featureInActChSize),
        .featureOutActChSize(featureOutActChSize),
        .featureOutActRowSize(featureOutActRowSize),
        .featureOutActColumnSize(featureOutActColumnSize),
        .featureOutRowAddr(featureOutRowAddr),
        .featureOutColumAddr(featureOutColumAddr),
        .featureOutChAddr(featureOutChAddr),
        .featureInChAddr(featureInChAddr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst = 1;
        #2;
        rst = 0;
    end

    // Test stimulus
    initial begin
        // Initialize feature sizes
        featureInActChSize = 7; // Assuming 8 channels
        featureOutActChSize = 7; // Assuming 8 channels
        featureOutActRowSize = 31; // Assuming 32 rows
        featureOutActColumnSize = 31; // Assuming 32 columns
        #16390;
        featureInActChSize = 7; // Assuming 8 channels
        featureOutActChSize = 15; // Assuming 8 channels
        featureOutActRowSize = 15; // Assuming 32 rows
        featureOutActColumnSize = 15; // Assuming 32 columns
        #8192;
        featureInActChSize = 15; // Assuming 8 channels
        featureOutActChSize = 31; // Assuming 8 channels
        featureOutActRowSize = 7; // Assuming 32 rows
        featureOutActColumnSize = 7; // Assuming 32 columns
        #4096;

    end

endmodule
