
module FW_PU #
(
    parameter MAC_SIZE = 3,
    parameter N_OF_MAC_ROWS = 3,
    parameter N_OF_MAC_CLMN = 3,
    parameter N_OF_CH_READ = 8,
    parameter NBITS = 16,
    parameter FEATURE_IN_ROW_SIZE = 32,
    parameter FEATURE_IN_COLUMN_SIZE = 32,
    parameter FEATURE_IN_CH_SIZE = 8,
    parameter FEATURE_OUT_ROW_SIZE = 32,
    parameter FEATURE_OUT_COLUMN_SIZE = 32,
    parameter FEATURE_OUT_CH_SIZE = 8
)
(
    input clk,
    input rst,
    //kernels in
    input  [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelVals,
    input  loadKernel,
    // Feature in 
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddr,
    input  [(NBITS*N_OF_CH_READ-1):0] featureInP1,featureInP2,featureInP3,
    //feature out
    output [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddr
    output [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddr
    output [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddr, 
    output [(NBITS-1):0] featureOutVal,
    //Actual feature size
    input [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInActChSize,
    input [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutActChSize,
    input [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutActRowSize,
    input [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutActColumnSize, 
    
);
//TODO : IMPLEMENTI WITH CH_IN > 8
reg left,right;
// Wire of the feature . It connect the feature manager to the corresponding MAC
wire [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ -1 ):0] featuresIn;
// Wire of the kernels . It connect the kernel manager to the corresponding MAC
wire [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ -1 ):0] kernels;
// wire of the partial sums. It connects the output of the various MAC to the register
wire [0:(N_OF_MAC_ROWS-1)][0:(N_OF_MAC_CLMN-1)][(NBITS-1):0] partialSumIn;

///////////////////////////FORWARD ADDRESS MAMANGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Genera gli indirizzi per il FW . Cicla su i feature out row and column e poi su channel out
FWAddrManager FWAM(.clk(clk),.rst(rst) ,.featureRow(featureOutRowAddr),.featureColum(featureOutColumAddr),.featureCh(featureOutChAddr));
//////////////////////////// KERNEL REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\
// Manage the movement of the kernels across the 3x3 mac grid
kernelRegisters KR (.clk(clk),.rst(rst),.load(loadKernel),.kernelIn(kernelVals),.kernelOut(kernels));
///////////////////////////FEATURE REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\
featureRegister FR (.right(right),.left(left),.rst(rst),.clk(clk),.featureInP1(featureInP1),.featureInP2(featureInP2),.featureInP3(featureInP3),.featureOut(featuresIn));
/////////////////////////// DIRECTION MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// It manage, given the indexing of the feature, the direction of movement of the kernel register
always @ (*) begin

    if (featureOutRowAddr[0]== 0)begin
        right = 1;
        left = 0;
    end
    else if (featureOutRowAddr[0]== 1)begin
        right = 0;
        left = 1;
    end
end

// Generazione dei MAC. Le 9 feature e i 9 kernel provengono da i due manager
genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (
            .featureIn(featuresIn[i][j]),
            .partialSumIn('{default:0}),
            .Kernel(kernels[i][j]),
            .featureOut(partialSumIn[i][j]));
        end
    end
endgenerate
// Ultimo dadda che somma i 9 prodotti della convoluzione
dadda_top DD(.DataIn(partialSumIn) , .DataOut (featureOutVal));
endmodule
