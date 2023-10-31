
module NN_tb;

    // Parameters
    parameter NBITS = 16;
    parameter N_FEATURE_READ = 8;

    // Signals
    reg clk, rst;
    wire [9:0] featureInReadAddrFWGDUMB;
    wire [0:2]featureInReadEnFWGDUMB;
    reg [0:7][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFWGDUMB,next_featureInReadValueFWGDUMB;

    // Instantiate feature_module
    NN uut (
        .clk(clk),
        .rst(rst),
        .featureInReadAddrFWGDUMB(featureInReadAddrFWGDUMB),
        .featureInReadEnFWGDUMB(featureInReadEnFWGDUMB),
        .featureInReadValueFWGDUMB(featureInReadValueFWGDUMB)
    );

    // GDumb ram memory instantiation
    genvar j ;
    
    generate
    for( j=0; j< 3; j=j+1) begin
    SRAM # (.PORT_WIDTH(128),
        .MEMORY_WIDHT(32*32/8),
        .MEMORY_TYPE("GDUMB"),
        .CHANNEL_IN(j),
        .CHANNEL_OUT(0)
        )
    SRAMgdumb (.writeAddr(),
        .readAddr(featureInReadAddrFWGDUMB[9:3]),
        .writeEn(),
        .readEn(featureInReadEnFWGDUMB[j]),
        .readValue(featureInReadValueFWGDUMB[j]),
        .writeValue(),
        .clk(clk),
        .rst(rst));
    end
    endgenerate
    // Clock generation
    always #5 clk = ~clk;
   
    // Test stimulus
    initial begin

     featureInReadValueFWGDUMB[3] = 0;
     featureInReadValueFWGDUMB[4] = 0;
     featureInReadValueFWGDUMB[5] = 0;
     featureInReadValueFWGDUMB[6] = 0;
     featureInReadValueFWGDUMB[7] = 0;

        // Initialize signals
        clk = 0;
        rst = 0;

        // Apply reset
        rst = 1;
        #10;
        rst = 0;


        #245765;
        rst =1;
        #10;
        rst =0;
        //$finish;
    end
endmodule