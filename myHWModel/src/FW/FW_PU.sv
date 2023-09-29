
module FW_PU #
(
    parameter MAC_SIZE = 3,
    parameter N_OF_MAC_ROWS = 3,
    parameter N_OF_MAC_CLMN = 3,
    parameter CHANNEL_IN_SIZE = 8,
    parameter NBITS = 16,
    parameter FEATURE_IN_ROW_SIZE = 32,
    parameter FEATURE_IN_COLUMN_SIZE = 32,
    parameter FEATURE_IN_CH_SIZE = 8
)
(
    input clk,
    input rst,
    //kernels in
    input  [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*CHANNEL_IN_SIZE-1):0] kernelVals,
    input  loadKernel,
    // Feature in 
    output  [($clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] featureInP1Addr,featureInP2Addr,featureInP3Addr,
    input  [(NBITS*CHANNEL_IN_SIZE-1):0] featureInP1,featureInP2,featureInP3,
    //feature out
    output [($clog2(FEATURE_IN_ROW_SIZE)-1):0]  featureOutRowAddr, 
    output [($clog2(FEATURE_IN_COLUMN_SIZE)-1):0] featureOutColumAddr,
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureOutChAddr, 
    output [(NBITS-1):0] featureOutVal
    
);
// Address of output feature
reg left,right;
// Wire of the feature . It connect the feature manager to the corresponding MAC
wire [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*CHANNEL_IN_SIZE -1 ):0] featuresIn;
// Wire of the kernels . It connect the kernel manager to the corresponding MAC
wire [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*CHANNEL_IN_SIZE -1 ):0] kernels;
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
////////////////////// FEATURE IN ADDRESS MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Crea gli indirizzi dei nuovi pixel da caricare


assign featureInP1Addr[9:5] = featureOutRowAddr;
assign featureInP1Addr[4:0] = featureOutColumAddr + 2;
assign featureInP2Addr[9:5] = featureOutRowAddr + 1;
assign featureInP2Addr[4:0] = featureOutColumAddr + 2;
assign featureInP3Addr[9:5] = featureOutRowAddr + 2;
assign featureInP3Addr[4:0] = featureOutColumAddr + 2;

// Generazione dei MAC. Le 9 feature e i 9 kernel provengono da i due manager
genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (
            .featureIn(featuresIn[i][j]),
            .partialSumIn('{default:0}),
            /*.featureIn[1](featuresIn[i][j][(2*NBITS-1):(NBITS)]),
            .featureIn[2](featuresIn[i][j][(3*NBITS-1):(2*NBITS)]),
            .featureIn[3](featuresIn[i][j][(4*NBITS-1):(3*NBITS)]),
            .featureIn[4](featuresIn[i][j][(5*NBITS-1):(4*NBITS)]),
            .featureIn[5](featuresIn[i][j][(6*NBITS-1):(5*NBITS)]),
            .featureIn[6](featuresIn[i][j][(7*NBITS-1):(6*NBITS)]),
            .featureIn[7](featuresIn[i][j][(8*NBITS-1):(7*NBITS)]),*/
            .Kernel(kernels[i][j]),/*
            .kernel[1](kernels[i][j][(2*NBITS-1):(NBITS)]),
            .kernel[2](kernels[i][j][(3*NBITS-1):(2*NBITS)]),
            .kernel[3](kernels[i][j][(4*NBITS-1):(3*NBITS)]),
            .kernel[4](kernels[i][j][(5*NBITS-1):(4*NBITS)]),
            .kernel[5](kernels[i][j][(6*NBITS-1):(5*NBITS)]),
            .kernel[6](kernels[i][j][(7*NBITS-1):(6*NBITS)]),
            .kernel[7](kernels[i][j][(8*NBITS-1):(7*NBITS)]),*/
            .featureOut(partialSumIn[i][j]));
        end
    end
endgenerate
// Ultimo dadda che somma i 9 prodotti della convoluzione
dadda_top DD(.DataIn(partialSumIn) , .DataOut (featureOutVal));
endmodule
