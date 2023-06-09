import numpy as np

class ReLU():

    def forward (self,input,inputSize,batchSize):

        output = np.zeros((inputSize,inputSize,batchSize))
        for k in range(batchSize):
            for i in range(inputSize):
                for j in range(inputSize):
                    if (input[i][j] > 0):
                        output[i] = input[j]
        return output
    
    