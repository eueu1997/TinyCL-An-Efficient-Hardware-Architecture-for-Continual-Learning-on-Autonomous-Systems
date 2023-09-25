module tb_FWAddrManager;

  // Define the parameters
  parameter rowSize = 32;
  parameter columnSize = 32;
  parameter ChSize = 8;

  // Define the signals
  reg clk, rst;
  reg [($clog2(rowSize)-1):0] featureRow;
  reg [($clog2(columnSize)-1):0] featureColumn;
  reg [($clog2(ChSize)-1):0] featureCh;

  // Instantiate the DUT
  FWAddrManager #(rowSize, columnSize, ChSize) dut (
    .clk(clk),
    .rst(rst),
    .featureRow(featureRow),
    .featureColum(featureColumn),
    .featureCh(featureCh)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test procedure
  initial begin
    // Initialize signals
    rst = 1;
    clk = 0;
    
    // Apply reset
    #10 rst = 0;

    // Allow some time for the DUT to process after reset
    #10;

    // Add your test cases here

    // End simulation
      end

endmodule
