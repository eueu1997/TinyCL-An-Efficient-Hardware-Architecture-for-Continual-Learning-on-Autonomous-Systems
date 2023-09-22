module dadda_top#
(
    parameter int NBitIn = 16,
	parameter int NBitOut = 20,
    parameter int NOps = 9
)
(
	input  logic [1:NOps][NBitIn:1] DataIn  ,
    output logic [NBitOut:1] DataOut  

);

typedef logic [1:6][NBit:1] l3;
typedef logic [1:4][NBit:1] l2;
typedef logic [1:3][NBit:1] l1;
typedef logic [1:2][NBit:1] l0;


    // Local variable
    l3 level3;
    l2 level2;
    l1 level1;
    l0 level0;

    level3 = Level4Func(DataIn);
    level2 = Level3Func(level3);
    level2 = Level1Func(level2);
    DataOut = Level1Func(level1);

//Compression from 9 to 6 addends
function automatic l3 Level4Func(input l4 level4);
    automatic l3 locLevel3 = '{'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0}};
    automatic int locI;
    automatic logic locTout = 0;
	automatic logic locTin = 0;
	// ARRAY INITIALIZATION
	for(locI = 0; locI < 16;locI++)begin

        if( locI = 0)begin
            locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][loc+1])
            locLevel3[1][locI] = HalfAdderFunc(level4[3][locI],level4[4][locI],locLevel3[2][locI+1])
            locLevel3[2][locI] = level4[5][locI];
            locLevel3[3][locI] = level4[6][locI];
            locLevel3[4][locI] = level4[7][locI];
		    locLevel3[5][locI] = level4[8][locI];
		end

		if(locI = 1)begin
            locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][loc+1])
            locLevel3[3][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[4][loc+1])
            locLevel3[4][locI] = HalfAdderFunc(level4[6][locI],level4[7][locI],locLevel3[5][locI+1])
			locLevel3[5][locI] = level4[8][locI];
		end;

        if(locI = 2 )begin
			locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][loc+1])
            locLevel3[2][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[3][loc+1])
            locLevel3[3][locI] = FullAdderFunc(level4[6][locI],level4[7][locI],level4[8][locI],locLevel3[4][loc+1])	
		end;

        if(locI = 3 )begin
			locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][loc+1])
            locLevel3[2][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[3][loc+1])
            locLevel3[5][locI] = FullAdderFunc(level4[6][locI],level4[7][locI],level4[8][locI],locLevel3[5][loc+1])	
		end;

        if(locI >= 4 )begin
			locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][loc+1])
            locLevel3[2][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[3][loc+1])
            locLevel3[4][locI] = FullAdderFunc(level4[6][locI],level4[7][locI],level4[8][locI],locLevel3[5][loc+1])	
		end;
        

	end

    
    return locLevel3;
endfunction

//Compression from 6 to 4 addends
function automatic l2 Level3Func(input l3 level3);
    automatic l2 locLevel2 = '{'{default:0},'{default:0},'{default:0},'{default:0}} ; 
    int locI;
    automatic logic locTout = 0;
	automatic logic locTin = 0; // NEED OF INITIALIZATION DUE TO BRUTE USAGE AS FIRST 5-3 COMRPESSOR

	for(locI = 0; locI < 17;locI++)begin

        if( locI = 0)begin
            locLevel2[0][locI] = FullAdderFunc(level3[0][locI],level3[1][locI],level3[2][locI],locLevel2[1][loc+1])
            locLevel2[1][locI] = level3[3][locI];
            locLevel2[2][locI] = level3[4][locI];
		    locLevel2[3][locI] = level3[5][locI];
		end

		if(locI = 1)begin
            locLevel2[0][locI] = FullAdderFunc(level3[0][locI],level3[1][locI],level3[2][locI],locLevel2[1][loc+1])
            locLevel2[2][locI] = HalfAdderFunc(level3[3][locI],level3[4][locI],locLevel2[3][locI+1])
			locLevel2[3][locI] = level3[5][locI];
		end;

        if(locI >= 2 && locI<=15)begin
			locLevel2[0][locI] = FullAdderFunc(level3[0][locI],level3[1][locI],level3[2][locI],locLevel2[1][loc+1])
            locLevel2[2][locI] = FullAdderFunc(level3[3][locI],level3[4][locI],level3[5][locI],locLevel2[3][loc+1])
		end;

        if(locI = 16)begin
            locLevel2[0][locI] = HalfAdderFunc(level3[1][locI],level3[3][locI],locLevel2[1][locI+1])
            locLevel2[2][locI] = level3[5][locI]
		end;

	end

    return locLevel2;
endfunction
//Compression from 4 to 3 addends
function automatic l1 Level2Func(input l2 level2);
    automatic l1 locLevel1 = '{'{default:0},'{default:0},'{default:0}};
    int locI;

	for(locI = 0; locI < 18;locI++)begin

        if( locI = 0)begin
            locLevel1[0][locI] = HalfAdderFunc(level2[0][locI],level2[1][locI],locLevel1[1][loc+1])
            locLevel1[1][locI] = level2[2][locI];
            locLevel1[2][locI] = level2[3][locI];
		end

		if(locI >= 1 && locI <= 16)begin
            locLevel1[0][locI] = FullAdderFunc(level2[0][locI],level2[1][locI],level2[2][locI],locLevel1[1][loc+1])
			locLevel1[2][locI] = level2[3][locI];
		end;

        if(locI = 17)begin
            locLevel1[0][locI] = level2[1][locI];

        end

	end
    return locLevel1;
endfunction

// Compression from 3 to 2 addends
function automatic l0  Level1Func(input l1 level1);
    automatic l0 locLevel0  = '{'{default:0},'{default:0}}; // NO INITIALLIZATION
    int locI;

    for(locI = 0; locI < 19;locI++)begin

        if( locI = 0)begin
            locLevel0[0][locI] = HalfAdderFunc(level1[0][locI],level1[1][locI],locLevel0[1][loc+1])
            locLevel0[1][locI] = level1[2][locI];
		end

		if(locI >= 1 && locI <= 16)begin
            locLevel0[0][locI] = FullAdderFunc(level1[0][locI],level1[1][locI],level1[2][locI],locLevel0[1][loc+1])
		end;

        if(locI = 17)begin
            locLevel0[0][locI] = HalfAdderFunc(level1[0][locI],level1[1][locI],locLevel0[1][loc+1])

        end

	end

	return locLevel0;
endfunction

function automatic logic HalfAdderFunc(input logic bit1, input logic bit2, output logic carryOut);
    
    carryOut = bit1 & bit2;
    return bit1 ^ bit2;

endfunction

function automatic logic FullAdderFunc(input logic bit1, input logic bit2, input logic carryIn, output logic carryOut);
    
    carryOut = (bit1 & bit2) | (carryIn & (bit1 ^ bit2));
    return (bit1 ^ bit2) ^ carryIn;
    
endfunction
endmodule