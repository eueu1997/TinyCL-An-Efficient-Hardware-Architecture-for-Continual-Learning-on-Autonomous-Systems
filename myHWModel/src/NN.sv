// Define the module instance
// TODO : stride assignation and modification inside PU
// TODO : trasforma parametri in define
// TODO : apply input feture read during DX calculation to apply ReLU derivative ( set 0 the gradient input whose position was at 0 on feature in)
// TODO : apply fetching also to kernel reading and writing during DK. 
// TODO : avendo fetchato , bisogna incrementare i valori di ch da leggere, considerando che se abbiamo finito un canale in ingrasso dovremmo incrementare il canale in uscita
// TODO : do better stride assignation
module NN #
(   
    parameter MAC_SIZE = 3,
    parameter KERNEL_SIZE = 3,
    parameter N_OF_MAC_ROWS = 3,
    parameter N_OF_MAC_CLMN = 3,
    parameter N_OF_CH_READ = 8,
    parameter NBITS = 16,
    parameter NLAYER = 1,
    // SIZES OF FEATURES 
    parameter int FEATURE_IN_ROW_SIZE [0:(NLAYER-1)]= {32},
    parameter int FEATURE_IN_COLUMN_SIZE [0:(NLAYER-1)] = {32},
    parameter int FEATURE_IN_CH_SIZE [0:(NLAYER-1)] = {8},
    parameter int FEATURE_OUT_ROW_SIZE [0:(NLAYER-1)]= {32},
    parameter int FEATURE_OUT_COLUMN_SIZE [0:(NLAYER-1)]= {32},
    parameter int FEATURE_OUT_CH_SIZE[0:(NLAYER-1)] = {8},
    // SIZES OF GRADIENT 
    parameter int GRADIENT_IN_ROW_SIZE [0:(NLAYER-1)]= FEATURE_OUT_ROW_SIZE,
    parameter int GRADIENT_IN_COLUMN_SIZE [0:(NLAYER-1)] = FEATURE_OUT_COLUMN_SIZE,
    parameter int GRADIENT_IN_CH_SIZE [0:(NLAYER-1)] = FEATURE_OUT_CH_SIZE,
    parameter int GRADIENT_OUT_ROW_SIZE [0:(NLAYER-1)]= FEATURE_IN_ROW_SIZE,
    parameter int GRADIENT_OUT_COLUMN_SIZE [0:(NLAYER-1)]= FEATURE_IN_COLUMN_SIZE,
    parameter int GRADIENT_OUT_CH_SIZE[0:(NLAYER-1)] = FEATURE_IN_CH_SIZE,
    parameter N_FEATURE_READ = 8,
    parameter string ACTIVATION = "RELU"

)
(   input clk,rst,
    output [0:9]featureInReadAddrFWGDUMB, // address of the feature
    output featureInReadEnFWGDUMB, // Enable of GDUMB RAM memory. It read on all channels ( 3 extendet to 8 just for compatibility), always port widht of 8*NBITS, so same logic as SRAM
    input [0:7][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFWGDUMB
);


    // Define signals
    reg [1:0] bw,next_bw;
    // Dynamic sizing of the feauture
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInActChSize;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutActChSize;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0])-1):0] featureOutActRowSize;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0])-1):0] featureOutActColumnSize;
    // matrix of 8*9 kernel values
    reg [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelValsFW;
    // flag saing kernel il ready to be loaded
    reg loadKernelFW;
    // channel of input feature. output, counted inside PU
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInChAddrFW;
    // 3 new pixels needed by MAC in forward computation
    reg [(NBITS*N_OF_CH_READ-1):0] featureInP1FW, featureInP2FW, featureInP3FW;
    // address of feature out : channel column and row. Column and row is used also by feature in for indexing. channel is used also to index the kernel
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutChAddrFW;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) -1):0] featureOutRowAddrFW;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):0] featureOutColumnAddrFW;
    // pixel of feature out : result of 3d convolution
    reg [(NBITS-1):0] featureOutValFW,featureOutValFWActivated;
    // BW signals : indexing of DK ( channel in, out , row and column.)
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInChAddrBWDK;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutChAddrBWDK;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) -1):0] featureInRowAddrBWDK;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):0] featureInColumnAddrBWDK;
    // 8 pixel used for dk calculation 
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] featureInBWDK;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] dyBWDK;
    // dk output
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dkBWDK;
    // flag: is 1 when dkBWDK is valid and can be stored( used to modify kernels)
    reg valid;
    // DX SIGNALS 
    reg  [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelBWDX;
    reg [(NBITS*N_OF_CH_READ-1):0] DyP1BWDX,DyP2BWDX,DyP3BWDX;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0]dxBWDX;
    // DX address signals
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] gradientInChAddrBWDX;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] gradientOutChAddrBWDX;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) -1):0] gradientOutRowAddrBWDX;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):0] gradientOutColumnAddrBWDX; 
    reg loadKernelBWDX;
    reg [0:($clog2(NLAYER)-1)]actLayer,next_actLayer;
    reg [1:0] stride;
    // Instantiate the module
    FW_BW_PU #(MAC_SIZE, KERNEL_SIZE, N_OF_MAC_ROWS, N_OF_MAC_CLMN, N_OF_CH_READ,
              NBITS, FEATURE_IN_ROW_SIZE[0], FEATURE_IN_COLUMN_SIZE[0], FEATURE_IN_CH_SIZE[NLAYER-1],
              FEATURE_OUT_ROW_SIZE[0], FEATURE_OUT_COLUMN_SIZE[0], FEATURE_OUT_CH_SIZE[NLAYER-1],
              N_FEATURE_READ) FW_BW_PU_i (
        .bw(bw),
        .clk(clk),
        .rst(rst),
        .featureInActChSize(featureInActChSize),
        .featureOutActChSize(featureOutActChSize),
        .featureOutActRowSize(featureOutActRowSize),
        .featureOutActColumnSize(featureOutActColumnSize),
        .stride(stride),
        .kernelValsFW(kernelValsFW),
        .loadKernelFW(loadKernelFW),
        .featureInChAddrFW(featureInChAddrFW),
        .featureInP1FW(featureInP1FW),
        .featureInP2FW(featureInP2FW),
        .featureInP3FW(featureInP3FW),
        .featureOutChAddrFW(featureOutChAddrFW),
        .featureOutRowAddrFW(featureOutRowAddrFW),
        .featureOutColumnAddrFW(featureOutColumnAddrFW),
        .featureOutValFW(featureOutValFW),
        .featureInChAddrBWDK(featureInChAddrBWDK),
        .featureOutChAddrBWDK(featureOutChAddrBWDK),
        .featureInRowAddrBWDK(featureInRowAddrBWDK),
        .featureInColumnAddrBWDK(featureInColumnAddrBWDK),
        .featureInBWDK(featureInBWDK),
        .dyBWDK(dyBWDK),
        .dkBWDK(dkBWDK),
        .valid(valid),
        .kernelBWDX(kernelBWDX)
        ,.DyP1BWDX(DyP1BWDX)
        ,.DyP2BWDX(DyP2BWDX)
        ,.DyP3BWDX(DyP3BWDX)
        ,.dxBWDX(dxBWDX)
        ,.gradientInChAddrBWDX(gradientInChAddrBWDX)
        ,.gradientOutChAddrBWDX(gradientOutChAddrBWDX)
        ,.gradientOutRowAddrBWDX(gradientOutRowAddrBWDX)
        ,.gradientOutColumnAddrBWDX(gradientOutColumnAddrBWDX)
        ,.loadKernelBWDX(loadKernelBWDX)

    );

