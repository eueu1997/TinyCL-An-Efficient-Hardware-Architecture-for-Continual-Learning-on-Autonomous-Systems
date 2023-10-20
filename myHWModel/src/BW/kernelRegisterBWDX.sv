module kernelRegistersBWDX #
(
    parameter NBITS = 16,
    parameter NCHANNELOUT = 8,
    parameter NKERNEL = 3
)
(
    //kernel inp
    input reg clk,
    input reg rst,
    input reg load,
    input [1:0]stride,
    input j,k,
    input var [0:(NKERNEL -1)][0:(NKERNEL -1)][(NCHANNELOUT*NBITS-1):0] kernelIn,
    output reg [0:(NKERNEL -1)][0:(NKERNEL -1)][(NBITS*NCHANNELOUT-1):0] kernelOut
);

reg [0:(NKERNEL -1)][0:(NKERNEL-1)][(NBITS*NCHANNELOUT-1):0]registers ;
reg [0:(NKERNEL-1)][0:(NKERNEL-1)][(NBITS*NCHANNELOUT-1):0]newRegisters ;

always @ (*)begin 
    if (load == 1)begin
        if(stride == 1) begin 
            kernelOut[2][0]  = registers[0][0];
            kernelOut[1][0]  = registers[0][1];
            kernelOut[0][0]  = registers[0][2];
            kernelOut[0][1]  = registers[1][2];
            kernelOut[0][2]  = registers[2][2];
            kernelOut[1][2]  = registers[2][1];
            kernelOut[2][2]  = registers[2][0];
            kernelOut[2][1]  = registers[1][0];
            kernelOut[1][1]  = registers[1][1];
        end else begin
            if(k==0)begin // if column index is even
                if ( j== 0)begin // if row index is even
                    kernelOut[0][0]  = registers[2][2];
                    kernelOut[0][1]  = registers[2][0];
                    kernelOut[1][0]  = registers[0][2];
                    kernelOut[1][1]  = registers[0][0];
                    kernelOut[0][2]  = 0;
                    kernelOut[1][2]  = 0;
                    kernelOut[2][2]  = 0;
                    kernelOut[2][1]  = 0;
                    kernelOut[2][0]  = 0;
                end else begin  // else is odd
                    kernelOut[0][0]  = 0;
                    kernelOut[0][1]  = 0;
                    kernelOut[1][0]  = registers[1][2];
                    kernelOut[1][1]  = registers[1][0];
                    kernelOut[0][2]  = 0;
                    kernelOut[1][2]  = 0;
                    kernelOut[2][2]  = 0;
                    kernelOut[2][1]  = 0;
                    kernelOut[2][0]  = 0;
                end
            end else begin // else is odd
                if ( j== 0)begin // if row index is even
                    kernelOut[1][0]  = registers[2][1];
                    kernelOut[1][1]  = registers[0][1];
                    kernelOut[0][0]  = 0;
                    kernelOut[0][1]  = 0;
                    kernelOut[0][2]  = 0;
                    kernelOut[1][2]  = 0;
                    kernelOut[2][2]  = 0;
                    kernelOut[2][1]  = 0;
                    kernelOut[2][0]  = 0;
                end else begin  // else is odd
                    kernelOut[2][0]  = 0;
                    kernelOut[1][0]  = 0;
                    kernelOut[0][0]  = 0;
                    kernelOut[0][1]  = 0;
                    kernelOut[0][2]  = 0;
                    kernelOut[1][2]  = 0;
                    kernelOut[2][2]  = 0;
                    kernelOut[2][1]  = 0;
                    kernelOut[1][1]  = registers[1][1];
                end
            end
        end
end else begin
    kernelOut = registers;
    end
end



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


endmodule

