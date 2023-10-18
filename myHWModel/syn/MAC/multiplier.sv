
module fixed_multi(num1, num2, result, overflow, precisionLost, result_full);
  input [15:0] num1, num2; //num1 is multiplicand and num2 is multiplier
  output [15:0] result;
  output overflow, precisionLost;
  reg [31:0] mid [31:0]; //shifted values
  reg [31:0] midB[3:0]; //addition of shifted values
  output [31:0] result_full; //32-bit results
  reg [31:0] num1_ext,num2_ext;

  assign precisionLost = |result_full[7:0];
  assign result = result_full[19:4]; //get rid of extra bits
  assign overflow = |result_full[31:24]; // most significant 8-bit is overflow
  assign result_full = midB[0] + midB[1] + midB[2] + midB[3]; 
  /*always@* //midB wires are added for readability
    begin
      if(num1[15] == 0)begin
        num1_ext = {8'd0, num1, 8'd0};
      end else begin
        num1_ext = {8'hFF, num1, 8'd0};
      end
      if(num2[15] == 0)begin
        num2_ext = {8'd0, num2, 8'd0};
      end else begin
        num2_ext = {8'hFF, num2, 8'd0};
      end
      midB[0] = mid[0] + mid[4] + mid[8] + mid[12] + mid[16] + mid[20] + mid[24] + mid[31];
      midB[1] = mid[1] + mid[5] + mid[9] + mid[13] + mid[17] + mid[21] + mid[25] + mid[30];
      midB[2] = mid[2] + mid[6] + mid[10] + mid[14]+ mid[18] + mid[22] + mid[26] + mid[29];
      midB[3] = mid[3] + mid[7] + mid[11] + mid[15]+ mid[19] + mid[23] + mid[27] + mid[28];
    end*/
    always@* //midB wires are added for readability
    begin
      if(num1[15] == 0)begin
        num1_ext = {12'd0, num1,4'd0};
      end else begin
        num1_ext = {12'hFFF, num1,4'd0};
      end
      if(num2[15] == 0)begin
        num2_ext = {12'd0, num2, 4'd0};
      end else begin
        num2_ext = {12'hFFF, num2, 4'd0};
      end
      midB[0] = mid[0] + mid[4] + mid[8] + mid[12] + mid[16] + mid[20] + mid[24] + mid[31];
      midB[1] = mid[1] + mid[5] + mid[9] + mid[13] + mid[17] + mid[21] + mid[25] + mid[30];
      midB[2] = mid[2] + mid[6] + mid[10] + mid[14]+ mid[18] + mid[22] + mid[26] + mid[29];
      midB[3] = mid[3] + mid[7] + mid[11] + mid[15]+ mid[19] + mid[23] + mid[27] + mid[28];  
      end
  always@* //shift and enable control
    begin
      mid[0]  = (num1_ext >> 16) & {32{num2_ext[0]}};
      mid[1]  = (num1_ext >> 15) & {32{num2_ext[1]}};
      mid[2]  = (num1_ext >> 14) & {32{num2_ext[2]}};
      mid[3]  = (num1_ext >> 13) & {32{num2_ext[3]}};
      mid[4]  = (num1_ext >> 12) & {32{num2_ext[4]}};
      mid[5]  = (num1_ext >> 11) & {32{num2_ext[5]}};
      mid[6]  = (num1_ext >> 10) & {32{num2_ext[6]}};
      mid[7]  = (num1_ext >> 9) & {32{num2_ext[7]}};
      mid[8]  = (num1_ext >> 8) & {32{num2_ext[8]}};
      mid[9]  = (num1_ext >> 7) & {32{num2_ext[9]}};
      mid[10] = (num1_ext >> 6) & {32{num2_ext[10]}};
      mid[11] = (num1_ext >> 5) & {32{num2_ext[11]}};
      mid[12] = (num1_ext >> 4) & {32{num2_ext[12]}};
      mid[13] = (num1_ext >> 3) & {32{num2_ext[13]}};
      mid[14] = (num1_ext >> 2) & {32{num2_ext[14]}};
      mid[15] = (num1_ext >> 1) & {32{num2_ext[15]}};
      mid[16] = (num1_ext    ) & {32{num2_ext[16]}};
      mid[17] = (num1_ext << 1) & {32{num2_ext[17]}};
      mid[18] = (num1_ext << 2) & {32{num2_ext[18]}};
      mid[19] = (num1_ext << 3) & {32{num2_ext[19]}};
      mid[20] = (num1_ext << 4 ) & {32{num2_ext[20]}};
      mid[21] = (num1_ext << 5) & {32{num2_ext[21]}};
      mid[22] = (num1_ext << 6) & {32{num2_ext[22]}};
      mid[23] = (num1_ext << 7) & {32{num2_ext[23]}};
      mid[24] = (num1_ext << 8) & {32{num2_ext[24]}};
      mid[25] = (num1_ext << 9) & {32{num2_ext[25]}};
      mid[26] = (num1_ext << 10) & {32{num2_ext[26]}};
      mid[27] = (num1_ext << 11) & {32{num2_ext[27]}};
      mid[28] = (num1_ext << 12) & {32{num2_ext[28]}};
      mid[29] = (num1_ext << 13) & {32{num2_ext[29]}};
      mid[30] = (num1_ext << 14) & {32{num2_ext[30]}};
      mid[31] = (num1_ext << 15) & {32{num2_ext[31]}};
/*
      mid[0]  = (num1_ext >> 12) & {32{num2[0]}};
      mid[1]  = (num1_ext >> 11) & {32{num2[1]}};
      mid[2]  = (num1_ext >> 10) & {32{num2[2]}};
      mid[3]  = (num1_ext >> 9) & {32{num2[3]}};
      mid[4]  = (num1_ext >> 8) & {32{num2[4]}};
      mid[5]  = (num1_ext >> 7) & {32{num2[5]}};
      mid[6]  = (num1_ext >> 6) & {32{num2[6]}};
      mid[7]  = (num1_ext >> 5) & {32{num2[7]}};
      mid[8]  = (num1_ext >> 4) & {32{num2[8]}};
      mid[9]  = (num1_ext >> 3) & {32{num2[9]}};
      mid[10] = (num1_ext >> 2) & {32{num2[10]}};
      mid[11] = (num1_ext >> 1) & {32{num2[11]}};
      mid[12] = (num1_ext     ) & {32{num2[12]}};
      mid[13] = (num1_ext << 1) & {32{num2[13]}};
      mid[14] = (num1_ext << 2) & {32{num2[14]}};
      mid[15] = (num1_ext << 3) & {32{num2[15]}};
*/
      
    end

endmodule