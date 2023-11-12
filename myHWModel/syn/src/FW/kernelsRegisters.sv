module kernelRegisters #
(
    parameter nBits = 16,
    parameter nChannelIn = 8,
    parameter nKernel = 3
)
(
    //kernel inp
    input  clk,
    input  rst,
    input  load,
    input  [0:(nKernel -1)][0:(nKernel -1)][(nChannelIn*nBits-1):0] kernelIn,
    output  [0:(nKernel -1)][0:(nKernel -1)][(nBits*nChannelIn-1):0] kernelOut
);

reg [0:(nKernel -1)][0:(nKernel-1)][(nBits*nChannelIn-1):0]registers ;
reg [0:(nKernel-1)][0:(nKernel-1)][(nBits*nChannelIn-1):0]newRegisters ;

always @ (*)begin
    if (rst == 1)begin
        newRegisters = '{'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}}};
    end 
    else begin 
        if (load == 1)begin
            newRegisters  = kernelIn;
    end else begin
            newRegisters = registers;
        end
    end
end

always @ ( posedge clk) begin
    
    registers = newRegisters;


end

assign kernelOut = newRegisters;

endmodule

