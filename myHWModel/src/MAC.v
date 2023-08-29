

module MAC ( 
    parameter N = 3, // # channels in
    parameter W = 3, // kernel row
    parameter L = 3  // kernel column
)(
    input [N*W*L]   InputFeature,
    input [N*W*L]   Kernel,
    output          OutputFeaturePixel
);
//Input wires
wire [0:N-1][0:W-1][0:L-1]  InputFeature_w = InputFeature;
wire [0:N-1][0:W-1][0:L-1]  Kernel_w = Kernel;
//Output wires
wire OutputFeaturePixel_w = OutputFeaturePixel;
//Output of each mult to be summed
wire [0:N-1][0:W-1][0:L-1]  MultOut;
//Generation of multiplier
genvar i,j,k
generate
    for(i=0;i<N;i=i+1) begin : mult_gen_i
        for(j=0;j<W;j=j+1) begin : mult_gen_j
            for(k=0;k<L;k=k+1) begin : mult_gen_k
                mult(
                    .DataInA    (InputFeature_w[i][j][k]),
                    .DataInB    (Kernel_w[i][j][k]),
                    .DataOut    (MultOut[i][j][k])
                )
            end
        end
    end
endgenerate
