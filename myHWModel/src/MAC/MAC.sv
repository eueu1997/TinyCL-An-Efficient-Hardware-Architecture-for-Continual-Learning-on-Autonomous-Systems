module MAC#
(
    parameter NBit = 16,
	parameter NBitOut = 20,
    parameter NOperands = 8
)
(
	input  [0:(NOperands-1)][(NBit-1):0] featureIn  , // 8 da moltiplicare piu il 9o che è la somma parziale
    input  [(NBit-1):0] partialSumIn,
    input  [0:(NOperands-1)][(NBit-1):0] Kernel  ,
    output reg [(NBit-1):0]   featureOut

);
wire [0:(NOperands)][(NBit-1):0] temp_w  ; // volontariamente 9. l'ultimo è a zero
wire [(NBitOut-1):0] featureOut_w;

assign temp_w[NOperands] = partialSumIn;

genvar i;
generate 
    for(i=0; i<NOperands; i=i+1) begin 
        fixed_multi Mi (.num1(featureIn[i]),.num2(Kernel[i]),.result(temp_w[i]),.overflow(),.precisionLost(),.result_full());
    end
endgenerate

dadda_top DU(.DataIn(temp_w), // 8Multiplications results
			.DataOut(featureOut_w));
//Temporaneamente prendo i 16 MSB: 8 fractional part + 8 integer part
assign featureOut[15:0] = featureOut_w[15:0];
endmodule