module FW_BW #(

)(
    input [($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1) : 0] featureOutAddr;
    output  [(NBITS*N_OF_CH_READ-1):0] featureInP1,featureInP2,featureInP3;

);

    // Define parameters
    parameter MAC_SIZE = 3;
    parameter N_OF_MAC_ROWS = 3;
    parameter N_OF_MAC_CLMN = 3;
    parameter N_OF_CH_READ = 8;
    parameter NBITS = 16;
    parameter FEATURE_IN_ROW_SIZE = 32;
    parameter FEATURE_IN_COLUMN_SIZE = 32;
    parameter FEATURE_IN_CH_SIZE = 8;
    parameter FEATURE_OUT_ROW_SIZE = 32;
    parameter FEATURE_OUT_COLUMN_SIZE = 32;
    parameter FEATURE_OUT_CH_SIZE = 8;
    parameter N_FEATURE_READ = 8,
    parameter KERNEL_SIZE = 3

    // Define signals FW
    reg clk;
    reg rst;
    reg [0:(N_OF_MAC_ROWS*N_OF_MAC_CLMN-1)][(NBITS*N_OF_CH_READ-1):0] newKernelVals,kernelVals;
    reg loadKernel;
    
    wire [($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] featureInP1Addr;
    wire [($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] featureInP2Addr;
    wire [($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):0] featureInP3Addr;
    wire [(NBITS-1):0] featureOutVal;
    // define isgnal BW
    reg [($clog2(CHANNEL_IN_DIM) + $clog2(FEATURE_IN_DIM) + $clog2(FEATURE_IN_DIM) -1):0] tb_featureInAddr;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] tb_featureIn;
    reg [($clog2(CHANNEL_OUT_DIM) + $clog2(FEATURE_OUT_DIM) + $clog2(FEATURE_OUT_DIM) -1):0] tb_dyAddr;
    reg [0:(N_FEATURE_READ -1)][(NBITS-1):0] tb_dy;
    reg [($clog2(CHANNEL_OUT_DIM) + $clog2(CHANNEL_IN_DIM) -1):0] tb_dkAddr;
    reg [0:(KERNEL_SIZE -1)][0:(KERNEL_SIZE -1)][(NBITS-1):0] tb_dk;
    reg valid;
    // GENVAR PER KERNEL MEMORY
    genvar i,j;
    // RAD ENABLE DI KERNEL MEMORY: SCEGLIE QUALE KERNEL MEMORY LEGGERE IN BASE AL CHANNEL IN / CHANNEL OUTE
    reg [0:(FEATURE_OUT_CH_SIZE-1)][0:(FEATURE_IN_CH_SIZE-1)]KreadEn ;
    // Instantiate the BW_PU module
    BW_PU#(
        .N_OF_MAC_ROWS(N_OF_MAC_ROWS),
        .N_OF_MAC_CLMN(N_OF_MAC_CLMN),
        .NBITS(NBITS),
        .N_FEATURE_READ(N_FEATURE_READ),
        .FEATURE_IN_ROW_SIZE(FEATURE_IN_ROW_SIZE),
        .FEATURE_IN_COLUMN_SIZE(FEATURE_IN_COLUMN_SIZE),
        .FEATURE_IN_CH_SIZE(FEATURE_IN_CH_SIZE),
        .FEATURE_OUT_ROW_SIZE(FEATURE_OUT_ROW_SIZE),
        .FEATURE_OUT_COLUMN_SIZE(FEATURE_OUT_COLUMN_SIZE),
        .FEATURE_OUT_CH_SIZE(FEATURE_OUT_CH_SIZE)
        .KERNEL_SIZE(KERNEL_SIZE)
    ) uut (
        .featureInAddr(tb_featureInAddr),
        .featureIn(tb_featureIn),
        .dyAddr(tb_dyAddr),
        .dy(tb_dy),
        .dkAddr(tb_dkAddr),
        .dk(tb_dk),
        .clk(clk),
        .rst(bw_pu_rst),
        .valid(valid)
    );
    // Instantiate the FW_PU module
    FW_PU#(
        .MAC_SIZE(MAC_SIZE),
        .N_OF_MAC_ROWS(N_OF_MAC_ROWS),
        .N_OF_MAC_CLMN(N_OF_MAC_CLMN),
        .N_OF_CH_READ(N_OF_CH_READ),
        .NBITS(NBITS),
        .FEATURE_IN_ROW_SIZE(FEATURE_IN_ROW_SIZE),
        .FEATURE_IN_COLUMN_SIZE(FEATURE_IN_COLUMN_SIZE),
        .FEATURE_IN_CH_SIZE(FEATURE_IN_CH_SIZE),
        .FEATURE_OUT_ROW_SIZE(FEATURE_OUT_ROW_SIZE),
        .FEATURE_OUT_COLUMN_SIZE(FEATURE_OUT_COLUMN_SIZE),
        .FEATURE_OUT_CH_SIZE(FEATURE_OUT_CH_SIZE)
    ) uut (
        .clk(clk),
        .rst(fw_pu_rst),
        .kernelVals(kernelVals),
        .loadKernel(loadKernel),
        .featureInP1Addr(featureInP1Addr), // TODO : togliere e usare solo feature out del layer +1
        .featureInP2Addr(featureInP2Addr),
        .featureInP3Addr(featureInP3Addr),
        .featureInP1(featureInP1),
        .featureInP2(featureInP2),
        .featureInP3(featureInP3),
        .featureOutAddr(featureOutAddr),
        .featureOutVal(featureOutVal)
    );
    generate 
        for(i = 0;i<FEATURE_OUT_CH_SIZE;i=i+1)begin
            for(j = 0;j<FEATURE_IN_CH_SIZE;j=j+1)begin
                 SRAM #(PORT_WIDTH, MEMORY_WIDTH) 
                kernelMem (
                .writeAddr(),
                .readAddr(KreadAddr),
                .writeEn(),
                .readEn(KreadEn[i][j])
                .readValue(KreadValue[i][j]),
                .writeValue(),
                .clk(clk),
                .rst(Krst)
    );
            end
        end
    endgenerate
    // local register for kernels read
    always @ ( *)begin
        if ( rst == 1)begin
            newKernelVals = '{'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}}};
        end else begin
            newKernelVals[KreadAddr] = KreadValue[featureOutAddr[($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1):($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) )]][featureInP1Addr[($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):( $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE))]]
        end
    end
    always @ ( posedge clk) begin
        kernelVals <= newKernelVals;
    end
    // Set enable for kernel read 
    always @ ( *)begin
        integer k,l;
        var chOut = featureOutAddr[($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1):($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) )];
        var chIn = featureInP1Addr[($clog2(FEATURE_IN_CH_SIZE) + $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE)-1):( $clog2(FEATURE_IN_ROW_SIZE)+$clog2(FEATURE_IN_COLUMN_SIZE))];
        if(state == FW_RST)begin // if we are loading kernel, enable only kernel of corrispective ch_in ch_out
        for(k=0;k<FEATURE_OUT_CH_SIZE;k=k+1)begin
            for(l=0;l<FEATURE_IN_CH_SIZE;l=l+8)begin
                if((k = chOut) & (l = chIn)) begin // enable a group on 8 ch_in kernel
                    KreadEn[k][l] = 1;
                    KreadEn[k][l+1] = 1;
                    KreadEn[k][l+2] = 1;
                    KreadEn[k][l+3] = 1;
                    KreadEn[k][l+4] = 1;
                    KreadEn[k][l+5] = 1;
                    KreadEn[k][l+6] = 1;
                    KreadEn[k][l+7] = 1;
                end else begin // dont read others channels
                    KreadEn[k][l] = 0;
                    KreadEn[k][l+1] = 0;
                    KreadEn[k][l+2] = 0;
                    KreadEn[k][l+3] = 0;
                    KreadEn[k][l+4] = 0;
                    KreadEn[k][l+5] = 0;
                    KreadEn[k][l+6] = 0;
                    KreadEn[k][l+7] = 0;
                end
            end
        end
        end else begin // otherwise, stop reading
            for(k=0;k<FEATURE_OUT_CH_SIZE;k=k+1)begin
            for(l=0;l<FEATURE_IN_CH_SIZE;l=l+1)begin
                KreadEn[k][l] = 0;
            end
            end
        end
    end
    
    
