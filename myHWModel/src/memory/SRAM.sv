  module SRAM # (

    parameter PORT_WIDTH = 16,
    parameter MEMORY_WIDHT = 1024
)
(
    input [($clog2(MEMORY_WIDHT)-1):0]writeAddr,
    input [($clog2(MEMORY_WIDHT)-1):0]readAddr,
    input writeEn,
    input readEn,
    output reg [(PORT_WIDTH-1):0] readValue,
    input [(PORT_WIDTH-1):0] writeValue,
    input clk,
    input rst
);
reg [PORT_WIDTH-1:0] mem[(MEMORY_WIDHT -1):0];

    always @(posedge clk) begin
        if (rst == 1) begin 
            for (int i =0; i<MEMORY_WIDHT; i = i+1)begin
                mem[i] <= i<<12;
            end
        end else begin
            if(writeEn == 1) begin
                mem[writeAddr] <= writeValue;
            end 
            if (readEn == 1) begin 
                readValue = mem[readAddr];
            end
        end
    end

endmodule