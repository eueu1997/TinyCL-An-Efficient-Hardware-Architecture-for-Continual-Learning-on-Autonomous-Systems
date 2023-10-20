module AddrManagerBWDX #
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
    input [1:0]stride,
    //Actual feature size
    input [($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInActChSize,
    input [($clog2(FEATURE_OUT_CH_SIZE)-1):0] gradientOutActChSize,
    input [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] gradientOutActRowSize,
    input [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] gradientOutActColumnSize, 
    // address generated
    output reg [($clog2(FEATURE_OUT_ROW_SIZE)-1):0]gradientOutRowAddr,
    output reg [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0]gradientOutColumAddr,
    output reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0]gradientOutChAddr,
    output reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInChAddr
);
reg [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] gradientOutColum,NewGradientOutColum;
reg [($clog2(FEATURE_OUT_ROW_SIZE)-1):0] gradientOutRow,NewGradientOutRow;
reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInCh,NewGradientInCh;
reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] gradientOutCh,NewGradientOutCh;

//Column iterator
always @ (*) begin 
    if ( rst == 1)begin
        NewGradientOutColum = '{default:0};
    end else begin
        if (gradientOutRow[0]==0)begin // if moving to right
	        if(gradientOutColum  == (gradientOutActColumnSize-1) )begin // if reach end of column
		        NewGradientOutColum = gradientOutColum ;
	        end else begin // otherwise
        	    NewGradientOutColum = gradientOutColum + 1 ;
	        end
        end else begin // if we are moving to left
            if(gradientOutColum == 0)begin // if reaching column 0
		        NewGradientOutColum = gradientOutColum ;
	        end else begin // otherwise
        	    NewGradientOutColum = gradientOutColum - 1 ;
	        end
        end
    end
end

// Row iterator
always @ (*) begin 
    if ( rst == 1)begin
        NewGradientOutRow = 0;
    end else begin
        if ((gradientOutRow == (gradientOutActRowSize-1))&&(gradientOutColum == 0)) begin // if the whole feature has been iterated
            NewGradientOutRow = 0;
        end else begin 
            if((((gradientOutColum== (gradientOutActColumnSize-1))&&(NewGradientOutColum== (gradientOutActColumnSize-1))) || (((gradientOutColum ==0)&&(NewGradientOutColum ==0) )&&(gradientOutRow != 0))))begin
                NewGradientOutRow = gradientOutRow + 1;
            end else begin
                NewGradientOutRow = gradientOutRow;
            end
        end
    end
end

//channel in iterator 
always @ (*) begin 
    if (rst == 1) begin
        NewGradientInCh = 0;
    end else begin
        if ((gradientOutRow == (gradientOutActRowSize-1) ) && (gradientOutColum == 0))begin// If we are at the end of the feature
            if(gradientInCh == (gradientInActChSize-1))begin // if we have passed all channel in 
                NewGradientInCh = 0;
            end else begin// otherwise iterate
                NewGradientInCh= gradientInCh +1; 
            end
        end else begin // otherwise
            NewGradientInCh = gradientInCh;
        end
    end
end
//channel out iterator 
always @ (*) begin 
    if (rst == 1) begin
        NewGradientOutCh = 0;
    end else begin
        if ((gradientOutRow == (gradientOutActRowSize-1) ) && (gradientOutColum == 0) && (gradientInCh ==  (gradientInActChSize-1)))begin // if iterate all channel in
            if(gradientOutCh ==  (gradientOutActChSize-1))begin // if iterate also all channel out
                NewGradientOutCh = 0;
            end else begin // otherwise, increment
                NewGradientOutCh= gradientOutCh + 1;
            end
        end else begin
            NewGradientOutCh = gradientOutCh;
        end
    end
end




always @ ( posedge clk) begin

    gradientInCh = NewGradientInCh;
    gradientOutColum = NewGradientOutColum;
    gradientOutRow = NewGradientOutRow;
    gradientOutCh = NewGradientOutCh;

end
assign gradientInChAddr = gradientInCh;
assign gradientOutRowAddr = gradientOutRow;
assign gradientOutColumAddr = gradientOutColum;
assign gradientOutChAddr = gradientOutCh;

endmodule