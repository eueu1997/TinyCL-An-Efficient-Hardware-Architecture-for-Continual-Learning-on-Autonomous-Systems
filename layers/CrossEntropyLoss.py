
import numpy as np

class CrossEntropyLoss():
    def __init__(self,numberOfClasses,batchSize) :
        self.nOfClasses = numberOfClasses
        self.batchSize = batchSize
        self.weight = np.zeros(self.batchSize)
        self.losses = np.zeros(batchSize)
    def forward(self,input,expected):

        losses  = np.zeros(self.batchSize)
        temp = 0
        temp2 = 0  

        for k in range(self.batchSize):
            temp = 0
            temp2 = 0
            for j in range (self.nOfClasses):
                for i in range(self.nOfClasses):
                    temp += np.log(input[k][i])
                temp2 +=  self.weights[j]*np.log(input[k][j]/temp)*expected[j]
            losses[k] = -temp2

        self.losses = losses

        return losses
    
    def feedback():

        # calculate derivative of losses respect over input and over weight ( we are not using weight here, so only over input)
        # calculate average over all derivative of losses
        pass

