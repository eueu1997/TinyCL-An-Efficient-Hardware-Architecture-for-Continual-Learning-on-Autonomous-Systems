// Visto che dobbiamo da creare 3x3 dk ( per ogni ch in e ch out) usiamo di nuovo un mac 3x3 in cui vengono mandati dentro feature in e dy. 
// Dy viene moltiplicato senza una regola precisa, infatti ogni pizxel di feature out è influenzato da tutti i kernel
// la feature in invece ha i bordi che non toccano alcuni kernel.
// la featureInMngr gestisce ciò,mandando fuori le feature nell'ordine giusto nei igusti MAC.
// a fine processo abbiamo nel registro di ogni MAC i 9 Dk 
module BW_PU #(
    parameter N_OF_MAC_ROWS = 3,
    parameter N_OF_MAC_CLMN = 3,
    parameter NBITS = 16,
    parameter N_FEATURE_READ = 8,
    parameter FEATURE_IN_ROW_SIZE = 32,
    parameter FEATURE_IN_COLUMN_SIZE = 32,
    parameter FEATURE_IN_CH_SIZE = 8,
    parameter FEATURE_OUT_ROW_SIZE = 32,
    parameter FEATURE_OUT_COLUMN_SIZE = 32,
    parameter FEATURE_OUT_CH_SIZE = 8,
    parameter KERNEL_SIZE = 3
)
( 
    // Feature in
    output reg [($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] featureInAddr,
    input  [0:(N_FEATURE_READ -1)][(NBITS-1):0]featureIn,
    // Dy in
    output reg [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1):0]dyAddr,
    input  [0:(N_FEATURE_READ -1)][(NBITS-1):0]dy,
    // dk out
    output  reg [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_IN_CH_SIZE) -1):0] dkAddr,
    output reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dk,
    input clk,
    input rst,
    output reg valid
);
reg [($clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] convAddr_r;
reg [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_IN_CH_SIZE) -1):0] dkAddr_r;

reg  [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0]partialSumIn,partialSumOut;
wire  [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][0:(N_FEATURE_READ -1)][(NBITS-1):0]featuresInMngd;
genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (.featureIn(featuresInMngd[i][j]),.partialSumIn(partialSumIn[i][j]),.Kernel(dy),.featureOut(partialSumOut[i][j]));
            register #(.WIDTH(NBITS)) PSi(.data_in(partialSumOut[i][j]),.clk(clk),.rst(rst),.data_out(partialSumIn[i][j]));

        end
    end

endgenerate

// DK validation signal
always @(*)  begin
    if ( convAddr_r == (FEATURE_IN_ROW_SIZE*FEATURE_IN_COLUMN_SIZE-N_FEATURE_READ) )begin
        valid <= 1;
    end else begin
        valid <= 0;
    end
end
// DK output
assign dk = partialSumOut;
// create address for dy,feature in and output dk address
assign dkAddr = dkAddr_r;
assign featureInAddr[($clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] = convAddr_r;
assign featureInAddr[($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1) : ($clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) )] = dkAddr_r[( $clog2(FEATURE_IN_CH_SIZE) -1):0];
assign dyAddr[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] = convAddr_r;// TODO : this can cause problem due tobnot considering stride
assign dyAddr[($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1):($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) )] = dkAddr_r[($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_IN_CH_SIZE)  -1):( $clog2(FEATURE_IN_CH_SIZE) )];
//Address manager. Generate 
BWDKAddrManager BWDK (.clk(clk),.rst(rst),.convAddr(convAddr_r),.dkAddr(dkAddr_r));
    
featureInMngr FIN(.featureInAddr(convAddr_r),.featureIn(featureIn),.featuresInMngd(featuresInMngd));
endmodule