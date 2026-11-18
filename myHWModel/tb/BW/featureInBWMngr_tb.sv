module tb_featureInBWMngr;

    // Define parameters
    parameter int FEATURE_OUT_ROW_SIZE = 32;
    parameter int FEATURE_OUT_COLUMN_SIZE = 32;
    parameter int NBITS = 16;
    parameter int KERNEL_SIZE = 3;
    parameter int NFEATURE_READ = 8;

    // Define signals
    reg [0:(NFEATURE_READ-1)][(NBITS-1):0] tb_featureIn;
    reg [($clog2(FEATURE_OUT_ROW_SIZE)-1):0] featureOutRowAddr;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] featureOutColumnAddr;
    wire [0:(KERNEL_SIZE - 1)][0:(KERNEL_SIZE - 1)][0:(NFEATURE_READ-1)][(NBITS-1):0] featuresInMngd;

    // Instantiate the module
    featureInBWMngr #( FEATURE_OUT_ROW_SIZE , FEATURE_OUT_COLUMN_SIZE, NBITS, KERNEL_SIZE, NFEATURE_READ) uut (
        .featureIn(tb_featureIn),
        .featuresInMngd(featuresInMngd),
        .featureOutRowAddr(featureOutRowAddr),
        .featureOutColumAddr(featureOutColumnAddr)
         );

    // Clock Generation
    initial begin
       
        // Initialize signals
        tb_featureIn[0] = 0;
        tb_featureIn[1] = 1;
        tb_featureIn[2] = 2;
        tb_featureIn[3] = 3;
        tb_featureIn[4] = 4;
        tb_featureIn[5] = 5;
        tb_featureIn[6] = 6;
        tb_featureIn[7] = 7;        
        featureOutRowAddr = 0;
        featureOutColumnAddr = 0;
        
        #10; // Wait for 100 ns
        featureOutColumnAddr =  8;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  16;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  24;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutRowAddr =  1;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  16;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  8;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  0;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutRowAddr =  2;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  8;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  16;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        featureOutColumnAddr =  24;
        tb_featureIn[0] = tb_featureIn[0] + 8;
        tb_featureIn[1] = tb_featureIn[1] + 8;
        tb_featureIn[2] = tb_featureIn[2] + 8;
        tb_featureIn[3] = tb_featureIn[3] + 8;
        tb_featureIn[4] = tb_featureIn[4] + 8;
        tb_featureIn[5] = tb_featureIn[5] + 8;
        tb_featureIn[6] = tb_featureIn[6] + 8;
        tb_featureIn[7] = tb_featureIn[7] + 8;
        #10; // Wait for 100 ns
        

    end


endmodule
