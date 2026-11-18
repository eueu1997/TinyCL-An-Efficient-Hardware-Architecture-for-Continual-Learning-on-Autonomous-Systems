// Define the module instance
// TODO : stride assignation and modification inside PU
// TODO : trasforma parametri in define
// TODO : apply input feture read during DX calculation to apply ReLU derivative ( set 0 the gradient input whose position was at 0 on feature in)
// TODO : avendo fetchato , bisogna incrementare i valori di ch da leggere, considerando che se abbiamo finito un canale in ingresso dovremmo incrementare il canale in uscita
// TODO : do better stride assignation
// TODO : in dk dovrebbe essere possibile eseguire la modifica dei kernel in 9 cili di clock mentre si inizia a calcolare la convoluzione successiva
// qiventa un problema nel caso di feature 8x8 perche in 8 cc finirà la convoluzione, mentre non avremo finito di aggiornare i kernel
// TODO : TIMING PROBLEMS :
//   - WHILE APPLYING DK ( READ KERNEL,SUM TO DK AND WRITE BACK) THE COMPUTATIONS GO ON. SHALL BE STOPPED. WE CANNOT FETCH THIS BECAUSE THE VALUE TO
//     ADD IS READY AT THE END .
//   -  AT BEGINNING (FIRST PIXELS OF GDUMB), WHILE LOADING THE FIRST KERNELS, WE HAVE ALSO TO WAIT, BECAUSE IN GENERAL IT IS PREFETCHED
// TODO : per qualche motivo se in DK metto valid a 1 quando indirizzi colonna e riga sono a 0, non va in load kernel. ad ora va il clock prim
// quando sono a max row e max column
//TODO : nel mac, fai tutti i calcoli a 32 bit, poi ritorna solo 16
// TODO : oramai, avendo cambiato la DK, non ci serve piu leggere 8 pixel alal volta, basta che siano piu di 3 . potrebbe essere utile scendere a PORT_WIDHT = 4*16, cosi possiamo fare anche matrici 4x4

// LA LETTURA DEI KERNEL SEMBRA CORRETTA ( NONOSTANZE LE LETTURE STRANE, ALLA FINE IL BLOCCO DI KERNEL SEMBRA GIUSTO) PERO A USA CHANNEL OUT = 1 ANZICHE CH OUT = 0
// QUESTO è DOVUTO AL FATTO DI SOPRA, CHE PER FARE PREFETCH DEL KERNLE, AUMENTO DI 1 IL CH. NON VA FATTO QUANDO I CH IN CH OUT E LAYER SONO A 0
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
    parameter string ACTIVATION = "NONE"

)
(   input clk,rst,
    output [9:0]featureInReadAddrFWGDUMB, // address of the feature
    output [0:2]featureInReadEnFWGDUMB, // Enable of GDUMB RAM memory. It read on all channels ( 3 extendet to 8 just for compatibility), always port widht of 8*NBITS, so same logic as SRAM
    input [0:7][(N_FEATURE_READ*NBITS-1):0] featureInReadValueFWGDUMB
);


    // Define signals
    reg [1:0] bw,next_bw;
    // Dynamic sizing of the feauture
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInActChSize;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutActChSize;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0])-1):0] featureOutActRowSize;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0])-1):0] featureOutActColumnSize;
        // FEATURE IN AND OUT ACTUAL LAYER SIZE
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInChAddrFW,NewFeatureInChAddrFW;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutChAddrFW,NewFeatureOutChAddrFW;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) -1):0] featureOutRowAddrFW;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):0] featureOutColumnAddrFW;
    // LOCAL SIGNALS PREFETCHING FETURE ADDRESS
    reg [($clog2(FEATURE_IN_COLUMN_SIZE[0])-1):0] NewFeatureInColumnPreFetch;
    reg [($clog2(FEATURE_IN_ROW_SIZE[0])-1):0] NewFeatureInRowPreFetch;
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] NewFeatureInChAddrPreFetch;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] NewFeatureOutChAddrPreFetch;
    reg [0:($clog2(NLAYER)-1)]NewFeatureLayerPreFetch;
    // matrix of 8*9 kernel values

    //LOCAL SIGNALS KERNEL LOAD
    reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)] kernelReadEn_r,kernelWriteEn_r;
    reg [0:(NLAYER-1)][0:(FEATURE_OUT_CH_SIZE[NLAYER-1]-1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(NBITS-1):0] kernelReadValues_r;
    reg [0:(FEATURE_OUT_CH_SIZE[NLAYER-1] -1)][0:(FEATURE_IN_CH_SIZE[NLAYER-1] -1)][(NBITS-1):0] kernelWriteValue_r;
    // KERNEL LOAD TO PU
    reg [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelValsFW;
    // flag saing kernel il ready to be loaded
    reg loadKernelFW;

    reg [($clog2(FEATURE_IN_ROW_SIZE[0]) + $clog2(FEATURE_IN_COLUMN_SIZE[0]) -1) :0] featureInReadAddr_r;
    // cè un alayer in piu solo per assegnazione comoda di sram in ciclo for. initilizzato
    reg [0:(NLAYER)][0:(FEATURE_IN_CH_SIZE[NLAYER-1]-1)][(N_FEATURE_READ*NBITS-1):0] featureInReadValue_r;
    reg [0:(NLAYER)][0: ( FEATURE_IN_CH_SIZE[NLAYER-1] -1)] featureInReadEn_r;
    reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] featureInBufferOfReadValueFW,next_featureInBufferOfReadValueFW; // buffer dove salviamo le tre righe lette e mandiamo i pixel alla PU. Ne abbiamo due perche mentre carichiamo i nuovi i vecchi dobbiamo ancora usarli
    // cè una layer in piu che va assenato all'ultima sram ma che sara inutilizzato
    // 3 new pixels needed by MAC in forward computation
    reg [(NBITS*N_OF_CH_READ-1):0] featureInP1FW, featureInP2FW, featureInP3FW;
    // pixel of feature out : result of 3d convolution
    reg [(NBITS-1):0] featureOutValFW,featureOutValFWActivated;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) + $clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1) :0] featureOutWriteAddrFW;
    reg [(N_FEATURE_READ*NBITS-1):0] featureOutWriteValueFW,next_featureOutWriteValueFW;


    // BW SIGNALS : indexing of DK ( channel in, out , row and column.)
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] featureInChAddrBWDK,temp_featureInChAddrBWDK_r,NewFeatureInChAddrBWDK;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] featureOutChAddrBWDK,temp_featureOutChAddrBWDK_r,NewFeatureOutChAddrBWDK;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) -1):0] featureInRowAddrBWDK;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):0] featureInColumnAddrBWDK;
    // 8 pixel used for dk calculation 
    reg [0:(KERNEL_SIZE-1)][(N_OF_CH_READ*NBITS-1):0] featureInBWDK;
    reg [(N_OF_CH_READ*NBITS-1):0] dyBWDK;
    // dk output
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] dkBWDK;
    reg [0:(KERNEL_SIZE * KERNEL_SIZE -1)][(NBITS*N_OF_CH_READ-1):0] dk_r;
    // flag: is 1 when dkBWDK is valid and can be stored( used to modify kernels)
    reg valid;
    // DX SIGNALS 
    // DX address signals
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] gradientInChAddrBWDX,NewGradientInChAddrBWDX;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] gradientOutChAddrBWDX,NewGradientOutChAddrBWDX;
    reg [($clog2(FEATURE_OUT_ROW_SIZE[0]) -1):0] gradientOutRowAddrBWDX;
    reg [($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):0] gradientOutColumnAddrBWDX; 
    // DX PREFETCHING SIGNALS 
    reg [($clog2(FEATURE_IN_COLUMN_SIZE[0])-1):0] NewGradientInColumnPreFetch;
    reg [($clog2(FEATURE_IN_ROW_SIZE[0])-1):0] NewGradientInRowPreFetch;
    reg [($clog2(FEATURE_IN_CH_SIZE[NLAYER-1])-1):0] NewGradientInChAddrPreFetch;
    reg [($clog2(FEATURE_OUT_CH_SIZE[NLAYER-1])-1):0] NewGradientOutChAddrPreFetch;
    // GRADIENT IN SIGNALS
    reg [0: (GRADIENT_OUT_CH_SIZE[0]-1)]gradientInReadEn_r;
    reg [($clog2(GRADIENT_IN_ROW_SIZE[0]) + $clog2(GRADIENT_IN_COLUMN_SIZE[0]) -1) :0]gradientInReadAddr_r;
    reg [0: (GRADIENT_OUT_CH_SIZE[0]-1)][(NBITS*N_FEATURE_READ-1):0]gradientInReadValue_r;
    reg [0:2][0:(N_OF_CH_READ-1)][(N_FEATURE_READ*NBITS-1):0] gradientInBufferOfReadValue,next_gradientInBufferOfReadValue;
    // KERNEL IN  SIGNALS
    reg  [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] kernelBWDX;
    reg [(NBITS*N_OF_CH_READ-1):0] DyP1BWDX,DyP2BWDX,DyP3BWDX;
    reg [(NBITS-1):0]dxBWDX;
    // DX WRITE SIGNALS
    reg [0: (GRADIENT_OUT_CH_SIZE[0]-1)]gradientOutWriteEn_r;
    reg [($clog2(GRADIENT_OUT_ROW_SIZE[0]) + $clog2(GRADIENT_OUT_COLUMN_SIZE[0]) -1) :0]gradientOutWriteAddr_r;
    reg [(N_FEATURE_READ*NBITS-1):0] gradientOutWriteValue,next_gradientOutWriteValue;

    reg loadKernelBWDX;
    reg [0:($clog2(NLAYER)-1)]actLayer,next_actLayer;
    reg [1:0] stride;

    // Define states
    typedef enum logic [1:0] {
        LOAD_KERNEL = 2'b00,
        RUNNING = 2'b10

    } FW_FSM_t;

    FW_FSM_t state_reg, next_state;
    reg [3:0] kernelAddrRead,next_kernelAddrRead;
    reg stall,clk_stalled;

    // Instantiate the module
    FW_BW_PU #(MAC_SIZE, KERNEL_SIZE, N_OF_MAC_ROWS, N_OF_MAC_CLMN, N_OF_CH_READ,
              NBITS, FEATURE_IN_ROW_SIZE[0], FEATURE_IN_COLUMN_SIZE[0], FEATURE_IN_CH_SIZE[NLAYER-1],
              FEATURE_OUT_ROW_SIZE[0], FEATURE_OUT_COLUMN_SIZE[0], FEATURE_OUT_CH_SIZE[NLAYER-1],
              N_FEATURE_READ) FW_BW_PU_i (
        .bw(bw),
        .clk(clk_stalled),
        .rst(rst),
        .featureInActChSize(featureInActChSize),
        .featureOutActChSize(featureOutActChSize),
        .featureOutActRowSize(featureOutActRowSize),
        .featureOutActColumnSize(featureOutActColumnSize),
        .stride(stride),
        .kernelValsFW(kernelValsFW),
        .loadKernelFW(loadKernelFW),
        .featureInChAddrFW(featureInChAddrFW),
        .NewFeatureInChAddrFW(NewFeatureInChAddrFW),
        .featureInP1FW(featureInP1FW),
        .featureInP2FW(featureInP2FW),
        .featureInP3FW(featureInP3FW),
        .featureOutChAddrFW(featureOutChAddrFW),
        .NewFeatureOutChAddrFW(NewFeatureOutChAddrFW),
        .featureOutRowAddrFW(featureOutRowAddrFW),
        .featureOutColumnAddrFW(featureOutColumnAddrFW),
        .featureOutValFW(featureOutValFW),
        .featureInChAddrBWDK(featureInChAddrBWDK),
        .NewFeatureInChAddrBWDK(NewFeatureInChAddrBWDK),
        .featureOutChAddrBWDK(featureOutChAddrBWDK),
        .NewFeatureOutChAddrBWDK(NewFeatureOutChAddrBWDK),
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
        ,.NewGradientInChAddrBWDX(NewGradientInChAddrBWDX)
        ,.gradientOutChAddrBWDX(gradientOutChAddrBWDX)
        ,.NewGradientOutChAddrBWDX(NewGradientOutChAddrBWDX)
        ,.gradientOutRowAddrBWDX(gradientOutRowAddrBWDX)
        ,.gradientOutColumnAddrBWDX(gradientOutColumnAddrBWDX)
        ,.loadKernelBWDX(loadKernelBWDX)

    );
