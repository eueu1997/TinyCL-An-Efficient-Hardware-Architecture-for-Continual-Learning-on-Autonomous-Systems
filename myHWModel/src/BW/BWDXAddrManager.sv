   
module BWDK_PU #
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
    output  [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE)+$clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] DYP1Addr,DYP2Addr,DYP3Addr,
    input  [(NBITS*N_OF_CH_READ-1):0] DyP1,DyP2,DyP3,
    //feature out
    output [($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] dxAddr, 
    output [(NBITS-1):0] dxVal
    
);
//TODO : IMPLEMENTI WITH CH_IN > 8
reg left,right;
// Wire of the feature . It connect the feature manager to the corresponding MAC
wire [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ -1 ):0] featuresIn;
// Wire of the kernels . It connect the kernel manager to the corresponding MAC
wire [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ -1 ):0] kernels;
// wire of the partial sums. It connects the output of the various MAC to the register
wire [0:(N_OF_MAC_ROWS-1)][0:(N_OF_MAC_CLMN-1)][(NBITS-1):0] partialSumIn;
wire  [($clog2(FEATURE_OUT_ROW_SIZE)-1):0]  dxRowAddr;
wire  [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] dxColumnAddr;
wire  [($clog2(FEATURE_OUT_CH_SIZE)-1):0] dxChAddr;
///////////////////////////FORWARD ADDRESS MAMANGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Genera gli indirizzi per il FW . Cicla su i feature out row and column e poi su channel out
FWAddrManager FWAM(.clk(clk),.rst(rst) ,.featureRow(dxRowAddr),.featureColum(dxColumnAddr),.featureCh(dxChAddr));
//////////////////////////// KERNEL REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\
// Manage the movement of the kernels across the 3x3 mac grid
kernelRegisters KR (.clk(clk),.rst(rst),.load(loadKernel),.kernelIn(kernelVals),.kernelOut(kernels));
///////////////////////////FEATURE REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\
featureRegister FR (.right(right),.left(left),.rst(rst),.clk(clk),.DyP1(DyP1),.DyP2(DyP2),.DyP3(DyP3),.featureOut(featuresIn));
/////////////////////////// DIRECTION MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// It manage, given the indexing of the feature, the direction of movement of the kernel register
always @ (*) begin

    if (dxRowAddr[0]== 0)begin
        right = 1;
        left = 0;
    end
    else if (dxRowAddr[0]== 1)begin
        right = 0;
        left = 1;
    end
end
////////////////////// FEATURE IN ADDRESS MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Crea gli indirizzi dei nuovi pixel da caricare

assign dxAddr = {dxChAddr,dxRowAddr,dxColumnAddr};

assign DYP1Addr[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = dxRowAddr;
assign DYP1Addr[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = dxColumnAddr + 2;
assign DYP2Addr[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = dxRowAddr + 1;
assign DYP2Addr[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = dxColumnAddr + 2;
assign DYP3Addr[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = dxRowAddr + 2;
assign DYP3Addr[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = dxColumnAddr + 2;

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
dadda_top DD(.DataIn(partialSumIn) , .DataOut (dxVal));
endmodule        