// Visto che dobbiamo da creare 3x3 dk ( per ogni ch in e ch out) usiamo di nuovo un mac 3x3 in cui vengono mandati dentro feature in e dy. 
// Dy viene moltiplicato senza una regola precisa, infatti ogni pizxel di feature out è influenzato da tutti i kernel
// la feature in invece ha i bordi che non toccano alcuni kernel.
// la featureInMngr gestisce ciò,mandando fuori le feature nell'ordine giusto nei igusti MAC.
// a fine processo abbiamo nel registro di ogni MAC i 9 Dk 
module BW_PU(
    parameter int nBits = 16;
)
(
    input logic [0:7][(nBits-1):0]featureIn;
    output logic featureInAddr;
    input logic []dyAddr;
    input logic [0:7][(nBits-1):0]dy
)
reg logic [0:2][0:2][(nBits-1):0]partialSumIn,partialSumOut
wire logic [0:2][0:2][0:7][(nBits-1):0]featuresInMngd;
genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (.featureIn[0:7](featuresInMngd[i][j]),.featureIn[8](partialSumOut[i][j]).kernel(dy),.featureOut(partialSumIn[i][j]),'1');
            register PSi(partialSumIn[i][j],partialSumOut[i][j],clk,rst)

        end
    end
endgenerate

featureInMngr FIN(.featureIn(featureIn),.featureInMngd(featuresInMngd),clk,rst);
endmodule