always @ (*)begin

    if ((gradientOutColumnAddrBWDX == 0)&&(gradientOutRowAddrBWDX ==0)&&(gradientOutChAddrBWDX == 0) && (gradientInChAddrBWDX == 0)&&(bw == 2)&&(kernelAddrRead != 8))begin
        stall <= 1;
    end else begin
        stall <= 0;    
    end

end

always @(*) begin
    if( stall == 1)begin
        clk_stalled <= 0;
    end else begin
        clk_stalled <= clk;
    end
end
// bit to stall PU

assign stride = 1;
/////////////////////////////// LAYER LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// layer counter updating logic. The logic depends of which operation we are
// According to wich operation we are processing ( BW = 0 : FORWARD ( FW ), BW = 1 : WEIGHT GRADIENT ( DK ), BW = 2 : GRADIENT PROPAGATION ( DX ))
// we set the boundaries to new layer. In forward the layer is increased when the all channel in are processed with all the channel out kernels
// In weight gradient calculation, when all the channels on the input gradeints has been convolved with the input features
// In gradient propagation , after the convolution of all the channels of the input gradient with all the kernels

always @ (*)begin

    if(rst== 1) begin
        next_actLayer = 0;
    end else begin
        if ( bw == 0)begin
            // if FW , check if all CH_IN are processed( +8 is because of we process 8 input channels at a time), all CH_OUT were processed, we are at the last row, we are at position 0 of the olumn counter ( not at MAX_COLUMN due to "snake" movememnt). check also if it is not last layer. ( if it is mantain layer and start backword)
            if(((featureInChAddrFW+8) == (FEATURE_IN_CH_SIZE[actLayer])) && (featureOutChAddrFW == (FEATURE_OUT_CH_SIZE[actLayer]-1)) && (featureOutRowAddrFW == (FEATURE_OUT_ROW_SIZE[actLayer]-1)) && (featureOutColumnAddrFW == 0)&&(actLayer !=(NLAYER-1))) begin
                next_actLayer <= actLayer +1;
            end else begin
                // if not, don't change layer
                next_actLayer <= actLayer;
            end 
        end else if (bw == 1)begin
            // in DK, we do not change layer, the layer will be updated while in DX
                next_actLayer <= actLayer; 
        end else if (bw == 2) begin
            // in DX, the conditions are the same of FW ( using gradient address ). 
            if(((gradientInChAddrBWDX+8) == (GRADIENT_IN_CH_SIZE[actLayer])) && (gradientOutChAddrBWDX == (GRADIENT_OUT_CH_SIZE[actLayer]-1)) && (gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1)) && (gradientOutColumnAddrBWDX == 0)) begin
                if(actLayer == 0) begin
                    // if we concluded the DX, we shall start to process a new image. The layer shall remain 0, while in the fetching logic it will already read the new kernel and the new feature
                    next_actLayer <= actLayer;
                end else begin
                    // othwerwise, decrement ( remember in back propagation the movement is from higher layer ( nearest to loss calculation) to lower ( near to GDumb memory))
                    next_actLayer <= actLayer -1;
                end
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
// It manage the bw signal which paresent which operation we are performing ( FW, DK or DX ) 

always @ (*) begin
    if( rst == 1)begin
        next_bw <= 0;
    end else begin
        if(bw == 0)begin 
            // When the convolution has been executed to the whole feature producing the whole feature out for all the layers, start backward
            if((actLayer == (NLAYER-1))&&(((featureInChAddrFW+8) == (FEATURE_IN_CH_SIZE[actLayer])) && (featureOutChAddrFW == (FEATURE_OUT_CH_SIZE[actLayer]-1)) && (featureOutRowAddrFW == (FEATURE_OUT_ROW_SIZE[actLayer]-1)) && (featureOutColumnAddrFW == 0))) begin
                next_bw <= 1;
            end else begin
                next_bw <= 0;
            end
        end else if ( bw == 1)begin
            // Also here iterate over all the 4 dimensions . Over them, move to DX
            if(((featureInChAddrBWDK+7) == (FEATURE_IN_CH_SIZE[actLayer]-1)) && (featureOutChAddrBWDK == (FEATURE_OUT_CH_SIZE[actLayer]-1)) && (featureInRowAddrBWDK == (FEATURE_IN_ROW_SIZE[actLayer]-1)) && ((featureInColumnAddrBWDK+7) == (FEATURE_IN_COLUMN_SIZE[actLayer]-1))) begin
                next_bw <= 2;
            end else begin
                next_bw <= 1;
            end
        end else if ( bw == 2) begin
            // Also there iterate over all 4 dimensiong. Over them , come back to DK calculation. In other process, the layer will be decreased
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


    // Define state update logic
    always_ff @(posedge clk or posedge rst) begin
        state_reg <= next_state; // Update state on clock edge
        kernelAddrRead <= next_kernelAddrRead;
    end

    // Define state transition logic between LOAD_KERNEL and RUNNING
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
                    if(valid == 1) begin
                        if(((featureInChAddrBWDK+7) == featureInActChSize) &&( featureOutChAddrBWDK == featureOutActChSize))begin
                            next_state <= RUNNING;
                            next_kernelAddrRead <= 0;
                        end else begin
                            next_state = LOAD_KERNEL;
                            next_kernelAddrRead <= 0;
                        end
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
                    if ((gradientOutColumnAddrBWDX == 0)&&(gradientOutRowAddrBWDX ==0)&&(gradientOutChAddrBWDX == 0) && (gradientInChAddrBWDX == 0)) begin // if we are just entered DX, move to load kernel and stall ( stall in other process)
                        next_state <= LOAD_KERNEL;
                        next_kernelAddrRead <= 0;
                    end else if((gradientOutColumnAddrBWDX == 9) && (gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1))) begin
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
// Save the address for kernel writing
always @ (posedge valid)begin
    temp_featureOutChAddrBWDK_r <= featureOutChAddrBWDK;
    temp_featureInChAddrBWDK_r <= featureInChAddrBWDK;
