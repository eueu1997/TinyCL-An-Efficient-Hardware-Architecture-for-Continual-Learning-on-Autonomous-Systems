module BWDKAddrManager #
(
    parameter FEATURE_OUT_ROW_SIZE = 32,
    parameter FEATURE_OUT_COLUMN_SIZE = 32,
    parameter FEATURE_OUT_CH_SIZE = 8,
    parameter FEATURE_IN_CH_SIZE = 8
)
(
    //kernel inp
    input logic clk,
    input logic rst,
    //Actual feature size
    input [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInActChSize,
    input [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutActChSize,
    input [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutActRowSize,
    input [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutActColumnSize, 
    // address generated
    output reg [($clog2(FEATURE_OUT_ROW_SIZE)-1):0]featureOutRowAddr,
    output reg [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0]featureOutColumAddr,
    output reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0]featureOutChAddr,NewFeatureOutChAddr,
    output reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddr,NewFeatureInChAddr
);
reg [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] featureOutColum,NewFeatureOutColum;
reg [($clog2(FEATURE_OUT_ROW_SIZE)-1):0] featureOutRow,NewFeatureOutRow;
reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInCh,NewFeatureInCh;
reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutCh,NewFeatureOutCh;

//Column iterator
always @ (*) begin 
    if ( rst == 1)begin
        NewFeatureOutColum = '{default:0};
    end else begin
	    if(featureOutColum == featureOutActColumnSize )begin // if reach end of column
		    NewFeatureOutColum = 0 ;
	    end else begin // otherwise
            NewFeatureOutColum = featureOutColum + 1 ;
	    end
    end
end

// Row iterator
always @ (*) begin 
    if ( rst == 1)begin
        NewFeatureOutRow = 0;
    end else begin
        if ((featureOutRow == featureOutActRowSize)&(featureOutColum == featureOutActColumnSize)) begin // if the whole feature has been iterated
            NewFeatureOutRow = 0;
        end else begin 
            if((featureOutColum == featureOutActColumnSize))begin
                NewFeatureOutRow = featureOutRow + 1;
            end else begin
                NewFeatureOutRow = featureOutRow;
            end
        end
    end
end

//channel in iterator 
always @ (*) begin 
    if (rst == 1) begin
        NewFeatureInCh = 0;
    end else begin
        if ((featureOutColum  == featureOutActColumnSize)&&(featureOutRow == featureOutActRowSize))begin// If we are at the end of the feature
            if((featureInCh+7) == featureInActChSize)begin // if we have passed all channel in 
                NewFeatureInCh = 0;
            end else begin// otherwise increment
                NewFeatureInCh= featureInCh + 8; 
            end
        end else begin // otherwise
            NewFeatureInCh = featureInCh;
        end
    end
end
//channel out iterator 
always @ (*) begin 
    if (rst == 1) begin
        NewFeatureOutCh = 0;
    end else begin
        if ((featureOutColum  == featureOutActColumnSize)&&(featureOutRow == featureOutActRowSize)&&((featureInCh+7) == featureInActChSize))begin // if iterate all channel in
            if(featureOutCh ==  featureOutActChSize)begin // if iterate also all channel out
                NewFeatureOutCh = 0;
            end else begin // otherwise, increment
                NewFeatureOutCh= featureOutCh + 1;
            end
        end else begin
            NewFeatureOutCh = featureOutCh;
        end
    end
end




always @ ( posedge clk) begin

    featureInCh = NewFeatureInCh;
    featureOutRow = NewFeatureOutRow;
    featureOutColum = NewFeatureOutColum;
    featureOutCh = NewFeatureOutCh;
    

end
assign featureInChAddr = featureInCh;
assign featureOutRowAddr = featureOutRow;
assign featureOutColumAddr = featureOutColum;
assign featureOutChAddr = featureOutCh;
assign NewFeatureOutChAddr = NewFeatureOutCh;
assign NewFeatureInChAddr = NewFeatureInCh;
endmodule