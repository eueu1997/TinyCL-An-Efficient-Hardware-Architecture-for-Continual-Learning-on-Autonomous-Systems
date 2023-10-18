module featureRegisterBWDX #
(
    parameter NBITS = 16,
    parameter NCHANNELOUT = 8
)
(
    //kernel inp
    input  right,
    input  left,
    input  rst,
    input  clk,
    input stride,j ,// used to modify the matrix according to stride value and if we are in a odd or even column/row
    input  [(NBITS*NCHANNELOUT-1):0] gradientInP1,
    input  [(NBITS*NCHANNELOUT-1):0] gradientInP2,
    input  [(NBITS*NCHANNELOUT-1):0] gradientInP3,
    output reg [0:2][0:2][(NBITS*NCHANNELOUT-1):0] gradientOut 
);

reg [0:2][0:2][(NBITS*NCHANNELOUT-1):0]registers ;
reg [0:2][0:2][(NBITS*NCHANNELOUT-1):0]newRegisters ;

always @ (*)begin
    if (rst == 1)begin
        newRegisters = '{'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}},'{'{default:0},'{default:0},'{default:0}}};
    end 
    else begin 
        if((stride == 2) && (j == 1))begin
            newRegisters = registers;
        end else begin
        if ((right == 1) & (left == 0))begin
            newRegisters[0][0] = registers [0][1];
            newRegisters[1][0] = registers [1][1];
            newRegisters[2][0] = registers [2][1];
            newRegisters[0][1] = registers [0][2];
            newRegisters[1][1] = registers [1][2];
            newRegisters[2][1] = registers [2][2];
            newRegisters[0][2] = gradientInP1;
            newRegisters[1][2] = gradientInP2;
            newRegisters[2][2] = gradientInP3;
        end
        else if ((right == 0) & (left == 1)) begin
            newRegisters[0][0] = gradientInP1;
            newRegisters[1][0] = gradientInP2;
            newRegisters[2][0] = gradientInP3;
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
            newRegisters[1][0] = registers [0][0];
            newRegisters[1][1] = registers [0][1];
            newRegisters[1][2] = registers [0][2];
            newRegisters[2][0] = gradientInP1;
            newRegisters[2][1] = gradientInP2;
            newRegisters[2][2] = gradientInP3;
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
end

always @ ( posedge clk) begin

    registers = newRegisters;

end
always @ (*) begin
    if (stride == 2) begin
        gradientOut[0][0] = registers [0][0];
        gradientOut[0][1] = registers [0][1];
        gradientOut[0][2] = 0;
        gradientOut[1][0] = registers [1][0];
        gradientOut[1][1] = registers [1][1];
        gradientOut[1][2] = 0;
        gradientOut[2][0] = 0;
        gradientOut[2][1] = 0;
        gradientOut[2][2] = 0;
    end else begin
        gradientOut = registers;
    end
end
endmodule

