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
            loadKernelFW <= 0;
        end else begin
            // Define state transitions based on current state
            case (state_reg)
                LOAD_KERNEL: begin
                    if (kernelAddrReadFW == (KERNEL_SIZE*KERNEL_SIZE-1) ) begin// 9 KERNEL ARE LOADED AND 9 PIXELS ALOS
                        next_state <= RUNNING; // TODO : let read feature IN also in load kernel
                        loadKernelFW <= 1; // start loading kernel into PU
                    end else begin
                        next_state <= LOAD_KERNEL;
                        loadKernelFW <= 0; // stop loading kernel
                    end
                end
        
                RUNNING : begin // TODO : set exit condition for ruinning state
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
// se siamo in LOAD_KERNEL status, allora leggiamoo i kernel e salviamo in buffer
always @ (*) begin
    if ( state_reg == LOAD_KERNEL) begin
        kernelValsFW[kernelAddrReadFW][(NBITS-1):0]           =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW]; // first channel in kernel 
        kernelValsFW[kernelAddrReadFW][(2*NBITS-1):(NBITS)]   =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+1]; // 2nd channel in kernel 
        kernelValsFW[kernelAddrReadFW][(3*NBITS-1):(2*NBITS)] =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+2]; // 3th channel in kernel 
        kernelValsFW[kernelAddrReadFW][(4*NBITS-1):(3*NBITS)] =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+3]; // 4th channel in kernel 
        kernelValsFW[kernelAddrReadFW][(5*NBITS-1):(4*NBITS)] =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+4]; // 5th channel in kernel 
        kernelValsFW[kernelAddrReadFW][(6*NBITS-1):(5*NBITS)] =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+5]; // 6th channel in kernel 
        kernelValsFW[kernelAddrReadFW][(7*NBITS-1):(6*NBITS)] =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+6]; // 7th channel in kernel 
        kernelValsFW[kernelAddrReadFW][(8*NBITS-1):(7*NBITS)] =  kernelReadValuesFw[actLayer][featureOutChAddrFW][featureInChAddrFW+7]; // 8th channel in kernel 
    end 

end
// kernel read enable .
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)] kernelReadEnFW;
reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(NBITS-1):0] kernelReadValuesFw;
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
            if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] > 4)begin // se mancano 3 clock al nuovo blocco di feature inizio a leggere
                if((ii == (actLayer-1)) && (kk == (featureInChAddrFW-1)))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
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
            if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 0) BEGIN// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
                if((ii == (actLayer-1)) && (kk == (featureOutChAddrFW-1)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
                    featureOutWriteEnFW[ii][jj]   = 1;
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
    if(state == RUNNING)begin
        if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 5)begin // carichiamo primo pixel
            featureInReadAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW[($clog2(featureOutActColumnSize)-1):($clog2(N_FEATURE_READ))]+1; // carica il valore della riga corrente ,l'indirizzo colonna è preso tagliando i primi 3 bit. il +1 dice di prende la parola successiva
            next_featureInBufferOfReadValueFW[0][0] = featureInReadValueFW[actLayer][featureInChAddrFW]; // save 8 channel of first row
            next_featureInBufferOfReadValueFW[0][1] = featureInReadValueFW[actLayer][featureInChAddrFW+1];
            next_featureInBufferOfReadValueFW[0][2] = featureInReadValueFW[actLayer][featureInChAddrFW+2];
            next_featureInBufferOfReadValueFW[0][3] = featureInReadValueFW[actLayer][featureInChAddrFW+3];
            next_featureInBufferOfReadValueFW[0][4] = featureInReadValueFW[actLayer][featureInChAddrFW+4];
            next_featureInBufferOfReadValueFW[0][5] = featureInReadValueFW[actLayer][featureInChAddrFW+5];
            next_featureInBufferOfReadValueFW[0][6] = featureInReadValueFW[actLayer][featureInChAddrFW+6];
            next_featureInBufferOfReadValueFW[0][7] = featureInReadValueFW[actLayer][featureInChAddrFW+7];
        end else if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 6)begin 
            featureInReadAddrFW = (featureOutRowAddrFW +1 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW[($clog2(featureOutActColumnSize)-1):($clog2(N_FEATURE_READ))]+1; // come sopra, solo che prendiamo un riga in piu
            next_featureInBufferOfReadValueFW[1][0] = featureInReadValueFW[actLayer][featureInChAddrFW]; // save 8 channel of second row
            next_featureInBufferOfReadValueFW[1][1] = featureInReadValueFW[actLayer][featureInChAddrFW+1];
            next_featureInBufferOfReadValueFW[1][2] = featureInReadValueFW[actLayer][featureInChAddrFW+2];
            next_featureInBufferOfReadValueFW[1][3] = featureInReadValueFW[actLayer][featureInChAddrFW+3];
            next_featureInBufferOfReadValueFW[1][4] = featureInReadValueFW[actLayer][featureInChAddrFW+4];
            next_featureInBufferOfReadValueFW[1][5] = featureInReadValueFW[actLayer][featureInChAddrFW+5];
            next_featureInBufferOfReadValueFW[1][6] = featureInReadValueFW[actLayer][featureInChAddrFW+6];
            next_featureInBufferOfReadValueFW[1][7] = featureInReadValueFW[actLayer][featureInChAddrFW+7];
        end else if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 7)begin 
            featureInReadAddrFW = (featureOutRowAddrFW +2 << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW[($clog2(featureOutActColumnSize)-1):($clog2(N_FEATURE_READ))]+1; // come sopra solo che prendiamo due righe in piu
            next_featureInBufferOfReadValueFW[2][0] = featureInReadValueFW[actLayer][featureInChAddrFW]; // save 8 channel of third row
            next_featureInBufferOfReadValueFW[2][1] = featureInReadValueFW[actLayer][featureInChAddrFW+1];
            next_featureInBufferOfReadValueFW[2][2] = featureInReadValueFW[actLayer][featureInChAddrFW+2];
            next_featureInBufferOfReadValueFW[2][3] = featureInReadValueFW[actLayer][featureInChAddrFW+3];
            next_featureInBufferOfReadValueFW[2][4] = featureInReadValueFW[actLayer][featureInChAddrFW+4];
            next_featureInBufferOfReadValueFW[2][5] = featureInReadValueFW[actLayer][featureInChAddrFW+5];
            next_featureInBufferOfReadValueFW[2][6] = featureInReadValueFW[actLayer][featureInChAddrFW+6];
            next_featureInBufferOfReadValueFW[2][7] = featureInReadValueFW[actLayer][featureInChAddrFW+7];
        end else begin
            featureInReadAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW[($clog2(featureOutActColumnSize)-1):($clog2(N_FEATURE_READ))]+1; // default . TODO : prova a lasciare vuoto

        end
        if (featureOutColumnAddrFW[2:0] == 0)begin 
            featureOutWriteValueFW = {(7*NBITS)'d0,featureOutValFW} ;
        end else begin 
            featureOutWriteValueFW = featureOutWriteValueFW | (featureOutValFW << (NBITS*featureOutColumnAddrFW[2:0])); // filling of write out buffer
        end
    end  
end
// update of feature in buffer
always @ (*) begin
    if(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 0)begin 
        featureInBufferOfReadValueFW = next_featureInBufferOfReadValueFW;
    end
end

// load FW PU from buffers
always @ (*)begin
    featureInP1FW = featureInBufferOfReadValueFW[0]; // TODO :CICLICALLY, TAKE 3 PIXEL ACCORDING TO THE COLUMN. 
    featureInP2FW = featureInBufferOfReadValueFW[1];
    featureInP3FW = featureInBufferOfReadValueFW[2];
end

// FEATURE OUT WRITE ADDRESS COMPOSITION
always @(*) begin
    featureOutWriteAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_ROW_SIZE[actLayer-1])))+featureOutColumnAddrFW; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
