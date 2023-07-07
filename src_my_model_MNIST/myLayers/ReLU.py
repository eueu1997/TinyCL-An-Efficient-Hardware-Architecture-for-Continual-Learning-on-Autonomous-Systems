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
                    if (input[k][i][j] > 0):
                        output[k][i][j] = input[k][i][j]
                    else : self.output[k][i][j] = 0
        return output
class ReLU1d():

    def __init__(self,inputSize,batchSize) -> None:
        self.inputSize = inputSize
        self.batchSize = batchSize
        self.output =  np.zeros((self.batchSize,self.inputSize))
        #feedback 
        self.dx = np.zeros((self.batchSize,self.inputSize))

    def forward (self,input):
        self.output = 1 / (np.exp(-input) + 1)

        #for k in range(self.batchSize):
        #    for i in range(self.inputSize):
        #        if (input[k][i] > 0):
        #            self.output[k][i] = input[k][i]
        #        else  :
        #            self.output[k][i] = 0
    
    def feedback (self,input):
        self.dx = ( self.output * (1 - self.output)) * input
         

        #for k in range(self.batchSize):
        #    for i in range(self.inputSize):
        #        if (input[k][i] > 0):
        #            self.dx[k][i] = input[k][i]
        #        else  :
        #            self.dx[k][i] = 0