assign stride = 1;
/////////////////////////////// LAYER LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// layer counter updating logic. The logic depends of which operation we are
always @ (*)begin

    if(rst== 1) begin
        next_actLayer = 0;
    end else begin
        if ( bw == 0)begin
            if(((featureInChAddrFW+8) == (FEATURE_IN_CH_SIZE[actLayer])) && (featureOutChAddrFW == (FEATURE_OUT_CH_SIZE[actLayer]-1)) && (featureOutRowAddrFW == (FEATURE_OUT_ROW_SIZE[actLayer]-1)) && (featureOutColumnAddrFW == 0)&&(actLayer !=(NLAYER-1))) begin
                next_actLayer <= actLayer +1;
            end else begin
                next_actLayer <= actLayer;
            end 
        end else if (bw == 1)begin
                next_actLayer <= actLayer; 
        end else if (bw == 2) begin
            if(((gradientInChAddrBWDX+8) == (GRADIENT_IN_CH_SIZE[actLayer])) && (gradientOutChAddrBWDX == (GRADIENT_OUT_CH_SIZE[actLayer]-1)) && (gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1)) && (gradientOutColumnAddrBWDX == 0)) begin
                next_actLayer <= actLayer -1;
            end else begin
                next_actLayer <= actLayer;
            end 
        end
    end
end

always @ ( posedge clk )begin

    actLayer = next_actLayer;

end

/////////////////////////////// BW SIGNAL LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always @ (*) begin
    if( rst == 1)begin
        next_bw <= 0;
    end else begin
        if(bw == 0)begin
            if((actLayer == (NLAYER-1))&&(((featureInChAddrFW+8) == (FEATURE_IN_CH_SIZE[actLayer])) && (featureOutChAddrFW == (FEATURE_OUT_CH_SIZE[actLayer]-1)) && (featureOutRowAddrFW == (FEATURE_OUT_ROW_SIZE[actLayer]-1)) && (featureOutColumnAddrFW == 0))) begin
                next_bw <= 1;
            end else begin
                next_bw <= 0;
            end
        end else if ( bw == 1)begin
            if((featureInChAddrBWDK == (FEATURE_IN_CH_SIZE[actLayer]-1)) && (featureOutChAddrBWDK == (FEATURE_OUT_CH_SIZE[actLayer]-1)) && (featureInRowAddrBWDK == (FEATURE_IN_ROW_SIZE[actLayer]-1)) && (featureInColumnAddrBWDK == 0)) begin
                next_bw <= 2;
            end else begin
                next_bw <= 1;
            end
        end else if ( bw == 2) begin
            if(((gradientInChAddrBWDX+8) == (GRADIENT_IN_CH_SIZE[actLayer])) && (gradientOutChAddrBWDX == (GRADIENT_OUT_CH_SIZE[actLayer]-1)) && (gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1)) && (gradientOutColumnAddrBWDX == 0)) begin
                next_bw <= 1;
            end else begin
                next_bw <= 2;
            end
        end else begin
            next_bw <= 0;
        end
    end
end

always @ (posedge clk) begin
    bw <= next_bw;
end

//////////////////////////////// FW STATE MACHINE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// LOAD_KERNEL each 8*channel in are convolved 
// START 
// LOAD_KERNEL : 6* LOAD N_FEATURE_READ KERNEL
// LOAD_FEATURE : LOAD 3*N_FEATURE_READ PIXEL - LOAD N_FEATURE_READ KERNEL
// LOAD_FEATURE : LOAD 3*N_FEATURE_READ PIXEL - LOAD N_FEATURE_READ KERNEL
// LOAD_FEATURE : LOAD 3*N_FEATURE_READ PIXEL - LOAD N_FEATURE_READ KERNEL
// RUNNING :  MAC_ENABLE - ADDRESS MANAGER ENABLE ( EXECUTION ) * featureOutActRowSize * featureOutActColumnSize
// END OF SHEET OF FEATURE OUT - RESTART TO READ KERNEL

