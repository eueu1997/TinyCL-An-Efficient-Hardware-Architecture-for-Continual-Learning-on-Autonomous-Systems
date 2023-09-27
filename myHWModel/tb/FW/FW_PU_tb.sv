module tb_FW_PU;

    // Define parameters
    parameter MAC_SIZE = 3;
    parameter N_OF_MAC_ROWS = 3;
    parameter N_OF_MAC_CLMN = 3;
    parameter CHANNEL_IN_SIZE = 8;
    parameter NBITS = 16;
    parameter FEATURE_IN_ROW_SIZE = 32;
    parameter FEATURE_IN_COLUMN_SIZE = 32;
    parameter FEATURE_IN_CH_SIZE = 8;

    // Define signals
    reg clk;
    reg rst;
    reg [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*CHANNEL_IN_SIZE-1):0] tb_kernelVals;
    reg loadKernel;
    reg [(NBITS*CHANNEL_IN_SIZE-1):0] tb_featureInP1;
    reg [(NBITS*CHANNEL_IN_SIZE-1):0] tb_featureInP2;
    reg [(NBITS*CHANNEL_IN_SIZE-1):0] tb_featureInP3;
    wire [($clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] tb_featureInP1Addr;
    wire [($clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] tb_featureInP2Addr;
    wire [($clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] tb_featureInP3Addr;
    wire [($clog2(FEATURE_IN_ROW_SIZE)-1):0] tb_featureOutRowAddr;
    wire [($clog2(FEATURE_IN_COLUMN_SIZE)-1):0] tb_featureOutColumAddr;
    wire [($clog2(FEATURE_IN_CH_SIZE)-1):0] tb_featureOutChAddr;
    wire [(NBITS-1):0] tb_featureOutVal;

    // Instantiate the FW_PU module
    FW_PU#(
        .MAC_SIZE(MAC_SIZE),
        .N_OF_MAC_ROWS(N_OF_MAC_ROWS),
        .N_OF_MAC_CLMN(N_OF_MAC_CLMN),
        .CHANNEL_IN_SIZE(CHANNEL_IN_SIZE),
        .NBITS(NBITS),
        .FEATURE_IN_ROW_SIZE(FEATURE_IN_ROW_SIZE),
        .FEATURE_IN_COLUMN_SIZE(FEATURE_IN_COLUMN_SIZE),
        .FEATURE_IN_CH_SIZE(FEATURE_IN_CH_SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .kernelVals(tb_kernelVals),
        .loadKernel(loadKernel),
        .featureInP1Addr(tb_featureInP1Addr),
        .featureInP2Addr(tb_featureInP2Addr),
        .featureInP3Addr(tb_featureInP3Addr),
        .featureInP1(tb_featureInP1),
        .featureInP2(tb_featureInP2),
        .featureInP3(tb_featureInP3),
        .featureOutRowAddr(tb_featureOutRowAddr),
        .featureOutColumAddr(tb_featureOutColumAddr),
        .featureOutChAddr(tb_featureOutChAddr),
        .featureOutVal(tb_featureOutVal)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset Generation
    initial begin
        rst = 1;
        #10 rst = 0;
    end

    // Test Stimulus
    initial begin
        // Generate random values for kernelVals, featureInP1, featureInP2, featureInP3
        // ...
        #10 ;
        tb_kernelVals[0] = 'h01000100010001000100010001000100;
        tb_kernelVals[1] = 'h01000100010001000100010001000100;
        tb_kernelVals[2] = 'h01000100010001000100010001000100;
        tb_kernelVals[3] = 'h01000100010001000100010001000100;
        tb_kernelVals[4] = 'h01000100010001000100010001000100;
        tb_kernelVals[5] = 'h01000100010001000100010001000100;
        tb_kernelVals[6] = 'h01000100010001000100010001000100;
        tb_kernelVals[7] = 'h01000100010001000100010001000100; 
        tb_kernelVals[8] = 'h01000100010001000100010001000100;        
       
        loadKernel = 1;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10 loadKernel = 0;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
        tb_featureInP1 = 'h01000100010001000100010001000100;
        tb_featureInP2 = 'h01000100010001000100010001000100;
        tb_featureInP3 = 'h01000100010001000100010001000100;
        #10;
    end

endmodule