end
// Combinational logic over state 
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


// Prefetching addresses calculation
always @ (*) begin

    if ( bw == 0)begin
        if ( state_reg == LOAD_KERNEL)begin
            // if we are in load_kernel, new column and row address for prefetching will be automatically 0 ( new feature )
            // Channel in and out addr is calculated
            if((featureInChAddrFW+7) == featureInActChSize)begin
                NewFeatureInChAddrPreFetch = 0;
                if(featureOutChAddrFW == featureOutActChSize)begin
                    // If we compute the convolution for all the output feature, we can increment the layer counter
                    NewFeatureOutChAddrPreFetch = 0;
                    NewFeatureLayerPreFetch = actLayer +1;
                end else begin
                    // otherwise we mantain same layer and increase counter of outchannel
                    NewFeatureOutChAddrPreFetch = featureOutChAddrFW+1;
                    NewFeatureLayerPreFetch = actLayer;
                end
            end else begin
                NewFeatureLayerPreFetch = actLayer;
                NewFeatureInChAddrPreFetch = featureInChAddrFW+8;
                NewFeatureOutChAddrPreFetch = featureOutChAddrFW;
                
            end 
            NewFeatureInColumnPreFetch = 0;
            NewFeatureInRowPreFetch = 0;
        end else if ( state_reg == RUNNING)begin
            // if we are in running, channel in and out will be the same, only row and column has to be recalculated
            NewFeatureLayerPreFetch = actLayer;
            NewFeatureInChAddrPreFetch = featureInChAddrFW ;
            NewFeatureOutChAddrPreFetch = featureOutChAddrFW;
            if (featureOutRowAddrFW[0]==0)begin
            // check if we are at end of column
                if((featureOutColumnAddrFW+8) > featureOutActColumnSize)begin
                    // if we are at the end of the column of the feature, due to " snake " movement of addresses, we do not update column
                    // set to 0 the first 3 bits so we will read the last column index
                    NewFeatureInColumnPreFetch = {featureOutColumnAddrFW[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3],3'b0};
                    if(featureOutRowAddrFW == featureOutActRowSize)begin
                        //if last row, restart from zero
                        NewFeatureInRowPreFetch = 0;
                    end else begin
                        // if is not the last row,add 1 to row
                        NewFeatureInRowPreFetch = featureOutRowAddrFW +1;
                    end
                end else begin
                    // not end of column, take the next 8 pixel block. we must increase by 1 the 4th bit and set to 0 the 3 LSB
                    NewFeatureInColumnPreFetch = {featureOutColumnAddrFW[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3]+1,3'b0};
                    NewFeatureInRowPreFetch = featureOutRowAddrFW;
                end
            end else begin
                if((featureOutColumnAddrFW[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3]) == 0)begin // if we are approaching the lest boerder of the matrix
                    //for same reason, this is the last block to be loaded in the row, no column updated
                    NewFeatureInColumnPreFetch = {featureOutColumnAddrFW[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3],3'b0};
                    if(featureOutRowAddrFW == featureOutActRowSize)begin
                        //if last row, restart from zero
                        NewFeatureInRowPreFetch = 0;
                    end else begin
                        // if is not the last row,add 1 to row
                        NewFeatureInRowPreFetch = featureOutRowAddrFW +1;
                    end
                end else begin
                // not end of column, take the next 8 pixel block. we must increase by 1 the 4th bit and set to 0 the 3 LSB
                NewFeatureInColumnPreFetch = {featureOutColumnAddrFW[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3]-1,3'b0};
                NewFeatureInRowPreFetch = featureOutRowAddrFW;
            end
            end
        end else begin // default 
                NewFeatureInChAddrPreFetch = 0;
                NewFeatureOutChAddrPreFetch = 0;
                NewFeatureLayerPreFetch = 0;
                NewFeatureInColumnPreFetch = 0;
                NewFeatureInRowPreFetch = 0;
        end
    end else if ( bw == 2) begin // on bw == 2 same logic as bw == 0, change only feature channel address with gradient channel address
        if(state_reg == LOAD_KERNEL) begin
            if((gradientInChAddrBWDX+8) == GRADIENT_IN_CH_SIZE[actLayer])begin
                NewFeatureInChAddrPreFetch = 0;
                if(gradientOutChAddrBWDX == (GRADIENT_OUT_CH_SIZE[actLayer]-1))begin
                    NewFeatureOutChAddrPreFetch = 0;
                    NewFeatureLayerPreFetch = actLayer +1;
                end else begin
                    NewFeatureLayerPreFetch = actLayer;
                    NewFeatureOutChAddrPreFetch = gradientOutChAddrBWDX+1;
                end
            end else begin
                NewFeatureInChAddrPreFetch = gradientInChAddrBWDX+8;
                NewFeatureOutChAddrPreFetch = gradientOutChAddrBWDX;
                NewFeatureLayerPreFetch = actLayer;
            end 
            NewFeatureInColumnPreFetch = 0;
            NewFeatureInRowPreFetch = 0;
        end else if ( state_reg == RUNNING) begin
            // if we are in running, channel in and out will be the same, only row and column has to be recalculated
            NewFeatureLayerPreFetch = actLayer;
            NewFeatureInChAddrPreFetch = gradientInChAddrBWDX ;
            NewFeatureOutChAddrPreFetch = gradientOutChAddrBWDX;
            if (gradientOutRowAddrBWDX[0]==0)begin
            // check if we are at end of column
                if((gradientOutColumnAddrBWDX+8) > (GRADIENT_OUT_COLUMN_SIZE[actLayer]-1))begin
                    // if we are at the end of the column of the feature, due to " snake " movement of addresses, we do not update column
                    // set to 0 the first 3 bits so we will read the last column index
                    NewFeatureInColumnPreFetch = {gradientOutColumnAddrBWDX[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3],3'b0};
                    if(gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1))begin
                        //if last row, restart from zero
                        NewFeatureInRowPreFetch = 0;
                    end else begin
                        // if is not the last row,add 1 to row
                        NewFeatureInRowPreFetch = gradientOutRowAddrBWDX +1;
                    end
                end else begin
                    // not end of column, take the next 8 pixel block. we must increase by 1 the 4th bit and set to 0 the 3 LSB
                    NewFeatureInColumnPreFetch = {gradientOutColumnAddrBWDX[($clog2(GRADIENT_OUT_COLUMN_SIZE[0]) -1):3]+1,3'b0};
                    NewFeatureInRowPreFetch = gradientOutRowAddrBWDX;
                end
            end else begin
                if((gradientOutColumnAddrBWDX[($clog2(GRADIENT_OUT_COLUMN_SIZE[0]) -1):3]) == 0)begin // if we are approaching the lest boerder of the matrix
                    //for same reason, this is the last block to be loaded in the row, no column updated
                    NewFeatureInColumnPreFetch = {gradientOutColumnAddrBWDX[($clog2(FEATURE_OUT_COLUMN_SIZE[0]) -1):3],3'b0};
                    if(gradientOutRowAddrBWDX == (GRADIENT_OUT_ROW_SIZE[actLayer]-1))begin
                        //if last row, restart from zero
                        NewFeatureInRowPreFetch = 0;
                    end else begin
                        // if is not the last row,add 1 to row
                        NewFeatureInRowPreFetch = gradientOutRowAddrBWDX +1;
                    end
                end else begin
                // not end of column, take the next 8 pixel block. we must increase by 1 the 4th bit and set to 0 the 3 LSB
                NewFeatureInColumnPreFetch = {gradientOutColumnAddrBWDX[($clog2(GRADIENT_OUT_COLUMN_SIZE[0]) -1):3]-1,3'b0};
                NewFeatureInRowPreFetch = gradientOutRowAddrBWDX;
            end
        end
        end else begin // DEFAULT
        NewFeatureInChAddrPreFetch = 0;
        NewFeatureOutChAddrPreFetch = 0;
        NewFeatureLayerPreFetch = 0;
        NewFeatureInColumnPreFetch = 0;
        NewFeatureInRowPreFetch = 0;
        end
    end
end

always @ (*)begin
    NewGradientInColumnPreFetch = NewFeatureInColumnPreFetch;
    NewGradientInRowPreFetch = NewFeatureInRowPreFetch;
    NewGradientInChAddrPreFetch = NewFeatureInChAddrPreFetch;
    NewGradientOutChAddrPreFetch = NewFeatureOutChAddrPreFetch;
end
////////////////////////////////////////// KERNEL MEMORY LOGIC \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// kernel read enable and kernel read value register. Used to enable and read value from the matrix of SRAM.
// Due to unability to dynamic indexing, declared with maximum sizes then will be partially used

// se siamo in LOAD_KERNEL status, allora leggiamoo i kernel e salviamo in buffer
// TODO : check sensitivity list. actually read wrongly the values

// KERNEL READ BUFFER FILLING
always @ (*) begin
    if ( state_reg == LOAD_KERNEL) begin
        if ( bw == 0) begin
            kernelValsFW[kernelAddrRead][(NBITS-1):0]           =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch]; // first channel in kernel 
            kernelValsFW[kernelAddrRead][(2*NBITS-1):(NBITS)]   =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+1]; // 2nd channel in kernel 
            kernelValsFW[kernelAddrRead][(3*NBITS-1):(2*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+2]; // 3th channel in kernel 
            kernelValsFW[kernelAddrRead][(4*NBITS-1):(3*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+3]; // 4th channel in kernel 
            kernelValsFW[kernelAddrRead][(5*NBITS-1):(4*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+4]; // 5th channel in kernel 
            kernelValsFW[kernelAddrRead][(6*NBITS-1):(5*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+5]; // 6th channel in kernel 
            kernelValsFW[kernelAddrRead][(7*NBITS-1):(6*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+6]; // 7th channel in kernel 
            kernelValsFW[kernelAddrRead][(8*NBITS-1):(7*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewFeatureOutChAddrPreFetch][NewFeatureInChAddrPreFetch+7]; // 8th channel in kernel 
            kernelWriteValue_r = 0;
            kernelBWDX = 0;
        end else if( bw == 1) begin
            // If we are in Dk, the actual valid DK is summed and written back in SRAM
            kernelValsFW = 0;
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r]     =  dk_r[kernelAddrRead][(1*NBITS-1):(0*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+1]   =  dk_r[kernelAddrRead][(2*NBITS-1):(1*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+2]   =  dk_r[kernelAddrRead][(3*NBITS-1):(2*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+3]   =  dk_r[kernelAddrRead][(4*NBITS-1):(3*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+4]   =  dk_r[kernelAddrRead][(5*NBITS-1):(4*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+5]   =  dk_r[kernelAddrRead][(6*NBITS-1):(5*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+6]   =  dk_r[kernelAddrRead][(7*NBITS-1):(6*NBITS)];
            kernelWriteValue_r[temp_featureOutChAddrBWDK_r][temp_featureInChAddrBWDK_r+7]   =  dk_r[kernelAddrRead][(8*NBITS-1):(7*NBITS)];
            kernelBWDX = 0;
        end else if ( bw == 2) begin
            // If we are in Dx, kernel is loaded as in forward. Is only chaned the PU port
            kernelValsFW = 0;
            kernelWriteValue_r = 0;
            kernelBWDX[kernelAddrRead][(NBITS-1):0]           =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch]; // first channel in kernel 
            kernelBWDX[kernelAddrRead][(2*NBITS-1):NBITS]     =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+1]; // 2nd channel in kernel 
            kernelBWDX[kernelAddrRead][(3*NBITS-1):(2*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+2]; // 3th channel in kernel 
            kernelBWDX[kernelAddrRead][(4*NBITS-1):(3*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+3]; // 4th channel in kernel 
            kernelBWDX[kernelAddrRead][(5*NBITS-1):(4*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+4]; // 5th channel in kernel 
            kernelBWDX[kernelAddrRead][(6*NBITS-1):(5*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+5]; // 6th channel in kernel 
            kernelBWDX[kernelAddrRead][(7*NBITS-1):(6*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+6]; // 7th channel in kernel 
            kernelBWDX[kernelAddrRead][(8*NBITS-1):(7*NBITS)] =  kernelReadValues_r[NewFeatureLayerPreFetch][NewGradientOutChAddrPreFetch][NewGradientInChAddrPreFetch+7]; // 8th channel in kernel 
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
                    if((ii == (NewFeatureLayerPreFetch)) && (jj == (NewFeatureOutChAddrPreFetch)) && (kk == (NewFeatureInChAddrPreFetch)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
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
                for(int kk=0; kk < FEATURE_IN_CH_SIZE[NLAYER-1]; kk=kk+8)begin
                    if ( state_reg == LOAD_KERNEL )begin
                        // WHEN CALCULATION DK KERNEL IS READ AND WRITTEN BACK 
                        if((ii == (actLayer)) && (jj == (temp_featureOutChAddrBWDK_r)) && (kk == (temp_featureInChAddrBWDK_r)))begin
                            kernelWriteEn_r[ii][jj][kk] = 1;
                            kernelWriteEn_r[ii][jj][kk+1] = 1;
                            kernelWriteEn_r[ii][jj][kk+2] = 1;
                            kernelWriteEn_r[ii][jj][kk+3] = 1;
                            kernelWriteEn_r[ii][jj][kk+4] = 1;
                            kernelWriteEn_r[ii][jj][kk+5] = 1;
                            kernelWriteEn_r[ii][jj][kk+6] = 1;
                            kernelWriteEn_r[ii][jj][kk+7] = 1;
                            kernelReadEn_r[ii][jj][kk] = 1;
                            kernelReadEn_r[ii][jj][kk+1] = 1;
                            kernelReadEn_r[ii][jj][kk+2] = 1;
                            kernelReadEn_r[ii][jj][kk+3] = 1;
                            kernelReadEn_r[ii][jj][kk+4] = 1;
                            kernelReadEn_r[ii][jj][kk+5] = 1;
                            kernelReadEn_r[ii][jj][kk+6] = 1;
                            kernelReadEn_r[ii][jj][kk+7] = 1;
                        end else begin
                            kernelWriteEn_r[ii][jj][kk] = 0;
                            kernelWriteEn_r[ii][jj][kk+1] = 0;
                            kernelWriteEn_r[ii][jj][kk+2] = 0;
                            kernelWriteEn_r[ii][jj][kk+3] = 0;
                            kernelWriteEn_r[ii][jj][kk+4] = 0;
                            kernelWriteEn_r[ii][jj][kk+5] = 0;
                            kernelWriteEn_r[ii][jj][kk+6] = 0;
                            kernelWriteEn_r[ii][jj][kk+7] = 0;
                            kernelReadEn_r[ii][jj][kk] = 0;
                            kernelReadEn_r[ii][jj][kk+1] = 0;
                            kernelReadEn_r[ii][jj][kk+2] = 0;
                            kernelReadEn_r[ii][jj][kk+3] = 0;
                            kernelReadEn_r[ii][jj][kk+4] = 0;
                            kernelReadEn_r[ii][jj][kk+5] = 0;
                            kernelReadEn_r[ii][jj][kk+6] = 0;
                            kernelReadEn_r[ii][jj][kk+7] = 0;
                        end
                    end else begin
                        kernelWriteEn_r[ii][jj][kk] = 0;
                            kernelWriteEn_r[ii][jj][kk+1] = 0;
                            kernelWriteEn_r[ii][jj][kk+2] = 0;
                            kernelWriteEn_r[ii][jj][kk+3] = 0;
                            kernelWriteEn_r[ii][jj][kk+4] = 0;
                            kernelWriteEn_r[ii][jj][kk+5] = 0;
                            kernelWriteEn_r[ii][jj][kk+6] = 0;
                            kernelWriteEn_r[ii][jj][kk+7] = 0;
                            kernelReadEn_r[ii][jj][kk] = 0;
                            kernelReadEn_r[ii][jj][kk+1] = 0;
                            kernelReadEn_r[ii][jj][kk+2] = 0;
                            kernelReadEn_r[ii][jj][kk+3] = 0;
                            kernelReadEn_r[ii][jj][kk+4] = 0;
                            kernelReadEn_r[ii][jj][kk+5] = 0;
                            kernelReadEn_r[ii][jj][kk+6] = 0;
                            kernelReadEn_r[ii][jj][kk+7] = 0;
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
                    if((ii == (NewFeatureLayerPreFetch)) && (jj == (NewGradientInChAddrPreFetch)) && (kk == (NewGradientOutChAddrPreFetch)))begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
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
                SRAM # (.PORT_WIDTH(NBITS),.MEMORY_WIDHT(16),.MEMORY_TYPE("KERNEL"),.CHANNEL_IN(k),.CHANNEL_OUT(j))
                SRAMKijk(.writeAddr(kernelAddrRead),
                .readAddr(kernelAddrRead),
                .writeEn(kernelWriteEn_r[i][j][k]),
                .readEn(kernelReadEn_r[i][j][k]),
                .readValue(kernelReadValues_r[i][j][k]),
                .writeValue(kernelWriteValue_r[i][j]),
                .clk(clk),
                .rst(rst));
            end
        end
    end
endgenerate


// READ ENABLE FOR FEATURE IN READING
always @ ( * ) begin 
    if(bw==0) begin // IF WE ARE IN FORWARD, READ 8 CHANNEL IN
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+8)begin
                if(((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] < 3)&&(featureOutRowAddrFW[0]==1))||((((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0]+2)&7) > 4)&&(featureOutRowAddrFW[0]==0))||((state_reg == LOAD_KERNEL) && (kernelAddrRead > 5)))begin // se mancano 3 clock al nuovo blocco di feature inizio a leggere
                    if((ii == actLayer) && (jj == NewFeatureInChAddrPreFetch))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
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
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+8)begin
                if(featureInColumnAddrBWDK[($clog2(N_FEATURE_READ)-1):0] > 4) begin
                if((ii == actLayer) && (jj == featureInChAddrBWDK))begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
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
    end else begin // if DX is calculated , feture is not needed
        for(int ii=0; ii<NLAYER; ii=ii+1)begin
            for (int jj=0; jj< FEATURE_IN_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            featureInReadEn_r[ii][jj]   = 0;
            end
        end 
    end
end
// GDumb read logic
assign featureInReadEnFWGDUMB[0] = featureInReadEn_r[0][0]; // when we are on layer 0, enable read from external GDumb RAM
assign featureInReadEnFWGDUMB[1] = featureInReadEn_r[0][1];
assign featureInReadEnFWGDUMB[2] = featureInReadEn_r[0][2];
assign featureInReadAddrFWGDUMB = featureInReadAddr_r;
// GDUMB VALUE READ LOADED INTO FEATURE IN SIGNALS
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

// FEATURE OUT WRITE ENABLE
always @ ( * ) begin 
    for(int ii=0; ii<NLAYER; ii=ii+1)begin
        for (int jj=0; jj< FEATURE_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if(bw==0)begin
                if(((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] ==0)&&(featureOutRowAddrFW[0] == 0)) || ((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] ==7)&&(featureOutRowAddrFW[0] == 1)))begin// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
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
// FEATURE IN PREFETCHING - BUFFER LOADING AND FEATURE IN ADDRESS ASSIGN. 
always @(*)begin
    if(bw==0)begin
        if((featureOutRowAddrFW == featureOutActRowSize)&&(featureOutColumnAddrFW < 3)) begin
            if(featureOutColumnAddrFW == 2)begin // carichiamo primo pixel
             // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            featureInReadAddr_r <= 0  ;
            next_featureInBufferOfReadValueFW[0][0] <= featureInReadValue_r[actLayer][0]; // save 8 channel of first row
            next_featureInBufferOfReadValueFW[0][1] <= featureInReadValue_r[actLayer][0+1];
            next_featureInBufferOfReadValueFW[0][2] <= featureInReadValue_r[actLayer][0+2];
            next_featureInBufferOfReadValueFW[0][3] <= featureInReadValue_r[actLayer][0+3];
            next_featureInBufferOfReadValueFW[0][4] <= featureInReadValue_r[actLayer][0+4];
            next_featureInBufferOfReadValueFW[0][5] <= featureInReadValue_r[actLayer][0+5];
            next_featureInBufferOfReadValueFW[0][6] <= featureInReadValue_r[actLayer][0+6];
            next_featureInBufferOfReadValueFW[0][7] <= featureInReadValue_r[actLayer][0+7];
            end else if(featureOutColumnAddrFW == 1)begin 
            // SAve check as above. In this case we also sum 1 to row
            featureInReadAddr_r <= (1 << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])));           
            next_featureInBufferOfReadValueFW[1][0] <= featureInReadValue_r[actLayer][0]; // save 8 channel of second row
            next_featureInBufferOfReadValueFW[1][1] <= featureInReadValue_r[actLayer][0+1];
            next_featureInBufferOfReadValueFW[1][2] <= featureInReadValue_r[actLayer][0+2];
            next_featureInBufferOfReadValueFW[1][3] <= featureInReadValue_r[actLayer][0+3];
            next_featureInBufferOfReadValueFW[1][4] <= featureInReadValue_r[actLayer][0+4];
            next_featureInBufferOfReadValueFW[1][5] <= featureInReadValue_r[actLayer][0+5];
            next_featureInBufferOfReadValueFW[1][6] <= featureInReadValue_r[actLayer][0+6];
            next_featureInBufferOfReadValueFW[1][7] <= featureInReadValue_r[actLayer][0+7];
            end else if(featureOutColumnAddrFW == 0)begin 
            // same reason as above
            featureInReadAddr_r <=  (2 << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])));           
            next_featureInBufferOfReadValueFW[2][0] <= featureInReadValue_r[actLayer][0]; // save 8 channel of third row
            next_featureInBufferOfReadValueFW[2][1] <= featureInReadValue_r[actLayer][0+1];
            next_featureInBufferOfReadValueFW[2][2] <= featureInReadValue_r[actLayer][0+2];
            next_featureInBufferOfReadValueFW[2][3] <= featureInReadValue_r[actLayer][0+3];
            next_featureInBufferOfReadValueFW[2][4] <= featureInReadValue_r[actLayer][0+4];
            next_featureInBufferOfReadValueFW[2][5] <= featureInReadValue_r[actLayer][0+5];
            next_featureInBufferOfReadValueFW[2][6] <= featureInReadValue_r[actLayer][0+6]; 
            next_featureInBufferOfReadValueFW[2][7] <= featureInReadValue_r[actLayer][0+7];
            end
        end else begin

        if(((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 2)&&(featureOutRowAddrFW[0]==1))||((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 3)&&(featureOutRowAddrFW[0]==0))||(kernelAddrRead == 6))begin // carichiamo primo pixel
             // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            featureInReadAddr_r <= (NewFeatureInRowPreFetch << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+NewFeatureInColumnPreFetch;   
            next_featureInBufferOfReadValueFW[0][0] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch]; // save 8 channel of first row
            next_featureInBufferOfReadValueFW[0][1] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+1];
            next_featureInBufferOfReadValueFW[0][2] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+2];
            next_featureInBufferOfReadValueFW[0][3] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+3];
            next_featureInBufferOfReadValueFW[0][4] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+4];
            next_featureInBufferOfReadValueFW[0][5] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+5];
            next_featureInBufferOfReadValueFW[0][6] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+6];
            next_featureInBufferOfReadValueFW[0][7] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+7];
        end else if(((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 1)&&(featureOutRowAddrFW[0]==1))||((featureOutRowAddrFW[0]==0)&&(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 4))||(kernelAddrRead == 7))begin 
            // SAve check as above. In this case we also sum 1 to row
            featureInReadAddr_r <= (NewFeatureInRowPreFetch+1 << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+NewFeatureInColumnPreFetch;           
            next_featureInBufferOfReadValueFW[1][0] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch]; // save 8 channel of second row
            next_featureInBufferOfReadValueFW[1][1] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+1];
            next_featureInBufferOfReadValueFW[1][2] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+2];
            next_featureInBufferOfReadValueFW[1][3] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+3];
            next_featureInBufferOfReadValueFW[1][4] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+4];
            next_featureInBufferOfReadValueFW[1][5] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+5];
            next_featureInBufferOfReadValueFW[1][6] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+6];
            next_featureInBufferOfReadValueFW[1][7] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+7];
        end else if(((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 0)&&(featureOutRowAddrFW[0]==1))||((featureOutRowAddrFW[0]==0)&&(featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 5))||(kernelAddrRead == 8))begin 
            // same reason as above
            featureInReadAddr_r <= (NewFeatureInRowPreFetch+2 << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+NewFeatureInColumnPreFetch;           
            next_featureInBufferOfReadValueFW[2][0] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch]; // save 8 channel of third row
            next_featureInBufferOfReadValueFW[2][1] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+1];
            next_featureInBufferOfReadValueFW[2][2] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+2];
            next_featureInBufferOfReadValueFW[2][3] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+3];
            next_featureInBufferOfReadValueFW[2][4] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+4];
            next_featureInBufferOfReadValueFW[2][5] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+5];
            next_featureInBufferOfReadValueFW[2][6] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+6]; 
            next_featureInBufferOfReadValueFW[2][7] <= featureInReadValue_r[NewFeatureLayerPreFetch][NewFeatureInChAddrPreFetch+7];
        end else begin
            featureInReadAddr_r <= 0; // default . 
        end  
        end     
    end else if ( bw == 1) begin // if we are in bw
        if(featureInColumnAddrBWDK[($clog2(N_FEATURE_READ)-1):0] == 5)begin // carichiamo primo pixel
             // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            featureInReadAddr_r <= (featureInRowAddrBWDK << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureInColumnAddrBWDK+3;   
            next_featureInBufferOfReadValueFW[0][0] <= featureInReadValue_r[actLayer][featureInChAddrBWDK]; // save 8 channel of first row
            next_featureInBufferOfReadValueFW[0][1] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+1];
            next_featureInBufferOfReadValueFW[0][2] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+2];
            next_featureInBufferOfReadValueFW[0][3] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+3];
            next_featureInBufferOfReadValueFW[0][4] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+4];
            next_featureInBufferOfReadValueFW[0][5] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+5];
            next_featureInBufferOfReadValueFW[0][6] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+6];
            next_featureInBufferOfReadValueFW[0][7] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+7];
        end else if(featureInColumnAddrBWDK[($clog2(N_FEATURE_READ)-1):0] == 6)begin 
            // SAve check as above. In this case we also sum 1 to row
            featureInReadAddr_r <= ((featureInRowAddrBWDK+1) << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureInColumnAddrBWDK+2;           
            next_featureInBufferOfReadValueFW[1][0] <= featureInReadValue_r[actLayer][featureInChAddrBWDK]; // save 8 channel of second row
            next_featureInBufferOfReadValueFW[1][1] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+1];
            next_featureInBufferOfReadValueFW[1][2] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+2];
            next_featureInBufferOfReadValueFW[1][3] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+3];
            next_featureInBufferOfReadValueFW[1][4] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+4];
            next_featureInBufferOfReadValueFW[1][5] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+5];
            next_featureInBufferOfReadValueFW[1][6] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+6];
            next_featureInBufferOfReadValueFW[1][7] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+7];
        end else if(featureInColumnAddrBWDK[($clog2(N_FEATURE_READ)-1):0] == 7)begin 
            // same reason as above
            featureInReadAddr_r <= ((featureInRowAddrBWDK+2) << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureInColumnAddrBWDK+1;           
            next_featureInBufferOfReadValueFW[2][0] <= featureInReadValue_r[actLayer][featureInChAddrBWDK]; // save 8 channel of third row
            next_featureInBufferOfReadValueFW[2][1] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+1];
            next_featureInBufferOfReadValueFW[2][2] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+2];
            next_featureInBufferOfReadValueFW[2][3] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+3];
            next_featureInBufferOfReadValueFW[2][4] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+4];
            next_featureInBufferOfReadValueFW[2][5] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+5];
            next_featureInBufferOfReadValueFW[2][6] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+6]; 
            next_featureInBufferOfReadValueFW[2][7] <= featureInReadValue_r[actLayer][featureInChAddrBWDK+7];
        end else begin
            featureInReadAddr_r <= 0; // default . 
        end
    end 