end



reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) + $clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1) :0] featureOutWriteAddrFW;
reg [(N_FEATURE_READ*NBITS-1):0] featureOutWriteValueFW;
reg [($clog2(FEATURE_IN_ROW_SIZE[0]) + $clog2(FEATURE_IN_COLUMN_SIZE[0]) -1) :0] featureInReadAddrFW;
reg [0:(NLAYER-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFW;
reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] featureInBufferOfReadValueFW,next_featureInBufferOfReadValueFW; // buffer dove salviamo le tre righe lette e mandiamo i pixel alla PU. Ne abbiamo due perche mentre carichiamo i nuovi i vecchi dobbiamo ancora usarli


///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// FEATURE OUT MEMORY \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////////
// FEATURE OUT MEMORY : CHANNEL OUT NUMBER OF MEMORY, EACH OF #ROWS*(#CLOUMN/8) WORDS OF 16*8= 128 BIT OF WORD LENGHT

generate
    for(i=0; i < NLAYER; i= i+1)begin
        for(j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1) begin
            SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),.MEMORY_WIDHT(FEATURE_OUT_ROW_SIZE[i]*(FEATURE_OUT_COLUMN_SIZE[i]/N_FEATURE_READ)))
                SRAMFij(.writeAddr(featureOutWriteAddrFW[($clog2(FEATURE_OUT_ROW_SIZE[i]) + $clog2(FEATURE_OUT_COLUMN_SIZE[i]) -1) :$clog2(N_FEATURE_READ)]),// we cut the last 3 bit due to port wirdht of N:FEATURE_READ*NBITS
                        .readAddr(featureInReadAddrFW[[i][($clog2(FEATURE_IN_ROW_SIZE[i]) + $clog2(FEATURE_IN_COLUMN_SIZE[i]) -1) :$clog2(N_FEATURE_READ)]]),// we cut the last 3 bit due to port wirdht of N:FEATURE_READ*NBITS
                        .writeEn(featureOutWriteEnFW[i][j]),
                        .readEn(featureInReadEnFW[i][j]),
                        .readValue(featureInReadValueFW[i][j]),
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

    
endmodule
