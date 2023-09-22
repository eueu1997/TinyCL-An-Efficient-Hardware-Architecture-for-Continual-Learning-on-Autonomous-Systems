module kernelRegisters
(
    parameter int nBits = 16,
    parameter int nChannelIn = 8
)
(
    //kernel inp
    input logic rst,
    input logic load,
    input logic [0:2][0:2][(nChannelIn*nBits-1):0] kernelIn,
    output logic [0:2][0:2][(nBits*nChannelIn-1):0] kernelOut
)

reg [0:2][0:2][(nBits*nChannelIn-1):0]registers ;
reg [0:2][0:2][(nBits*nChannelIn-1):0]newRegisters ;

always @ (*)begin
    if (rst = '1')begin
        newRegisters = '{'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0}};
    end 
    else begin 
        if (load = '1')then
            newRegisters  = kernelIn;
    end else begin
            newRegisters = registers;
        end
    end


always @ ( posedge clk) begin
    
    registers = newRegisters;


end

assign kernelOut = registers;

endmodule

