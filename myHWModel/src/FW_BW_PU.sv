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
    input [1:0] bw, // 0 = fw , 1 = bw
    input clk,
    input rst,
    //Actual feature size
    input [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInActChSize,
    input [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutActChSize,
    input [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutActRowSize,
    input [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutActColumnSize, 
    input [1:0] stride,
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
    // BACKWARD DK SIGNALS
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrBWDK,
    output [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrBWDK,
    output [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureInRowAddrBWDK,
    output [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureInColumnAddrBWDK, 
    // Feature in
    input  [0:(N_FEATURE_READ -1)][(NBITS-1):0]featureInBWDK,
    // Dy in
    input  [0:(N_FEATURE_READ -1)][(NBITS-1):0]dyBWDK,
    // dk out
    output reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dkBWDK,
    output reg valid, // VALIDITY SIGNAL FOR DK
    // BACKWARD DX SIGNALS
    input [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelBWDX,
    input  [(NBITS*N_OF_CH_READ-1):0] DyP1BWDX,DyP2BWDX,DyP3BWDX,
    output reg [0:(N_FEATURE_READ -1)][(NBITS-1):0]dxBWDX,
    // DX address signals
    output reg[($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInChAddrBWDX,
    output reg[($clog2(FEATURE_OUT_CH_SIZE)-1):0] gradientOutChAddrBWDX,
    output reg[($clog2(FEATURE_OUT_ROW_SIZE) -1):0] gradientOutRowAddrBWDX,
    output reg[($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] gradientOutColumnAddrBWDX, 
    input  loadKernelBWDX


);
////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////BACKWARD LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////////////////////////////////////////////////////////
reg [($clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] convAddr_r;
reg [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_IN_CH_SIZE) -1):0] dkAddr_r;

wire  [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][0:(N_FEATURE_READ -1)][(NBITS-1):0]featuresInBwDk;

/////////////////////////// BACKWARD ADDRESS MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\
BWDKAddrManager BWDK (.clk(clk),.rst((rst|~bw[0])),
                        .featureInActChSize(featureInActChSize),
                        .featureOutActChSize(featureOutActChSize),
                        .featureOutActRowSize(featureOutActRowSize),
                        .featureOutActColumnSize(featureOutActColumnSize),
                        .featureOutRowAddr(featureInRowAddrBWDK),
                        .featureOutColumAddr(featureInColumnAddrBWDK),
                        .featureOutChAddr(featureOutChAddrBWDK),
                        .featureInChAddr(featureInChAddrBWDK));
////////////////////////// BACKWARD FEATURE MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\
featureInBWMngr FIN(.featureOutRowAddr(featureInRowAddrBWDK),
                    .featureOutColumAddr(featureInColumnAddrBWDK),
                    .featureIn(featureInBWDK),
                    .featuresInMngd(featuresInBwDk));

///////////////////////////////////////////////////////////////////////////////
/////////////////////////// FORWARD LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////
reg left,right;
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] kernelsFw;
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] featuresInFw;
///////////////////////////FORWARD ADDRESS MAMANGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Genera gli indirizzi per il FW . Cicla su i feature out row and column e poi su channel out
FWAddrManager FWAM(.clk(clk),.rst((rst|bw[0]|bw[1])) ,
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
kernelRegisters KR (.clk(clk),.rst((rst|bw[0]|bw[1])),.load(loadKernelFW),.kernelIn(kernelValsFW),.kernelOut(kernelsFw));
///////////////////////////FEATURE REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\
featureRegister FR (.right(right),.left(left),.rst((rst|bw[0]|bw[1])),.clk(clk),
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
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] DyBWDX;
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] kernelsBWDX;

// Muxing of signal on forward of backward
always @ (* ) begin 
    if(bw == 0)begin // forward
        data1 = featuresInFw;
        partialSumIn = 0;
        data2 = kernelsFw;
        partialSumMACDadda = partialSumMAC;
        dkBWDK = 0; // TODO : si potrebbe mettere alta impedenza
    end if(bw == 1) begin // bw dk
        data1 = featuresInBwDk;
        partialSumIn = partialSumMAC_r;
        data2 = dyBWDK;
        partialSumMACDadda = 0;
        if ( convAddr_r == (FEATURE_IN_ROW_SIZE*FEATURE_IN_COLUMN_SIZE-N_FEATURE_READ) )begin
            valid = 1;
            dkBWDK = partialSumMAC_r;
        end else begin
            valid = 0;
            dkBWDK = 0;
        end
    end else begin // bw dx
        data1 = DyBWDX;
        partialSumIn = 0;
        data2 = kernelsBWDX;
        partialSumMACDadda = 0;
    end

end

//////////////////////////// KERNEL REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\
// Manage the movement of the kernels across the 3x3 mac grid
kernelRegistersBWDX KRBWDX (.clk(clk),.rst((rst|~bw[1])),.stride(stride)
                            ,.j(gradientOutRowAddrBWDX[0])
                            ,.k(gradientOutColumnAddrBWDX[0])
                            ,.load(loadKernelBWDX)
                            ,.kernelIn(kernelBWDX)
                            ,.kernelOut(kernelsBWDX));
///////////////////////////FEATURE REGISTER MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\
featureRegisterBWDX FRBWDX (.right(right),.left(left),.rst((rst|~bw[0])),.clk(clk),
                    .stride(stride),
                    .j(gradientOutRowAddrBWDX[0]),
                    .gradientInP1(DyP1BWDX),
                    .gradientInP2(DyP2BWDX),
                    .gradientInP3(DyP3BWDX),
                    .gradientOut(DyBWDX));
AddrManagerBWDX AMBWDX (.clk(clk),.rst(rst),.stride(stride)
                        ,.gradientInActChSize(featureOutActChSize)
                        ,.gradientOutActChSize(featureInActChSize)
                        ,.gradientOutActRowSize(featureOutActRowSize*stride)
                        ,.gradientOutActColumnSize(featureOutActColumnSize*stride) 
                        ,.gradientOutRowAddr(gradientOutRowAddrBWDX)
                        ,.gradientOutColumAddr(gradientOutColumnAddrBWDX)
                        ,.gradientOutChAddr(gradientOutChAddrBWDX)
                        ,.gradientInChAddr(gradientInChAddrBWDX));
endmodule

