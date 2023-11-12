/* Due to te fact we cannot take benefit of the channel In to parallelize ( 1 output is given as the convolution between 1 feature in channel with 1 dy channel( its a 2d conv, not 3d as FW))
i decided to read block of 8 feature and dy and to fit into the MAC that has 8 multi + the dadda ( 8 is a power of 2)
*/
module featureInBWMngr # (
    parameter int FEATURE_OUT_ROW_SIZE = 32,
    parameter int FEATURE_OUT_COLUMN_SIZE = 32,
    parameter int NBITS = 16,
    parameter int KERNEL_SIZE = 3,
    parameter int NFEATURE_READ = 8
)
(
    input  [0:(NFEATURE_READ-1)][(NBITS-1):0]featureIn,
    output  reg [0:(KERNEL_SIZE - 1)][0:(KERNEL_SIZE - 1)][0:(NFEATURE_READ-1)][(NBITS-1):0]featuresInMngd,
    // address generated
    input  [($clog2(FEATURE_OUT_ROW_SIZE)-1):0]featureOutRowAddr,
    input  [($clog2(FEATURE_OUT_COLUMN_SIZE)-1):0]featureOutColumAddr
);

always @(*)  begin

        if (  featureOutRowAddr == 0 )begin // per i kernel con indice di riga 0
            if ( featureOutColumAddr == 0 ) begin 
                featuresInMngd[0][0][0:7] = featureIn[0:7]; // kernel 0 tocca tutti i feature in
                featuresInMngd[0][1][1:7] = featureIn[1:7]; // kernel 1 non tocca i feature 0
                featuresInMngd[0][1][0] = '{default:0};
                featuresInMngd[0][2][2:7] = featureIn[2:7]; // kernel 2 non tocca feature 0 e 1 
                featuresInMngd[0][2][0:1] = '{default:0};
            end else begin 
                featuresInMngd[0][0][0:7] = featureIn[0:7];
                featuresInMngd[0][1][0:7] = featureIn[0:7];
                featuresInMngd[0][2][0:7] = featureIn[0:7];
            end
            featuresInMngd[1][0] = '{default:0};// le feature con indice riga 0 non influenzano kernel con indice riga maggiore di 0
            featuresInMngd[1][1] = '{default:0};
            featuresInMngd[1][2] = '{default:0};
            featuresInMngd[2][0] = '{default:0};
            featuresInMngd[2][1] = '{default:0};
            featuresInMngd[2][2] = '{default:0};
        end else if ( featureOutRowAddr == 1 ) begin // per kernel con indice riga  1
            if ( featureOutColumAddr == 0 ) begin
                featuresInMngd[0][0][0:7] = featureIn[0:7];
                featuresInMngd[0][1][1:7] = featureIn[1:7];
                featuresInMngd[0][1][0:0] = '{default:0};
                featuresInMngd[0][2][2:7] = featureIn[2:7];
                featuresInMngd[0][2][0:1] = '{default:0};
                featuresInMngd[1][0][0:7] = featureIn[0:7];
                featuresInMngd[1][1][1:7] = featureIn[1:7];
                featuresInMngd[1][1][0:0] = '{default:0};
                featuresInMngd[1][2][2:7] = featureIn[2:7];
                featuresInMngd[1][2][0:1] = '{default:0};
            end else begin 
                featuresInMngd[0][0][0:7] = featureIn[0:7];
                featuresInMngd[0][1][0:7] = featureIn[0:7];
                featuresInMngd[0][2][0:7] = featureIn[0:7];
                featuresInMngd[1][0][0:7] = featureIn[0:7];
                featuresInMngd[1][1][0:7] = featureIn[0:7];
                featuresInMngd[1][2][0:7] = featureIn[0:7];
            end
            featuresInMngd[2][0] = '{default:0}; // le feature con idice di riga 1  no influiscono su kernel indice riga 2
            featuresInMngd[2][1] = '{default:0};
            featuresInMngd[2][2] = '{default:0};
        end else begin
            if (featureOutColumAddr == 0) begin // tutte le feature con indice di riga > 1
                featuresInMngd[0][0][0:7] = featureIn[0:7];
                featuresInMngd[0][1][1:7] = featureIn[1:7];
                featuresInMngd[0][1][0:0] = '{default:0};
                featuresInMngd[0][2][2:7] = featureIn[2:7];
                featuresInMngd[0][2][0:1] = '{default:0};
                featuresInMngd[1][0][0:7] = featureIn[0:7];
                featuresInMngd[1][1][1:7] = featureIn[1:7];
                featuresInMngd[1][1][0:0] = '{default:0};
                featuresInMngd[1][2][2:7] = featureIn[2:7];
                featuresInMngd[1][2][0:1] = '{default:0};
                featuresInMngd[2][0][0:7] = featureIn[0:7];
                featuresInMngd[2][1][1:7] = featureIn[1:7];
                featuresInMngd[2][1][0:0] = '{default:0};
                featuresInMngd[2][2][2:7] = featureIn[2:7];
                featuresInMngd[2][2][0:1] = '{default:0};
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