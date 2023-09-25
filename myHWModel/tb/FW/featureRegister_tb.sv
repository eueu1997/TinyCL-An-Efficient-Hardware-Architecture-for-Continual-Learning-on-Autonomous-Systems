module tb_featureRegister;

  // Define the parameters
  parameter int nBits = 16;
  parameter int nChannelIn = 1;

  // Define the signals
  reg right, left, rst, clk;
  reg [0:2][(nBits*nChannelIn-1):0] featureIn;
  wire [0:2][0:2][(nBits*nChannelIn-1):0] featureOut;

  // Instantiate the DUT
  featureRegister #(nBits, nChannelIn) dut (
    .right(right),
    .left(left),
    .rst(rst),
    .clk(clk),
    .featureIn(featureIn),
    .featureOut(featureOut)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test procedure
  initial begin
    // Initialize signals
    right = 0;
    left = 0;
    rst = 1;
    clk = 0;
    featureIn = '{default:0};

    // Reset the DUT
    #10 rst = 0;

    // Test with right = 0, left = 0
    #10 right = 1; left = 0;
    featureIn[0] = 'h0000;
    featureIn[1] = 'h0001;
    featureIn[2] = 'h0002; // Example input data
    #10;
    assert(featureOut[0][0] == 'h0000) else $display("Test 1 failed");
    assert(featureOut[0][1] == 'h0000) else $display("Test 2 failed");
    assert(featureOut[0][2] == 'h0000) else $display("Test 3 failed");
    assert(featureOut[1][0] == 'h0000) else $display("Test 4 failed");
    assert(featureOut[1][1] == 'h0000) else $display("Test 5 failed");
    assert(featureOut[1][2] == 'h0001) else $display("Test 6 failed");
    assert(featureOut[2][0] == 'h0000) else $display("Test 7 failed");
    assert(featureOut[2][1] == 'h0000) else $display("Test 8 failed");
    assert(featureOut[2][2] == 'h0002) else $display("Test 9 failed");
    featureIn[0] = 'h0003;
    featureIn[1] = 'h0004;
    featureIn[2] = 'h0005; // Example input data
    #10;
    assert(featureOut[0][0] == 'h0000) else $display("Test 10 failed");
    assert(featureOut[0][1] == 'h0000) else $display("Test 11 failed");
    assert(featureOut[0][2] == 'h0003) else $display("Test 12 failed");
    assert(featureOut[1][0] == 'h0000) else $display("Test 13 failed");
    assert(featureOut[1][1] == 'h0001) else $display("Test 14 failed");
    assert(featureOut[1][2] == 'h0004) else $display("Test 15 failed");
    assert(featureOut[2][0] == 'h0000) else $display("Test 16 failed");
    assert(featureOut[2][1] == 'h0002) else $display("Test 17 failed");
    assert(featureOut[2][2] == 'h0005) else $display("Test 18 failed");
    featureIn[0] = 'h0006;
    featureIn[1] = 'h0007;
    featureIn[2] = 'h0008; // Example input data
    #10
    assert(featureOut[0][0] == 'h0000) else $display("Test 19 failed");
    assert(featureOut[0][1] == 'h0003) else $display("Test 20 failed");
    assert(featureOut[0][2] == 'h0006) else $display("Test 21 failed");
    assert(featureOut[1][0] == 'h0001) else $display("Test 22 failed");
    assert(featureOut[1][1] == 'h0004) else $display("Test 23 failed");
    assert(featureOut[1][2] == 'h0007) else $display("Test 24 failed");
    assert(featureOut[2][0] == 'h0002) else $display("Test 25 failed");
    assert(featureOut[2][1] == 'h0005) else $display("Test 26 failed");
    assert(featureOut[2][2] == 'h0008) else $display("Test 27 failed");
    right = 0; left = 0;
    featureIn[0] = 'h0009;
    featureIn[1] = 'h000A;
    featureIn[2] = 'h000B; // Example input data
    #10 
    assert(featureOut[0][0] == 'h0001) else $display("Test 28 failed");
    assert(featureOut[0][1] == 'h0004) else $display("Test 29 failed");
    assert(featureOut[0][2] == 'h0007) else $display("Test 30 failed");
    assert(featureOut[1][0] == 'h0000) else $display("Test 31 failed");
    assert(featureOut[1][1] == 'h0003) else $display("Test 32 failed");
    assert(featureOut[1][2] == 'h0006) else $display("Test 33 failed");
    assert(featureOut[2][0] == 'h0009) else $display("Test 34 failed");
    assert(featureOut[2][1] == 'h000A) else $display("Test 35 failed");
    assert(featureOut[2][2] == 'h000B) else $display("Test 36 failed");
    // Add checks for featureOut here if needed


  end

endmodule
