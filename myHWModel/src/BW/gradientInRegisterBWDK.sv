module  gradientInRegisterBWDK  #(
parameter N_CH_READ = 8,
parameter N_MAC_COLUMN = 3,
parameter N_MAC_ROW = 3,
parameter NBITS = 16
)(
input clk,rst,
input [(N_CH_READ*NBITS-1):0] dy,
output [0:(N_MAC_COLUMN-1)][(N_CH_READ*NBITS-1):0] dy_out
);
reg [0:(N_MAC_COLUMN-1)][(N_CH_READ*NBITS-1):0] dy_in_r,dy_out_r;

always @ ( *)begin
    if(rst == 1)begin
        dy_in_r[0] = dy;
        dy_in_r[1] = 0;
        dy_in_r[2] = 0;
    end else begin
        dy_in_r[0] = dy;
        dy_in_r[1] = dy_out_r[0];
        dy_in_r[2] = dy_out_r[1];
    end
end

always @ ( posedge clk)begin
    
    dy_out_r[0] = dy_in_r[0];
    dy_out_r[1] = dy_in_r[1];
    dy_out_r[2] = dy_in_r[2];

end
assign dy_out[0] = dy_out_r[0];
assign dy_out[1] = dy_out_r[1];
assign dy_out[2] = dy_out_r[2];

endmodule