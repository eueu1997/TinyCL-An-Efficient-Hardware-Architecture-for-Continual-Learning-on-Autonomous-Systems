module featureRegister #
(
    parameter nBits = 16,
    parameter nChannelIn = 8
)
(
    //kernel inp
    input  right,
    input  left,
    input  rst,
    input  clk,
    input  [(nBits*nChannelIn-1):0] featureInP1,
    input  [(nBits*nChannelIn-1):0] featureInP2,
    input  [(nBits*nChannelIn-1):0] featureInP3,
    output reg [0:2][0:2][(nBits*nChannelIn-1):0] featureOut 
);

reg [0:2][0:2][(nBits*nChannelIn-1):0]registers ;
reg [0:2][0:2][(nBits*nChannelIn-1):0]newRegisters ;

always @ (*)begin
    if (rst == 1)begin
        newRegisters = '{'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}}};
    end 
    else begin 
        if ((right == 1) & (left == 0))begin
            newRegisters[0][0] = registers [0][1];
            newRegisters[1][0] = registers [1][1];
            newRegisters[2][0] = registers [2][1];
            newRegisters[0][1] = registers [0][2];
            newRegisters[1][1] = registers [1][2];
            newRegisters[2][1] = registers [2][2];
            newRegisters[0][2] = featureInP1;
            newRegisters[1][2] = featureInP2;
            newRegisters[2][2] = featureInP3;

        end
        else if ((right == 0) & (left == 1)) begin
            newRegisters[0][0] = featureInP1;
            newRegisters[1][0] = featureInP2;
            newRegisters[2][0] = featureInP3;
            newRegisters[0][1] = registers [0][0];
            newRegisters[1][1] = registers [1][0];
            newRegisters[2][1] = registers [2][0];
            newRegisters[0][2] = registers [0][1];
            newRegisters[1][2] = registers [1][1];
            newRegisters[2][2] = registers [2][1];
        end
        else if ((right ==  0) & (left == 0)) begin // we code it for vertical movement. It only can go down
            newRegisters[0][0] = registers [1][0];
            newRegisters[0][1] = registers [1][1];
            newRegisters[0][2] = registers [1][2];
            newRegisters[1][0] = registers [2][0];
            newRegisters[1][1] = registers [2][1];
            newRegisters[1][2] = registers [2][2];
            newRegisters[2][0] = featureInP1;
            newRegisters[2][1] = featureInP2;
            newRegisters[2][2] = featureInP3;
        end
        else begin // non serve, per ora facciamo che non muove nulla

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

assign featureOut = newRegisters;

endmodule

