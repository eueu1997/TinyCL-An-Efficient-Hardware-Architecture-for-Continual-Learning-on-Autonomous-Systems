module enableManger
(
    parameter int FEATURE_INT_SIZE;
    parameter int MAC_NUMBER = 3;
)
(
    input logic [(int(log2(FEATURE_INT_SIZE))-1):0] featureInAddrRow;
    input logic [(int(log2(FEATURE_INT_SIZE))-1):0] featureInAddrColmn;
    output logic [(MAC_NUMBER-1):0][(MAC_NUMBER-1):0] enables;
)


always @ ()begin
    if ($unsigned(featureInAddrColmn) = 0)begin
        if ($unsigned(featureInAddrRow) = 0)begin
            enables[0][0] = '1';
            enables[0][1] = '0';
            enables[0][2] = '0':
        end 
        else if ($unsigned(featureInAddrRow) = 1)begin
            enables[0][0] = '1';
            enables[0][1] = '1';
            enables[0][2] = '0';
        end
        else if ($unsigned(featureInAddrRow) > 1)begin
            enables[0][0] = '1';
            enables[0][1] = '1';
            enables[0][2] = '1';
        end    
        enables[1][0] = '0';
        enables[1][1] = '0';
        enables[1][2] = '0';
        enables[2][0] = '0';
        enables[2][1] = '0';
        enables[2][2] = '0';
    end
    else if ($unsigned(featureInAddrColmn) = 1)begin
        if ($unsigned(featureInAddrRow) = 0)begin
            enables[0][0] = '1';
            enables[0][1] = '0';
            enables[0][2] = '0';
            enables[1][0] = '1';
            enables[1][1] = '0';
            enables[1][2] = '0';
        end 
        else if ($unsigned(featureInAddrRow) = 1)begin
            enables[0][0] = '1';
            enables[0][1] = '1';
            enables[0][2] = '0';
            enables[1][0] = '1';
            enables[1][1] = '1';
            enables[1][2] = '0';
        end
        else if ($unsigned(featureInAddrRow) > 1)begin
            enables[0][0] = '1';
            enables[0][1] = '1';
            enables[0][2] = '1';
            enables[1][0] = '1';
            enables[1][1] = '1';
            enables[1][2] = '1';
        end    

        enables[2][0] = '0';
        enables[2][1] = '0';
        enables[2][2] = '0';
    end
    else if ($unsigned(featureInAddrColmn) > 1)begin
        if ($unsigned(featureInAddrRow) = 0)begin
            enables[0][0] = '1';
            enables[0][1] = '0';
            enables[0][2] = '0';
            enables[1][0] = '1';
            enables[1][1] = '0';
            enables[1][2] = '0';
            enables[2][0] = '1';
            enables[2][1] = '0';
            enables[2][2] = '0';
        end 
        else if ($unsigned(featureInAddrRow) = 1)begin
            enables[0][0] = '1';
            enables[0][1] = '1';
            enables[0][2] = '0';
            enables[1][0] = '1';
            enables[1][1] = '1';
            enables[1][2] = '0';
            enables[2][0] = '1';
            enables[2][1] = '1';
            enables[2][2] = '0';
        end
        else if ($unsigned(featureInAddrRow) > 1)begin
            enables[0][0] = '1';
            enables[0][1] = '1';
            enables[0][2] = '1';
            enables[1][0] = '1';
            enables[1][1] = '1';
            enables[1][2] = '1';    
            enables[2][0] = '1';
            enables[2][1] = '1';
            enables[2][2] = '1';
        end    

    end
end
endmodule