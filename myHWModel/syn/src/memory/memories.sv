

module memories # 
    (parameter MAC_SIZE = 3,
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
    parameter N_FEATURE_READ = 8)
    (input clk,
     input rst,
     input en,
     input [($clog2(16)-1):0]writeAddrKernel,
    input [($clog2(16)-1):0]readAddrKernel,
    output reg [(16-1):0] readValueKernel,
    input [(16-1):0] writeValueKernel,
    input [($clog2(FEATURE_OUT_ROW_SIZE[0]*(FEATURE_OUT_COLUMN_SIZE[0]/N_FEATURE_READ))-1):0]writeAddrFeature,
    input [($clog2(FEATURE_OUT_ROW_SIZE[0]*(FEATURE_OUT_COLUMN_SIZE[0]/N_FEATURE_READ))-1):0]readAddrFeature,
    output reg [(16*N_FEATURE_READ-1):0] readValueFeature,
    input [(16*N_FEATURE_READ-1):0] writeValueFeature,
    input [($clog2(GRADIENT_OUT_ROW_SIZE[0]*(GRADIENT_OUT_COLUMN_SIZE[0]/N_FEATURE_READ))-1):0]writeAddrGradient,
    input [($clog2(GRADIENT_OUT_ROW_SIZE[0]*(GRADIENT_OUT_COLUMN_SIZE[0]/N_FEATURE_READ))-1):0]readAddrGradient,
    output reg [(16*N_FEATURE_READ-1):0] readValueGradient,
    input [(16*N_FEATURE_READ-1):0] writeValueGradient
     
     
     
     );
genvar i,j,k;
generate
    for (i=0;i < NLAYER; i= i+1) begin 
        for (j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1)begin
            for(k=0; k< FEATURE_IN_CH_SIZE[i]; k=k+1)begin
                SRAM # (.PORT_WIDTH(NBITS),.MEMORY_WIDHT(16),.CHANNEL_IN(k),.CHANNEL_OUT(j))
                SRAMKijk(.writeAddr(writeAddrKernel),
                .readAddr(readAddrKernel),
                .writeEn(en),
                .readEn(en),
                .readValue(readValueKernel),
                .writeValue(writeValueKernel),
                .clk(clk),
                .rst(rst));
            end
        end
    end
endgenerate
generate
    for(i=0; i < NLAYER; i= i+1)begin
        for(j=0; j< FEATURE_OUT_CH_SIZE[i]; j=j+1) begin
            SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),
            .MEMORY_WIDHT(FEATURE_OUT_ROW_SIZE[i]*(FEATURE_OUT_COLUMN_SIZE[i]/N_FEATURE_READ)),
            .CHANNEL_IN(0),
            .CHANNEL_OUT(j))
                SRAMFij(.writeAddr(writeAddrFeature),// we cut the last 3 bit due to port wirdht of N:FEATURE_READ*NBITS
                        .readAddr(readAddrFeature),// we cut the last 3 bit due to port wirdht of N:FEATURE_READ*NBITS
                        .writeEn(en),
                        .readEn(en),
                        .readValue(readValueFeature),
                        .writeValue(writeValueFeature),
                        .clk(clk),
                        .rst(rst));
            end
        end
endgenerate
generate
for(j=0; j< GRADIENT_OUT_CH_SIZE[0]; j=j+1) begin
SRAM # (.PORT_WIDTH(NBITS*N_FEATURE_READ),
        .MEMORY_WIDHT(GRADIENT_OUT_ROW_SIZE[0]*(GRADIENT_OUT_COLUMN_SIZE[0]/N_FEATURE_READ)),
        .CHANNEL_IN(j),
        .CHANNEL_OUT(j)
        )
SRAMdx (.writeAddr(writeAddrGradient),
        .readAddr(readAddrGradient),
        .writeEn(en),
        .readEn(en),
        .readValue(readValueGradient),
        .writeValue(writeValueGradient),
        .clk(clk),
        .rst(rst));
end
endgenerate

endmodule