module MAC#
(
    parameter int NBit = 16,
	parameter int NBitOut = 20,
    parameter int NOperands = 8
)
(
	input  logic [0:(NOperands)][(NBit-1):0] featureIn  , // 8 da moltiplicare piu il 9o che è la somma parziale
    input  logic [0:(NOperands-1)][(NBit-1):0] Kernel  ,
    output logic [(NBit-1):0]   featureOut

);
wire [0:(NOperands-1)][(NBit-1):0] temp_w;
wire [(NBitOut-1):0] featureOut_w


genvar i;
generate 
    for(i=0; i<NOperands; i=i+1) begin 
        mult mi (.A(featureIn[i]),.B(Kernel[i]),.DataOut(temp_w[i]));
    end
endgenerate

dadda_top DU	
(			.DataIn[0:(NOperands-1)](temp_w), // 8Multiplications results
            .DataIn[NOperands](featureIn[NOperands]) // partial sum 
			.DataOut(featureOut_w));
//Bisogna poi decidere di tagliare i 4 MSB per farlo tornare a 16 bit
featureOut = featureOut_w;
endmodule