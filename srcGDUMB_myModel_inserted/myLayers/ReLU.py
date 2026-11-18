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
        self.output =  np.zeros((self.batchSize,self.inputSize),dtype="float32")
        #feedback 
        self.dx = np.zeros((self.batchSize,self.inputSize),dtype="float32")

    def forward (self,input):
        self.output = 1 / (np.exp(-input,dtype=("float32")) + 1)
        #self.output = np.maximum(input, 0)
    
    def feedback (self,input):
        self.dx = ( self.output * (1 - self.output)) * input  # sigmoid activation funztion
        #self.dx = 1 * (input > 0)                   # Relu activation funxtio
         
