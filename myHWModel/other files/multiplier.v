module mult#
(
    parameter int NBit = 16,
)
(
	input  logic [NBitIn-1:0] A  ,
    input  logic [NBitIn-1:0] B  ,

    output logic [NBit-1:'0] DataOut  

);

DataOut = A*B;

endmodule