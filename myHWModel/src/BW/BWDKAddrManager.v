module BWDKAddrManager
(
   
    parameter integer channelOutDim;
    parameter integer channelInDim;
    parameter integer featureOutDim;
    parameter integer featureInDim;
    parameter integer stride;
)
(
    input logic clk;
    input logic rst;
    output logic [int(log2(channelInDim)):0][int(log2(featureInDim)):0][int(log2(featureInDim)):0] featureInAddr;
    output logic [int(log2(channelOutDim)):0][int(log2(featureOutDim)):0][int(log2(featureOutDim)):0] dyAddr;
)
// Number of feature read each step
parameter int N_FEATURE_READ = 8;

reg logic [int(log2(featureInDim)):0][int(log2(featureInDim)):0] featureInAddr_r,newFeatureInAddr_r;
reg logic [int(log2(channelInDim)):0] featureInChAddr_r,newFeatureInChAddr_r
reg logic [int(log2(featureOutDim)):0][int(log2(featureOutDim)):0] dyAddr_r,newDyAddr_r;
reg logic [int(log2(channelOutDim)):0] dyChAddr_r,newDyChAddr_r;

// 2d iteration over dy and feature in
always @ () begin
    if(rst = '1') begin
        newFeatureInAddr_r = {default:0};
        newDyAddr_r = {default:0};
    end else begin
        newFeatureInAddr_r = featureInAddr_r + (N_FEATURE_READ*stride)[int(log2(featureInDim)):0][int(log2(featureInDim)):0] ;
        newDyAddr_r = dyAddr_r + N_FEATURE_READ[int(log2(featureOutDim)):0][int(log2(featureOutDim)):0] ;
    end

end
// Iteration over channel of feature in
always @ ()begin
    if(rst = '1')begin
        newFeatureInChAddr_r = {default:0}
    end else begin
        // If one channel of the feature has been readed, then move to next 8 channels
        if ( featureInAddr_r = [(int(log2(featureInDim)) + int(log2(featureInDim))) : 0](2**((int(log2(featureInDim)) + int(log2(featureInDim))) )))begin
            newFeatureInChAddr_r = featureInChAddr_r + 8;
        end else begin 
            newFeatureInChAddr_r = featureInChAddr_r ;
        end

    end
end
// Iteration over channel of dy
always @ ()begin
    if(rst = '1')begin
        newDyChAddr_r = {default:0}
    end else begin
        // If all the channel of the feature in has been read, then move to next channel of dy
        if ( featureInChAddr_r = [(int(log2(channelInDim))) : 0](2**(int(log2(channelInDim)) )))begin
            newFeatureInChAddr_r = featureInChAddr_r +1;
        end else begin 
            newFeatureInChAddr_r = featureInChAddr_r ;

        end
    end
end
always @ ( posedge clk) begin
    featureInAddr_r = newFeatureInAddr_r;
    dyAddr_r = newDyAddr_r;
    dyChAddr_r =  newDyChAddr_r;
    featureInChAddr_r = newFeatureInChAddr_r;
end

assign [int(log2(channelInDim)):0] featureInAddr  = featureInChAddr_r;
assign [int(log2(featureInDim)):0][int(log2(featureInDim)):0] featureInAddr = featureInAddr_r;
assign [int(log2(channelOutDim)):0] dyAddr = dyAddr_r;
assign [int(log2(featureOutDim)):0][int(log2(featureOutDim)):0] dyAddr = dyChAddr_r;

endmodule