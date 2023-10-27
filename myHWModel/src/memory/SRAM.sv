  module SRAM # (

    parameter PORT_WIDTH = 16,
    parameter MEMORY_WIDHT = 1024,
    parameter MEMORY_TYPE = "GDUMB_MEM", // KERNEL,  GRADIENT, GDUMB ,FEATURE
    parameter int CHANNEL_IN = 0,
    parameter int CHANNEL_OUT = 0
)
(
    input [($clog2(MEMORY_WIDHT)-1):0]writeAddr,
    input [($clog2(MEMORY_WIDHT)-1):0]readAddr,
    input writeEn,
    input readEn,
    output reg [(PORT_WIDTH-1):0] readValue,
    input [(PORT_WIDTH-1):0] writeValue,
    input clk,
    input rst
);
reg [PORT_WIDTH-1:0] mem[(MEMORY_WIDHT -1):0];

    always @(negedge clk) begin
        string file_path,file_path2;
        integer code;

        if (rst == 1) begin 
            if (MEMORY_TYPE == "KERNEL") begin
                    //$display("kernel Writing. Channel out : %0d.Channel In : %0d",CHANNEL_OUT,CHANNEL_IN);
                    $sformat( file_path,"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_out/%0d_%0d.txt", CHANNEL_OUT,CHANNEL_IN);
                    //$display("path : %s",file_path);
                    $writememh(file_path,mem);
                    //$display("kernel reading. Channel In : %0d. Channel out : %0d",CHANNEL_IN,CHANNEL_OUT);
                    $sformat( file_path,"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_in/%0d_%0d.txt", CHANNEL_OUT,CHANNEL_IN);
                    //$display("path : %s",file_path);
                    $readmemh(file_path,mem);
                    
                end else if (MEMORY_TYPE == "GRADIENT") begin
                    //$display("gradient Writing. Channel out : %0d",CHANNEL_OUT);
                    $sformat( file_path,"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_out/%0d.txt", CHANNEL_OUT);
                    //$display("path : %s",file_path);
                    $writememh(file_path,mem);
                    //$display("gradient reading. Channel out : %s",CHANNEL_IN);
                    $sformat( file_path,"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_in/%0d.txt", CHANNEL_IN);     
                    //$display("path : %s",file_path);               
                    $readmemh(file_path,mem);
                    //$display(" From gradient read : %h",mem[0]);
                end else if (MEMORY_TYPE == "GDUMB")begin
                    //$display("Gdumb  Writing. Channel In : %0d",CHANNEL_IN);
                    $sformat( file_path,"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gdumbs/%0d.txt", CHANNEL_IN);
                    //$display("path : %s",file_path);  
                    $readmemh(file_path,mem);
                    $display(" From GDUMB CHANNEL %0d mem read addr 0: %h",CHANNEL_IN,mem[0]);
                    $display(" From GDUMB CHANNEL %0d mem read addr 1: %h",CHANNEL_IN,mem[1]);
                    $display(" From GDUMB CHANNEL %0d mem read addr 2: %h",CHANNEL_IN,mem[2]);
                    $display(" From GDUMB CHANNEL %0d mem read addr 3: %h",CHANNEL_IN,mem[3]);
                end else if (MEMORY_TYPE == "FEATURE") begin
                    //$display("Feature Writing. Channel out : %0d",CHANNEL_OUT);
                    $sformat( file_path,"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/feature_out/%0d.txt", CHANNEL_OUT);
                    //$display("path : %s",file_path);  
                    $writememh(file_path,mem);      
                end else begin
                    $display("No file found!. Simulation will be terminated");
                    $finish;
                end
        end else begin
            if(writeEn == 1) begin
                mem[writeAddr] <= writeValue;
            end 
            if (readEn == 1) begin 
                readValue <= mem[readAddr];
            end
        end
    end

endmodule