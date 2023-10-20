module tb_featureRegisterBWDX;

    // Parameters
    parameter NBITS = 16;
    parameter NCHANNELOUT = 8;

    // Signals
    reg clk, rst;
    reg right, left;
    reg [1:0] stride;
    reg j;
    reg [(NBITS*NCHANNELOUT-1):0] gradientInP1, gradientInP2, gradientInP3;
    reg [0:2][0:2][(NBITS*NCHANNELOUT-1):0] gradientOut;

    // Instantiate the featureRegisterBWDX module
    featureRegisterBWDX #(NBITS, NCHANNELOUT) uut (
        .right(right),
        .left(left),
        .rst(rst),
        .clk(clk),
        .stride(stride),
        .j(j),
        .gradientInP1(gradientInP1),
        .gradientInP2(gradientInP2),
        .gradientInP3(gradientInP3),
        .gradientOut(gradientOut)
    );

    // Clock generation
    always #5 clk = ~clk;
    always #10 gradientInP1 = gradientInP1+1;
    always #10 gradientInP2 = gradientInP2+1;
    always #10 gradientInP3 = gradientInP3+1;

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        right = 1;
        left = 0;
        stride = 2'b10;
        j = 1;
        gradientInP1 = 16'h1234; // Example value, change as needed
        gradientInP2 = 16'h5678; // Example value, change as needed
        gradientInP3 = 16'h9ABC; // Example value, change as needed

        // Apply reset
        rst = 1;
        #10;
        rst = 0;
        #100;
        rst = 1;
        stride = 1;
        #10;
        rst = 0;
        // Generate some activity
        // Set inputs and let the module process them

   
    end

endmodule