// HERE IS PRESENT THE LOGIC MANAGING WHEN THE KERNEL HAS TO BE LOADED AND WHEN NOT

    // Define states
    typedef enum logic [1:0] {
        LOAD_KERNEL = 2'b00,
        RUNNING = 2'b10

    } FW_FSM_t;

    // Define state register and next state variable
    FW_FSM_t state_reg, next_state;
    reg [3:0] kernelAddrRead,next_kernelAddrRead;

    // Define state update logic
    always_ff @(posedge clk or posedge rst) begin
        state_reg <= next_state; // Update state on clock edge
        kernelAddrRead <= next_kernelAddrRead;
    end

    // Define state transition logic
    always_ff @(*) begin
        if (rst == 1) begin
            next_state <= LOAD_KERNEL; // Initialize next state to S0 on reset
            next_kernelAddrRead <= 0;
        end else begin
            // Define state transitions based on current state
            if ( bw == 0)begin
            case (state_reg)
                LOAD_KERNEL: begin // The new kernel 8x3x3 is loaded. 
                    if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; 
                        next_kernelAddrRead <= 0;
                    end else begin
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= kernelAddrRead +1;
                    end
                end
        
                RUNNING : begin 
                    if((featureOutColumnAddrFW == 9) && (featureOutRowAddrFW == featureOutActRowSize)) begin
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= 0;
                    end else begin
                        next_state <= RUNNING;
                        next_kernelAddrRead <= 0;
                    end
                end
                default: begin 
                    next_state <= RUNNING; // Default to S0 (for safety)
                    next_kernelAddrRead <= 0;
                end
            endcase
            end else if ( bw == 1) begin 
                // If kernel gradient is calculated , the kernel is read at the end of the Dk calculus, when valid is risen
                case (state_reg)
                LOAD_KERNEL: begin
                    if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; 
                        next_kernelAddrRead <= 0;
                    end else begin
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= kernelAddrRead +1;
                    end
                end
        
                RUNNING : begin 
                    if((valid == 1)) begin
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= 0;
                    end else begin
                        next_state <= RUNNING;
                        next_kernelAddrRead <= 0;
                    end
                end
                default: begin
                    next_state <= LOAD_KERNEL; // Default to S0 (for safety)
                    next_kernelAddrRead <= 0;
                end
                endcase
            end else if ( bw == 2) begin
            case (state_reg)
                LOAD_KERNEL: begin // The new kernel 8x3x3 is loaded. T
                    if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; 
                        next_kernelAddrRead <= 0;
                    end else begin
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= kernelAddrRead +1;
                    end
                end
        
                RUNNING : begin 
                    if((gradientOutColumnAddrBWDX == 9) && (gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1))) begin
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= 0;
                    end else begin
                        next_state <= RUNNING;
                        next_kernelAddrRead <= 0;
                    end
                end
                default: begin
                    next_state <= LOAD_KERNEL; // Default to S0 (for safety)
                    next_kernelAddrRead <= 0;

                end
            endcase 
            end else begin
                next_state <= LOAD_KERNEL;
                next_kernelAddrRead <= 0;
            end
        end
    end
always @(*)begin
    if (bw == 0)begin
    case(state_reg)
        LOAD_KERNEL : begin
            if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin
                loadKernelFW <=1;
            end else begin
                loadKernelFW <=0;
            end
            loadKernelBWDX <=0;
        end
        RUNNING : begin 
            loadKernelFW <=0;
            loadKernelBWDX <=0;
        end
    endcase
    end else if ( bw == 2) begin
        case(state_reg)
        LOAD_KERNEL : begin
            if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin
                loadKernelBWDX <=1;
            end else begin
                loadKernelBWDX <=0;
            end
            loadKernelFW <=0;
        end
        RUNNING : begin 
            loadKernelFW <=0;
            loadKernelBWDX <=0;
        end
    endcase
    end else  begin
        loadKernelFW <= 0;
        loadKernelBWDX <= 0;
    end
end
    
