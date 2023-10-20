module tb_SRAM;

    // Parameters
    parameter PORT_WIDTH = 16;
    parameter MEMORY_WIDTH = 16;

    // Signals
    reg [$clog2(MEMORY_WIDTH)-1:0] writeAddr;
    reg [$clog2(MEMORY_WIDTH)-1:0] readAddr;
    reg writeEn;
    reg readEn;
    reg [(PORT_WIDTH-1):0] writeValue;
    wire [(PORT_WIDTH-1):0] readValue;
    reg clk;
    reg rst;

    // Instantiate the SRAM module
    SRAM #(PORT_WIDTH, MEMORY_WIDTH) uut (
        .writeAddr(writeAddr),
        .readAddr(readAddr),
        .writeEn(writeEn),
        .readEn(readEn),
        .readValue(readValue),
        .writeValue(writeValue),
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        writeAddr = 0;
        readAddr = 0;
        writeEn = 0;
        writeValue = 0;

        // Reset
        rst = 1;
        #10;
        rst = 0;

        // Write data to address 0
        readEn = 1;
        for ( int i = 0; i < MEMORY_WIDTH; i=i+1)begin
            readAddr = i;
            #10;
        end
        writeEn = 1;
        readEn = 0;
        writeAddr = 1;
        writeValue = 16'hDEF0;
        #10;
        writeAddr = 2;
        writeValue = 16'h1234;
        #10;
        writeAddr = 3;
        writeValue = 16'h5678;
        #10;
        writeEn = 0;
        readEn  =1;
        writeValue = 16'h0000;
        readAddr = 0;
        #10;
        readAddr = 1;
        #10;
        readAddr = 2;
        #10;
        readAddr = 3;
        #10;
        rst = 1;
        #10;
        rst = 0;
        readAddr = 0;
        #10;
        readAddr = 1;
        #10;
        readAddr = 2;
        #10;
        readAddr = 3;
        #10;


     
    end

endmodule
