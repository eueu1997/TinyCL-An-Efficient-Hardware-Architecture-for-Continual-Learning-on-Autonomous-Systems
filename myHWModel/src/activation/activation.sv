module relu_module #
(
    parameter act_rule;
)
(
    input logic [31:0] input_value, // Input value (32-bit signed)
    output logic [31:0] output_value // Output value (32-bit signed)
);

    always_comb begin
        if (act_rule == "RELU") begin
            if (input_value >= 0) begin
                output_value = input_value; // Output is the same as input if input >= 0
            end else begin
                output_value = 32'h0; // Output is 0 if input < 0
            end
        end else begin // default : relu
        if (input_value >= 0) begin
                output_value = input_value; // Output is the same as input if input >= 0
            end else begin
                output_value = 32'h0; // Output is 0 if input < 0
            end
        end
    end

endmodule