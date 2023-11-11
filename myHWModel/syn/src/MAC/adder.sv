module fixed_add#
(
    parameter NBit = 16,
	parameter NBitOut = 16,
)(
    input [(NBit-1):0] num1, // 32-bit input operand 1
    input [(NBit-1):0] num2, // 32-bit input operand 2
    output [(NBitOut-1):0] result // 32-bit output result
);

    // Adder logic
    assign result = num1 + num2;

endmodule
