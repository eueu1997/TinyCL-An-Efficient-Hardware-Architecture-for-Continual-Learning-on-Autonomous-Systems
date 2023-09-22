module FWAddrManager #
(
    parameter rowSize = 32,
    parameter columnSize = 32,
    parameter ChSize = 8
)
(
    //kernel inp
    input logic clk,
    input logic rst,

    output reg [($clog2(rowSize)-1):0]featureRow,
    output reg [($clog2(columnSize)-1):0]featureColum,
    output reg [($clog2(ChSize)-1):0]featureCh
);
reg [($clog2(columnSize)-1):0] featureOutColum,NewFeatureOutColum;
reg [($clog2(rowSize)-1):0] featureOutRow,NewFeatureOutRow;
reg [($clog2(ChSize)-1):0] featureOutCh,NewFeatureOutCh;

// Row iterator
always @ (*) begin 
    if ( rst == 1)begin
        NewFeatureOutRow = '{default:0};
    end else begin
    if((((featureOutColum == '{default:1})&(NewFeatureOutColum == '{default:1})) | (((featureOutColum =='{default:0})&(NewFeatureOutColum =='{default:0}) )&(featureOutRow != '{default:0}))))begin
        NewFeatureOutRow = featureOutRow + 1;
    end
    else begin
        NewFeatureOutRow = featureOutRow;
    end
    end
end
//Column iterator
always @ (*) begin 
    if ( rst == 1)begin
        NewFeatureOutColum = '{default:0};
    end else begin
    if (featureOutRow[0]==0)begin
	if(featureOutColum == '{default:1})begin
		NewFeatureOutColum = featureOutColum ;
	end else begin
        	NewFeatureOutColum = featureOutColum + 1 ;
	end
    end else begin
        if(featureOutColum == '{default:0})begin
		NewFeatureOutColum = featureOutColum ;
	end else begin
        	NewFeatureOutColum = featureOutColum - 1 ;
	end
    end
    end
end
//iteration over channel out
always @ (*) begin 
    if (rst == 1) begin
        NewFeatureOutCh = '{default:0};
    end else begin
    if ((featureOutRow == '{default:1}) & (featureOutColum == '{default:0}))begin
        NewFeatureOutCh= featureOutCh + 1;
    end else begin
        NewFeatureOutCh = featureOutCh;
    end
    end
end




always @ ( posedge clk) begin

    featureOutRow = NewFeatureOutRow;
    featureOutColum = NewFeatureOutColum;
    featureOutCh = NewFeatureOutCh;

end

assign featureRow = featureOutRow;
assign featureColum = featureOutColum;
assign featureCh = featureOutCh;

endmodule