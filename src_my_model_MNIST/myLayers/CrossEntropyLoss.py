
import numpy as np

class CrossEntropyLoss():
    def __init__(self,numberOfClasses,batchSize) :
        self.nOfClasses = numberOfClasses
        self.batchSize = batchSize
        #forward
        self.expected = np.zeros(numberOfClasses)
        self.output = np.zeros(batchSize)
        self.input = np.zeros((batchSize,numberOfClasses)) # input will be a matrix, each line are the value of probability for each class, this for each image in bathc
        #feedback
        self.dx = np.zeros((batchSize,numberOfClasses))
    def forward(self,input,expected):

        losses  = np.zeros(self.batchSize)
        temp = 0
        temp2 = 0  
        self.input = input
        traslated = np.zeros((self.batchSize,self.nOfClasses))

        self.expected = expected
        for k in range(self.batchSize):
            temp = 0
            temp2 = 0
            
            for j in range (self.nOfClasses):
                y = 0
                y = 1 if (j==expected[k]) else 0
                for i in range(self.nOfClasses):
                    a = input[k][i]
                    b = np.exp(a)
                    temp += b
                temp2 +=  np.log(np.exp(input[k][j])/temp)*y
                temp = 0
            losses[k] = -temp2

        self.output = losses

    
    def feedback(self):

        # calculate derivative of losses respect over input and over weight ( we are not using weight here, so only over input)
        # calculate average over all derivative of losses
        output = np.zeros((self.batchSize,self.nOfClasses))
        sumOfoutputs = np.zeros(self.batchSize)
        for k in range(self.batchSize):
            for c in range(self.nOfClasses):
                sumOfoutputs[k] += np.exp(self.input[k][c])
        for k in range(self.batchSize):
            for c in range(self.nOfClasses):
                output[k][c] = (sumOfoutputs[k]) / np.exp(self.input[k][c])*((np.exp(3*self.input[k][c]) + sumOfoutputs[k]*np.exp(self.input[k][c]))/np.exp(2*self.input[k][c]))*self.expected[c]
        self.dx = output
   