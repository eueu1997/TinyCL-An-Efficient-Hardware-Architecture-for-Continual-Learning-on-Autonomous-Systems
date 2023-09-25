
module FW_PU
(
    parameter int MAC_SIZE = 3;
    parameter int N_OF_MAC_ROWS = 3;
    parameter int N_OF_MAC_CLMN = 3;
    parameter int CHANNEL_IN_SIZE = 8;
)
(
    //kernels in
    input logic [0:7][0:8][(nBits-1):0] kernelVals;
    input logic loadKernel;
    // Feature in 
    output logic [9:0] featureInP1Addr,featureInP2Addr,featureInP3Addr;
    input logic [15:0][(nBits*nChannelIn-1):0] featureInP1,featureInP2,featureInP3;
    //feature out
    output logic [4:0]  featureOutRowAddr, featureOutColumAddr,featureOutChAddr; // given by store command
    output logic [(nBits-1):0] featureOutVal; // given by store command
    
)
// Address of output feature
reg logic left,right;
// Wire enabling the MACs. It connect the enable manager to the MACs
wire logic [0:(MAC_SIZE -1)][0:(MAC_SIZE -1)] enables_w;
// Wire of the kernels . It connect the kernel manager to the corresponding MAC
wire logic [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(nBits*CHANNEL_IN_SIZE -1 )] featuresIn;
// wire of the partial sums. It connects the output of the various MAC to the register
wire logic [0:(N_OF_MAC_ROWS-1)][0:(N_OF_MAC_CLMN-1)][(nBits-1)] partialSumIn;


///////////////////////////FORWARD ADDRESS MAMANGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Genera gli indirizzi per il FW . Cicla su i feature out row and column e poi su channel out
FWAddrManager FWAM(.clk(clk),.rst(rst) ,.featureRow(featureOutRowAddr),.featureColum(featureOutColumAddr),.featureCh(featureOutChAddr));
//////////////////////////// KERNEL REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\
// Manage the movement of the kernels across the 3x3 mac grid
kernelRegisters KR (.clk(clk),.rst(rst),.load(loadKernel),.kernelIn(kernelVals),.kernelOut(kernels));
///////////////////////////FEATURE REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\
featureRegisters FR (.right(right),.left(left),.rst(rst),.clk(clk),.featureIn[0](featureInP1),.featureIn[1](featureInP2),.featureIn[2](featureInP3),.featureOut(featuresIn));
/////////////////////////// DIRECTION MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// It manage, given the indexing of the feature, the direction of movement of the kernel register
always @ begin

    if (addressOut_row[0]='0')begin
        right = '1';
        left = '0';
    end
    else if (addressOut_row[0]='1')begin
        right = '0';
        left = '1';
    end
end
////////////////////// FEATURE IN ADDRESS MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Crea gli indirizzi dei nuovi pixel da caricare
always @ begin

    featureInP1Addr[9:5] = featureOutRowAddr
    featureInP1Addr[4:0] = featureOutColumAddr + 2
    featureInP2Addr[9:5] = featureOutRowAddr + 1
    featureInP2Addr[4:0] = featureOutColumAddr + 2
    featureInP3Addr[9:5] = featureOutRowAddr + 2
    featureInP3Addr[4:0] = featureOutColumAddr + 2
end
// Generazione dei MAC. Le 9 feature e i 9 kernel provengono da i due manager
genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (
            .featureIn[0](featuresIn[i][j][(nBits-1):(0)]),
            .featureIn[1](featuresIn[i][j][(2*nBits-1):(nBits)]),
            .featureIn[2](featuresIn[i][j][(3*nBits-1):(2*nBits)]),
            .featureIn[3](featuresIn[i][j][(4*nBits-1):(3*nBits)]),
            .featureIn[4](featuresIn[i][j][(5*nBits-1):(4*nBits)]),
            .featureIn[5](featuresIn[i][j][(6*nBits-1):(5*nBits)]),
            .featureIn[6](featuresIn[i][j][(7*nBits-1):(6*nBits)]),
            .featureIn[7](featuresIn[i][j][(8*nBits-1):(7*nBits)]),
            .kernel[0](kernels[i][j][(nBits-1):0]),
            .kernel[1](kernels[i][j][(2*nBits-1):(nBits)]),
            .kernel[2](kernels[i][j][(3*nBits-1):(2*nBits)]),
            .kernel[3](kernels[i][j][(4*nBits-1):(3*nBits)]),
            .kernel[4](kernels[i][j][(5*nBits-1):(4*nBits)]),
            .kernel[5](kernels[i][j][(6*nBits-1):(5*nBits)]),
            .kernel[6](kernels[i][j][(7*nBits-1):(6*nBits)]),
            .kernel[7](kernels[i][j][(8*nBits-1):(7*nBits)]),
            .featureOut(partialSumIn[i][j]));
        end
    end
endgenerate
// Ultimo dadda che somma i 9 prodotti della convoluzione
dadda_top DD(.DataIn(partialSumIn) , DataOut (featureOutVal));
endmodule
