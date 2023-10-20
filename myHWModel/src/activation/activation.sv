module activation #
(
    parameter act_rule = "RELU",
    parameter NBITS = 16
)
(
    input logic [(NBITS-1):0] input_value, // Input value (32-bit signed)
    output logic [(NBITS-1):0] output_value // Output value (32-bit signed)
);

    always_comb begin
        if (act_rule == "RELU") begin
            if (input_value[NBITS-1] == 0) begin // if it is positive
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