// State machine of CU
enum int unsigned { FW_RST = 0,K_LOAD = 1, EXE = 2, FNSH = 3 } state, next_state;
reg [0:(KERNEL_SIZE*KERNEL_SIZE-1) : 0 ] KreadAddr,next_KreadAddr
// Next state logic 
always_comb begin : next_state_logic
	  case(state)
		FW_RST: begin 
            if (KreadAddr == (KERNEL_SIZE*KERNEL_SIZE-1)) begin
            next_state = K_LOAD;
            end else begin
            next_state = FW_RST;
            end
        end
		K_LOAD: begin 
            next_state = EXE;
        end
        EXE : begin
            if()
        end

	  endcase
end
// State combinational logic
always_comb begin
	  case(state)
		FW_RST: begin
            next_KreadAddr = KreadAddr +1;
            fw_pu_rst = 1;
            loadKernel = 0;
        end
		K_LOAD: begin
            next_KreadAddr = 0;
            fw_pu_rst = 0;
            loadKernel = 1;
        end
		EXE: begin
            next_KreadAddr = 0;
            fw_pu_rst = 0;
            loadKernel = 0;        
        end
		 S3: o = data[0];
	  endcase
end
// register of FF
always_ff@(posedge clk or negedge reset) begin
	if(~reset) begin 
        state <= K_LOAD;
        KreadAddr <= 0;
    end else begin 
		state <= next_state;
        KreadAddr <= next_KreadAddr;
    end
