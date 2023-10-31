
parameter N_FEATURE_READ = 8;
parameter NBITS = 16;

input clk,rst;
input [(N_FEATURE_READ*NBITS-1):0] dy
output [(N_FEATURE_READ*NBITS-1):0] dy_out
input [1:0] j; // column index

reg [0:1][(NBITS-1):0] dy_r,next_dy_r

always @ ( *)begin

    if(rst == 1)begin
        next_dy_r[0] = 0;
        next_dy_r[1] = 0;
    end else begin
        if(j==0)begin
            dy_out <= dy;
            next_dy_r[0] = 0;
            next_dy_r[1] = 0;
        end else if(j==1)begin
            dy_out = dy >> (NBITS)
            next_dy_r[0] = dy[(N_FEATURE_READ*NBITS-1):((N_FEATURE_READ-1)*NBITS)];
            next_dy_r[1] = 0;
        end else if(j==2)begin
            dy_out = dy >> (2*NBITS)
            next_dy_r[0] = dy[((N_FEATURE_READ-1)*NBITS-1):((N_FEATURE_READ-2)*NBITS)];
            next_dy_r[1] = dy[(N_FEATURE_READ*NBITS-1):((N_FEATURE_READ-1)*NBITS)];
        end else begin
            dy_out <= dy;
            next_dy_r[0] = 0;
            next_dy_r[1] = 0;
        end 
    end
end

always @ ( posedge clk)begin
    dy_r[0] <= next_dy_r[0];
    dy_r[1] <= next_dy_r[1];

end