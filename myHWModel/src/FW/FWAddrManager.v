module FWAddrManager
(
    
)
(
    //kernel inp
    input logic clk;
    input logic rst ;

    output logic [4:0]featureRow,featureColum,featureCh;
)

reg [0:5] featureOutRow,featureOutColum,featureOutCh
reg [0:5] NewFeatureOutRow,NewFeatureOutColum,NewFeatureOutCh

// Iteration over feature
always @ () begin 
    if ( rst = '1')begin
        NewFeatureOutRow = "00000";
        NewFeatureOutColum = "00000";
    end else begin
    if (featureOutColum[0]='0')begin
        NewFeatureOutRow = featureOutRow + 1 ;
    end else begin
        NewFeatureOutRow = featureOutRow - 1 ;
    end
    if(featureOutRow = "11111") or (featureOutRow = "00000")begin
        NewFeatureOutColum = featureOutColum + 1;
    end
    else begin
        NewFeatureOutColum = featureOutColum;
    end
    end
end
//iteration over channel out
always @ () begin 
    if (rst = '1') begin
        NewFeatureOutCh = "00000"
    end else begin
    if (featureOutRow = "11111") and (featureOutColum = "11111")begin
        NewFeatureOutCh = featureOutCh + 1
    end else begin
        NewFeatureOutCh = featureOutCh
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