////////////////////////////////////////// KERNEL MEMORY LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// kernel read enable and kernel read value register. Used to enable and read value from the matrix of SRAM.
// Due to unability to dynamic indexing, declared with maximum sizes then will be partially used
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)] kernelReadEn_r,kernelWriteEn_r;
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(NBITS-1):0] kernelReadValues_r;
reg [(NBITS-1):0] kernelWriteValue_r;
reg [0:(KERNEL_SIZE * KERNEL_SIZE -1)][(NBITS-1):0] dk_r;
// se siamo in LOAD_KERNEL status, allora leggiamoo i kernel e salviamo in buffer
// TODO : check sensitivity list. actually read wrongly the values
always @ (*) begin
    if ( state_reg == LOAD_KERNEL) begin
        if ( bw == 0) begin
            kernelValsFW[kernelAddrRead][(NBITS-1):0]           =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW]; // first channel in kernel 
            kernelValsFW[kernelAddrRead][(2*NBITS-1):(NBITS)]   =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+1]; // 2nd channel in kernel 
            kernelValsFW[kernelAddrRead][(3*NBITS-1):(2*NBITS)] =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+2]; // 3th channel in kernel 
            kernelValsFW[kernelAddrRead][(4*NBITS-1):(3*NBITS)] =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+3]; // 4th channel in kernel 
            kernelValsFW[kernelAddrRead][(5*NBITS-1):(4*NBITS)] =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+4]; // 5th channel in kernel 
            kernelValsFW[kernelAddrRead][(6*NBITS-1):(5*NBITS)] =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+5]; // 6th channel in kernel 
            kernelValsFW[kernelAddrRead][(7*NBITS-1):(6*NBITS)] =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+6]; // 7th channel in kernel 
            kernelValsFW[kernelAddrRead][(8*NBITS-1):(7*NBITS)] =  kernelReadValues_r[actLayer][featureOutChAddrFW][featureInChAddrFW+7]; // 8th channel in kernel 
            kernelWriteValue_r = 0;
            kernelBWDX = 0;
        end else if( bw == 1) begin
            // If we are in Dk, the actual valid DK is summed and written back in SRAM
            kernelValsFW = 0;
            kernelWriteValue_r          =  kernelReadValues_r[actLayer][featureOutChAddrBWDK][featureInChAddrBWDK] + dk_r[kernelAddrRead];
            kernelBWDX = 0;
        end else if ( bw == 2) begin
            // If we are in Dx, kernel is loaded as in forward. Is only chaned the PU port
            kernelValsFW = 0;
            kernelWriteValue_r = 0;
            kernelBWDX[kernelAddrRead][(NBITS-1):0]           =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX]; // first channel in kernel 
            kernelBWDX[kernelAddrRead][(2*NBITS-1):NBITS]     =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+1]; // 2nd channel in kernel 
            kernelBWDX[kernelAddrRead][(3*NBITS-1):(2*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+2]; // 3th channel in kernel 
            kernelBWDX[kernelAddrRead][(4*NBITS-1):(3*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+3]; // 4th channel in kernel 
            kernelBWDX[kernelAddrRead][(5*NBITS-1):(4*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+4]; // 5th channel in kernel 
            kernelBWDX[kernelAddrRead][(6*NBITS-1):(5*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+5]; // 6th channel in kernel 
            kernelBWDX[kernelAddrRead][(7*NBITS-1):(6*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+6]; // 7th channel in kernel 
            kernelBWDX[kernelAddrRead][(8*NBITS-1):(7*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrBWDX][gradientInChAddrBWDX+7]; // 8th channel in kernel         end else begin
        end else begin
            kernelValsFW = 0;
            kernelWriteValue_r = 0;
            kernelBWDX = 0;
        end
    end else begin
        kernelValsFW = 0;
        kernelWriteValue_r = 0;
        kernelBWDX = 0;
    end
end
// ENABLING KERNEL READING AND WRITING. IT DIFFER BY OPERATION ( FORWARD, DK AND DX GRADIENT CALCULATION)
always @ ( *) begin
    if(bw==0)begin
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            for(int kk=0; kk < FEATURE_IN_CH_SIZE[NLAYER-1]; kk=kk+8)begin
                if (state_reg == LOAD_KERNEL)begin // if we are loading the kernels
                    if((ii == (actLayer)) && (jj == (featureOutChAddrFW)) && (kk == (featureInChAddrFW)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                    kernelReadEn_r[ii][jj][kk]   = 1;
                    kernelReadEn_r[ii][jj][kk+1] = 1;
                    kernelReadEn_r[ii][jj][kk+2] = 1;
                    kernelReadEn_r[ii][jj][kk+3] = 1;
                    kernelReadEn_r[ii][jj][kk+4] = 1;
                    kernelReadEn_r[ii][jj][kk+5] = 1;
                    kernelReadEn_r[ii][jj][kk+6] = 1;
                    kernelReadEn_r[ii][jj][kk+7] = 1;

                    end else begin
                    kernelReadEn_r[ii][jj][kk]   = 0;
                    kernelReadEn_r[ii][jj][kk+1] = 0;
                    kernelReadEn_r[ii][jj][kk+2] = 0;
                    kernelReadEn_r[ii][jj][kk+3] = 0;
                    kernelReadEn_r[ii][jj][kk+4] = 0;
                    kernelReadEn_r[ii][jj][kk+5] = 0;
                    kernelReadEn_r[ii][jj][kk+6] = 0;
                    kernelReadEn_r[ii][jj][kk+7] = 0;
                    end
                end else begin // if we are not il loading kernel status, dont load anithing
                    kernelReadEn_r[ii][jj][kk]   = 0;
                    kernelReadEn_r[ii][jj][kk+1] = 0;
                    kernelReadEn_r[ii][jj][kk+2] = 0;
                    kernelReadEn_r[ii][jj][kk+3] = 0;
                    kernelReadEn_r[ii][jj][kk+4] = 0;
                    kernelReadEn_r[ii][jj][kk+5] = 0;
                    kernelReadEn_r[ii][jj][kk+6] = 0;
                    kernelReadEn_r[ii][jj][kk+7] = 0;
                end
                    kernelWriteEn_r[ii][jj][kk]   = 0;
                    kernelWriteEn_r[ii][jj][kk+1] = 0;
                    kernelWriteEn_r[ii][jj][kk+2] = 0;
                    kernelWriteEn_r[ii][jj][kk+3] = 0;
                    kernelWriteEn_r[ii][jj][kk+4] = 0;
                    kernelWriteEn_r[ii][jj][kk+5] = 0;
                    kernelWriteEn_r[ii][jj][kk+6] = 0;
                    kernelWriteEn_r[ii][jj][kk+7] = 0;
            end
        end
    end
    end else if ( bw == 1) begin
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
                for(int kk=0; kk < FEATURE_IN_CH_SIZE[NLAYER-1]; kk=kk+1)begin
                    if ( state_reg == LOAD_KERNEL )begin
                        // WHEN CALCULATION DK KERNEL IS READ AND WRITTEN BACK 
                        if((ii == (actLayer)) && (jj == (featureOutChAddrBWDK)) && (kk == (featureInChAddrBWDK)))begin
                            kernelReadEn_r[ii][jj][kk]   = 1;
                            kernelWriteEn_r[ii][jj][kk] = 1;
                        end else begin
                            kernelReadEn_r[ii][jj][kk]   = 0;
                            kernelWriteEn_r[ii][jj][kk] = 0;
                    end
                    end else begin
                        kernelReadEn_r[ii][jj][kk]   = 0;
                        kernelWriteEn_r[ii][jj][kk] = 0;
                    end
                end
            end
        end
    end else if ( bw == 2) begin
        // DURING DX CALCULATION , KERNEL IS READ AS IN FORWARD
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< GRADIENT_IN_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            for(int kk=0; kk < GRADIENT_OUT_CH_SIZE[NLAYER-1]; kk=kk+8)begin
                if (state_reg == LOAD_KERNEL)begin // if we are loading the kernels
                    if((ii == (actLayer)) && (jj == (gradientInChAddrBWDX)) && (kk == (gradientOutChAddrBWDX)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                        kernelReadEn_r[ii][jj][kk]   = 1;
                        kernelReadEn_r[ii][jj][kk+1] = 1;
                        kernelReadEn_r[ii][jj][kk+2] = 1;
                        kernelReadEn_r[ii][jj][kk+3] = 1;
                        kernelReadEn_r[ii][jj][kk+4] = 1;
                        kernelReadEn_r[ii][jj][kk+5] = 1;
                        kernelReadEn_r[ii][jj][kk+6] = 1;
                        kernelReadEn_r[ii][jj][kk+7] = 1;
                    end else begin
                        kernelReadEn_r[ii][jj][kk]   = 0;
                        kernelReadEn_r[ii][jj][kk+1] = 0;
                        kernelReadEn_r[ii][jj][kk+2] = 0;
                        kernelReadEn_r[ii][jj][kk+3] = 0;
                        kernelReadEn_r[ii][jj][kk+4] = 0;
                        kernelReadEn_r[ii][jj][kk+5] = 0;
                        kernelReadEn_r[ii][jj][kk+6] = 0;
                        kernelReadEn_r[ii][jj][kk+7] = 0;
                    end
                end else begin // if we are not il loading kernel status, dont load anithing
                    kernelReadEn_r[ii][jj][kk]   = 0;
                    kernelReadEn_r[ii][jj][kk+1] = 0;
                    kernelReadEn_r[ii][jj][kk+2] = 0;
                    kernelReadEn_r[ii][jj][kk+3] = 0;
                    kernelReadEn_r[ii][jj][kk+4] = 0;
                    kernelReadEn_r[ii][jj][kk+5] = 0;
                    kernelReadEn_r[ii][jj][kk+6] = 0;
                    kernelReadEn_r[ii][jj][kk+7] = 0;
                end
                kernelWriteEn_r[ii][jj][kk]   = 0;
                kernelWriteEn_r[ii][jj][kk+1] = 0;
                kernelWriteEn_r[ii][jj][kk+2] = 0;
                kernelWriteEn_r[ii][jj][kk+3] = 0;
                kernelWriteEn_r[ii][jj][kk+4] = 0;
                kernelWriteEn_r[ii][jj][kk+5] = 0;
                kernelWriteEn_r[ii][jj][kk+6] = 0;
                kernelWriteEn_r[ii][jj][kk+7] = 0;
            end
        end
    end
    end
end
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// KERNEL MEMORY \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////////
// KERNEL MEMORY : CHANNEL OUT * CHANNEL IN NUMBER OF MEMORY, EACH OF 16 WORDS( 9 USED ) OF 16 WORD LENGHT, THIS FOR EACH LAYER
// One 3x3 kernel for each memory. High unusage of memory
genvar i,j,k;
generate
    for (i=0;i < NLAYER; i= i+1) begin 
        for (j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1)begin
            for(k=0; k< FEATURE_IN_CH_SIZE[i]; k=k+1)begin
                SRAM # (.PORT_WIDTH(NBITS),.MEMORY_WIDHT(16))
                SRAMKijk(.writeAddr(kernelAddrRead),
                .readAddr(kernelAddrRead),
                .writeEn(kernelWriteEn_r[i][j][k]),
                .readEn(kernelReadEn_r[i][j][k]),
                .readValue(kernelReadValues_r[i][j][k]),
                .writeValue(kernelWriteValue_r),
                .clk(clk),
                .rst(rst));
            end
        end
    end
endgenerate





reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) + $clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1) :0] featureOutWriteAddrFW;
reg [(N_FEATURE_READ*NBITS-1):0] featureOutWriteValueFW;
reg [($clog2(FEATURE_IN_ROW_SIZE[0]) + $clog2(FEATURE_IN_COLUMN_SIZE[0]) -1) :0] featureInReadAddr_r;
// cè un alayer in piu solo per assegnazione comoda di sram in ciclo for. initilizzato
reg [0:(NLAYER)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(N_FEATURE_READ*NBITS-1):0] featureInReadValue_r;
reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] featureInBufferOfReadValueFW,next_featureInBufferOfReadValueFW; // buffer dove salviamo le tre righe lette e mandiamo i pixel alla PU. Ne abbiamo due perche mentre carichiamo i nuovi i vecchi dobbiamo ancora usarli
// cè una layer in piu che va assenato all'ultima sram ma che sara inutilizzato
reg [0:(NLAYER)][0: ( FEATURE_IN_CH_SIZE[NLAYER-1] -1)] featureInReadEn_r;
// read enable for feature in reading
always @ ( * ) begin 
    if(bw==0) begin // IF WE ARE IN FORWARD, READ 8 CHANNEL IN
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+8)begin
                if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] > 4)||((state_reg == LOAD_KERNEL) && (kernelAddrRead > 5)))begin // se mancano 3 clock al nuovo blocco di feature inizio a leggere
                    if((ii == actLayer) && (jj == featureInChAddrFW))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
                        featureInReadEn_r[ii][jj]   = 1;
                        featureInReadEn_r[ii][jj+1] = 1;
                        featureInReadEn_r[ii][jj+2] = 1;
                        featureInReadEn_r[ii][jj+3] = 1;
                        featureInReadEn_r[ii][jj+4] = 1;
                        featureInReadEn_r[ii][jj+5] = 1;
                        featureInReadEn_r[ii][jj+6] = 1;
                        featureInReadEn_r[ii][jj+7] = 1;
                    end else begin 
                        featureInReadEn_r[ii][jj]   = 0;
                        featureInReadEn_r[ii][jj+1] = 0;
                        featureInReadEn_r[ii][jj+2] = 0;
                        featureInReadEn_r[ii][jj+3] = 0;
                        featureInReadEn_r[ii][jj+4] = 0;
                        featureInReadEn_r[ii][jj+5] = 0;
                        featureInReadEn_r[ii][jj+6] = 0;
                        featureInReadEn_r[ii][jj+7] = 0;
                    end
                end else begin
                    featureInReadEn_r[ii][jj]   = 0;
                    featureInReadEn_r[ii][jj+1] = 0;
                    featureInReadEn_r[ii][jj+2] = 0;
                    featureInReadEn_r[ii][jj+3] = 0;
                    featureInReadEn_r[ii][jj+4] = 0;
                    featureInReadEn_r[ii][jj+5] = 0;
                    featureInReadEn_r[ii][jj+6] = 0;
                    featureInReadEn_r[ii][jj+7] = 0;
                end
            end
        end
    end else if ( bw == 1) begin // if we are in BACKWARD PROPAGATION, DK CALCULATION READ ONE CHANNEL AT A TIME
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+1)begin
                if((ii == actLayer) && (jj == featureInChAddrBWDK))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
                    featureInReadEn_r[ii][jj]   = 1;
                end else begin 
                    featureInReadEn_r[ii][jj]   = 0;
                end
            end
        end
    end else begin // if DX is calculated , feture is not needed
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            featureInReadEn_r[ii][jj]   = 0;
            end
        end 
    end
end
// GDumb read logic
assign featureInReadEnFWGDUMB = featureInReadEn_r[0][0]; // when we are on layer 0, enable read from external GDumb RAM
assign featureInReadAddrFWGDUMB = featureInReadAddr_r;
always @ (*)begin
    featureInReadValue_r[0][featureInChAddrFW]   = featureInReadValueFWGDUMB[0]; // the feature for layer 0 came from GDumb RAM
    featureInReadValue_r[0][featureInChAddrFW+1] = featureInReadValueFWGDUMB[1];
    featureInReadValue_r[0][featureInChAddrFW+2] = featureInReadValueFWGDUMB[2];
    featureInReadValue_r[0][featureInChAddrFW+3] = featureInReadValueFWGDUMB[3];
    featureInReadValue_r[0][featureInChAddrFW+4] = featureInReadValueFWGDUMB[4];
    featureInReadValue_r[0][featureInChAddrFW+5] = featureInReadValueFWGDUMB[5];
    featureInReadValue_r[0][featureInChAddrFW+6] = featureInReadValueFWGDUMB[6];
    featureInReadValue_r[0][featureInChAddrFW+7] = featureInReadValueFWGDUMB[7];
end
reg [0:(NLAYER-1)][0: ( FEATURE_OUT_CH_SIZE[NLAYER-1] -1)] featureOutWriteEnFW;

// write  enable for feature out writing
always @ ( * ) begin 
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if(bw==0)begin
                if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == (N_FEATURE_READ-1)) begin// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
                    if((ii == (actLayer)) && (jj == (featureOutChAddrFW)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                        featureOutWriteEnFW[ii][jj]   = 1;
                    end else begin 
                        featureOutWriteEnFW[ii][jj]   = 0;
                    end
                end else begin
                        featureOutWriteEnFW[ii][jj]   = 0;
                end
            end else begin
                featureOutWriteEnFW[ii][jj]   = 0;
            end
        end
    end
end
// LOGICA PER CARICARE NEI 3 CICLI PRECEDENTI I TRE NUOVI GRUPPI DI PIXEL
always @(*)begin
    if(bw==0)begin
        if(state_reg == RUNNING)begin // TODO : controllo kernelAddrRead in state reg running non ha senso
            if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 5)||(kernelAddrRead == 6))begin // carichiamo primo pixel
             // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer])
                featureInReadAddr_r = (featureOutRowAddrFW+1 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW;
            end else begin
                featureInReadAddr_r = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW +8;
            end
            next_featureInBufferOfReadValueFW[0][0] = featureInReadValue_r[actLayer][featureInChAddrFW]; // save 8 channel of first row
            next_featureInBufferOfReadValueFW[0][1] = featureInReadValue_r[actLayer][featureInChAddrFW+1];
            next_featureInBufferOfReadValueFW[0][2] = featureInReadValue_r[actLayer][featureInChAddrFW+2];
            next_featureInBufferOfReadValueFW[0][3] = featureInReadValue_r[actLayer][featureInChAddrFW+3];
            next_featureInBufferOfReadValueFW[0][4] = featureInReadValue_r[actLayer][featureInChAddrFW+4];
            next_featureInBufferOfReadValueFW[0][5] = featureInReadValue_r[actLayer][featureInChAddrFW+5];
            next_featureInBufferOfReadValueFW[0][6] = featureInReadValue_r[actLayer][featureInChAddrFW+6];
            next_featureInBufferOfReadValueFW[0][7] = featureInReadValue_r[actLayer][featureInChAddrFW+7];
        end else if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 6)||(kernelAddrRead == 7))begin 
            // SAve check as above. In this case we also sum 1 to row
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer]) begin
                featureInReadAddr_r = (featureOutRowAddrFW+2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW;
            end else begin
                featureInReadAddr_r = (featureOutRowAddrFW+1 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW +8;
            end            
            next_featureInBufferOfReadValueFW[1][0] = featureInReadValue_r[actLayer][featureInChAddrFW]; // save 8 channel of second row
            next_featureInBufferOfReadValueFW[1][1] = featureInReadValue_r[actLayer][featureInChAddrFW+1];
            next_featureInBufferOfReadValueFW[1][2] = featureInReadValue_r[actLayer][featureInChAddrFW+2];
            next_featureInBufferOfReadValueFW[1][3] = featureInReadValue_r[actLayer][featureInChAddrFW+3];
            next_featureInBufferOfReadValueFW[1][4] = featureInReadValue_r[actLayer][featureInChAddrFW+4];
            next_featureInBufferOfReadValueFW[1][5] = featureInReadValue_r[actLayer][featureInChAddrFW+5];
            next_featureInBufferOfReadValueFW[1][6] = featureInReadValue_r[actLayer][featureInChAddrFW+6];
            next_featureInBufferOfReadValueFW[1][7] = featureInReadValue_r[actLayer][featureInChAddrFW+7];
        end else if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 7)||(kernelAddrRead == 8))begin 
            // same reason as above
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer]) begin
                featureInReadAddr_r = (featureOutRowAddrFW+3 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW;
            end else begin
                featureInReadAddr_r = (featureOutRowAddrFW+2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW +8;
            end             
            next_featureInBufferOfReadValueFW[2][0] = featureInReadValue_r[actLayer][featureInChAddrFW]; // save 8 channel of third row
            next_featureInBufferOfReadValueFW[2][1] = featureInReadValue_r[actLayer][featureInChAddrFW+1];
            next_featureInBufferOfReadValueFW[2][2] = featureInReadValue_r[actLayer][featureInChAddrFW+2];
            next_featureInBufferOfReadValueFW[2][3] = featureInReadValue_r[actLayer][featureInChAddrFW+3];
            next_featureInBufferOfReadValueFW[2][4] = featureInReadValue_r[actLayer][featureInChAddrFW+4];
            next_featureInBufferOfReadValueFW[2][5] = featureInReadValue_r[actLayer][featureInChAddrFW+5];
            next_featureInBufferOfReadValueFW[2][6] = featureInReadValue_r[actLayer][featureInChAddrFW+6]; 
            next_featureInBufferOfReadValueFW[2][7] = featureInReadValue_r[actLayer][featureInChAddrFW+7];
        end else begin
            featureInReadAddr_r = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureOutColumnAddrFW+8; // default . 
        end
    end else if ( bw == 1) begin // if we are in bw
        // no fetching of data, the data is read and used in the same cycle
        featureInReadAddr_r = (featureInRowAddrBWDK << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])))+featureInColumnAddrBWDK;
        // One channel only is read, assigned to featureInBWDK port of FW_BW_PU
        featureInBWDK = featureInReadValue_r[actLayer][featureInChAddrBWDK]; 
    end 
