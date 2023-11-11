module test #(parameter WIDTH = 16) (input [WIDTH-1:0] data_in, input clk,input rst, output reg [WIDTH-1:0] data_out);

    // Define internal register storage
    reg [WIDTH-1:0] reg_data;

    // Assign data_out to reg_data
    always @(*) begin
        if(rst == 1)begin
            reg_data = '{default:0};
        end else  begin 
            reg_data = data_in;
        end
    end

    // Update register on rising edge of wr_en
    always @(posedge clk) begin
        data_out = reg_data;
    end

endmodule