end
// FEATURE OUT WRITE BUFFER VALUE LOAD 
always @ (*)begin
    if ( bw == 0)
        if (featureOutRowAddrFW[0] == 0)begin
            if (featureOutColumnAddrFW[2:0] == 0)begin
                next_featureOutWriteValueFW = {{(7*NBITS){1'b0}},featureOutValFWActivated} ;
            end else begin
                next_featureOutWriteValueFW = featureOutWriteValueFW | (featureOutValFWActivated << (NBITS*featureOutColumnAddrFW[2:0])); // filling of write out buffer
            end
        end else begin
            if (featureOutColumnAddrFW[2:0] == 7)begin
                next_featureOutWriteValueFW = {featureOutValFWActivated,{(7*NBITS){1'b0}}} ;
            end else begin
                next_featureOutWriteValueFW = featureOutWriteValueFW | (featureOutValFWActivated << (NBITS*featureOutColumnAddrFW[2:0])); // filling of write out buffer
            end
        end
end

always @ (posedge clk) begin
    featureOutWriteValueFW = next_featureOutWriteValueFW;
end

// WRITING OF FEATURE OUT BUFFER
always @ (*) begin
    if(bw==0)begin
    if(((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 6)&&(featureOutRowAddrFW[0]==0))||((featureOutColumnAddrFW[($clog2(N_FEATURE_READ)-1):0] == 7)&&(featureOutRowAddrFW[0]==1))||((featureOutColumnAddrFW == 0)&&(featureOutRowAddrFW[0]==0)))begin // new 8 feature are loaded
        featureInBufferOfReadValueFW = next_featureInBufferOfReadValueFW;
    end
    end else if (bw==1) begin
    if(featureInColumnAddrBWDK[($clog2(N_FEATURE_READ)-1):0] == 0)begin // new 8 feature are loaded
        featureInBufferOfReadValueFW = next_featureInBufferOfReadValueFW;
    end
    end 

end
// Activation layer : module to apply activation to pixel 
activation # (.act_rule(ACTIVATION)) activation (.input_value(featureOutValFW),.output_value(featureOutValFWActivated));

// PIXELS LOAD FROM FEATURE IN BUFFER READ
always @ (*)begin
    if(bw==0)begin
    if(featureOutRowAddrFW[0] == 0)begin
        if(featureOutColumnAddrFW > (featureOutActColumnSize-2))begin
            featureInP1FW = 0;
            featureInP2FW = 0;
            featureInP3FW = 0;
        end else if (featureOutColumnAddrFW == 0)begin 
            featureInP1FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP1FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][((featureOutColumnAddrFW[2:0])&7)*NBITS+:NBITS]; 

            featureInP2FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP2FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 
            featureInP2FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 
            featureInP2FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 
            featureInP2FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 
            featureInP2FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 
            featureInP2FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 
            featureInP2FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][((featureOutColumnAddrFW[2:0]+1)&7)*NBITS+:NBITS]; 

            featureInP3FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP3FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS];
        end else begin
            featureInP1FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[0][0][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP1FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[0][1][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[0][2][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[0][3][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[0][4][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[0][5][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[0][6][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[0][7][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 

            featureInP2FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[1][0][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP2FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[1][1][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP2FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[1][2][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP2FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[1][3][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP2FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[1][4][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP2FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[1][5][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP2FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[1][6][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP2FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[1][7][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 

            featureInP3FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP3FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
            featureInP3FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][((featureOutColumnAddrFW[2:0]+2)&7)*NBITS+:NBITS]; 
        end
    end else begin
        if(featureOutColumnAddrFW == featureOutActColumnSize)begin
            // new row, pass p1 = [row][maxColumn], p2 = , p3 = 0
            featureInP1FW[(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            featureInP1FW[(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP1FW[(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP1FW[(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP1FW[(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP1FW[(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP1FW[(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP1FW[(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][featureOutColumnAddrFW[2:0]*NBITS+:NBITS]; 
            featureInP2FW = 0;
            featureInP3FW = 0;
        end else begin // otherwise, normal
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
    end 
end

// FEATURE IN BWDK
always @(*)begin
    if(bw == 1)begin
    if(featureInRowAddrBWDK < (featureOutActRowSize-1))begin
    featureInBWDK[0][(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[0][0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // channel 0, featureInColumnAddrBWDK-th feature of the buffer
    featureInBWDK[0][(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[0][1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // channel 1
    featureInBWDK[0][(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[0][2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[0][3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[0][4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[0][5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[0][6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[0][7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 

    featureInBWDK[1][(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[1][0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInBWDK[1][(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[1][1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[1][2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[1][3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[1][4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[1][5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[1][6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[1][7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 

    featureInBWDK[2][(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[2][0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInBWDK[2][(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[2][1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[2][(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[2][2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[2][(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[2][3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[2][(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[2][4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[2][(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[2][5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[2][(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[2][6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[2][(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[2][7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    end else if(featureInRowAddrBWDK == (featureOutActRowSize-1))begin
    featureInBWDK[0][(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[0][0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInBWDK[0][(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[0][1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[0][2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[0][3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[0][4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[0][5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[0][6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[0][7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 

    featureInBWDK[1][(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[1][0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInBWDK[1][(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[1][1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[1][2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[1][3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[1][4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[1][5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[1][6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[1][(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[1][7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 

    featureInBWDK[2] = 0;

    end else if(featureInRowAddrBWDK == featureOutActRowSize)begin
    featureInBWDK[0][(1*NBITS-1):0*NBITS] = featureInBufferOfReadValueFW[0][0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    featureInBWDK[0][(2*NBITS-1):1*NBITS] = featureInBufferOfReadValueFW[0][1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(3*NBITS-1):2*NBITS] = featureInBufferOfReadValueFW[0][2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(4*NBITS-1):3*NBITS] = featureInBufferOfReadValueFW[0][3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(5*NBITS-1):4*NBITS] = featureInBufferOfReadValueFW[0][4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(6*NBITS-1):5*NBITS] = featureInBufferOfReadValueFW[0][5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(7*NBITS-1):6*NBITS] = featureInBufferOfReadValueFW[0][6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    featureInBWDK[0][(8*NBITS-1):7*NBITS] = featureInBufferOfReadValueFW[0][7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 

    featureInBWDK[1]  = 0;

    featureInBWDK[2] = 0;
    end
    end
end
// FEATURE OUT WRITE ADDRESS COMPOSITION
always @(*) begin
    if (featureOutRowAddrFW[0] == 0)begin
        if (featureOutColumnAddrFW == 0 ) begin
            // if im even but at beginnig, the previus block to be written was in a odd block in a previous row
            featureOutWriteAddrFW = ((featureOutRowAddrFW-1) << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureOutColumnAddrFW; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end else begin
            // otherwise, the block to be saved is of the previous 8 feture out
            featureOutWriteAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureOutColumnAddrFW-8; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end
    end else begin
        if (featureOutColumnAddrFW == (FEATURE_OUT_COLUMN_SIZE[actLayer]-1)) begin
            // if we are into new odd block , our feture out was of the previous even row
            featureOutWriteAddrFW = ((featureOutRowAddrFW-1) << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureOutColumnAddrFW-7; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end else begin
            featureOutWriteAddrFW = (featureOutRowAddrFW << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureOutColumnAddrFW+1; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end
    end
end



///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// FEATURE OUT MEMORY \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////////////////////////////////////
// FEATURE OUT MEMORY : CHANNEL OUT NUMBER OF MEMORY, EACH OF #ROWS*(#CLOUMN/8) WORDS OF 16*8= 128 BIT OF WORD LENGHT

generate
    for(i=0; i < NLAYER; i= i+1)begin
        for(j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1) begin
            SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),
            .MEMORY_WIDHT(FEATURE_OUT_ROW_SIZE[i]*(FEATURE_OUT_COLUMN_SIZE[i]/N_FEATURE_READ)),
            .MEMORY_TYPE("FEATURE"),
            .CHANNEL_IN(0),
            .CHANNEL_OUT(j))
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

// READ GRADIENT ENABLE
always @(*) begin
    if ( bw == 0)begin
        for ( int jj = 0; jj < FEATURE_OUT_CH_SIZE[0]; jj=jj+1)begin // Forward operation , no read over gradient memory
            gradientInReadEn_r[jj]=0;
        end 
    end else if ( bw == 1 ) begin // if dk calculation , read given dk channel
        for ( int jj = 0; jj < FEATURE_OUT_CH_SIZE[0]; jj=jj+8)begin 
            if(featureInColumnAddrBWDK[2:0] == 0)begin
                if(featureOutChAddrBWDK == jj)begin
                        gradientInReadEn_r[jj]   = 1;
                        gradientInReadEn_r[jj+1] = 1;
                        gradientInReadEn_r[jj+2] = 1;
                        gradientInReadEn_r[jj+3] = 1;
                        gradientInReadEn_r[jj+4] = 1;
                        gradientInReadEn_r[jj+5] = 1;
                        gradientInReadEn_r[jj+6] = 1;
                        gradientInReadEn_r[jj+7] = 1;
                    end else begin 
                        gradientInReadEn_r[jj]   = 0;
                        gradientInReadEn_r[jj+1] = 0;
                        gradientInReadEn_r[jj+2] = 0;
                        gradientInReadEn_r[jj+3] = 0;
                        gradientInReadEn_r[jj+4] = 0;
                        gradientInReadEn_r[jj+5] = 0;
                        gradientInReadEn_r[jj+6] = 0;
                        gradientInReadEn_r[jj+7] = 0;    
                    end
            end else begin
                gradientInReadEn_r[jj]   = 0;
                gradientInReadEn_r[jj+1] = 0;
                gradientInReadEn_r[jj+2] = 0;
                gradientInReadEn_r[jj+3] = 0;
                gradientInReadEn_r[jj+4] = 0;
                gradientInReadEn_r[jj+5] = 0;
                gradientInReadEn_r[jj+6] = 0;
                gradientInReadEn_r[jj+7] = 0;    
            end
        end
    end else if ( bw == 2 ) begin // if dx, read of dx channel
        for (int jj=0; jj< GRADIENT_IN_CH_SIZE[NLAYER-1]; jj=jj+8)begin
                if(((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] < 3)&&(gradientOutRowAddrBWDX[0]==1))||((((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0]+2)&7) > 4)&&(gradientOutRowAddrBWDX[0]==0))||((state_reg == LOAD_KERNEL) && (kernelAddrRead > 5)))begin // se mancano 3 clock al nuovo blocco di feature inizio a leggere
                    if(jj == NewFeatureInChAddrPreFetch)begin // set to 1 the feature in enable according with the actual layer, channel out and channel in
                        gradientInReadEn_r[jj]   = 1;
                        gradientInReadEn_r[jj+1] = 1;
                        gradientInReadEn_r[jj+2] = 1;
                        gradientInReadEn_r[jj+3] = 1;
                        gradientInReadEn_r[jj+4] = 1;
                        gradientInReadEn_r[jj+5] = 1;
                        gradientInReadEn_r[jj+6] = 1;
                        gradientInReadEn_r[jj+7] = 1;
                    end else begin 
                        gradientInReadEn_r[jj]   = 0;
                        gradientInReadEn_r[jj+1] = 0;
                        gradientInReadEn_r[jj+2] = 0;
                        gradientInReadEn_r[jj+3] = 0;
                        gradientInReadEn_r[jj+4] = 0;
                        gradientInReadEn_r[jj+5] = 0;
                        gradientInReadEn_r[jj+6] = 0;
                        gradientInReadEn_r[jj+7] = 0;
                    end
                end else begin
                    gradientInReadEn_r[jj]   = 0;
                    gradientInReadEn_r[jj+1] = 0;
                    gradientInReadEn_r[jj+2] = 0;
                    gradientInReadEn_r[jj+3] = 0;
                    gradientInReadEn_r[jj+4] = 0;
                    gradientInReadEn_r[jj+5] = 0;
                    gradientInReadEn_r[jj+6] = 0;
                    gradientInReadEn_r[jj+7] = 0;
                end
        end
    end
end


// WRITE GRADIENT ENABLE
always @ ( * ) begin 
        for (int jj=0; jj< GRADIENT_OUT_CH_SIZE[NLAYER-1]; jj=jj+1)begin
            if(bw==2)begin
                if(((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] ==0)&&(gradientOutRowAddrBWDX[0] == 0)) || ((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] ==7)&&(gradientOutRowAddrBWDX[0] == 1))) begin// SCRIVIAMO SOLO OGNI 8 COLONNE PERCHE ABBIAMO PORTA DA 8*16 BIT
                    if(jj == gradientOutChAddrBWDX)begin // set to 1 the kernel enable according with the actual layer, channel out and channel in
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

// GRADIENT OUT BUFFER FILL
always @ (*)begin  
    if( bw == 2)begin
        if (gradientOutRowAddrBWDX[0] == 0)begin
            if (gradientOutColumnAddrBWDX[2:0] == 0)begin
                next_gradientOutWriteValue = {{(7*NBITS){1'b0}},dxBWDX} ;
            end else begin
                next_gradientOutWriteValue = gradientOutWriteValue | (dxBWDX << (NBITS*gradientOutColumnAddrBWDX[2:0])); // filling of write out buffer
            end
        end else begin
            if (gradientOutColumnAddrBWDX[2:0] == 7)begin
                next_gradientOutWriteValue = {dxBWDX,{(7*NBITS){1'b0}}} ;
            end else begin
                next_gradientOutWriteValue = gradientOutWriteValue | (dxBWDX << (NBITS*gradientOutColumnAddrBWDX[2:0])); // filling of write out buffer
            end
        end
    end
end

always @(posedge clk)begin

    gradientOutWriteValue <= next_gradientOutWriteValue;
end
// PU GRADIENT IN ASSIGN FOR DK CALCULATION
always @(*)begin
    dyBWDK[(1*NBITS-1):0*NBITS] = gradientInReadValue_r[0][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
    dyBWDK[(2*NBITS-1):1*NBITS] = gradientInReadValue_r[1][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    dyBWDK[(3*NBITS-1):2*NBITS] = gradientInReadValue_r[2][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    dyBWDK[(4*NBITS-1):3*NBITS] = gradientInReadValue_r[3][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    dyBWDK[(5*NBITS-1):4*NBITS] = gradientInReadValue_r[4][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    dyBWDK[(6*NBITS-1):5*NBITS] = gradientInReadValue_r[5][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    dyBWDK[(7*NBITS-1):6*NBITS] = gradientInReadValue_r[6][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
    dyBWDK[(8*NBITS-1):7*NBITS] = gradientInReadValue_r[7][featureInColumnAddrBWDK[2:0]*NBITS+:NBITS]; 
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
// GRADIENT OUT WRITE ADDRESS COMPOSITION
always @(*) begin
    if (gradientOutRowAddrBWDX[0] == 0)begin
        if (gradientOutColumnAddrBWDX == 0 ) begin
            // if im even but at beginnig, the previus block to be written was in a odd block in a previous row
            gradientOutWriteAddr_r = ((gradientOutRowAddrBWDX-1) << ($clog2(GRADIENT_OUT_COLUMN_SIZE[actLayer])))+gradientOutColumnAddrBWDX; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end else begin
            // otherwise, the block to be saved is of the previous 8 feture out
            gradientOutWriteAddr_r = (gradientOutRowAddrBWDX << ($clog2(GRADIENT_OUT_COLUMN_SIZE[actLayer])))+gradientOutColumnAddrBWDX-8; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end
    end else begin
        if (gradientOutColumnAddrBWDX == (GRADIENT_OUT_COLUMN_SIZE[actLayer]-1)) begin
            // if we are into new odd block , our feture out was of the previous even row
            gradientOutWriteAddr_r = ((gradientOutRowAddrBWDX-1) << ($clog2(GRADIENT_OUT_COLUMN_SIZE[actLayer])))+gradientOutColumnAddrBWDX-7; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end else begin
            gradientOutWriteAddr_r = (gradientOutRowAddrBWDX << ($clog2(GRADIENT_OUT_COLUMN_SIZE[actLayer])))+gradientOutColumnAddrBWDX+1; // ricomponi l'indirizzo di scrittura. uso shift come moltiplicazione
        end
    end
end

always @ (*) begin
    if(bw == 1)begin 
        gradientInReadAddr_r = (featureInRowAddrBWDK << ($clog2(FEATURE_OUT_COLUMN_SIZE[actLayer])))+featureInColumnAddrBWDK;;
    end 
end
// GRADIENT IN BUFFER FILLING  AND WRITE/READ ADDRESS ASSIGNATION
always@(*)begin
    if(bw==2)begin
        if(((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 2)&&(gradientOutRowAddrBWDX[0]==1))||((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 3)&&(gradientOutRowAddrBWDX[0]==0))||(kernelAddrRead == 6))begin // carichiamo primo pixel
             // carica il valore della riga corrente ,l'indirizzo colonna è preso INTERO ( i primi 3 bit verranno tagliati quando mandati alla memoria). il +8 dice di prende la parola successiva
            // Nel caso fossiamo a fine colonna, anziche aggiungere 8 all indirizzo colonna , aggiungiamo 1 a quello riga
            gradientInReadAddr_r <= (NewGradientInRowPreFetch << ($clog2(GRADIENT_IN_COLUMN_SIZE[actLayer])))+NewGradientInColumnPreFetch;   
            next_gradientInBufferOfReadValue[0][0] <= gradientInReadValue_r[NewGradientInChAddrPreFetch]; // save 8 channel of first row
            next_gradientInBufferOfReadValue[0][1] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+1];
            next_gradientInBufferOfReadValue[0][2] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+2];
            next_gradientInBufferOfReadValue[0][3] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+3];
            next_gradientInBufferOfReadValue[0][4] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+4];
            next_gradientInBufferOfReadValue[0][5] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+5];
            next_gradientInBufferOfReadValue[0][6] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+6];
            next_gradientInBufferOfReadValue[0][7] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+7];
        end else if(((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 1)&&(gradientOutRowAddrBWDX[0]==1))||((gradientOutRowAddrBWDX[0]==0)&&(gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 4))||(kernelAddrRead == 7))begin 
            // SAve check as above. In this case we also sum 1 to row
            gradientInReadAddr_r <= (NewGradientInRowPreFetch+1 << ($clog2(GRADIENT_IN_COLUMN_SIZE[actLayer])))+NewGradientInColumnPreFetch;           
            next_gradientInBufferOfReadValue[1][0] <= gradientInReadValue_r[NewGradientInChAddrPreFetch]; // save 8 channel of second row
            next_gradientInBufferOfReadValue[1][1] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+1];
            next_gradientInBufferOfReadValue[1][2] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+2];
            next_gradientInBufferOfReadValue[1][3] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+3];
            next_gradientInBufferOfReadValue[1][4] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+4];
            next_gradientInBufferOfReadValue[1][5] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+5];
            next_gradientInBufferOfReadValue[1][6] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+6];
            next_gradientInBufferOfReadValue[1][7] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+7];
        end else if(((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 0)&&(gradientOutRowAddrBWDX[0]==1))||((gradientOutRowAddrBWDX[0]==0)&&(gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 5))||(kernelAddrRead == 8))begin 
            // same reason as above
            gradientInReadAddr_r <= (NewGradientInRowPreFetch+2 << ($clog2(GRADIENT_IN_COLUMN_SIZE[actLayer])))+NewGradientInColumnPreFetch;           
            next_gradientInBufferOfReadValue[2][0] <= gradientInReadValue_r[NewGradientInChAddrPreFetch]; // save 8 channel of third row
            next_gradientInBufferOfReadValue[2][1] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+1];
            next_gradientInBufferOfReadValue[2][2] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+2];
            next_gradientInBufferOfReadValue[2][3] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+3];
            next_gradientInBufferOfReadValue[2][4] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+4];
            next_gradientInBufferOfReadValue[2][5] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+5];
            next_gradientInBufferOfReadValue[2][6] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+6]; 
            next_gradientInBufferOfReadValue[2][7] <= gradientInReadValue_r[NewGradientInChAddrPreFetch+7];
        end else begin
            gradientInReadAddr_r <= 0; // default . 
        end
    end
end
// GRADIENT BUFFER UPDATE
always @ (*) begin
    if(bw==2)begin
        if(((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 6)&&(gradientOutRowAddrBWDX[0]==0))||((gradientOutColumnAddrBWDX[($clog2(N_FEATURE_READ)-1):0] == 7)&&(gradientOutRowAddrBWDX[0]==1))||((gradientOutColumnAddrBWDX == 0)&&(gradientOutRowAddrBWDX[0]==0)))begin // new 8 gradient are loaded
            gradientInBufferOfReadValue = next_gradientInBufferOfReadValue;
        end 
    end
end

// GRADEINT IN PIXEL PU ASSIGNATION
always @ (*)begin
    if(bw==2)begin
    if(gradientOutRowAddrBWDX[0] == 0)begin
        if(gradientOutColumnAddrBWDX > (GRADIENT_OUT_COLUMN_SIZE[actLayer]-3))begin
            DyP1BWDX = 0;
            DyP2BWDX = 0;
            DyP3BWDX = 0;
        end else if (gradientOutColumnAddrBWDX == 0)begin 
            DyP1BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP1BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 
            DyP1BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 
            DyP1BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 
            DyP1BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 
            DyP1BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 
            DyP1BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 
            DyP1BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][((gradientOutColumnAddrBWDX[2:0])&7)*NBITS+:NBITS]; 

            DyP2BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP2BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][((gradientOutColumnAddrBWDX[2:0]+1)&7)*NBITS+:NBITS]; 

            DyP3BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP3BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS];
        end else begin
            DyP1BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[0][0][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP1BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[0][1][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP1BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[0][2][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP1BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[0][3][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP1BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[0][4][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP1BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[0][5][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP1BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[0][6][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP1BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[0][7][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 

            DyP2BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[1][0][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP2BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[1][1][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[1][2][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[1][3][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[1][4][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[1][5][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[1][6][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP2BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[1][7][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 

            DyP3BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP3BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
            DyP3BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][((gradientOutColumnAddrBWDX[2:0]+2)&7)*NBITS+:NBITS]; 
        end
    end else begin
        if(gradientOutColumnAddrBWDX == (GRADIENT_OUT_COLUMN_SIZE[actLayer]-1))begin
            // new row, pass p1 = [row][maxColumn], p2 = , p3 = 0
            DyP1BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP1BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX = 0;
            DyP3BWDX = 0;
        end else begin // otherwise, normal
            DyP1BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[0][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP1BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[0][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[0][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[0][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[0][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[0][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[0][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP1BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[0][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 

            DyP2BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[1][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP2BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[1][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[1][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[1][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[1][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[1][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[1][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP2BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[1][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 

            DyP3BWDX[(1*NBITS-1):0*NBITS] = gradientInBufferOfReadValue[2][0][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; // take NBITS of the featurep ixel given the actual column address
            DyP3BWDX[(2*NBITS-1):1*NBITS] = gradientInBufferOfReadValue[2][1][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP3BWDX[(3*NBITS-1):2*NBITS] = gradientInBufferOfReadValue[2][2][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP3BWDX[(4*NBITS-1):3*NBITS] = gradientInBufferOfReadValue[2][3][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP3BWDX[(5*NBITS-1):4*NBITS] = gradientInBufferOfReadValue[2][4][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP3BWDX[(6*NBITS-1):5*NBITS] = gradientInBufferOfReadValue[2][5][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP3BWDX[(7*NBITS-1):6*NBITS] = gradientInBufferOfReadValue[2][6][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
            DyP3BWDX[(8*NBITS-1):7*NBITS] = gradientInBufferOfReadValue[2][7][gradientOutColumnAddrBWDX[2:0]*NBITS+:NBITS]; 
        end
    end
    end 
end

/////////////////////////////// GRADIENT PROPAGATION MEMORY \\\\\\\\\\\\\\\\\\\\
generate
for(j=0; j< GRADIENT_OUT_CH_SIZE[0]; j=j+1) begin
SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),
        .MEMORY_WIDHT(GRADIENT_OUT_ROW_SIZE[0]*(GRADIENT_OUT_COLUMN_SIZE[0]/N_FEATURE_READ)),
        .MEMORY_TYPE("GRADIENT"),
        .CHANNEL_IN(j),
        .CHANNEL_OUT(j)
        )
SRAMdx (.writeAddr(gradientOutWriteAddr_r[($clog2(GRADIENT_OUT_ROW_SIZE[0]) + $clog2(GRADIENT_OUT_COLUMN_SIZE[0]) -1):$clog2(N_FEATURE_READ)]),
        .readAddr(gradientInReadAddr_r[($clog2(GRADIENT_IN_ROW_SIZE[0]) + $clog2(GRADIENT_IN_COLUMN_SIZE[0]) -1):$clog2(N_FEATURE_READ)]),
        .writeEn(gradientOutWriteEn_r[j]),
        .readEn(gradientInReadEn_r[j]),
        .readValue(gradientInReadValue_r[j]),
        .writeValue(gradientOutWriteValue),
        .clk(clk),
        .rst(rst));
end
endgenerate
endmodule
