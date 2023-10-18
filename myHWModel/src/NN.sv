// Define the module instance
// TODO : HAS TO BE ASSIGNED bw 
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
    parameter N_FEATURE_READ = 8
    parameter string ACTIVATION = "RELU"

)// TODO create logic to read from GDUMB RAM at first layer
(
    output [0:9]featureInReadAddrFWGDUMB, // address of the feature
    output featureInReadEnFWGDUMB, // Enable of GDUMB RAM memory. It read on all channels ( 3 extendet to 8 just for compatibility), always port widht of 8*NBITS, so same logic as SRAM
    input [0:7][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFWGDUMB
);


    // Define signals
    reg bw;
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
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrFW;
    // 3 new pixels needed by MAC in forward computation
    reg [(NBITS*N_OF_CH_READ-1):0] featureInP1FW, featureInP2FW, featureInP3FW;
    // address of feature out : channel column and row. Column and row is used also by feature in for indexing. channel is used also to index the kernel
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrFW;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrFW;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrFW;
    // pixel of feature out : result of 3d convolution
    reg [(NBITS-1):0] featureOutValFW,featureOutValFWActivated;
    // BW signals : indexing of DK ( channel in, out , row and column.)
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrBWDk;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrBWDk;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrBWDk;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrBWDk;
    // 8 pixel used for dk calculation 
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] featureInBW;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] dyBW;
    // dk output
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dkBW;
    // flag: is 1 when dkBW is valid and can be stored( used to modify kernels)
    reg valid;
    // DX SIGNALS 
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] kernelBWDX;
    reg [(NBITS*N_OF_CH_READ-1):0] DyP1BWDY,DyP2BWDY,DyP3BWDY;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0]dxBWDX;
    // DX address signals
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] gradientInChAddrBWDX;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] gradinetOutChAddrBWDX;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] gradientOutRowAddrBWDX;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] gradientOutColumnAddrBWDX; 
    reg loadKernelBWDX;
    reg [0:($clog2(NLAYER)-1)]actLayer;

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
        .featureOutRowAddrFW(featureOutRowAddrFW),
        .featureOutColumnAddrFW(featureOutColumnAddrFW),
        .featureOutValFW(featureOutValFW),
        .featureInChAddrBWDk(featureInChAddrBWDk),
        .featureOutChAddrBWDk(featureOutChAddrBWDk),
        .featureOutRowAddrBWDk(featureOutRowAddrBWDk),
        .featureOutColumnAddrBWDk(featureOutColumnAddrBWDk),
        .featureInBW(featureInBW),
        .dyBW(dyBW),
        .dkBW(dkBW),
        .valid(valid),
        .kernelBWDX(kernelBWDX)
        ,.DyP1BWDX(DyP1BWDX)
        ,.DyP2BWDX(DyP2BWDX)
        ,.DyP3BWDX(DyP3BWDX)
        ,.dxBWDX(dxBWDX)
        ,.gradientInChAddrBWDX(gradientInChAddrBWDX)
        ,.gradinetOutChAddrBWDX(gradinetOutChAddrBWDX)
        ,.gradientOutRowAddrBWDX(gradientOutRowAddrBWDX)
        ,.gradientOutColumnAddrBWDX(gradientOutColumnAddrBWDX)
        ,.loadKernelBWDX(loadKernelBWDX)

    );
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
    reg [1:0] featureLoadedCnt, next_featureLoadedCnt;

    // Define state update logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= LOAD_KERNEL; // Initialize state to S0 on reset
            featureLoadedCnt <= 0;
            kernelAddrRead <= 0;
        end else begin
            state_reg <= next_state; // Update state on clock edge
            featureLoadedCnt <= next_featureLoadedCnt;
            kernelAddrRead <= next_kernelAddrRead;
        end
    end

    // Define state transition logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            next_state <= LOAD_KERNEL; // Initialize next state to S0 on reset
            loadKernelFW <= 0;
        end else begin
            // Define state transitions based on current state
            if ( bw == 0)begin
            case (state_reg)
                LOAD_KERNEL: begin // The new kernel 8x3x3 is loaded. TODO : apply fetching also to kernel
                    if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; 
                        loadKernelFW <= 1; // start loading kernel into PU
                    end else begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0; // stop loading kernel
                    end
                end
        
                RUNNING : begin 
                    if((featureOutColumnAddrFW == 0) && (featureOutRowAddrFW == (featureOutActRowSize))) begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0;
                    end else begin
                        next_state <= RUNNING;
                        loadKernelFW <= 0;
                    end
                end
                default: next_state <= LOAD_KERNEL; // Default to S0 (for safety)
            endcase
            end else if ( bw == 1) begin 
                // If kernel gradient is calculated , the kernel is read at the end of the Dk calculus, when valid is risen
                case (state_reg)
                LOAD_KERNEL: begin
                    if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; 
                        loadKernelFW <= 0; // IT REMAINS ZERO BECAUSE KERNEL IS NOT LOADED INTO PU
                    end else begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0; 
                    end
                end
        
                RUNNING : begin 
                    if((valid == 1)) begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0;
                    end else begin
                        next_state <= RUNNING;
                        loadKernelFW <= 0;
                    end
                end
                default: next_state <= LOAD_KERNEL; // Default to S0 (for safety)
                endcase
            end else if ( bw == 2) begin
            case (state_reg)
                LOAD_KERNEL: begin // The new kernel 8x3x3 is loaded. TODO : apply fetching also to kernel
                    if (kernelAddrRead == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; 
                        loadKernelFW <= 1; // start loading kernel into PU
                    end else begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0; // stop loading kernel
                    end
                end
        
                RUNNING : begin 
                    if((featureOutColumnAddrFW == 0) && (featureOutRowAddrFW == (featureOutActRowSize))) begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0;
                    end else begin
                        next_state <= RUNNING;
                        loadKernelFW <= 0;
                    end
                end
                default: next_state <= LOAD_KERNEL; // Default to S0 (for safety)
            endcase 
            end
        end
    end
    always @ ( *) begin
        case (state_reg)
            LOAD_KERNEL: begin
               next_kernelAddrRead <= kernelAddrRead +1;  // count the number of kernel pixel loaded
            end
        
            RUNNING : begin 
                next_kernelAddrRead <= 0; // working operation, feature loaded while computing feature out 
            end
                
            endcase
    end
////////////////////////////////////////// KERNEL MEMORY LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// kernel read enable and kernel read value register. Used to enable and read value from the matrix of SRAM.
// Due to unability to dynamic indexing, declared with maximum sizes then will be partially used
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)] kernelReadEn_r,kernelWriteEn_r;
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(NBITS-1):0] kernelReadValues_r;
reg [(NBITS-1):0] kernelWriteValue_r;
// se siamo in LOAD_KERNEL status, allora leggiamoo i kernel e salviamo in buffer
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
        end else if( bw == 1) begin
            // If we are in Dk, the actual valid DK is summed and written back in SRAM
            kernelWriteValue_r          =  kernelReadValues_r[actLayer][featureOutChAddrBWDk][featureInChAddrBWDk] + dk_r[kernelAddrRead];
        end else if ( bw == 2) begin
            // If we are in Dx, kernel is loaded as in forward. Is only chaned the PU port
            dxBWDX[kernelAddrRead][(NBITS-1):0]           =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW]; // first channel in kernel 
            dxBWDX[kernelAddrRead][(2*NBITS-1):(NBITS)]   =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+1]; // 2nd channel in kernel 
            dxBWDX[kernelAddrRead][(3*NBITS-1):(2*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+2]; // 3th channel in kernel 
            dxBWDX[kernelAddrRead][(4*NBITS-1):(3*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+3]; // 4th channel in kernel 
            dxBWDX[kernelAddrRead][(5*NBITS-1):(4*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+4]; // 5th channel in kernel 
            dxBWDX[kernelAddrRead][(6*NBITS-1):(5*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+5]; // 6th channel in kernel 
            dxBWDX[kernelAddrRead][(7*NBITS-1):(6*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+6]; // 7th channel in kernel 
            dxBWDX[kernelAddrRead][(8*NBITS-1):(7*NBITS)] =  kernelReadValues_r[actLayer][gradientOutChAddrFW][gradientInChAddrFW+7]; // 8th channel in kernel         end else begin
        end
    end
end
// ENABLIG KERNEL READING AND WRITING. IT DIFFER BY OPERATION ( FORWARD, DK AND DX GRADIENT CALCULATION)
always @ ( *) begin
    if(bw==0)begin
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            for(int kk=0; kk < FEATURE_IN_CH_SIZE[NLAYER-1]; kk=kk+8)begin
                if (state_reg == LOAD_KERNEL)begin // if we are loading the kernels
                    if((ii == (actLayer-1)) && (jj == (featureOutChAddrFW-1)) && (kk == (featureInChAddrFW-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
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
                        if((ii == (actLayer-1)) && (jj == (featureOutChAddrBWDk-1)) && (kk == (featureInChAddrBWDk-1)))begin
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
        for (int jj=0; jj< GRADEINT_IN_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            for(int kk=0; kk < GRADIENT_OUT_CH_SIZE[NLAYER-1]; kk=kk+8)begin
                if (state_reg == LOAD_KERNEL)begin // if we are loading the kernels
                    if((ii == (actLayer-1)) && (jj == (gradientInChAddr-1)) && (kk == (gradientOutChAddr-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
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
                .writeEn(kernelWriteEn_r),
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
reg [0:(NLAYER)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(N_FEATURE_READ*NBITS-1):0] featureInReadValue_r;// cè un alayer in piu solo per assegnazione comoda di sram in ciclo for. initilizzato
reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] featureInBufferOfReadValueFW,next_featureInBufferOfReadValueFW; // buffer dove salviamo le tre righe lette e mandiamo i pixel alla PU. Ne abbiamo due perche mentre carichiamo i nuovi i vecchi dobbiamo ancora usarli

reg [0:(NLAYER)][0: ( FEATURE_IN_CH_SIZE[NLAYER-1] -1)] featureInReadEn_r;// cè una layer in piu che va assenato all'ultima sram ma che sara inutilizzato
// read enable for feature in reading
always @ ( * ) begin 
    if(bw==0) begin // IF WE ARE IN FORWARD, READ 8 CHANNEL IN
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+8)begin
                if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] > 4)||((state_reg == LOAD_KERNEL) && (kernelAddrRead > 5)))begin // se mancano 3 clock al nuovo blocco di feature inizio a leggere
                    if((ii == (actLayer)) && (jj == (featureInChAddrFW-1)))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
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
                if((ii == (actLayer)) && (jj == (featureOutColumnAddrBWDk-1)))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
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
    featureInReadValue_r[0][featureInChAddrFW] = featureInReadValueFWGDUMB[0]; // the feature for layer 0 came from GDumb RAM
    featureInReadValue_r[0][featureInChAddrFW+1] = featureInReadValueFWGDUMB[1];
    featureInReadValue_r[0][featureInChAddrFW+2] = featureInReadValueFWGDUMB[2];
    featureInReadValue_r[0][featureInChAddrFW+3] = featureInReadValueFWGDUMB[3];
    featureInReadValue_r[0][featureInChAddrFW+4] = featureInReadValueFWGDUMB[4];
    featureInReadValue_r[0][featureInChAddrFW+5] = featureInReadValueFWGDUMB[5];
    featureInReadValue_r[0][featureInChAddrFW+6] = featureInReadValueFWGDUMB[6];
    featureInReadValue_r[0][featureInChAddrFW+7] = featureInReadValueFWGDUMB[7];
end
reg [0:(NLAYER)][0: ( FEATURE_OUT_CH_SIZE[NLAYER-1] -1)] featureOutWriteEnFW;

// write  enable for feature out writing
always @ ( * ) begin 
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if(bw==0)begin
                if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 0) begin// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
                    if((ii == (actLayer)) && (jj == (featureOutChAddrFW-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
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
        if(state_reg == RUNNING)begin
            if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 5)||(kernelAddrRead == 6))begin // carichiamo primo pixel
             // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer-1])
                featureInReadAddr_r = (featureOutRowAddrFW+1 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW;
            end else begin
                featureInReadAddr_r = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW +8;
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
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer-1]) begin
                featureInReadAddr_r = (featureOutRowAddrFW+2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW;
            end else begin
                featureInReadAddr_r = (featureOutRowAddrFW+1 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW +8;
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
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer-1]) begin
                featureInReadAddr_r = (featureOutRowAddrFW+3 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW;
            end else begin
                featureInReadAddr_r = (featureOutRowAddrFW+2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW +8;
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
            featureInReadAddr_r = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW+8; // default . TODO : prova a lasciare vuoto
        end
        if (featureOutColumnAddrFW[2:0] == 0)begin // if we are calculated 8 feature out, for the new cycle , reset the buffer
            featureOutWriteValueFW = {{(7*NBITS){1'b0}},featureOutValFWActivated} ;
        end else begin // otherwise continue to load the buffer
            featureOutWriteValueFW = featureOutWriteValueFW | (featureOutValFWActivated << (NBITS*featureOutColumnAddrFW[2:0])); // filling of write out buffer
        end 
    end else if ( bw == 1) begin // if we are in bw
        // no fetching of data, the data is read and used in the same cycle
        featureInReadAddr_r = (featureOutRowAddrBWDk << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrBWDk;
        // One channel only is read, assigned to featureInBW port of FW_BW_PU
        featureInBW = featureInReadValue_r[actLayer][featureInChAddrBWDk]; 
    end 
end
always @ (*)begin
    if ( bw == 0)
        if (featureOutColumnAddrFW[2:0] == 0)begin // if we are calculated 8 feature out, for the new cycle , reset the buffer
            featureOutWriteValueFW = {{(7*NBITS){1'b0}},featureOutValFWActivated} ;
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
activation # (.act_rule(ACTIVATION)) activation (.valueInput(featureOutValFW),.valueOutput(featureOutValFWActivated));
// load FW PU from buffers
always @ (*)begin
    if(bw==0)begin
    featureInP1FW = featureInBufferOfReadValueFW[0][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInP1FW = featureInBufferOfReadValueFW[0][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW = featureInBufferOfReadValueFW[0][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW = featureInBufferOfReadValueFW[0][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW = featureInBufferOfReadValueFW[0][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW = featureInBufferOfReadValueFW[0][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW = featureInBufferOfReadValueFW[0][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP1FW = featureInBufferOfReadValueFW[0][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 

    featureInP2FW = featureInBufferOfReadValueFW[1][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInP2FW = featureInBufferOfReadValueFW[1][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW = featureInBufferOfReadValueFW[1][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW = featureInBufferOfReadValueFW[1][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW = featureInBufferOfReadValueFW[1][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW = featureInBufferOfReadValueFW[1][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW = featureInBufferOfReadValueFW[1][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP2FW = featureInBufferOfReadValueFW[1][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 

    featureInP3FW = featureInBufferOfReadValueFW[2][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInP3FW = featureInBufferOfReadValueFW[2][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW = featureInBufferOfReadValueFW[2][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW = featureInBufferOfReadValueFW[2][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW = featureInBufferOfReadValueFW[2][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW = featureInBufferOfReadValueFW[2][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW = featureInBufferOfReadValueFW[2][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    featureInP3FW = featureInBufferOfReadValueFW[2][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    end 
end

// FEATURE OUT WRITE ADDRESS COMPOSITION
always @(*) begin
    featureOutWriteAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
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
                        .writeValue(featureOutWriteValueFW[i]),
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
reg [0: (FEATURE_OUT_CH_SIZE[0]-1)]dyReadEn_r;
reg [0: (FEATURE_OUT_CH_SIZE[0]-1)][(NBITS*N_FEATURE_READ-1):0]dyReadValue_r;
reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] gradientInBufferOfReadValueFW,next_gradientInBufferOfReadValue;
reg dyReadAddr_r;

// READ  GRADIENT ENABLE
always @(*) begin

    for ( jj = 0; jj < FEATURE_OUT_CH_SIZE[0]; j=j+1)begin
        if ( bw == 0)begin // Forward operation , no read over gradient memory
            dyReadEn_r[jj]=0;
        end if ( (bw == 1) ) begin // if dk calculation , read given dk channel
            if(DkChOutAddrBWDk == jj)begin
                dyReadEn_r[jj]=1;
            end else begin
                dyReadEn_r[jj]=0;       
            end
        end if ( (bw == 2) ) begin // if dx, read of dx channel
            if(gradientInChAddrBWDX == jj)begin
                dyReadEn_r[jj]=1;
            end else begin
                dyReadEn_r[jj]=0;       
            end
        end else begin // default . dont read
            dyReadEn_r[jj]=0;
        end
    end
end
// WRITE GRADIENT ENABLE
always @ ( * ) begin 
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< GRADIENT_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if(bw==2)begin
                if(gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 0) begin// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
                    if((ii == (actLayer)) && (jj == (gradeintOutChAddr-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                        gradientOutWriteEn[ii][jj]   = 1;
                    end else begin 
                        gradientOutWriteEn[ii][jj]   = 0;
                    end
                end else begin
                        gradientOutWriteEn[ii][jj]   = 0;
                end
            end else begin
                gradientOutWriteEn[ii][jj]   = 0;
            end
        end
    end
end
reg [(N_FEATURE_READ*NBITS-1):0] gradientOutWriteValue;
// GRADIENT OUT BUFFER FILL
always @ (*)begin  
    if( bw == 2)begin
        if (gradientOutColumnAddrBWDX[2:0] == 0)begin // if we are calculated 8 feature out, for the new cycle , reset the buffer
            gradientOutWriteValue = {{(7*NBITS){1'b0}},dxBWDX} ;
        end else begin // otherwise continue to load the buffer
            gradientOutWriteValue = gradientOutWriteValue | (dxBWDX << (NBITS*gradientOutColumnAddrBWDX[2:0])); // filling of write out buffer
        end     end else begin
        gradientOutWriteValue = 0;
    end
end

// PU GRADIENT IN ASSIGN FOR DK CALCULATION
always @(*)begin
    dyBW = dyReadValue_r[DkChOutAddrBWDk];
end

// DK READ FROM PU
reg [0: (KERNEL_SIZE*KERNEL_SIZE-1)][(NBITS-1):0] dk_r;
always @(*)begin
    if(valid == 1)begin
        dk_r = dkBW; 
    end
end

// FEATURE OUT WRITE ADDRESS COMPOSITION
reg [($clog2(GRADIENT_OUT_ROW_SIZE[0]) + $clog2(GRADIENT_OUT_COLUMN_SIZE[0]) -1) :0]  gradientOutWriteAddr;
always @(*) begin
    gradientOutWriteAddr = (gradientOutRowAddrBWDX << ($clog2(GRADEINT_OUT_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
end
// GRADIENT IN BUFFER FILLING  AND WRITE/READ ADDRESS ASSIGNATION
always @( *)begin
    if(bw == 1)begin 
        dyReadAddr_r = featureInReadAddr_r;
    end else if (bw == 2) begin
        if(state_reg == RUNNING)begin
            if((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 5)||(kernelAddrRead == 6))begin // carichiamo primo pixel
            // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            if((gradientOutColumnAddrBWDX+7) > FEATURE_IN_COLUMN_SIZE[actLayer-1])begin
                dyReadAddr_r = (gradientOutRowAddrBWDX+1 << ($clog2(FEATURE_IN_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX;
            end else begin
                dyReadAddr_r = (gradientOutRowAddrBWDX << ($clog2(FEATURE_IN_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX +8;
            end
            next_gradientInBufferOfReadValue[0][0] = dyReadValue_r[actLayer][featureInChAddrFW]; // save 8 channel of first row
            next_gradientInBufferOfReadValue[0][1] = dyReadValue_r[actLayer][featureInChAddrFW+1];
            next_gradientInBufferOfReadValue[0][2] = dyReadValue_r[actLayer][featureInChAddrFW+2];
            next_gradientInBufferOfReadValue[0][3] = dyReadValue_r[actLayer][featureInChAddrFW+3];
            next_gradientInBufferOfReadValue[0][4] = dyReadValue_r[actLayer][featureInChAddrFW+4];
            next_gradientInBufferOfReadValue[0][5] = dyReadValue_r[actLayer][featureInChAddrFW+5];
            next_gradientInBufferOfReadValue[0][6] = dyReadValue_r[actLayer][featureInChAddrFW+6];
            next_gradientInBufferOfReadValue[0][7] = dyReadValue_r[actLayer][featureInChAddrFW+7];
        end else if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 6)||(kernelAddrRead == 7))begin 
            // SAve check as above. In this case we also sum 1 to row
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer-1]) begin
                dyReadAddr_r = (gradientOutRowAddrBWDX+2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX;
            end else begin
                dyReadAddr_r = (gradientOutRowAddrBWDX+1 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX +8;
            end            
            next_gradientInBufferOfReadValue[1][0] = dyReadValue_r[actLayer][featureInChAddrFW]; // save 8 channel of second row
            next_gradientInBufferOfReadValue[1][1] = dyReadValue_r[actLayer][featureInChAddrFW+1];
            next_gradientInBufferOfReadValue[1][2] = dyReadValue_r[actLayer][featureInChAddrFW+2];
            next_gradientInBufferOfReadValue[1][3] = dyReadValue_r[actLayer][featureInChAddrFW+3];
            next_gradientInBufferOfReadValue[1][4] = dyReadValue_r[actLayer][featureInChAddrFW+4];
            next_gradientInBufferOfReadValue[1][5] = dyReadValue_r[actLayer][featureInChAddrFW+5];
            next_gradientInBufferOfReadValue[1][6] = dyReadValue_r[actLayer][featureInChAddrFW+6];
            next_gradientInBufferOfReadValue[1][7] = dyReadValue_r[actLayer][featureInChAddrFW+7];
        end else if((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 7)||(kernelAddrRead == 8))begin 
            // same reason as above
            if((featureOutColumnAddrFW+7) > FEATURE_OUT_COLUMN_SIZE[actLayer-1]) begin
                dyReadAddr_r = (gradientOutRowAddrBWDX+3 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX;
            end else begin
                dyReadAddr_r = (gradientOutRowAddrBWDX+2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX +8;
            end             
            next_gradientInBufferOfReadValue[2][0] = dyReadValue_r[actLayer][featureInChAddrFW]; // save 8 channel of third row
            next_gradientInBufferOfReadValue[2][1] = dyReadValue_r[actLayer][featureInChAddrFW+1];
            next_gradientInBufferOfReadValue[2][2] = dyReadValue_r[actLayer][featureInChAddrFW+2];
            next_gradientInBufferOfReadValue[2][3] = dyReadValue_r[actLayer][featureInChAddrFW+3];
            next_gradientInBufferOfReadValue[2][4] = dyReadValue_r[actLayer][featureInChAddrFW+4];
            next_gradientInBufferOfReadValue[2][5] = dyReadValue_r[actLayer][featureInChAddrFW+5];
            next_gradientInBufferOfReadValue[2][6] = dyReadValue_r[actLayer][featureInChAddrFW+6]; 
            next_gradientInBufferOfReadValue[2][7] = dyReadValue_r[actLayer][featureInChAddrFW+7];
        end else begin
            featureInReadAddr_r = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+gradientOutColumnAddrBWDX+8; // default . TODO : prova a lasciare vuoto
        end
    end
end
end
// GRADIENT BUFFER UPDATE
always @ (*) begin
    if(bw==0)begin
    if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 0)begin // new 8 feature are loaded
        gradientInBufferOfReadValue = next_gradientInBufferOfReadValue;
    end
    end
end
// GRADIENT IN PIXEL TO PU ASSIGNATION
always @ (*)begin
    if else (bw == 2)begin
    DyP1BWDX = gradientInBufferOfReadValue[0][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    DyP1BWDX = gradientInBufferOfReadValue[0][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP1BWDX = gradientInBufferOfReadValue[0][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP1BWDX = gradientInBufferOfReadValue[0][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP1BWDX = gradientInBufferOfReadValue[0][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP1BWDX = gradientInBufferOfReadValue[0][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP1BWDX = gradientInBufferOfReadValue[0][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP1BWDX = gradientInBufferOfReadValue[0][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 

    DyP2BWDX = gradientInBufferOfReadValue[1][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    DyP2BWDX = gradientInBufferOfReadValue[1][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP2BWDX = gradientInBufferOfReadValue[1][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP2BWDX = gradientInBufferOfReadValue[1][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP2BWDX = gradientInBufferOfReadValue[1][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP2BWDX = gradientInBufferOfReadValue[1][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP2BWDX = gradientInBufferOfReadValue[1][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP2BWDX = gradientInBufferOfReadValue[1][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 

    DyP3BWDX = gradientInBufferOfReadValue[2][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    DyP3BWDX = gradientInBufferOfReadValue[2][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP3BWDX = gradientInBufferOfReadValue[2][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP3BWDX = gradientInBufferOfReadValue[2][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP3BWDX = gradientInBufferOfReadValue[2][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP3BWDX = gradientInBufferOfReadValue[2][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP3BWDX = gradientInBufferOfReadValue[2][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    DyP3BWDX = gradientInBufferOfReadValue[2][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
    end
end
/////////////////////////////// GRADIENT PROPAGATION MEMORY \\\\\\\\\\\\\\\\\\\\
for(j=0; j< FEATURE_OUT_CH_SIZE[0]; j=j+1) begin
SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),.MEMORY_WIDHT(FEATURE_OUT_ROW_SIZE[0]*(FEATURE_OUT_COLUMN_SIZE[0]/N_FEATURE_READ)))
SRAMdx (.writeAddr(gradientOutWriteAddr),
        .readAddr(dyReadAddr_r),
        .writeEn(gradientOutWriteEn),
        .readEn(dyReadEn_r),
        .readValue(dyReadValue_r),
        .writeValue(gradientOutWriteValue),
        .clk(clk),
        .rst(rst));
end
endmodule
