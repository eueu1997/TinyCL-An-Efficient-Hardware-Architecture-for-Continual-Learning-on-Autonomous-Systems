module tb_kernelRegistersBWDX;

    // Parameters
    parameter NBITS = 16;
    parameter NCHANNELOUT = 8;
    parameter NKERNEL = 3;

    // Signals
    reg clk, rst, load;
    reg [1:0] stride;
    reg j, k;
    reg [0:(NKERNEL-1)][0:(NKERNEL-1)][(NCHANNELOUT*NBITS)-1:0] kernelIn;
    reg [0:(NKERNEL-1)][0:(NKERNEL-1)][(NCHANNELOUT*NBITS)-1:0] kernelOut;

    // Instantiate the kernelRegistersBWDX module
    kernelRegistersBWDX #(NBITS, NCHANNELOUT, NKERNEL) uut (
        .clk(clk),
        .rst(rst),
        .load(load),
        .stride(stride),
        .j(j),
        .k(k),
        .kernelIn(kernelIn),
        .kernelOut(kernelOut)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        load = 0;
        stride = 2'b01; // Example value, change as needed
        j = 0;
        k = 0;

        // Apply reset
        rst = 1;
        #10;
        rst = 0;

        // Load kernelIn with some values
        load = 1;
        kernelIn[0][0] = 128'h0123456789ABCDEF0123456789ABCDEF;
        kernelIn[0][1] = 128'hFEDCBA9876543210FEDCBA9876543210;
        kernelIn[0][2] = 128'h55555555555555555555555555555555;
        kernelIn[1][0] = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        kernelIn[1][1] = 128'hBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB;
        kernelIn[1][2] = 128'hCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC;
        kernelIn[2][0] = 128'hDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD;
        kernelIn[2][1] = 128'hEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE;
        kernelIn[2][2] = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        #10;
        load = 0;
        // Test various combinations of stride, j, k

        // Set stride = 1, j = 1, k = 1
        stride = 2'b01;
        j = 1;
        k = 1;
        #30;

        // Set stride = 2, j = 0, k = 0
        stride = 2'b10;
        j = 0;
        k = 0;
        #50;
        kernelIn[0][0] = 128'h55555555555555555555555555555555;
        // Set stride = 2, j = 0, k = 0
        stride = 2'b10;
        j = 1;
        k = 0;
        #50;
        kernelIn[1][1] = 128'hDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD;
        // Set stride = 2, j = 0, k = 0
        stride = 2'b10;
        j = 0;
        k = 1;
        #50;
        // Set stride = 2, j = 0, k = 0
        stride = 2'b10;
        j = 1;
        k = 1;
        #50;

        

        // Add more test cases as needed

    
    end

endmodule
