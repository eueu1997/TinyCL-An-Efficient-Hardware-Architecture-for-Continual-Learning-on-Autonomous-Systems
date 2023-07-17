import numpy as np

class ReLU1d():

    def __init__(self,inputSize,batchSize) -> None:
        self.inputSize = inputSize
        self.batchSize = batchSize
        self.output =  np.zeros((self.batchSize,self.inputSize),dtype="float32")
        #feedback 
        self.dx = np.zeros((self.batchSize,self.inputSize),dtype="float32")

    def forward (self,input):
        self.output = 1 / (np.exp(-input,dtype=("float32")) + 1)

    
    def feedback (self,input):
        self.dx = ( self.output * (1 - self.output)) * input
