from .FCLayer import FCLayer
from .BatchNorm1d import BatchNorm1d
from .ReLU import ReLU1d 
import numpy as np
from .CrossEntropyLoss import CrossEntropyLoss

class MLPOnMIST():

    def __init__(self,inputDataSize):

        self.inputData = int(inputDataSize)
        self.inputSize = int(self.inputData*self.inputData)
        self.nClasses  = 10
        self.batchSize = 16
        self.epsilon =  10 ** -3
        self.weightDecay = 1e-6
        self.momentumFC = 0.9
        self.momentumBN = 0.9

    # create model
    # Due layer lineare - batchNormalization e sigmoid ( si chiama relu ma implementa la signoid function)
    # ultimo later senza batch normalization
        self.linear0 = FCLayer(self.inputSize,100,self.batchSize,self.weightDecay,0.1)
        self.batchNorm1d0 = BatchNorm1d(100,self.batchSize,self.epsilon,self.weightDecay,0.1)
        self.relu0 = ReLU1d(400,self.batchSize)
        self.linear1 = FCLayer(100,100,self.batchSize,self.weightDecay,0.5)
        self.batchNorm1d1 = BatchNorm1d(100,self.batchSize,self.epsilon,self.weightDecay,0.5)
        self.relu1 = ReLU1d(100,self.batchSize)
        self.linear2 = FCLayer(100,10,self.batchSize,self.weightDecay,0.9)
        self.relu2 = ReLU1d(10,self.batchSize)
        # calcolo loss tramite cross entropy algo
        self.crossEntropy = CrossEntropyLoss(self.nClasses,self.batchSize,self.epsilon)

    def forward(self,inputs,labels):
    #start forward
        flatted = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        
        for b in range(self.batchSize):
            flatted[b] = inputs[b].flatten()
        #normalize 0,1
        self.linear0.forward(flatted)
        output = self.linear0.output
        self.batchNorm1d0.forward(output)
        output = self.batchNorm1d0.output
        self.relu0.forward(output)
        output = self.relu0.output
        self.linear1.forward(output)
        output = self.linear1.output
        self.batchNorm1d1.forward(output)
        output = self.batchNorm1d1.output
        self.relu1.forward(output)
        output = self.relu1.output
        self.linear2.forward(output)
        output = self.linear2.output
        self.relu2.forward(output)
        estimation = self.relu2.output
        self.crossEntropy.forward(estimation,ConvToOneHot(labels,self.batchSize,self.nClasses))
        return self.crossEntropy.output
    def feedback(self,lr):
        #start feedback
        self.crossEntropy.feedback()
        dx = self.crossEntropy.dx
        self.relu2.feedback(dx)
        dx = self.relu2.dx
        self.linear2.feedback(dx,lr)
        dx = self.linear2.dx        
        self.relu1.feedback(dx)
        dx = self.relu1.dx
        self.batchNorm1d1.feedback(dx,lr)
        dx = self.batchNorm1d1.dx
        self.linear1.feedback(dx,lr)
        dx = self.linear1.dx
        self.relu0.feedback(dx)
        dx = self.relu0.dx
        self.batchNorm1d0.feedback(dx,lr)
        dx = self.batchNorm1d0.dx
        self.linear0.feedback(dx,lr)
        dx = self.linear0.dx

        

def ConvToOneHot(input,batchSize,inputSize):
    b = np.zeros((batchSize, inputSize ),dtype="float32")
    b[np.arange(input.size), input] = 1
    return b