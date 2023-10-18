// Define the module instance
module FW_BW_PU_tb;

    parameter MAC_SIZE = 3;
    parameter KERNEL_SIZE = 3;
    parameter N_OF_MAC_ROWS = 3;
    parameter N_OF_MAC_CLMN = 3;
    parameter N_OF_CH_READ = 8;
    parameter NBITS = 16;
    parameter FEATURE_IN_ROW_SIZE= 32;
    parameter FEATURE_IN_COLUMN_SIZE = 32;
    parameter FEATURE_IN_CH_SIZE = 8;
    parameter FEATURE_OUT_ROW_SIZE = 32;
    parameter FEATURE_OUT_COLUMN_SIZE = 32;
    parameter FEATURE_OUT_CH_SIZE = 8;
    parameter N_FEATURE_READ = 8;
    // Define signals
    reg [0:1]bw;
    reg clk;
    reg rst;
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInActChSize;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutActChSize;
    reg [($clog2(FEATURE_OUT_ROW_SIZE)-1):0] featureOutActRowSize;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] featureOutActColumnSize;
    reg stride;
    reg [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelValsFW;
    reg loadKernelFW;
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrFW;
    reg [(NBITS*N_OF_CH_READ-1):0] featureInP1FW, featureInP2FW, featureInP3FW;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrFW;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureInRowAddrFW;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureInColumnAddrFW;
    reg [(NBITS-1):0] featureOutValFW;
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] DkChInAddrBWDk;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] dkChOutAddrBWDk;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrBWDk;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrBWDk;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] featureInBW;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] dyBW;
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dkBW;
    reg valid;
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] kernelBWDX,
    reg  [(NBITS*N_OF_CH_READ-1):0] DyP1BWDY,DyP2BWDY,DyP3BWDY,
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0]dxBWDX,
    // DX address signals
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInChAddrBWDX,
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] gradinetOutChAddrBWDX,
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] gradientOutRowAddrBWDX,
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] gradientOutColumnAddrBWDX, 
    reg  loadKernelBWDX

    reg [(NBITS-1):0]kernel[0:(FEATURE_OUT_CH_SIZE*FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE-1)];
    reg [(NBITS-1):0]featureIn1[0:(FEATURE_IN_CH_SIZE*FEATURE_IN_ROW_SIZE*FEATURE_IN_COLUMN_SIZE-1)];
    reg [(NBITS-1):0]featureOut1 [0:(FEATURE_OUT_CH_SIZE*FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE-1)];

    reg [(FEATURE_IN_CH_SIZE + FEATURE_IN_ROW_SIZE + FEATURE_IN_COLUMN_SIZE -1):0]featureIn2[(NBITS-1):0];
    reg [(FEATURE_IN_CH_SIZE + FEATURE_IN_ROW_SIZE + FEATURE_IN_COLUMN_SIZE -1):0]featureIn3[(NBITS-1):0];

    reg [(FEATURE_OUT_CH_SIZE + FEATURE_OUT_ROW_SIZE + FEATURE_OUT_COLUMN_SIZE -1):0]featureOut2[(NBITS-1):0];
    reg [(FEATURE_OUT_CH_SIZE + FEATURE_OUT_ROW_SIZE + FEATURE_OUT_COLUMN_SIZE -1):0]featureOut3[(NBITS-1):0];

    // Instantiate the module
    FW_BW_PU #(MAC_SIZE, KERNEL_SIZE, N_OF_MAC_ROWS, N_OF_MAC_CLMN, N_OF_CH_READ,
              NBITS, FEATURE_IN_ROW_SIZE, FEATURE_IN_COLUMN_SIZE, FEATURE_IN_CH_SIZE,
              FEATURE_OUT_ROW_SIZE, FEATURE_OUT_COLUMN_SIZE, FEATURE_OUT_CH_SIZE,
              N_FEATURE_READ) uut (
        .bw(bw),
        .clk(clk),
        .rst(rst),
        .featureInActChSize(featureInActChSize),
        .featureOutActChSize(featureOutActChSize),
        .featureOutActRowSize(featureOutActRowSize),
        .featureOutActColumnSize(featureOutActColumnSize),
        .kernelValsFW(kernelValsFW),
        .loadKernelFW(loadKernelFW),
        .featureInChAddrFW(featureInChAddrFW),
        .featureInP1FW(featureInP1FW),
        .featureInP2FW(featureInP2FW),
        .featureInP3FW(featureInP3FW),
        .featureOutChAddrFW(featureOutChAddrFW),
        .featureInRowAddrFW(featureInRowAddrFW),
        .featureInColumnAddrFW(featureInColumnAddrFW),
        .featureOutValFW(featureOutValFW),
        .DkChInAddrBWDk(DkChInAddrBWDk),
        .dkChOutAddrBWDk(dkChOutAddrBWDk),
        .featureOutRowAddrBWDk(featureOutRowAddrBWDk),
        .featureOutColumnAddrBWDk(featureOutColumnAddrBWDk),
        .featureInBW(featureInBW),
        .dyBW(dyBW),
        .dkBW(dkBW),
        .valid(valid)
    );

    always #5 clk = ~clk;

    // Define stimulus
    initial begin
        clk = 0;
        rst = 1;
        loadKernelFW = 0;
        #10;
        rst = 0;
        bw = 0;
        featureInActChSize = FEATURE_IN_CH_SIZE-1;
        featureOutActChSize = FEATURE_OUT_CH_SIZE-1;
        featureOutActRowSize = FEATURE_OUT_ROW_SIZE-1;
        featureOutActColumnSize = FEATURE_OUT_COLUMN_SIZE-1;
        $readmemh("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/kernel.txt",kernel);
        $readmemh("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureIn1.txt", featureIn1);
        while ((featureOutChAddrFW  != featureOutActChSize ) || (featureInRowAddrFW != featureOutActRowSize ) || (featureInColumnAddrFW != 0) || ((featureInChAddrFW+7) != featureInActChSize)) begin
            if (( featureInRowAddrFW == 0 ) && ( featureInColumnAddrFW == 0) )begin // TODO : MOVE LOGIC LOAD KERNEL INSIDE PU
                loadKernelFW = 1;
                for (int i=0; i <KERNEL_SIZE; i= i+1)begin
                    for (int j=0; j < KERNEL_SIZE; j= j+1)begin
                
                kernelValsFW[(i*KERNEL_SIZE)+j][(1*NBITS-1):(0*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+0)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(2*NBITS-1):(1*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+1)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(3*NBITS-1):(2*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+2)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(4*NBITS-1):(3*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+3)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(5*NBITS-1):(4*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+4)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(6*NBITS-1):(5*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+5)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(7*NBITS-1):(6*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+6)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                kernelValsFW[(i*KERNEL_SIZE)+j][(8*NBITS-1):(7*NBITS)] = kernel[(featureOutChAddrFW*(FEATURE_IN_CH_SIZE*KERNEL_SIZE*KERNEL_SIZE)+(featureInChAddrFW+7)*(KERNEL_SIZE*KERNEL_SIZE)+(i*(KERNEL_SIZE))+j)];
                
               
                    end
                end
                
            end
            if((featureInColumnAddrFW+2) > featureOutActColumnSize)begin
                featureInP1FW = 0;
                featureInP2FW = 0;
                featureInP3FW = 0;
            end else begin
            if(featureInRowAddrFW[0] == 0)begin // TODO : MOVE LOGIC ADDRES INSIDE 

            featureInP1FW[(NBITS-1):0]         = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];

            featureInP2FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP2FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];

            featureInP3FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            featureInP3FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+2)];
            end else begin
            featureInP1FW[(NBITS-1):0]        = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];

            featureInP2FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP2FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];

            featureInP3FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            featureInP3FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW+0)];
            
            end
            end
            featureOut1[((featureOutChAddrFW)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureInRowAddrFW)*(FEATURE_OUT_COLUMN_SIZE) + featureInColumnAddrFW)] = featureOutValFW;
            
            #10;
            loadKernelFW = 0;
        end
        $writememh("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutVerilogHex.txt",featureOut1);
        #5;
        rst = 1;
        /*featureInActChSize = 16;
        featureOutActChSize = 16;
        featureOutActRowSize = 16;
        featureOutActColumnSize = 16;
        $readmemh("featureIn2.txt", featureIn2);
        while ((featureOutChAddrFW != FEATURE_OUT_CH_SIZE[1] )&& (featureInRowAddrFW!=FEATURE_OUT_ROW_SIZE[1] )&& (featureInColumnAddrFW!= FEATURE_OUT_COLUMN_SIZE[1]) && ((featureInChAddrFW+8) != featureInChAddrFW[1])) begin
            featureInP1FW[(NBITS-1):0]        = featureIn2[featureInChAddrFW][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn2[featureInChAddrFW+1][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn2[featureInChAddrFW+2][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn2[featureInChAddrFW+3][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn2[featureInChAddrFW+4][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn2[featureInChAddrFW+5][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn2[featureInChAddrFW+6][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn2[featureInChAddrFW+7][featureInRowAddrFW+0][featureInColumnAddrFW+2];

            featureInP2FW[(NBITS-1):0]        = featureIn2[featureInChAddrFW][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(2*NBITS-1):NBITS]   = featureIn2[featureInChAddrFW+1][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(3*NBITS-1):2*NBITS] = featureIn2[featureInChAddrFW+2][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(4*NBITS-1):3*NBITS] = featureIn2[featureInChAddrFW+3][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(5*NBITS-1):4*NBITS] = featureIn2[featureInChAddrFW+4][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(6*NBITS-1):5*NBITS] = featureIn2[featureInChAddrFW+5][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(7*NBITS-1):6*NBITS] = featureIn2[featureInChAddrFW+6][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(8*NBITS-1):7*NBITS] = featureIn2[featureInChAddrFW+7][featureInRowAddrFW+1][featureInColumnAddrFW+2];

            featureInP3FW[(NBITS-1):0]        = featureIn2[featureInChAddrFW][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(2*NBITS-1):NBITS]   = featureIn2[featureInChAddrFW+1][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(3*NBITS-1):2*NBITS] = featureIn2[featureInChAddrFW+2][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(4*NBITS-1):3*NBITS] = featureIn2[featureInChAddrFW+3][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(5*NBITS-1):4*NBITS] = featureIn2[featureInChAddrFW+4][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(6*NBITS-1):5*NBITS] = featureIn2[featureInChAddrFW+5][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(7*NBITS-1):6*NBITS] = featureIn2[featureInChAddrFW+6][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(8*NBITS-1):7*NBITS] = featureIn2[featureInChAddrFW+7][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            
            featureOut2[featureOutChAddrFW][featureInRowAddrFW][featureInColumnAddrFW] = featureOutValFW;
            #10;
        end
        $writememh("featureOut2",featureOut2);
        featureInActChSize = 32;
        featureOutActChSize = 32;
        featureOutActRowSize = 8;
        featureOutActColumnSize = 8;
        $readmemh("featureIn3.txt", featureIn3);
        while ((featureOutChAddrFW != FEATURE_OUT_CH_SIZE[2] )&& (featureInRowAddrFW!=FEATURE_OUT_ROW_SIZE[2] )&& (featureInColumnAddrFW!= FEATURE_OUT_COLUMN_SIZE[2]) && ((featureInChAddrFW+8) != featureInChAddrFW[2])) begin
            featureInP1FW[(NBITS-1):0]         = featureIn3[featureInChAddrFW][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn3[featureInChAddrFW+1][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn3[featureInChAddrFW+2][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn3[featureInChAddrFW+3][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn3[featureInChAddrFW+4][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn3[featureInChAddrFW+5][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn3[featureInChAddrFW+6][featureInRowAddrFW+0][featureInColumnAddrFW+2];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn3[featureInChAddrFW+7][featureInRowAddrFW+0][featureInColumnAddrFW+2];

            featureInP2FW[(NBITS-1):0]         = featureIn3[featureInChAddrFW][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(2*NBITS-1):NBITS]   = featureIn3[featureInChAddrFW+1][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(3*NBITS-1):2*NBITS] = featureIn3[featureInChAddrFW+2][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(4*NBITS-1):3*NBITS] = featureIn3[featureInChAddrFW+3][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(5*NBITS-1):4*NBITS] = featureIn3[featureInChAddrFW+4][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(6*NBITS-1):5*NBITS] = featureIn3[featureInChAddrFW+5][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(7*NBITS-1):6*NBITS] = featureIn3[featureInChAddrFW+6][featureInRowAddrFW+1][featureInColumnAddrFW+2];
            featureInP2FW[(8*NBITS-1):7*NBITS] = featureIn3[featureInChAddrFW+7][featureInRowAddrFW+1][featureInColumnAddrFW+2];

            featureInP3FW[(NBITS-1):0]         = featureIn3[featureInChAddrFW][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(2*NBITS-1):NBITS]   = featureIn3[featureInChAddrFW+1][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(3*NBITS-1):2*NBITS] = featureIn3[featureInChAddrFW+2][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(4*NBITS-1):3*NBITS] = featureIn3[featureInChAddrFW+3][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(5*NBITS-1):4*NBITS] = featureIn3[featureInChAddrFW+4][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(6*NBITS-1):5*NBITS] = featureIn3[featureInChAddrFW+5][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(7*NBITS-1):6*NBITS] = featureIn3[featureInChAddrFW+6][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            featureInP3FW[(8*NBITS-1):7*NBITS] = featureIn3[featureInChAddrFW+7][featureInRowAddrFW+2][featureInColumnAddrFW+2];
            
            featureOut3[featureOutChAddrFW][featureInRowAddrFW][featureInColumnAddrFW] = featureOutValFW;
            #10;
        end
        $writememh("featureOut3",featureOut3);*/
        $finish;
    end

    
endmodule