end
// FEATURE OUT WRITE value 
always @ (*)begin
    if ( bw == 0)
        if (featureOutColumnAddrFW[2:0] == 0)begin // if we are calculated 8 feature out, for the new cycle , reset the buffer
            if (featureOutRowAddrFW[0] == 0)begin
                featureOutWriteValueFW = {{(7*NBITS){1'b0}},featureOutValFWActivated} ;
            end else begin 
                featureOutWriteValueFW = {featureOutValFWActivated,{(7*NBITS){1'b0}}} ;
            end
        end else begin // otherwise continue to load the buffer
            featureOutWriteValueFW = featureOutWriteValueFW | (featureOutValFWActivated << (NBITS*featureOutColumnAddrFW[2:0])); // filling of write out buffer
        end 
end


// update of feature in buffer
always @ (*) begin
    if(bw==0)begin
    if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 0)begin // new 8 feature are loaded
        featureInBufferOfReadValueFW = next_featureInBufferOfReadValueFW;
    end
    end
end
// Activation layer : module to apply activation to pixel 
activation # (.act_rule(ACTIVATION)) activation (.input_value(featureOutValFW),.output_value(featureOutValFWActivated));
// load FW PU from buffers
always @ (*)begin
    if(bw==0)begin
    featureInP1FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[0][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInP1FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[0][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[0][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[0][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[0][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[0][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[0][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[0][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 

    featureInP2FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[1][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInP2FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[1][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[1][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[1][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[1][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[1][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[1][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[1][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 

    featureInP3FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInP3FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    end 
end

// FEATURE OUT WRITE ADDRESS COMPOSITION
always @(*) begin
    featureOutWriteAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer])-1))+featureOutColumnAddrFW; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
end



///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// FEATURE OUT MEMORY \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////////
// FEATURE OUT MEMORY : CHANNEL OUT NUMBER OF MEMORY, EACH OF #ROWS*(#CLOUMN/8) WORDS OF 16*8= 128 BIT OF WORD LENGHT

generate
    for(i=0; i < NLAYER; i= i+1)begin
        for(j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1) begin
            SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),.MEMORY_WIDHT(FEATURE_OUT_ROW_SIZE[i]*(FEATURE_OUT_COLUMN_SIZE[i]/N_FEATURE_READ)))
                SRAMFij(.writeAddr(featureOutWriteAddrFW[($clog2(FEATURE_OUT_ROW_SIZE[i]) + $clog2(FEATURE_OUT_COLUMN_SIZE[i]) -1) :$clog2(N_FEATURE_READ)]),// we cut the last 3 bit due to port wirdht of N:FEATURE_READ*NBITS
                        .readAddr(featureInReadAddr_r[($clog2(FEATURE_IN_ROW_SIZE[i]) + $clog2(FEATURE_IN_COLUMN_SIZE[i]) -1) :$clog2(N_FEATURE_READ)]),// we cut the last 3 bit due to port wirdht of N:FEATURE_READ*NBITS
                        .writeEn(featureOutWriteEnFW[i][j]),
                        .readEn(featureInReadEn_r[i+1][j]),
                        .readValue(featureInReadValue_r[i+1][j]),
                        .writeValue(featureOutWriteValueFW),
                        .clk(clk),
                        .rst(rst));
            end
        end
endgenerate
// Assign the size of the feature of the layer
always @(*)begin
    featureInActChSize = FEATURE_IN_CH_SIZE[actLayer]-1;
    featureOutActChSize = FEATURE_OUT_CH_SIZE[actLayer]-1;
    featureOutActRowSize = FEATURE_OUT_ROW_SIZE[actLayer]-1;
    featureOutActColumnSize = FEATURE_OUT_COLUMN_SIZE[actLayer]-1;
end
////////////////////////////// GRADIENT PROPAGATION LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\
reg [0: (GRADIENT_OUT_CH_SIZE[0]-1)]gradientInReadEn_r,gradientOutWriteEn_r;
reg [0: (GRADIENT_OUT_CH_SIZE[0]-1)][(NBITS*N_FEATURE_READ-1):0]gradientInReadValue_r;
reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] gradientInBufferOfReadValue,next_gradientInBufferOfReadValue;
reg [($clog2(GRADIENT_IN_ROW_SIZE[0]) + $clog2(GRADIENT_IN_COLUMN_SIZE[0]/N_FEATURE_READ) -1) :0]gradientInReadAddr_r;

// READ GRADIENT ENABLE
always @(*) begin
    for ( int jj = 0; jj < FEATURE_OUT_CH_SIZE[0]; jj=jj+1)begin
        if ( bw == 0)begin // Forward operation , no read over gradient memory
            gradientInReadEn_r[jj]=0;
        end else if ( bw == 1 ) begin // if dk calculation , read given dk channel
            if(featureOutChAddrBWDK == jj)begin
                gradientInReadEn_r[jj]=1;
            end else begin
                gradientInReadEn_r[jj]=0;       
            end
        end else if ( bw == 2 ) begin // if dx, read of dx channel
            if(gradientInChAddrBWDX == jj)begin
                gradientInReadEn_r[jj]=1;
            end else begin
                gradientInReadEn_r[jj]=0;       
            end
        end else begin // default . dont read
            gradientInReadEn_r[jj]=0;
        end
    end
end
// WRITE GRADIENT ENABLE
always @ ( * ) begin 
        for (int jj=0; jj< GRADIENT_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if(bw==2)begin
                if(gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 0) begin// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
                    if(jj == (gradientOutChAddrBWDX-1))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                        gradientOutWriteEn_r[jj]   = 1;
                    end else begin 
                        gradientOutWriteEn_r[jj]   = 0;
                    end
                end else begin
                        gradientOutWriteEn_r[jj]   = 0;
                end
            end else begin
                gradientOutWriteEn_r[jj]   = 0;
            end
        end
end
reg [(N_FEATURE_READ*NBITS-1):0] gradientOutWriteValue;
// GRADIENT OUT BUFFER FILL
always @ (*)begin  
    if( bw == 2)begin
        if (gradientOutColumnAddrBWDX[2:0] == 0)begin // if we are calculated 8 gradient out, for the new cycle , reset the buffer
            gradientOutWriteValue = {{(7*NBITS){1'b0}},dxBWDX} ;
        end else begin // otherwise continue to load the buffer
            gradientOutWriteValue = gradientOutWriteValue | (dxBWDX << (NBITS*gradientOutColumnAddrBWDX[2:0])); // filling of write out buffer
        end     end else begin
        gradientOutWriteValue = 0;
    end
end

// PU GRADIENT IN ASSIGN FOR DK CALCULATION
always @(*)begin
    dyBWDK = gradientInReadValue_r[featureOutChAddrBWDK];
end

// DK READ FROM PU
always @(*)begin
    if(valid == 1)begin
        dk_r[0] = dkBWDK[0][0]; 
        dk_r[1] = dkBWDK[0][1]; 
        dk_r[2] = dkBWDK[0][2]; 
        dk_r[3] = dkBWDK[1][0]; 
        dk_r[4] = dkBWDK[1][1]; 
        dk_r[5] = dkBWDK[1][2]; 
        dk_r[6] = dkBWDK[2][0]; 
        dk_r[7] = dkBWDK[2][1]; 
        dk_r[8] = dkBWDK[2][2]; 
    end
end

// FEATURE OUT WRITE ADDRESS COMPOSITION
reg [($clog2(GRADIENT_OUT_ROW_SIZE[0]) + $clog2(GRADIENT_OUT_COLUMN_SIZE[0]/N_FEATURE_READ) -1) :0]  gradientOutWriteAddr_r;
always @(*) begin
    gradientOutWriteAddr_r = (gradientOutRowAddrBWDX << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
end
always @ (*) begin
    if(bw == 1)begin 
        gradientInReadAddr_r = featureInReadAddr_r;
    end 
end
// GRADIENT IN BUFFER FILLING  AND WRITE/READ ADDRESS ASSIGNATION
always @( *)begin
    if (bw == 2) begin
        if(state_reg == RUNNING)begin
            if((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 5)||(kernelAddrRead == 6))begin // carichiamo primo pixel
            // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
                if((gradientOutColumnAddrBWDX+7) > GRADIENT_OUT_COLUMN_SIZE[actLayer])begin
                    gradientInReadAddr_r = (gradientOutRowAddrBWDX+1 << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX;
                end else begin
                    gradientInReadAddr_r = (gradientOutRowAddrBWDX << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX +8;
                end
                next_gradientInBufferOfReadValue[0][0] = gradientInReadValue_r[gradientInChAddrBWDX]; // save 8 channel of first row
                next_gradientInBufferOfReadValue[0][1] = gradientInReadValue_r[gradientInChAddrBWDX+1];
                next_gradientInBufferOfReadValue[0][2] = gradientInReadValue_r[gradientInChAddrBWDX+2];
                next_gradientInBufferOfReadValue[0][3] = gradientInReadValue_r[gradientInChAddrBWDX+3];
                next_gradientInBufferOfReadValue[0][4] = gradientInReadValue_r[gradientInChAddrBWDX+4];
                next_gradientInBufferOfReadValue[0][5] = gradientInReadValue_r[gradientInChAddrBWDX+5];
                next_gradientInBufferOfReadValue[0][6] = gradientInReadValue_r[gradientInChAddrBWDX+6];
                next_gradientInBufferOfReadValue[0][7] = gradientInReadValue_r[gradientInChAddrBWDX+7];
            end else if((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 6)||(kernelAddrRead == 7))begin 
                // SAve check as above. In this case we also sum 1 to row
                if((gradientOutColumnAddrBWDX+7) > GRADIENT_OUT_COLUMN_SIZE[actLayer]) begin
                    gradientInReadAddr_r = (gradientOutRowAddrBWDX+2 << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX;
                end else begin
                    gradientInReadAddr_r = (gradientOutRowAddrBWDX+1 << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX +8;
                end            
                next_gradientInBufferOfReadValue[1][0] = gradientInReadValue_r[gradientInChAddrBWDX]; // save 8 channel of second row
                next_gradientInBufferOfReadValue[1][1] = gradientInReadValue_r[gradientInChAddrBWDX+1];
                next_gradientInBufferOfReadValue[1][2] = gradientInReadValue_r[gradientInChAddrBWDX+2];
                next_gradientInBufferOfReadValue[1][3] = gradientInReadValue_r[gradientInChAddrBWDX+3];
                next_gradientInBufferOfReadValue[1][4] = gradientInReadValue_r[gradientInChAddrBWDX+4];
                next_gradientInBufferOfReadValue[1][5] = gradientInReadValue_r[gradientInChAddrBWDX+5];
                next_gradientInBufferOfReadValue[1][6] = gradientInReadValue_r[gradientInChAddrBWDX+6];
                next_gradientInBufferOfReadValue[1][7] = gradientInReadValue_r[gradientInChAddrBWDX+7];
            end else if((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 7)||(kernelAddrRead == 8))begin 
                // same reason as above
                if((gradientOutColumnAddrBWDX+7) > GRADIENT_OUT_COLUMN_SIZE[actLayer]) begin
                    gradientInReadAddr_r = (gradientOutRowAddrBWDX+3 << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX;
                end else begin
                    gradientInReadAddr_r = (gradientOutRowAddrBWDX+2 << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX +8;
                end             
                next_gradientInBufferOfReadValue[2][0] = gradientInReadValue_r[gradientInChAddrBWDX]; // save 8 channel of third row
                next_gradientInBufferOfReadValue[2][1] = gradientInReadValue_r[gradientInChAddrBWDX+1];
                next_gradientInBufferOfReadValue[2][2] = gradientInReadValue_r[gradientInChAddrBWDX+2];
                next_gradientInBufferOfReadValue[2][3] = gradientInReadValue_r[gradientInChAddrBWDX+3];
                next_gradientInBufferOfReadValue[2][4] = gradientInReadValue_r[gradientInChAddrBWDX+4];
                next_gradientInBufferOfReadValue[2][5] = gradientInReadValue_r[gradientInChAddrBWDX+5];
                next_gradientInBufferOfReadValue[2][6] = gradientInReadValue_r[gradientInChAddrBWDX+6]; 
                next_gradientInBufferOfReadValue[2][7] = gradientInReadValue_r[gradientInChAddrBWDX+7];
            end else begin
                gradientInReadAddr_r = (gradientOutRowAddrBWDX << ($clog2(GRADIENT_OUT_ROW_SIZE[actLayer])))+gradientOutColumnAddrBWDX+8; // default . 
                next_gradientInBufferOfReadValue = 0;
            end
        end
    end
end
// GRADIENT BUFFER UPDATE
always @ (*) begin
    if(bw==2)begin
        if(gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 0)begin // new 8 gradient are loaded
            gradientInBufferOfReadValue = next_gradientInBufferOfReadValue;
        end 
    end
end
// GRADIENT IN PIXEL TO PU ASSIGNATION
always @ (*)begin
    if (bw == 2)begin
    DyP1BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[0][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the gradient  pixel given the actual column address
    DyP1BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[0][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP1BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[0][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP1BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[0][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP1BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[0][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP1BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[0][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP1BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[0][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP1BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[0][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 

    DyP2BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[1][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the gradient pixel given the actual column address
    DyP2BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[1][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP2BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[1][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP2BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[1][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP2BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[1][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP2BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[1][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP2BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[1][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP2BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[1][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 

    DyP3BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the gradient pixel given the actual column address
    DyP3BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP3BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP3BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP3BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP3BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP3BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    DyP3BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
    end
end
/////////////////////////////// GRADIENT PROPAGATION MEMORY \\\\\\\\\\\\\\\\\\\\
for(j=0; j< GRADIENT_OUT_CH_SIZE[0]; j=j+1) begin
SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),.MEMORY_WIDHT(GRADIENT_OUT_ROW_SIZE[0]*(GRADIENT_OUT_COLUMN_SIZE[0]/N_FEATURE_READ)))
SRAMdx (.writeAddr(gradientOutWriteAddr_r),
        .readAddr(gradientInReadAddr_r),
        .writeEn(gradientOutWriteEn_r[j]),
        .readEn(gradientInReadEn_r[j]),
        .readValue(gradientInReadValue_r[j]),
        .writeValue(gradientOutWriteValue),
        .clk(clk),
        .rst(rst));
end
endmodule
