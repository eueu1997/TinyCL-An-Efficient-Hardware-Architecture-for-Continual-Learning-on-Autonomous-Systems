module dadda_top #
(
    parameter NBitIn = 16,
    parameter NBitOut = 20,
    parameter NOps = 9
)
(
    input  [0:(NOps-1)][(NBitIn-1):0] DataIn  ,
    output reg [(NBitIn-1):0] DataOut  

);
typedef reg [0:8][(NBitIn-1):0] l4;
typedef reg [0:5][(NBitOut-1):0] l3;
typedef reg [0:3][(NBitOut-1):0] l2;
typedef reg [0:2][(NBitOut-1):0] l1;
typedef reg [0:1][(NBitOut-1):0] l0;


    // Local variableù
    l4 level4;
    l3 level3;
    l2 level2;
    l1 level1;
    l0 level0;
    reg [(NBitOut-1):0] temp;

	always_comb	begin 
    level3 = Level4Func(DataIn);
    level2 = Level3Func(level3);
    level1 = Level2Func(level2);
    level0 = Level1Func(level1);
    temp = level0[0] + level0[1];
    DataOut = temp[(NBitIn-1):0];
    end
//Compression from 9 to 6 addends
function  automatic l3 Level4Func(input l4 level4);
    automatic  l3 locLevel3 = '{'{default:0},'{default:0},'{default:0},'{default:0},'{default:0},'{default:0}};
	// ARRAY INITIALIZATION
	for(int locI = 0; locI < 16;locI = locI + 1)begin

        if( locI == 0)begin
            locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][locI+1]);
            locLevel3[1][locI] = HalfAdderFunc(level4[3][locI],level4[4][locI],locLevel3[2][locI+1]);
            locLevel3[2][locI] = level4[5][locI];
            locLevel3[3][locI] = level4[6][locI];
            locLevel3[4][locI] = level4[7][locI];
		    locLevel3[5][locI] = level4[8][locI];
        end  else if(locI == 1)begin
            locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][locI+1]);
            locLevel3[3][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[4][locI+1]);
            locLevel3[4][locI] = HalfAdderFunc(level4[6][locI],level4[7][locI],locLevel3[5][locI+1]);
			locLevel3[5][locI] = level4[8][locI];
        end else if(locI == 2 )begin
	        locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][locI+1]);
            locLevel3[2][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[3][locI+1]);
            locLevel3[3][locI] = FullAdderFunc(level4[6][locI],level4[7][locI],level4[8][locI],locLevel3[4][locI+1]);
        end else if(locI == 3 )begin
			locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][locI+1]);
            locLevel3[2][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[3][locI+1]);
            locLevel3[5][locI] = FullAdderFunc(level4[6][locI],level4[7][locI],level4[8][locI],locLevel3[5][locI+1]);
        end  else begin
			locLevel3[0][locI] = FullAdderFunc(level4[0][locI],level4[1][locI],level4[2][locI],locLevel3[1][locI+1]);
            locLevel3[2][locI] = FullAdderFunc(level4[3][locI],level4[4][locI],level4[5][locI],locLevel3[3][locI+1]);
            locLevel3[4][locI] = FullAdderFunc(level4[6][locI],level4[7][locI],level4[8][locI],locLevel3[5][locI+1]);
		end
        

	end

    
    return locLevel3;
endfunction

//Compression from 6 to 4 addends
function  automatic l2 Level3Func(input l3 level3);
    automatic l2 locLevel2 = '{'{default:0},'{default:0},'{default:0},'{default:0}} ; 
    int locI;
    
	for(locI = 0; locI < 17;locI = locI + 1)begin

        if( locI == 0)begin
            locLevel2[0][locI] = FullAdderFunc(level3[0][locI],level3[1][locI],level3[2][locI],locLevel2[1][locI+1]);
            locLevel2[1][locI] = level3[3][locI];
            locLevel2[2][locI] = level3[4][locI];
		    locLevel2[3][locI] = level3[5][locI];
        end else if(locI == 1)begin
            locLevel2[0][locI] = FullAdderFunc(level3[0][locI],level3[1][locI],level3[2][locI],locLevel2[1][locI+1]);
            locLevel2[2][locI] = HalfAdderFunc(level3[3][locI],level3[4][locI],locLevel2[3][locI+1]);
			locLevel2[3][locI] = level3[5][locI];
        end else if((locI >= 2) && (locI<=15))begin
			locLevel2[0][locI] = FullAdderFunc(level3[0][locI],level3[1][locI],level3[2][locI],locLevel2[1][locI+1]);
            locLevel2[2][locI] = FullAdderFunc(level3[3][locI],level3[4][locI],level3[5][locI],locLevel2[3][locI+1]);
        end else begin
            locLevel2[0][locI] = HalfAdderFunc(level3[1][locI],level3[3][locI],locLevel2[1][locI+1]);
            locLevel2[2][locI] = level3[5][locI];
		end

	end

    return locLevel2;
endfunction
//Compression from 4 to 3 addends
function automatic l1 Level2Func(input l2 level2);
    automatic l1 locLevel1 = '{'{default:0},'{default:0},'{default:0}};
    int locI;

	for(locI = 0; locI < 18;locI = locI +1)begin

        if( locI == 0)begin
            locLevel1[0][locI] = HalfAdderFunc(level2[0][locI],level2[1][locI],locLevel1[1][locI+1]);
            locLevel1[1][locI] = level2[2][locI];
            locLevel1[2][locI] = level2[3][locI];
        end else if((locI >= 1) && (locI <= 16))begin
            locLevel1[0][locI] = FullAdderFunc(level2[0][locI],level2[1][locI],level2[2][locI],locLevel1[1][locI+1]);
			locLevel1[2][locI] = level2[3][locI];
        end else begin
            locLevel1[0][locI] = level2[1][locI];

        end

	end
    return locLevel1;
endfunction

// Compression from 3 to 2 addends
function automatic l0  Level1Func(input l1 level1);
    automatic l0 locLevel0  = '{'{default:0},'{default:0}}; // NO INITIALLIZATION
    int locI;

    for(locI = 0; locI < 19;locI = locI +1)begin

        if( locI == 0)begin
            locLevel0[0][locI] = HalfAdderFunc(level1[0][locI],level1[1][locI],locLevel0[1][locI+1]);
            locLevel0[1][locI] = level1[2][locI];
        end else if((locI >= 1) && (locI <= 16))begin
            locLevel0[0][locI] = FullAdderFunc(level1[0][locI],level1[1][locI],level1[2][locI],locLevel0[1][locI+1]);
        end  else begin
            locLevel0[0][locI] = HalfAdderFunc(level1[0][locI],level1[1][locI],locLevel0[1][locI+1]);

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