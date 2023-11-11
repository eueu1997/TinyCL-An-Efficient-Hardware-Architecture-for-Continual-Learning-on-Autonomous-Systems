
module MAC#
(
    parameter NBit = 16,
    parameter NOperands = 8
)
(
    input clk,
    input select, // if = 0, multi operand sum ( fw, dx); if == 1 multi sum ( dk)
	input  [(NOperands-1):0][(NBit-1):0] featureIn  , // 8 da moltiplicare piu il 9o che è la somma parziale
    input  [(NOperands*NBit-1):0] partialSumIn,
    input  [(NOperands-1):0][(NBit-1):0] Kernel  ,
    output reg [(NBit-1):0]   featureOut,
    output reg [(NOperands*NBit-1):0] featureOutDk

);
reg  [(NOperands-1):0][(NBit-1):0] featureIn_r;
reg [(NOperands-1):0][(NBit-1):0] Kernel_r;
wire [0:(NOperands-1)][(2*NBit-1):0] temp_w  ; // volontariamente 9. l'ultimo è a zero
reg [0:(NOperands-1)][(2*NBit-1):0]opAdd1,opAdd2,res;
reg [(NBit-1):0] featureOut_r;
reg [(NOperands*NBit-1):0] featureOutDk_r;
genvar i;
generate 
    for(i=0; i<NOperands; i=i+1) begin 
        fixed_multi Mi (.num1(featureIn_r[i]),.num2(Kernel_r[i]),.result(),.overflow(),.precisionLost(),.result_full(temp_w[i]));
        fixed_add #(.NBit(32),.NBitOut(32)) Ai (.num1(opAdd1[i]),.num2(opAdd2[i]),.result(res[i]));

    end
endgenerate

always @ ( posedge clk ) begin
    featureIn_r = featureIn;
    Kernel_r = Kernel;
    //if( select == 0)begin//
        // first row of adders
end
    assign    opAdd1[0] = temp_w[0];
    assign    opAdd1[1] = temp_w[1];
    assign    opAdd1[2] = temp_w[2];
    assign    opAdd1[3] = temp_w[3];
    assign    opAdd2[0] = temp_w[4];
    assign    opAdd2[1] = temp_w[5];
    assign    opAdd2[2] = temp_w[6];
    assign    opAdd2[3] = temp_w[7];
        //second row of adders
    assign    opAdd1[4] = res[0];
    assign    opAdd1[5] = res[1];
    assign    opAdd2[4] = res[2];
    assign    opAdd2[5] = res[3];
        // last row of adders
    assign    opAdd1[6] = res[4];
    assign    opAdd2[6] = res[5];
    assign    opAdd1[7] = 0;
    assign    opAdd2[7] = 0;
    assign    featureOut = res[6][19:4];
    assign    featureOutDk=0;
    /*end else begin
        opAdd1[0] = temp_w[0];
        opAdd2[0] = partialSumIn[(1*NBit-1):0*NBit];
        opAdd1[1] = temp_w[1];
        opAdd2[1] = partialSumIn[(2*NBit-1):1*NBit];
        opAdd1[2] = temp_w[2];
        opAdd2[2] = partialSumIn[(3*NBit-1):2*NBit];
        opAdd1[3] = temp_w[3];
        opAdd2[3] = partialSumIn[(4*NBit-1):3*NBit];
        opAdd1[4] = temp_w[4];
        opAdd2[4] = partialSumIn[(5*NBit-1):4*NBit];
        opAdd1[5] = temp_w[5];
        opAdd2[5] = partialSumIn[(6*NBit-1):5*NBit];
        opAdd1[6] = temp_w[6];
        opAdd2[6] = partialSumIn[(7*NBit-1):6*NBit];
        opAdd1[7] = temp_w[7];
        opAdd2[7] = partialSumIn[(8*NBit-1):7*NBit];
        featureOut_r = 0;
        featureOutDk_r[(1*NBit-1):0*NBit]=res[0][19:4];
        featureOutDk_r[(2*NBit-1):1*NBit]=res[1][19:4];
        featureOutDk_r[(3*NBit-1):2*NBit]=res[2][19:4];
        featureOutDk_r[(4*NBit-1):3*NBit]=res[3][19:4];
        featureOutDk_r[(5*NBit-1):4*NBit]=res[4][19:4];
        featureOutDk_r[(6*NBit-1):5*NBit]=res[5][19:4];
        featureOutDk_r[(7*NBit-1):6*NBit]=res[6][19:4];
        featureOutDk_r[(8*NBit-1):7*NBit]=res[7][19:4];
    end*/
//end
/*
always @ (posedge clk)begin
    featureOut = featureOut_r;
    featureOutDk = featureOutDk_r;
end*/

endmodule