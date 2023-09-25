module tb_dadda_top;
    // Define parameters
    parameter int NBitIn = 16;
    parameter int NBitOut = 20;
    parameter int NOps = 9;
    
    // Define time units and precision
    `timescale 1ns/1ps
    
    
    
    
    // Define signals
    logic [1:NOps][NBitIn:1] DataIn;
    logic [NBitOut:1] DataOut;

// Instantiate the dadda_top module
    dadda_top#(
        .NBitIn(NBitIn),
        .NBitOut(NBitOut),
        .NOps(NOps)
    ) u_dadda_top (
        .DataIn(DataIn),
        .DataOut(DataOut)
    );
    // Initialize variables
    initial begin
        DataIn[1] = 'b1111111111111111;
        DataIn[2] = 'b1111111111111111;
        DataIn[3] = 'b1111111111111111;
        DataIn[4] = 'b1111111111111111;
        DataIn[5] = 'b1111111111111111;
        DataIn[6] = 'b1111111111111111;
        DataIn[7] = 'b1111111111111111;
        DataIn[8] = 'b1111111111111111;
        DataIn[9] = 'b1111111111111111;

        
        #10
        DataIn[1] = 'b0000000000000000;
        DataIn[2] = 'b1111111111111111;
        DataIn[3] = 'b0000000000000000;
        DataIn[4] = 'b0000000000000000;
        DataIn[5] = 'b1111111111111111;
        DataIn[6] = 'b0000000000000000;
        DataIn[7] = 'b0000000000000000;
        DataIn[8] = 'b1111111111111111;
        DataIn[9] = 'b0000000000000000;
        /*
        // Generate random inputs
        foreach(DataIn[i]) begin
            foreach(DataIn[i][j]) begin
                DataIn[i][j] = $urandom_range(0, (1<<NBitIn)-1);
            end
        end
        
        // Apply inputs
        #10;
        $display("Expected: %0d. Out output : %0d",DataIn[1]+DataIn[2]+DataIn[3]+DataIn[4]+DataIn[5]+DataIn[6]+DataIn[7]+DataIn[8]+DataIn[9],DataOut);
        #10;

        foreach(DataIn[i]) begin
            foreach(DataIn[i][j]) begin
                DataIn[i][j] = $urandom_range(0, (1<<NBitIn)-1);
            end
        end
        #10;
        $display("Expected: %0d. Out output : %0d",DataIn[1]+DataIn[2]+DataIn[3]+DataIn[4]+DataIn[5]+DataIn[6]+DataIn[7]+DataIn[8]+DataIn[9],DataOut);
        #10;
        foreach(DataIn[i]) begin
            foreach(DataIn[i][j]) begin
                DataIn[i][j] = $urandom_range(0, (1<<NBitIn)-1);
            end
        end
        
        // Apply inputs
        #10;
        $display("Expected: %0d. Out output : %0d",DataIn[1]+DataIn[2]+DataIn[3]+DataIn[4]+DataIn[5]+DataIn[6]+DataIn[7]+DataIn[8]+DataIn[9],DataOut);
        #10;
        foreach(DataIn[i]) begin
            foreach(DataIn[i][j]) begin
                DataIn[i][j] = $urandom_range(0, (1<<NBitIn)-1);
            end
        end
        
        // Apply inputs
        #10;
        $display("Expected: %0d. Out output : %0d",DataIn[1]+DataIn[2]+DataIn[3]+DataIn[4]+DataIn[5]+DataIn[6]+DataIn[7]+DataIn[8]+DataIn[9],DataOut);
        #10;
        foreach(DataIn[i]) begin
            foreach(DataIn[i][j]) begin
                DataIn[i][j] = $urandom_range(0, (1<<NBitIn)-1);
            end
        end
        
        // Apply inputs
        #10;
        $display("Expected: %0d. Out output : %0d",DataIn[1]+DataIn[2]+DataIn[3]+DataIn[4]+DataIn[5]+DataIn[6]+DataIn[7]+DataIn[8]+DataIn[9],DataOut);
        #10;
        foreach(DataIn[i]) begin
            foreach(DataIn[i][j]) begin
                DataIn[i][j] = $urandom_range(0, (1<<NBitIn)-1);
            end
        end
        
        // Apply inputs
        #10;
        $display("Expected: %0d. Out output : %0d",DataIn[1]+DataIn[2]+DataIn[3]+DataIn[4]+DataIn[5]+DataIn[6]+DataIn[7]+DataIn[8]+DataIn[9],DataOut);
        #10;*/
        
        
        
        // Add your verification code here
        
       
    end
endmodule
