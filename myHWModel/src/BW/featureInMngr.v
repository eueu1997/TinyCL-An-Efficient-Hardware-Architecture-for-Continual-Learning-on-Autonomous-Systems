featureInMngr module (
    parameter int featureInDim = 32;
    parameter int nBits = 16;
    parameter int kernelSize = 3;
    parameter int nFeatureRead = 8;

)
(
    output logic [(2*int(log2(featureInDim))-1):0] featureInAddr;
    input logic [0:(nFeatureRead-1)][(nBits-1):0]featureIn;
    output logic [0:(kernelSize - 1)][0:(kernelSize - 1)][0:(nFeatureRead-1)][(nBits-1):0]featuresInMngd;
    input logic clk;
    input logic rst;
)

always @( )  begin
    if(rst = '0')begin
        featuresInMngd = {default:0};
    end else begin
        if ( featureInAddr[(2*int(log2(featureInDim))-1):(int(log2(featureInDim)))] = 0[(int(log2(featureInDim))-1):0] )begin // per i kernel con indice di colonna 0
        if ( featureInAddr[(int(log2(featureInDim))-1):0] = 0[(int(log2(featureInDim))-1):0] ) begin
            featuresInMngd[0][0][0:7] = featureIn[0:7]; // kernel 0 tocca tutti i feature in
            featuresInMngd[0][1][1:7] = featureIn[1:7];// kernel 1 non tocca i feature 0
            featuresInMngd[0][1][0:1] = {default:0};
            featuresInMngd[0][2][2:7] = featureIn[2:7]; // kernel 2 non tocca feature 0 e 1 
            featuresInMngd[0][2][0:2] = {default:0};
        end else begin 
            featuresInMngd[0][0][0:7] = featureIn[0:7];
            featuresInMngd[0][1][0:7] = featureIn[0:7];
            featuresInMngd[0][2][0:7] = featureIn[0:7];
        end
            featuresInMngd[1][0] = {default:0};// le feature con indice di riga maggiore di 1 non infuiscono su kernel riga 0
            featuresInMngd[1][1] = {default:0};
            featuresInMngd[1][2] = {default:0};
            featuresInMngd[2][0] = {default:0};
            featuresInMngd[2][1] = {default:0};
            featuresInMngd[2][2] = {default:0};
    end else if ( featureInAddr[(2*int(log2(featureInDim))-1):(int(log2(featureInDim)))] = 1[(int(log2(featureInDim))-1):0] ) begin // per kernel con indice riga 
        if ( featureInAddr[(int(log2(featureInDim))-1):0] = 0[(int(log2(featureInDim))-1):0] ) begin
            featuresInMngd[0][0][0:7] = featureIn[0:7];
            featuresInMngd[0][1][1:7] = featureIn[1:7];
            featuresInMngd[0][1][0:1] = {default:0};
            featuresInMngd[0][2][2:7] = featureIn[2:7];
            featuresInMngd[0][2][0:2] = {default:0};
            featuresInMngd[1][0][0:7] = featureIn[0:7];
            featuresInMngd[1][1][1:7] = featureIn[1:7];
            featuresInMngd[1][1][0:1] = {default:0};
            featuresInMngd[1][2][2:7] = featureIn[2:7];
            featuresInMngd[1][2][0:2] = {default:0};
        end else begin 
            featuresInMngd[0][0][0:7] = featureIn[0:7];
            featuresInMngd[0][1][0:7] = featureIn[0:7];
            featuresInMngd[0][2][0:7] = featureIn[0:7];
            featuresInMngd[1][0][0:7] = featureIn[0:7];
            featuresInMngd[1][1][0:7] = featureIn[0:7];
            featuresInMngd[1][2][0:7] = featureIn[0:7];
        end
            featuresInMngd[2][0] = {default:0}; // le feature con idice di riga 1  no influiscono su kernel indice riga 2
            featuresInMngd[2][1] = {default:0};
            featuresInMngd[2][2] = {default:0};
    end else begin

    end if ( featureInAddr[(int(log2(featureInDim))-1):0] > 1[(int(log2(featureInDim))-1):0] ) begin // tutte le feature con indice di
            featuresInMngd[0][0][0:7] = featureIn[0:7];
            featuresInMngd[0][1][1:7] = featureIn[1:7];
            featuresInMngd[0][1][0:1] = {default:0};
            featuresInMngd[0][2][2:7] = featureIn[2:7];
            featuresInMngd[0][2][0:2] = {default:0};
            featuresInMngd[1][0][0:7] = featureIn[0:7];
            featuresInMngd[1][1][1:7] = featureIn[1:7];
            featuresInMngd[1][1][0:1] = {default:0};
            featuresInMngd[1][2][2:7] = featureIn[2:7];
            featuresInMngd[1][2][0:2] = {default:0};
            featuresInMngd[2][0][0:7] = featureIn[0:7];
            featuresInMngd[2][1][1:7] = featureIn[1:7];
            featuresInMngd[2][1][0:1] = {default:0};
            featuresInMngd[2][2][2:7] = featureIn[2:7];
            featuresInMngd[2][2][0:2] = {default:0};
        end else begin 
            featuresInMngd[0][0][0:7] = featureIn[0:7];
            featuresInMngd[0][1][0:7] = featureIn[0:7];
            featuresInMngd[0][2][0:7] = featureIn[0:7];
            featuresInMngd[1][0][0:7] = featureIn[0:7];
            featuresInMngd[1][1][0:7] = featureIn[0:7];
            featuresInMngd[1][2][0:7] = featureIn[0:7];
            featuresInMngd[2][0][0:7] = featureIn[0:7];
            featuresInMngd[2][1][0:7] = featureIn[0:7];
            featuresInMngd[2][2][0:7] = featureIn[0:7];
        end
            
    end
    
end
endmodule