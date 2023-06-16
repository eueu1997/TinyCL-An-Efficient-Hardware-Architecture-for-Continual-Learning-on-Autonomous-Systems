import numpy as np

class ReLU2d():
    def __init__(self,inputSize,batchSize) -> None:
        self.inputSize = inputSize
        self.batchSize = batchSize
    
    def forward (self,input):

        output = np.zeros((self.inputSize,self.inputSize,self.batchSize))
        for k in range(self.batchSize):
            for i in range(self.inputSize):
                for j in range(self.inputSize):
                    if (input[i][j] > 0):
                        output[i][j] = input[i][j]
                    else : self.output[i][j] = 0
        return output
class ReLU1d():

    def __init__(self,inputSize,batchSize) -> None:
        self.inputSize = inputSize
        self.batchSize = batchSize
        self.output =  np.zeros((self.batchSize,self.inputSize))
    
    def forward (self,input):
        for k in range(self.batchSize):
            for i in range(self.inputSize):
                if (input[i] > 0):
                    self.output[i] = input[i]
                else  :
                    self.output[i] = 0
    