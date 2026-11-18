module GDumb #
(
    parameter GDUMB_MEMORY = 10000,
    parameter PRETRAINED_CLASSES = 10
)
(
    input clk,rst,
    //input GDumbRamValueRead,
    //output GDumbRamAddrsRead,
    //output GDumbRamReadEn,

    input updateMem ,// 1 = new feature coming
    input nOfClass, // New number of class. 
    output int nOfClass_out, oldnOfClass_out
    /*input [0:2][31:0][31:0]GDumbRamValueTOBEWrite,
    input GdumbRamLabelTOBEWrite,
    // Feature memory writing
    output GDumbRamWriteValueEn,
    output [($clog2(GDUMB_MEMORY)-1):0]GDumbRamAddrsValue,
    output[0:2][31:0][31:0]GDumbRamValue,
    // feature memory writing
    output GDumbRamWriteLabelEn,
    output [($clog2(GDUMB_MEMORY)-1):0]GDumbRamAddrsLabel,
    output GdumbRamLabel*/
);

/*
NN (
    .featureInReadAddrFWGDUMB(GDumbRamAddrsRead),
    .featureInReadEnFWGDUMB(GDumbRamReadEn),
    .featureInReadValueFWGDUMB(GDumbRamValueRead)
)*/
// 1: rearrange the memory in order to make space for new feature
// 2 : insert new feature
/*
reg [($clog2(GDUMB_MEMORY)-1):0] writeAddr,next_writeAddr;
reg [($clog2(GDUMB_MEMORY)-1):0] readAddr,next_readAddr;
always @(*)begin
    if(updateMem == 1)begin
        GDumbRamWriteEn  <= 1;
        GDumbRamReadEn <= 1;
        next_writeAddr <= writeAddr +1;
        if((writeAddr+1) == actualClass_r*nOfClass_r)begin
            next_readAddr <= (actualClass_r+1)*old_nOfClass_r;
            next_actualClass_r <= actualClass_r +1;
        end else begin
            next_readAddr <= readAddr +1;
            next_actualClass_r <= actualClass_r;
        end
    end
end

always @ ( posedge clk ) begin

    readAddr <= next_readAddr;
    writeAddr <= next_writeAddr;
    actualClass_r <= next_actualClass_r;
end
*/
reg int old_nOfClass_r,nOfClass_r,next_old_nOfClass_r,next_nOfClass_r;

always @ (posedge updateMem) begin
    nOfClass_r <= nOfClass;
end 

always @ (negedge updateMem) begin
    old_nOfClass_r <= next_nOfClass_r;
end 

always @ (posedge clk) begin
    next_nOfClass_r <= nOfClass_r;
    next_old_nOfClass_r <= old_nOfClass_r;
end
endmodule