module MAC#
(
    parameter int NBit = 16,
	parameter int NBitOut = 20,
    parameter int NOperands = 8
)
(
	input  [0:(NOperands-1)][(NBit-1):0] featureIn  , // 8 da moltiplicare piu il 9o che è la somma parziale
    input  [0:(NOperands-1)][(NBit-1):0] Kernel  ,
    output [(NBit-1):0]   featureOut

);
wire [0:(NOperands-1)][(NBit-1):0] temp_w;
wire [(NBitOut-1):0] featureOut_w


genvar i;
generate 
    for(i=0; i<NOperands; i=i+1) begin 
        fixed_multi Mi (.num1(featureIn[i]),.num2(Kernel[i]),.result(temp_w[i]),.precisionLost(),.result_full());
    end
endgenerate

dadda_top DU	
(			.DataIn[0:(NOperands-1)](temp_w), // 8Multiplications results
            .DataIn[NOperands]({default:0}) // partial sum 
			.DataOut(featureOut_w));
//Temporaneamente prendo i 16 MSB: 8 fractional part + 8 integer part
// fractional part
assign featureOut[7:0] = featureOut_w[7:0];
//integer part
assign featureOut[15:8] = featureOut_w[15:8];
endmodule