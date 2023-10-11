//TODO : modifica segnali BWDK e poi fai test
module FW_BW_PU #
(
    parameter MAC_SIZE = 3,
    parameter KERNEL_SIZE = 3,
    parameter N_OF_MAC_ROWS = 3,
    parameter N_OF_MAC_CLMN = 3,
    parameter N_OF_CH_READ = 8,
    parameter NBITS = 16,
    parameter FEATURE_IN_ROW_SIZE = 32,
    parameter FEATURE_IN_COLUMN_SIZE = 32,
    parameter FEATURE_IN_CH_SIZE = 8,
    parameter FEATURE_OUT_ROW_SIZE = 32,
    parameter FEATURE_OUT_COLUMN_SIZE = 32,
    parameter FEATURE_OUT_CH_SIZE = 8,
    parameter N_FEATURE_READ = 8
)
(
    input bw, // 0 = fw , 1 = bw
    input clk,
    input rst,
    //Actual feature size
    input [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInActChSize,
    input [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutActChSize,
    input [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutActRowSize,
    input [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutActColumnSize, 
    // FORWARD SIGNALS
    //kernels in
    input  [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelValsFW,
    input  loadKernelFW,
    // Feature in 
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrFW,
    input  [(NBITS*N_OF_CH_READ-1):0] featureInP1FW,featureInP2FW,featureInP3FW,
    //feature out
    output [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrFW,
    output [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrFW,
    output [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrFW, 
    output [(NBITS-1):0] featureOutValFW,
    // BACKWARD SIGNALS
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] DkChInAddrBWDk,
    output [($clog2(FEATURE_OUT_CH_SIZE)-1):0] dkChOutAddrBWDk,
    output [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrBWDk,
    output [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrBWDk, 
    // Feature in
    input  [0:(N_FEATURE_READ -1)][(NBITS-1):0]featureInBW,
    // Dy in
    input  [0:(N_FEATURE_READ -1)][(NBITS-1):0]dyBW,
    // dk out
    output reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dkBW,
    output reg valid // VALIDITY SIGNAL FOR DK
);
////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////BACKWARD LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////////////////////////////////////////////////////////
reg [($clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] convAddr_r;
reg [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_IN_CH_SIZE) -1):0] dkAddr_r;

wire  [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][0:(N_FEATURE_READ -1)][(NBITS-1):0]featuresInBwDk;

/////////////////////////// BACKWARD ADDRESS MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\
BWDKAddrManager BWDK (.clk(clk),.rst((rst|bw)),
                        .featureInActChSize(featureInActChSize),
                        .featureOutActChSize(featureOutActChSize),
                        .featureOutActRowSize(featureOutActRowSize),
                        .featureOutActColumnSize(featureOutActColumnSize),
                        .featureOutRowAddr(featureOutRowAddrBWDk),
                        .featureOutColumAddr(featureOutColumnAddrBWDk),
                        .featureOutChAddr(DkChOutAddrBWDk),
                        .featureInChAddr(DkChInAddrBWDk));
////////////////////////// BACKWARD FEATURE MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\
featureInBWMngr FIN(.featureOutRowAddr(featureOutRowAddrBWDk),
                    .featureOutColumAddr(featureOutColumnAddrBWDk),
                    .featureIn(featureInBW),
                    .featuresInMngd(featuresInBwDk));

///////////////////////////////////////////////////////////////////////////////
/////////////////////////// FORWARD LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////
reg left,right;
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] kernelsFw;
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] featuresInFw;
///////////////////////////FORWARD ADDRESS MAMANGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Genera gli indirizzi per il FW . Cicla su i feature out row and column e poi su channel out
FWAddrManager FWAM(.clk(clk),.rst((rst|bw)) ,
                    .featureInActChSize(featureInActChSize),
                    .featureOutActChSize(featureOutActChSize),
                    .featureOutActRowSize(featureOutActRowSize),
                    .featureOutActColumnSize(featureOutActColumnSize),
                    .featureOutRowAddr(featureOutRowAddrFW),
                    .featureOutColumAddr(featureOutColumnAddrFW),
                    .featureOutChAddr(featureOutChAddrFW),
                    .featureInChAddr(featureInChAddrFW));
//////////////////////////// KERNEL REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Manage the movement of the kernels across the 3x3 mac grid
kernelRegisters KR (.clk(clk),.rst((rst|bw)),.load(loadKernelFW),.kernelIn(kernelValsFW),.kernelOut(kernelsFw));
///////////////////////////FEATURE REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\
featureRegister FR (.right(right),.left(left),.rst((rst|bw)),.clk(clk),
                    .featureInP1(featureInP1FW),
                    .featureInP2(featureInP2FW),
                    .featureInP3(featureInP3FW),
                    .featureOut(featuresInFw));
/////////////////////////// DIRECTION MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// It manage, given the indexing of the feature, the direction of movement of the kernel register

always @ (*) begin

    if (featureOutRowAddrFW[0]== 0)begin
        right = 1;
        left = 0;
    end
    else if (featureOutRowAddrFW[0]== 1)begin
        right = 0;
        left = 1;
    end
end
////////////////////////////////////////// MAC GENERATION \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// Generazione dei MAC. Le 9 feature e i 9 kernel provengono da i due manager
reg [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ -1 ):0] data1,data2;
reg [0:(N_OF_MAC_ROWS -1)][0:(N_OF_MAC_CLMN -1)][(NBITS-1):0]partialSumIn,partialSumMAC,partialSumMAC_r,partialSumMACDadda;
reg daddaEn;

genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (
            .featureIn(data1[i][j]),
            .partialSumIn(partialSumIn[i][j]),
            .Kernel(data2[i][j]),
            .featureOut(partialSumMAC[i][j]));
            register #(.WIDTH(NBITS)) PSi(.data_in(partialSumMAC[i][j]),.clk(clk),.rst(rst),.data_out(partialSumMAC_r[i][j]));

        end
    end
endgenerate
// Ultimo dadda che somma i 9 prodotti della convoluzione per il forward
dadda_top DD(.DataIn(partialSumMACDadda) , .DataOut (featureOutValFW));

// Muxing of signal on forward of backward
always @ (* ) begin 
    if(bw == 0)begin
        data1 = featuresInFw;
        partialSumIn = 0;
        data2 = kernelsFw;
        partialSumMACDadda = partialSumMAC;
        dkBW = 0; // TODO : si potrebbe mettere alta impedenza
    end else begin 
        data1 = featuresInBwDk;
        partialSumIn = partialSumMAC_r;
        data2 = dyBW;
        partialSumMACDadda = 0;
        if ( convAddr_r == (FEATURE_IN_ROW_SIZE*FEATURE_IN_COLUMN_SIZE-N_FEATURE_READ) )begin
            valid = 1;
            dkBW = partialSumMAC_r;
        end else begin
            valid = 0;
            dkBW = 0;
        end
    end
end


endmodule

