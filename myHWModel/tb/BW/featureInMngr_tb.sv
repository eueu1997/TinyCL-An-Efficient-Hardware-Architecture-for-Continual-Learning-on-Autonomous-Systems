module tb_featureInMngr;

    // Define parameters
    parameter int FEATURE_IN_DIM = 32;
    parameter int NBITS = 16;
    parameter int KERNEL_SIZE = 3;
    parameter int NFEATURE_READ = 8;

    // Define signals
    reg [(2*$clog2(FEATURE_IN_DIM)-1):0] tb_featureInAddr;
    reg [0:(NFEATURE_READ-1)][(NBITS-1):0] tb_featureIn;
    wire [0:(KERNEL_SIZE - 1)][0:(KERNEL_SIZE - 1)][(NBITS*NFEATURE_READ-1):0] tb_featuresInMngd;

    // Instantiate the featureInMngr module
    featureInMngr#(
        .FEATURE_IN_DIM(FEATURE_IN_DIM),
        .NBITS(NBITS),
        .KERNEL_SIZE(KERNEL_SIZE),
        .NFEATURE_READ(NFEATURE_READ)
    ) uut (
        .featureInAddr(tb_featureInAddr),
        .featureIn(tb_featureIn),
        .featuresInMngd(tb_featuresInMngd)
    );

    // Clock Generation
    initial begin
        $dumpfile("tb_featureInMngr.vcd"); // Dump VCD file for simulation
        $dumpvars(0, tb_featureInMngr); // Dump all variables

        // Initialize signals
        tb_featureIn[0] = 0;
        tb_featureIn[1] = 1;
        tb_featureIn[2] = 2;
        tb_featureIn[3] = 3;
        tb_featureIn[4] = 4;
        tb_featureIn[5] = 5;
        tb_featureIn[6] = 6;
        tb_featureIn[7] = 7;        
        tb_featureInAddr = 0;

        repeat ((FEATURE_IN_DIM*FEATURE_IN_DIM)/NFEATURE_READ) begin
            #10; // Wait for 100 ns
            tb_featureInAddr = tb_featureInAddr + 8;
            tb_featureIn[0] = tb_featureIn[0] + 8;
            tb_featureIn[1] = tb_featureIn[1] + 8;
            tb_featureIn[2] = tb_featureIn[2] + 8;
            tb_featureIn[3] = tb_featureIn[3] + 8;
            tb_featureIn[4] = tb_featureIn[4] + 8;
            tb_featureIn[5] = tb_featureIn[5] + 8;
            tb_featureIn[6] = tb_featureIn[6] + 8;
            tb_featureIn[7] = tb_featureIn[7] + 8;
        end

    end


endmodule
