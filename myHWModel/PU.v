
parameter int N_OF_MAC_ROWS = 3;
parameter int N_OF_MAC_CLMN = 3;





genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (.featureIn[0:7](featuresIn).featureIn[8](partialSumOut),kernels,partialSum);
            register PSregister(partialSum,partialSumOut,clk,rst);
        end
    end
endgenerate