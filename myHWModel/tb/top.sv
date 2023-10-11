// Define the module instance
module FW_BW_PU_tb;

    parameter MAC_SIZE = 3;
    parameter KERNEL_SIZE = 3;
    parameter N_OF_MAC_ROWS = 3;
    parameter N_OF_MAC_CLMN = 3;
    parameter N_OF_CH_READ = 8;
    parameter NBITS = 16;
    parameter NLAYER = 1;
    parameter [0:(NLAYER-1)]FEATURE_IN_ROW_SIZE= [32];
    parameter [0:(NLAYER-1)]FEATURE_IN_COLUMN_SIZE = [32];
    parameter [0:(NLAYER-1)]FEATURE_IN_CH_SIZE = [8];
    parameter [0:(NLAYER-1)]FEATURE_OUT_ROW_SIZE = [32];
    parameter [0:(NLAYER-1)]FEATURE_OUT_COLUMN_SIZE = [32];
    parameter [0:(NLAYER-1)]FEATURE_OUT_CH_SIZE = [8];

    parameter N_FEATURE_READ = 8;
    // Define signals
    reg bw;
    reg clk;
    reg rst;
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInActChSize;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutActChSize;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0])-1):0] featureOutActRowSize;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0])-1):0] featureOutActColumnSize;
    reg [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelValsFW;
    reg loadKernelFW;
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] featureInChAddrFW;
    reg [(NBITS*N_OF_CH_READ-1):0] featureInP1FW, featureInP2FW, featureInP3FW;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] featureOutChAddrFW;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrFW;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrFW;
    reg [(NBITS-1):0] featureOutValFW;
    reg [($clog2(FEATURE_IN_CH_SIZE)-1):0] DkChInAddrBWDk;
    reg [($clog2(FEATURE_OUT_CH_SIZE)-1):0] dkChOutAddrBWDk;
    reg [($clog2(FEATURE_OUT_ROW_SIZE) -1):0] featureOutRowAddrBWDk;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE) -1):0] featureOutColumnAddrBWDk;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] featureInBW;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] dyBW;
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] dkBW;
    reg valid;
    reg [0:($clog2(NLAYER)-1)]actLayer;

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
        .featureOutRowAddrFW(featureOutRowAddrFW),
        .featureOutColumnAddrFW(featureOutColumnAddrFW),
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
//////////////////////////////// FW STATE MACHINE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// LOAD_KERNEL each 8*channel in are convolved 
// START 
// LOAD_KERNEL : 6* LOAD N_FEATURE_READ KERNEL
// LOAD_FEATURE : LOAD 3*N_FEATURE_READ PIXEL - LOAD N_FEATURE_READ KERNEL
// LOAD_FEATURE : LOAD 3*N_FEATURE_READ PIXEL - LOAD N_FEATURE_READ KERNEL
// START : LOAD 3*N_FEATURE_READ PIXEL - LOAD N_FEATURE_READ KERNEL - MAC_ENABLE - ADDRESS MANAGER ENABLE
// RUNNING :  MAC_ENABLE - ADDRESS MANAGER ENABLE ( EXECUTION ) * featureOutActRowSize * featureOutActColumnSize
// END OF SHEET OF FEATURE OUT - RESTART TO READ KERNEL


    // Define states
    typedef enum logic [1:0] {
        LOAD_KERNEL_AND_FEATURE = 2'b00,
        RUNNING = 2'b10

    } FW_FSM_t;

    // Define state register and next state variable
    state_t state_reg, next_state;
    reg [3:0] kernelAddrReadFW,next_kernelAddrReadFW;
    reg [1:0] featureLoadedCnt, next_featureLoadedCnt;

    // Define state update logic
    always_ff @(posedge clk or posedge reset) begin
        if (rst) begin
            state_reg <= LOAD_KERNEL; // Initialize state to S0 on reset
            featureLoadedCnt <= 0;
            kernelAddrReadFW <= 0;
        end else begin
            state_reg <= next_state; // Update state on clock edge
            featureLoadedCnt <= next_featureLoadedCnt;
            kernelAddrReadFW <= next_kernelAddrReadFW;
        end
    end

    // Define state transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (rst) begin
            next_state <= LOAD_KERNEL; // Initialize next state to S0 on reset
        end else begin
            // Define state transitions based on current state
            case (state_reg)
                LOAD_KERNEL: begin
                    if (kernelAddrReadFW == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= LOAD_KERNEL;
                    end else begin
                        next_state <= RUNNING;
                    end
                end
        
                RUNNING : begin 
                    next_state <= LOAD_FEATURE;
                end

                LOAD_FEATURE : begin 
                    if ( featureLoadedCnt == 2) begin
                        next_state <= RUNNING;    
                    end else begin
                        next_state <= LOAD_FEATURE;
                    end 
                end
                default: next_state <= LOAD_KERNEL; // Default to S0 (for safety)
            endcase
        end
    end
    always @ ( *) begin
        case (state_reg)
            LOAD_KERNEL: begin
               next_kernelAddrReadFW <= kernelAddrReadFW +1;  
               next_featureLoadedCnt <= 0;  
            end
        
            RUNNING : begin 
                next_kernelAddrReadFW <= 0;
                next_featureLoadedCnt <= 0;
            end
                next_kernelAddrReadFW <= 0;
                next_featureLoadedCnt <= featureLoadedCnt +1;
            endcase
    end

endmodule
// kernel read enable .
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)] kernelReadEnFW;
always @ ( *) begin
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            for(int kk=0; kk < FEATURE_IN_CH_SIZE[NLAYER-1]; kk=kk+8)begin
                if (state_reg == LOAD_KERNEL)begin // if we are loading the kernels
                    if((ii == (actLayer-1)) && (jj == (featureOutChAddrFW-1)) && (kk == (featureInChAddrFW-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                    kernelReadEnFW[ii][jj][kk]   = 1;
                    kernelReadEnFW[ii][jj][kk+1] = 1;
                    kernelReadEnFW[ii][jj][kk+2] = 1;
                    kernelReadEnFW[ii][jj][kk+3] = 1;
                    kernelReadEnFW[ii][jj][kk+4] = 1;
                    kernelReadEnFW[ii][jj][kk+5] = 1;
                    kernelReadEnFW[ii][jj][kk+6] = 1;
                    kernelReadEnFW[ii][jj][kk+7] = 1;

                    end else begin
                    kernelReadEnFW[ii][jj][kk]   = 0;
                    kernelReadEnFW[ii][jj][kk+1] = 0;
                    kernelReadEnFW[ii][jj][kk+2] = 0;
                    kernelReadEnFW[ii][jj][kk+3] = 0;
                    kernelReadEnFW[ii][jj][kk+4] = 0;
                    kernelReadEnFW[ii][jj][kk+5] = 0;
                    kernelReadEnFW[ii][jj][kk+6] = 0;
                    kernelReadEnFW[ii][jj][kk+7] = 0;
                    end
                end else begin // if we are not il loading kernel status, dont load anithing
                    kernelReadEnFW[ii][jj][kk]   = 0;
                    kernelReadEnFW[ii][jj][kk+1] = 0;
                    kernelReadEnFW[ii][jj][kk+2] = 0;
                    kernelReadEnFW[ii][jj][kk+3] = 0;
                    kernelReadEnFW[ii][jj][kk+4] = 0;
                    kernelReadEnFW[ii][jj][kk+5] = 0;
                    kernelReadEnFW[ii][jj][kk+6] = 0;
                    kernelReadEnFW[ii][jj][kk+7] = 0;
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
                SRAMKijk(.writeAddr(),.readAddr(kernelAddrReadFW),.writeEn(),.readEn(kernelReadEnFW[i][j][k]),.readValue(),.writeValue(),.clk(),.rst());
            end
        end
    end
endgenerate




reg [0:(NLAYER)][0: ( FEATURE_IN_CH_SIZE[NLAYER-1] -1)] featureInReadEnFW;
// read enable for feature in reading
always @ ( * ) begin 
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+8)begin
            if((ii == (actLayer-1)) && (kk == (featureInChAddrFW-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                featureInReadEnFW[ii][jj]   = 1;
                featureInReadEnFW[ii][jj+1] = 1;
                featureInReadEnFW[ii][jj+2] = 1;
                featureInReadEnFW[ii][jj+3] = 1;
                featureInReadEnFW[ii][jj+4] = 1;
                featureInReadEnFW[ii][jj+5] = 1;
                featureInReadEnFW[ii][jj+6] = 1;
                featureInReadEnFW[ii][jj+7] = 1;
            end else begin 
                featureInReadEnFW[ii][jj]   = 0;
                featureInReadEnFW[ii][jj+1] = 0;
                featureInReadEnFW[ii][jj+2] = 0;
                featureInReadEnFW[ii][jj+3] = 0;
                featureInReadEnFW[ii][jj+4] = 0;
                featureInReadEnFW[ii][jj+5] = 0;
                featureInReadEnFW[ii][jj+6] = 0;
                featureInReadEnFW[ii][jj+7] = 0;
            end
        end
    end

end
reg [0:(NLAYER)][0: ( FEATURE_OUT_CH_SIZE[NLAYER-1] -1)] featureOutWriteEnFW;

// write  enable for feature out writing
always @ ( * ) begin 
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if((ii == (actLayer-1)) && (kk == (featureOutChAddrFW-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                featureOutWriteEnFW[ii][jj]   = 1;
            end else begin 
                featureOutWriteEnFW[ii][jj]   = 0;
            end
        end
    end
end

always @(*) begin
    featureOutWriteAddrFW = (featureOutRowAddrFW*FEATURE_OUT_ROW_SIZE[actLayer-1])+featureOutColumnAddrFW;
end
always @(*) begin
    featureInReadAddrFW =
end

featureOutRowAddrFW
featureOutColumnAddrFW

reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) + $clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1) :0] featureOutWriteAddrFW;
reg [(N_FEATURE_READ*NBITS-1):0] featureOutWriteValueFW;
reg [($clog2(FEATURE_IN_ROW_SIZE[0]) + $clog2(FEATURE_IN_COLUMN_SIZE[0]) -1) :0] featureInReadAddrFW;
reg [0:(NLAYER-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFW;

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// FEATURE OUT MEMORY \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////////
// FEATURE OUT MEMORY : CHANNEL OUT NUMBER OF MEMORY, EACH OF #ROWS*(#CLOUMN/8) WORDS OF 16*8= 128 BIT OF WORD LENGHT

generate
    for(i=0; i < NLAYER; i= i+1)begin
        for(j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1) begin
            SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),.MEMORY_WIDHT(FEATURE_OUT_ROW_SIZE[i]*(FEATURE_OUT_COLUMN_SIZE[i]/N_FEATURE_READ)))
                SRAMFij(.writeAddr(featureOutWriteAddrFW[($clog2(FEATURE_OUT_ROW_SIZE[i]) + $clog2(FEATURE_OUT_COLUMN_SIZE[i]/N_FEATURE_READ) -1) :0]),.readAddr(featureInReadAddrFW[[i][($clog2(FEATURE_IN_ROW_SIZE[i]) + $clog2(FEATURE_IN_COLUMN_SIZE[i]/N_FEATURE_READ) -1) :0]]),.writeEn(featureOutWriteEnFW[i][j]),.readEn(featureInReadEnFW[i][j]),.readValue(featureInReadValueFW[i][j]),.writeValue(featureOutWriteValueFW[i]),.clk(clk),.rst(rst));
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
    // Define stimulus
    initial begin

        while ((featureOutChAddrFW  != featureOutActChSize ) || (featureOutRowAddrFW != featureOutActRowSize ) || (featureOutColumnAddrFW != 0) || ((featureInChAddrFW+7) != featureInActChSize)) begin
            if (( featureOutRowAddrFW == 0 ) && ( featureOutColumnAddrFW == 0) )begin // TODO : MOVE LOGIC LOAD KERNEL INSIDE PU
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
            if((featureOutColumnAddrFW+2) > featureOutActColumnSize)begin
                featureInP1FW = 0;
                featureInP2FW = 0;
                featureInP3FW = 0;
            end else begin
            if(featureOutRowAddrFW[0] == 0)begin // TODO : MOVE LOGIC ADDRES INSIDE 

            featureInP1FW[(NBITS-1):0]         = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];

            featureInP2FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP2FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];

            featureInP3FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            featureInP3FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+2)];
            end else begin
            featureInP1FW[(NBITS-1):0]        = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+0)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];

            featureInP2FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP2FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+1)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];

            featureInP3FW[(NBITS-1):0]          = featureIn1[((featureInChAddrFW+0)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(2*NBITS-1):NBITS]    = featureIn1[((featureInChAddrFW+1)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(3*NBITS-1):2*NBITS]  = featureIn1[((featureInChAddrFW+2)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(4*NBITS-1):3*NBITS]  = featureIn1[((featureInChAddrFW+3)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(5*NBITS-1):4*NBITS]  = featureIn1[((featureInChAddrFW+4)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(6*NBITS-1):5*NBITS]  = featureIn1[((featureInChAddrFW+5)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(7*NBITS-1):6*NBITS]  = featureIn1[((featureInChAddrFW+6)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            featureInP3FW[(8*NBITS-1):7*NBITS]  = featureIn1[((featureInChAddrFW+7)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW+2)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW+0)];
            
            end
            end
            featureOut1[((featureOutChAddrFW)*(FEATURE_OUT_ROW_SIZE*FEATURE_OUT_COLUMN_SIZE) + (featureOutRowAddrFW)*(FEATURE_OUT_COLUMN_SIZE) + featureOutColumnAddrFW)] = featureOutValFW;
            
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
        while ((featureOutChAddrFW != FEATURE_OUT_CH_SIZE[1] )&& (featureOutRowAddrFW!=FEATURE_OUT_ROW_SIZE[1] )&& (featureOutColumnAddrFW!= FEATURE_OUT_COLUMN_SIZE[1]) && ((featureInChAddrFW+8) != featureInChAddrFW[1])) begin
            featureInP1FW[(NBITS-1):0]        = featureIn2[featureInChAddrFW][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn2[featureInChAddrFW+1][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn2[featureInChAddrFW+2][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn2[featureInChAddrFW+3][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn2[featureInChAddrFW+4][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn2[featureInChAddrFW+5][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn2[featureInChAddrFW+6][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn2[featureInChAddrFW+7][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];

            featureInP2FW[(NBITS-1):0]        = featureIn2[featureInChAddrFW][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(2*NBITS-1):NBITS]   = featureIn2[featureInChAddrFW+1][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(3*NBITS-1):2*NBITS] = featureIn2[featureInChAddrFW+2][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(4*NBITS-1):3*NBITS] = featureIn2[featureInChAddrFW+3][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(5*NBITS-1):4*NBITS] = featureIn2[featureInChAddrFW+4][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(6*NBITS-1):5*NBITS] = featureIn2[featureInChAddrFW+5][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(7*NBITS-1):6*NBITS] = featureIn2[featureInChAddrFW+6][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(8*NBITS-1):7*NBITS] = featureIn2[featureInChAddrFW+7][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];

            featureInP3FW[(NBITS-1):0]        = featureIn2[featureInChAddrFW][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(2*NBITS-1):NBITS]   = featureIn2[featureInChAddrFW+1][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(3*NBITS-1):2*NBITS] = featureIn2[featureInChAddrFW+2][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(4*NBITS-1):3*NBITS] = featureIn2[featureInChAddrFW+3][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(5*NBITS-1):4*NBITS] = featureIn2[featureInChAddrFW+4][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(6*NBITS-1):5*NBITS] = featureIn2[featureInChAddrFW+5][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(7*NBITS-1):6*NBITS] = featureIn2[featureInChAddrFW+6][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(8*NBITS-1):7*NBITS] = featureIn2[featureInChAddrFW+7][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            
            featureOut2[featureOutChAddrFW][featureOutRowAddrFW][featureOutColumnAddrFW] = featureOutValFW;
            #10;
        end
        $writememh("featureOut2",featureOut2);
        featureInActChSize = 32;
        featureOutActChSize = 32;
        featureOutActRowSize = 8;
        featureOutActColumnSize = 8;
        $readmemh("featureIn3.txt", featureIn3);
        while ((featureOutChAddrFW != FEATURE_OUT_CH_SIZE[2] )&& (featureOutRowAddrFW!=FEATURE_OUT_ROW_SIZE[2] )&& (featureOutColumnAddrFW!= FEATURE_OUT_COLUMN_SIZE[2]) && ((featureInChAddrFW+8) != featureInChAddrFW[2])) begin
            featureInP1FW[(NBITS-1):0]         = featureIn3[featureInChAddrFW][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(2*NBITS-1):NBITS]   = featureIn3[featureInChAddrFW+1][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureIn3[featureInChAddrFW+2][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureIn3[featureInChAddrFW+3][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureIn3[featureInChAddrFW+4][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureIn3[featureInChAddrFW+5][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureIn3[featureInChAddrFW+6][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureIn3[featureInChAddrFW+7][featureOutRowAddrFW+0][featureOutColumnAddrFW+2];

            featureInP2FW[(NBITS-1):0]         = featureIn3[featureInChAddrFW][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(2*NBITS-1):NBITS]   = featureIn3[featureInChAddrFW+1][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(3*NBITS-1):2*NBITS] = featureIn3[featureInChAddrFW+2][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(4*NBITS-1):3*NBITS] = featureIn3[featureInChAddrFW+3][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(5*NBITS-1):4*NBITS] = featureIn3[featureInChAddrFW+4][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(6*NBITS-1):5*NBITS] = featureIn3[featureInChAddrFW+5][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(7*NBITS-1):6*NBITS] = featureIn3[featureInChAddrFW+6][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];
            featureInP2FW[(8*NBITS-1):7*NBITS] = featureIn3[featureInChAddrFW+7][featureOutRowAddrFW+1][featureOutColumnAddrFW+2];

            featureInP3FW[(NBITS-1):0]         = featureIn3[featureInChAddrFW][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(2*NBITS-1):NBITS]   = featureIn3[featureInChAddrFW+1][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(3*NBITS-1):2*NBITS] = featureIn3[featureInChAddrFW+2][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(4*NBITS-1):3*NBITS] = featureIn3[featureInChAddrFW+3][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(5*NBITS-1):4*NBITS] = featureIn3[featureInChAddrFW+4][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(6*NBITS-1):5*NBITS] = featureIn3[featureInChAddrFW+5][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(7*NBITS-1):6*NBITS] = featureIn3[featureInChAddrFW+6][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            featureInP3FW[(8*NBITS-1):7*NBITS] = featureIn3[featureInChAddrFW+7][featureOutRowAddrFW+2][featureOutColumnAddrFW+2];
            
            featureOut3[featureOutChAddrFW][featureOutRowAddrFW][featureOutColumnAddrFW] = featureOutValFW;
            #10;
        end
        $writememh("featureOut3",featureOut3);*/
        $finish;
    end

    
endmodule
