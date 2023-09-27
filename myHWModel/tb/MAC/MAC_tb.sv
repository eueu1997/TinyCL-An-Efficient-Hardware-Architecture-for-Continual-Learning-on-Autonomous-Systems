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
            .Kernel(tb_Kernel),
            .featureOut(tb_featureOut)
        );

    // Initialize inputs
    initial begin
        tb_featureIn[0] = 'h0180;
        tb_featureIn[1] = 'h0280;
        tb_featureIn[2] = 'h0380;
        tb_featureIn[3] = 'h0380;
        tb_featureIn[4] = 'h0080;
        tb_featureIn[5] = 'h0180;
        tb_featureIn[6] = 'h0080;
        tb_featureIn[7] = 'h0180;
        tb_Kernel[0] = 'h0200;
        tb_Kernel[1] = 'h0200;
        tb_Kernel[2] = 'h0200;
        tb_Kernel[3] = 'h0300;
        tb_Kernel[4] = 'h0c00;
        tb_Kernel[5] = 'h0800;
        tb_Kernel[6] = 'h0100;
        tb_Kernel[7] = 'h0100;

	    $display("Inputs : \n feature: %h ,%h ,%h ,%h ,%h ,%h ,%h ,%h \n kernels : %h ,%h ,%h ,%h ,%h ,%h ,%h ,%h ",tb_featureIn[0],tb_featureIn[1],tb_featureIn[2],tb_featureIn[3],tb_featureIn[4],tb_featureIn[5],tb_featureIn[6],tb_featureIn[7],tb_Kernel[0],tb_Kernel[1],tb_Kernel[2],tb_Kernel[3],tb_Kernel[4],tb_Kernel[5],tb_Kernel[6],tb_Kernel[7]);
        $display("Result: %0d", tb_featureOut);  
    end

    // Monitor outputs

endmodule