end
generate 
    for(i = 0;i<FEATURE_OUT_CH_SIZE;i=i+1)begin
        SRAM #(PORT_WIDTH, MEMORY_WIDTH) 
        featureOutMem (
        .writeAddr(),
        .readAddr1(readAddr1),
        .readAddr2(readAddr2),
        .readAddr3(readAddr3),        
        .writeEn(),
        .readEn(readEn[i]),
        .readValue1(readValue1[i]),
        .readValue2(readValue2[i]),
        .readValue3(readValue3[i]),
        .writeValue(),
        .clk(clk),
        .rst(rst)
        );
    end;
endgenerate
// read from next layer of its feature in
always @(*)begin 
    var chOut = featureOutAddr[($clog2(FEATURE_OUT_CH_SIZE) + $clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) -1):($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE) )];
    if(featureOutAddr[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] > (FEATURE_OUT_COLUMN_SIZE-2)) begin // if we are close to border, we do not take the read and send 0 insted ( like is padded)
        featureInP1 = '{default:0};
        featureInP2 = '{default:0};
        featureInP3 = '{default:0};
    end else begin  // otherwise take the read
        featureInP1 = readValue1[chOut];
        featureInP2 = readValue2[chOut];
        featureInP3 = readValue3[chOut];
    end
end
always @ (*)begin // generazione segnali indirizzo di lettura feature dato l'indirizzo da layer +1 ( che sara il suo feature out)
    if(featureOutAddr[($clog2(FEATURE_OUT_COLUMN_SIZE))] == 0) begin// se l'indice riga è pari, allora stiamo andando a destra
        readAddr1[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = featureOutRowAddr; // TODO : sostituire featureOutRow e featureOutColum con segnali questo modulo
        readAddr1[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = featureOutColumAddr + 2;
        readAddr2[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = featureOutRowAddr + 1;
        readAddr2[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = featureOutColumAddr + 2;
        readAddr3[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = featureOutRowAddr + 2;
        readAddr3[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = featureOutColumAddr + 2;
    end else begin
        readAddr1[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = featureOutRowAddr; 
        readAddr1[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = featureOutColumAddr ;
        readAddr2[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = featureOutRowAddr ;
        readAddr2[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = featureOutColumAddr ;
        readAddr3[($clog2(FEATURE_OUT_ROW_SIZE) + $clog2(FEATURE_OUT_COLUMN_SIZE)):($clog2(FEATURE_OUT_COLUMN_SIZE))] = featureOutRowAddr ;
        readAddr3[($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0] = featureOutColumAddr ;
    end
end
endmodule
