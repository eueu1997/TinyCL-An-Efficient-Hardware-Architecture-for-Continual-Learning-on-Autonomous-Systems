module tb_MAC;

    // Define parameters
    parameter int NBit = 16;
    parameter int NBitOut = 20;
    parameter int NOperands = 8;

    // Define signals
    reg [0:(NOperands-1)][(NBit-1):0] tb_featureIn;
    reg [0:(NOperands-1)][(NBit-1):0] tb_Kernel;
    wire [(NBit-1):0] tb_featureOut;

    // Instantiate the MAC module
    MAC#(.NBit(NBit), .NBitOut(NBitOut), .NOperands(NOperands))
        uut (
            .featureIn(tb_featureIn),
            .partialSumIn(16'h0000),
            .Kernel(tb_Kernel),
            .featureOut(tb_featureOut)
        );

    // Initialize inputs
    initial begin
    
        tb_featureIn[0] = 'h0033;
        tb_featureIn[1] = 'h0001;
        tb_featureIn[2] = 'h0009;
        tb_featureIn[3] = 'h0031;
        tb_featureIn[4] = 'h0029;
        tb_featureIn[5] = 'hFFFB;
        tb_featureIn[6] = 'h002D;
        tb_featureIn[7] = 'h002B;
        tb_Kernel[0] = 'hFF89;
        tb_Kernel[1] = 'hFF46;
        tb_Kernel[2] = 'hFF81;
        tb_Kernel[3] = 'hFFEF;
        tb_Kernel[4] = 'hFF3E;
        tb_Kernel[5] = 'hFF20;
        tb_Kernel[6] = 'hFFBF;
        tb_Kernel[7] = 'h00F1;
        #10
        tb_featureIn[0] = 'h02A0;
        tb_featureIn[1] = 'h0280;
        tb_featureIn[2] = 'h0180;
        tb_featureIn[3] = 'h0180;
        tb_featureIn[4] = 'h0380;
        tb_featureIn[5] = 'hFE00;
        tb_featureIn[6] = 'h0110;
        tb_featureIn[7] = 'h0110;
        tb_Kernel[0] = 'h0230;
        tb_Kernel[1] = 'h0230;
        tb_Kernel[2] = 'h0230;
        tb_Kernel[3] = 'h02C0;
        tb_Kernel[4] = 'h02A0;
        tb_Kernel[5] = 'h0220;
        tb_Kernel[6] = 'h0220;
        tb_Kernel[7] = 'h0220;
  
    end

    // Monitor outputs

endmodule
