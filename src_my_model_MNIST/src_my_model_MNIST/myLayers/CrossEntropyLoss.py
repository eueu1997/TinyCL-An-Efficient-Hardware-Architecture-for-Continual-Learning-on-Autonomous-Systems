
import numpy as np

class CrossEntropyLoss():
    def __init__(self,numberOfClasses,batchSize) :
        self.nOfClasses = numberOfClasses
        self.batchSize = batchSize
        #forward
        self.expected = np.zeros(numberOfClasses)
        self.output = np.zeros(batchSize)
        self.softmax = np.zeros((self.batchSize,self.nOfClasses))
        self.input = np.zeros((batchSize,numberOfClasses)) # input will be a matrix, each line are the value of probability for each class, this for each image in bathc
        #feedback
        self.dx = np.zeros((batchSize,numberOfClasses))
    def forward(self,input,expected):

        losses  = np.zeros(self.batchSize)
        temp = 0 
        self.input = input
        self.expected = expected
        for k in range(self.batchSize):
            temp = 0
            for i in range(self.nOfClasses):
                a = input[k][i]
                b = np.exp(a)
                temp += b        
            j=expected[k]     
            for i in range(self.nOfClasses):           
                self.softmax[k][i] = np.exp(input[k][i])/temp # save softmax of all outputs
            losses[k] = -np.log(self.softmax[k][j]) # use only the one of the expected to calculate the loss
                
        self.output = losses

    
    def feedback(self):

        # calculate derivative of losses respect over input and over weight ( we are not using weight here, so only over input)
        # calculate average over all derivative of losses
        output = np.zeros((self.batchSize,self.nOfClasses))
        for k in range(self.batchSize):
            for j in range(self.nOfClasses):
                if(j==self.expected[k]):
                    output[k][j] = self.softmax[k][j] - 1
                else:
                    output[k][j] = self.softmax[k][j]
        self.dx = output
   