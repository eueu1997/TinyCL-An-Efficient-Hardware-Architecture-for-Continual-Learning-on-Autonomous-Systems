module kernelRegisters
(

)
(
    //kernel inp
    input logic right;
    input logic left;
    input logic rst;
    input logic load;
    input logic [0:2][(nBits*nChannelIn-1)]kernelIn;
    output logic [0:2][0:2][(nBits*nChannelIn-1)] kernelOut;
)

reg [0:2][0:2][(nBits*nChannelIn-1)]registers ;
reg [0:2][0:2][(nBits*nChannelIn-1)]newRegisters ;

always @ ()begin
    if (rst = '1')begin
        newRegisters = '{'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0}};
    end 
    else begin 
        if (right = '1') && (left = '0')begin
            newRegisters[0][1] = registers [0][0];
            newRegisters[0][2] = registers [0][1];
            if (load = 0) begin // if we are loading new kernel
                newRegisters[0][0] = registers [0][2];
            end
            else begin
                newRegisters[0][0] = kernelIn[0];
            end
            newRegisters[1][1] = registers [1][0];
            newRegisters[1][2] = registers [1][1];
            newRegisters[1][0] = registers [1][2];
            newRegisters[2][1] = registers [2][0];
            newRegisters[2][2] = registers [2][1];
            newRegisters[2][0] = registers [2][2];

        end
        else if (right = '0') && (left = '1') begin
            newRegisters[0][2] = registers [0][0];
            newRegisters[0][0] = registers [0][1];
            newRegisters[0][1] = registers [0][2];
            newRegisters[1][2] = registers [1][0];
            newRegisters[1][0] = registers [1][1];
            newRegisters[1][1] = registers [1][2];
            newRegisters[2][2] = registers [2][0];
            newRegisters[2][0] = registers [2][1];
            newRegisters[2][1] = registers [2][2];
        end
        else if (right = '0') && (left = '0') begin // we code it for vertical movement. It only can go down
            if (load ='0')begin
                newRegisters[0][0] = registers [2][0];
                newRegisters[0][1] = registers [2][1];
                newRegisters[0][2] = registers [2][2];
            end 
            else begin 
                newRegisters[0][0] = kernelIn [0];// per ora supponiamo che i kernel vengano inviati con l'ordine gia fatto ( non saranno sempre 0 - 1 - 2, ma serviranno ordinati in base al MAC address)
                newRegisters[0][1] = kernelIn [1];
                newRegisters[0][2] = kernelIn [2];
            end
            newRegisters[1][0] = registers [0][0];
            newRegisters[1][1] = registers [0][1];
            newRegisters[1][2] = registers [0][2];
            newRegisters[2][0] = registers [1][0];
            newRegisters[2][1] = registers [1][1];
            newRegisters[2][2] = registers [1][2];
        end
        else if (right = '1') && (left = '1') begin // non serve, per ora facciamo che non muove nulla

            newRegisters[0][0] = registers [0][0];
            newRegisters[0][1] = registers [0][1];
            newRegisters[0][2] = registers [0][2];
            newRegisters[1][0] = registers [1][0];
            newRegisters[1][1] = registers [1][1];
            newRegisters[1][2] = registers [1][2];
            newRegisters[2][0] = registers [2][0];
            newRegisters[2][1] = registers [2][1];
            newRegisters[2][2] = registers [2][2];
        end
    end
end

always @ ( posedge clk) begin

    registers = newRegisters;

end

assign kernelOut = registers;

endmodule

