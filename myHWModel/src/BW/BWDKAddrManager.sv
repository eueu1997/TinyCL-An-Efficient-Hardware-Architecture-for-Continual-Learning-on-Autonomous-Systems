module BWDKAddrManager #
(
    parameter CHANNEL_OUT_DIM = 8,
    parameter CHANNEL_IN_DIM = 8,
    parameter FEATURE_OUT_DIM = 32,
    parameter FEATURE_IN_DIM = 32,
    parameter KERNEL_SIZE = 3,
    parameter STRIDE = 1,
    parameter N_FEATURE_READ = 8
)
(
    input  logic clk,
    input  logic rst,
    output  reg [($clog2(FEATURE_IN_DIM) + $clog2(FEATURE_IN_DIM) -1):0] convAddr,
    output  reg [($clog2(CHANNEL_OUT_DIM) + $clog2(CHANNEL_IN_DIM) -1):0] dkAddr
);
// Number of feature read each step

reg [($clog2(FEATURE_IN_DIM) + $clog2(FEATURE_IN_DIM) -1):0] convAddr_r,newConvAddr_r;
reg [($clog2(CHANNEL_OUT_DIM) + $clog2(CHANNEL_IN_DIM)  -1):0] dkAddr_r,newDkAddr_r;

// 2d iteration over convolution 
always @ (*) begin
    if(rst == 1) begin
        newConvAddr_r = '{default:0};
        newDkAddr_r = '{default:0};
    end else begin
        if ( convAddr_r == ( (FEATURE_OUT_DIM*FEATURE_OUT_DIM) - (N_FEATURE_READ)) )begin
            newDkAddr_r = dkAddr_r + 1;
        end else begin 
            newDkAddr_r = dkAddr_r ;
        end
        newConvAddr_r = convAddr_r + (N_FEATURE_READ*STRIDE) ;
    end
end


always @ ( posedge clk) begin
    dkAddr_r = newDkAddr_r;
    convAddr_r = newConvAddr_r;
end

assign convAddr = convAddr_r;
assign dkAddr = dkAddr_r;

endmodule