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
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrFW,NewFeatureInChAddrFW,
    input  [(NBITS*N_OF_CH_READ-1):0] featureInP1FW,featureInP2FW,featureInP3FW,
    //feature out
    output [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrFW,NewFeatureOutChAddrFW,
    output [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrFW,
    output [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrFW, 
    output reg [(NBITS-1):0] featureOutValFW,
    // BACKWARD DK SIGNALS
    output [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrBWDK,NewFeatureInChAddrBWDK,
    output [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrBWDK,NewFeatureOutChAddrBWDK,
    output [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureInRowAddrBWDK,
    output [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureInColumnAddrBWDK, 
    // Feature in
    input  [0:(KERNEL_SIZE-1)][(N_FEATURE_READ*NBITS-1):0]featureInBWDK,
    // Dy in
    input  [(N_OF_CH_READ*NBITS-1):0]dyBWDK,
    // dk out
    output reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] dkBWDK,
    output reg valid, // VALIDITY SIGNAL FOR DK, RST SIGNAL FOR GIR
    // BACKWARD DX SIGNALS
    input [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelBWDX,
    input  [(NBITS*N_OF_CH_READ-1):0] DyP1BWDX,DyP2BWDX,DyP3BWDX,
    output reg [(NBITS-1):0]dxBWDX,
    // DX address signals
    output reg[($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInChAddrBWDX,NewGradientInChAddrBWDX,
    output reg[($clog2(FEATURE_OUT_CH_SIZE)-1):0] gradientOutChAddrBWDX,NewGradientOutChAddrBWDX,
    output reg[($clog2(FEATURE_OUT_ROW_SIZE) -1):0] gradientOutRowAddrBWDX,
    output reg[($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] gradientOutColumnAddrBWDX, 
    input  loadKernelBWDX


);
////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////BACKWARD DK LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////////////////////////////////////////////////////////
reg [($clog2(FEATURE_IN_ROW_SIZE) + $clog2(FEATURE_IN_COLUMN_SIZE) -1):0] convAddr_r;
reg [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_IN_CH_SIZE) -1):0] dkAddr_r;
reg rstGIR;
wire  [0:(KERNEL_SIZE -1)][(N_OF_CH_READ*NBITS-1):0]featuresInBWDK;
wire  [0:(KERNEL_SIZE -1)][(N_OF_CH_READ*NBITS-1):0]dyBWDK_r;
/////////////////////////// BACKWARD ADDRESS MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\
BWDKAddrManager BWDK (.clk(clk),.rst((rst|~bw[0])),
                        .featureInActChSize(featureInActChSize),
                        .featureOutActChSize(featureOutActChSize),
                        .featureOutActRowSize(featureOutActRowSize),
                        .featureOutActColumnSize(featureOutActColumnSize),
                        .featureOutRowAddr(featureInRowAddrBWDK),
                        .featureOutColumAddr(featureInColumnAddrBWDK),
                        .featureOutChAddr(featureOutChAddrBWDK),
                        .NewFeatureOutChAddr(NewFeatureOutChAddrBWDK),
                        .featureInChAddr(featureInChAddrBWDK),
                        .NewFeatureInChAddr(NewFeatureInChAddrBWDK));
////////////////////////// BACKWARD FEATURE MANAGER \\\\\\\\\\\\\\\\\\\\\\\\\\\

gradientInRegisterBWDK # ( N_OF_CH_READ,KERNEL_SIZE,KERNEL_SIZE,NBITS ) 
GIR(.clk(clk),
.rst(rst|rstGIR),
.dy(dyBWDK),
.dy_out(dyBWDK_r));

always @ (*) begin

    if(featureInColumnAddrBWDK == 0)begin
        rstGIR = 1;
    end else begin
        rstGIR = 0;
    end
end
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
                    .NewFeatureOutChAddr(NewFeatureOutChAddrFW),
                    .featureInChAddr(featureInChAddrFW),
                    .NewFeatureInChAddr(NewFeatureInChAddrFW)
                    );
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
if(bw == 0)begin
    if (featureOutRowAddrFW[0]== 0)begin
        if(featureOutColumnAddrFW == 0)begin // new row, go down
            right = 0;
            left = 0;
        end else begin
            right = 1;
            left = 0;
        end
    end
    else if (featureOutRowAddrFW[0]== 1)begin
        if(featureOutColumnAddrFW == featureOutActColumnSize)begin // new row, go down
            right = 0;
            left = 0;
        end else begin
            right = 0;
            left = 1;
        end
    end
end else if ( bw==2) begin
    if (gradientOutRowAddrBWDX[0]== 0)begin
        if(gradientOutColumnAddrBWDX == 0)begin // new row, go down
            right = 0;
            left = 0;
        end else begin
            right = 1;
            left = 0;
        end
    end
    else if (gradientOutRowAddrBWDX[0]== 1)begin
        if(gradientOutColumnAddrBWDX == featureOutActColumnSize)begin // new row, go down
            right = 0;
            left = 0;
        end else begin
            right = 0;
            left = 1;
        end
    end
end
end
////////////////////////////////////////// MAC GENERATION \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// Generazione dei MAC. Le 9 feature e i 9 kernel provengono da i due manager
reg [0:(N_OF_MAC_ROWS -1 )][0:(N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ -1 ):0] data1,data2;
reg [0:(N_OF_MAC_ROWS -1)][0:(N_OF_MAC_CLMN -1)][(NBITS*N_OF_CH_READ-1):0]partialSumIn,partialSumOutDk,partialSumMAC_r;
reg [0:(N_OF_MAC_ROWS -1)][0:(N_OF_MAC_CLMN -1)][(NBITS-1):0] partialSumMACDadda,partialSumMAC;
reg daddaEn;
reg [(NBITS-1):0]daddaOut_r;
reg regRst;
genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (
            .select(bw[0]),
            .featureIn(data1[i][j]),
            .partialSumIn(partialSumIn[i][j]),
            .Kernel(data2[i][j]),
            .featureOut(partialSumMAC[i][j]),
            .featureOutDk(partialSumOutDk[i][j]));
            register #(.WIDTH(128)) PSi(.data_in(partialSumOutDk[i][j]),.clk(clk),.rst(regRst),.data_out(partialSumMAC_r[i][j]));

        end
    end
endgenerate
// Ultimo dadda che somma i 9 prodotti della convoluzione per il forward e il dx
dadda_top DD(.DataIn(partialSumMACDadda) , .DataOut (daddaOut_r));
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] DyBWDX;
reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] kernelsBWDX;

// Muxing of signal on forward of backward
always @ (* ) begin 
    if(bw == 0)begin // forward
        data1[0][0] = featuresInFw[0][0];
        data1[0][1] = featuresInFw[0][1];
        data1[0][2] = featuresInFw[0][2];
        data1[1][0] = featuresInFw[1][0];
        data1[1][1] = featuresInFw[1][1];
        data1[1][2] = featuresInFw[1][2];
        data1[2][0] = featuresInFw[2][0];
        data1[2][1] = featuresInFw[2][1];
        data1[2][2] = featuresInFw[2][2];

        data2[0][0] = kernelsFw[0][0];
        data2[0][1] = kernelsFw[0][1];
        data2[0][2] = kernelsFw[0][2];
        data2[1][0] = kernelsFw[1][0];
        data2[1][1] = kernelsFw[1][1];
        data2[1][2] = kernelsFw[1][2];
        data2[2][0] = kernelsFw[2][0];
        data2[2][1] = kernelsFw[2][1];
        data2[2][2] = kernelsFw[2][2];
        partialSumIn = 0;
        partialSumMACDadda = partialSumMAC;
        dkBWDK = 0; // TODO : si potrebbe mettere alta impedenza
        featureOutValFW = daddaOut_r;
        dxBWDX = 0;
        valid = 0;
    end else if(bw == 1) begin // bw dk
        data1[0][0] = featureInBWDK[0];
        data1[0][1] = featureInBWDK[0];
        data1[0][2] = featureInBWDK[0];
        data1[1][0] = featureInBWDK[1];
        data1[1][1] = featureInBWDK[1];
        data1[1][2] = featureInBWDK[1];
        data1[2][0] = featureInBWDK[2];
        data1[2][1] = featureInBWDK[2];
        data1[2][2] = featureInBWDK[2];

        data2[0][0] = dyBWDK_r[0];
        data2[0][1] = dyBWDK_r[1];
        data2[0][2] = dyBWDK_r[2];
        data2[1][0] = dyBWDK_r[0];
        data2[1][1] = dyBWDK_r[1];
        data2[1][2] = dyBWDK_r[2];
        data2[2][0] = dyBWDK_r[0];
        data2[2][1] = dyBWDK_r[1];
        data2[2][2] = dyBWDK_r[2];

        partialSumIn[0][0] = partialSumMAC_r[0][0];
        partialSumIn[0][1] = partialSumMAC_r[0][1];
        partialSumIn[0][2] = partialSumMAC_r[0][2];
        partialSumIn[1][0] = partialSumMAC_r[1][0];
        partialSumIn[1][1] = partialSumMAC_r[1][1];
        partialSumIn[1][2] = partialSumMAC_r[1][2];
        partialSumIn[2][0] = partialSumMAC_r[2][0];
        partialSumIn[2][1] = partialSumMAC_r[2][1];
        partialSumIn[2][2] = partialSumMAC_r[2][2];

        partialSumMACDadda = 0;
        featureOutValFW =0 ;
        if ( (featureInRowAddrBWDK == featureOutActRowSize) && (featureInColumnAddrBWDK == featureOutActColumnSize) )begin
            valid = 1;
            dkBWDK[0][0] = partialSumMAC_r[0][0];
            dkBWDK[0][1] = partialSumMAC_r[0][1];
            dkBWDK[0][2] = partialSumMAC_r[0][2];
            dkBWDK[1][0] = partialSumMAC_r[1][0];
            dkBWDK[1][1] = partialSumMAC_r[1][1];
            dkBWDK[1][2] = partialSumMAC_r[1][2];
            dkBWDK[2][0] = partialSumMAC_r[2][0];
            dkBWDK[2][1] = partialSumMAC_r[2][1];
            dkBWDK[2][2] = partialSumMAC_r[2][2];

        end else begin
            valid = 0;
            dkBWDK = 0;
        end
        if ( (featureInRowAddrBWDK == 0) && (featureInColumnAddrBWDK == 0) )begin // TODO : dovrebbe resettare il registro solo con colonna == 0, a ogni giro.
            regRst = 1;
        end else begin
            regRst = 0;
        end
    end else if ( bw == 2) begin // bw dx
        data1[0][0] = DyBWDX[0][0];
        data1[0][1] = DyBWDX[0][1];
        data1[0][2] = DyBWDX[0][2];
        data1[1][0] = DyBWDX[1][0];
        data1[1][1] = DyBWDX[1][1];
        data1[1][2] = DyBWDX[1][2];
        data1[2][0] = DyBWDX[2][0];
        data1[2][1] = DyBWDX[2][1];
        data1[2][2] = DyBWDX[2][2];

        data2[0][0] = kernelsBWDX[0][0];
        data2[0][1] = kernelsBWDX[0][1];
        data2[0][2] = kernelsBWDX[0][2];
        data2[1][0] = kernelsBWDX[1][0];
        data2[1][1] = kernelsBWDX[1][1];
        data2[1][2] = kernelsBWDX[1][2];
        data2[2][0] = kernelsBWDX[2][0];
        data2[2][1] = kernelsBWDX[2][1];
        data2[2][2] = kernelsBWDX[2][2];
        partialSumIn = 0;
        partialSumMACDadda = partialSumMAC;
        valid = 0;
        dkBWDK = 0;
        dxBWDX = daddaOut_r;
        featureOutValFW = 0;
    end else begin 
        valid = 0;
        data1 = 0;
        partialSumIn = 0;
        data2 = 0;
        partialSumMACDadda = 0;
        dkBWDK = 0;
        dxBWDX = 0;
        featureOutValFW = 0;
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
featureRegisterBWDX FRBWDX (.right(right),.left(left),.rst((rst|~bw[1])),.clk(clk),
                    .stride(stride),
                    .j(gradientOutRowAddrBWDX[0]),
                    .gradientInP1(DyP1BWDX),
                    .gradientInP2(DyP2BWDX),
                    .gradientInP3(DyP3BWDX),
                    .gradientOut(DyBWDX));
AddrManagerBWDX AMBWDX (.clk(clk),.rst((rst|~bw[1])),.stride(stride)
                        ,.gradientInActChSize(featureOutActChSize)
                        ,.gradientOutActChSize(featureInActChSize)
                        ,.gradientOutActRowSize(featureOutActRowSize*stride)
                        ,.gradientOutActColumnSize(featureOutActColumnSize*stride) 
                        ,.gradientOutRowAddr(gradientOutRowAddrBWDX)
                        ,.gradientOutColumAddr(gradientOutColumnAddrBWDX)
                        ,.gradientOutChAddr(gradientOutChAddrBWDX)
                        ,.NewGradientOutChAddr(NewGradientOutChAddrBWDX)
                        ,.gradientInChAddr(gradientInChAddrBWDX)
                        ,.NewGradientInChAddr(NewGradientInChAddrBWDX));
endmodule

