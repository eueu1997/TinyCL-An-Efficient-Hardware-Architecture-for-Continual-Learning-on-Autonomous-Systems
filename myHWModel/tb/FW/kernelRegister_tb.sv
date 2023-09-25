module tb_kernelRegisters;

  // Define the parameters
  parameter nBits = 16;
  parameter nChannelIn = 8;

  // Define the signals
  reg clk, rst, load;
  reg [0:2][0:2][(nChannelIn*nBits-1):0] kernelIn;
  reg [0:2][0:2][(nBits*nChannelIn-1):0] kernelOut;

  // Instantiate the DUT
  kernelRegisters #(nBits, nChannelIn) dut (
    .clk(clk),
    .rst(rst),
    .load(load),
    .kernelIn(kernelIn),
    .kernelOut(kernelOut)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test procedure
  initial begin
    // Initialize signals
    rst = 1;
    clk = 0;
    load = 0;

    // Apply reset
    #10 rst = 0;

    // Allow some time for the DUT to process after reset
    #10;

    // Set some example values for kernelIn
    kernelIn = '{
  '{128'h00000001000200030004000500060007, 128'h01000101010201030104010501060107, 128'h02000201020202030204020502060207},
  '{128'h10001001100210031004100510061007, 128'h00000000000000000000000000000005, 128'h12001201120212031204120512061207},
  '{128'h20002001200220032004200520062007, 128'h00000000000000000000000000000008, 128'h22002201220222032204220522062207}
    };
    // Toggle load signal to load kernelIn
    load = 1;
    #10 load = 0;

    // Allow some time for the DUT to process
    #10;

    // Check the kernelOut values (add your checks here)
    if (kernelOut !== kernelIn) $fatal("Test failed. kernelOut does not match kernelIn.");
    #10 kernelIn = '{
  '{128'h00000000000000000000000000000001, 128'h00000000000000000000000000000002, 128'h00000000000000000000000000000003},
  '{128'h00000000000000000000000000000004, 128'h00000000000000000000000000000005, 128'h00000000000000000000000000000006},
  '{128'h00000000000000000000000000000007, 128'h00000000000000000000000000000008, 128'h00000000000000000000000000000009}
};
    // End simulation
    
  end

endmodule
