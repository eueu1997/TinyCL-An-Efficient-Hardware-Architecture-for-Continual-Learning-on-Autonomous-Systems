from .FCLayer import FCLayer
from .BatchNorm1d import BatchNorm1d
from .ReLU import ReLU1d 
import numpy as np
from .CrossEntropyLoss import CrossEntropyLoss

class MLPOnMIST():

    def __init__(self):
 
        self.inputData = int(28)
        self.inputSize = int(self.inputData*self.inputData)
        self.nClasses  = 10
        self.batchSize = 16
        self.epsilon = 1e-6

    # create model
        self.linear0 = FCLayer(self.inputSize,400,self.batchSize)
        self.batchNorm1d0 = BatchNorm1d(400,self.batchSize,self.epsilon)
        self.relu0 = ReLU1d(400,16)
        self.linear1 = FCLayer(400,400,16)
        self.batchNorm1d1 = BatchNorm1d(400,16,self.epsilon)
        self.relu1 = ReLU1d(400,16)
        self.linear2 = FCLayer(400,10,16)
        self.batchNorm1d2 = BatchNorm1d(10,16,self.epsilon)
        self.crossEntropy = CrossEntropyLoss(self.nClasses,self.batchSize)

    def forward(self,inputs,labels):
    #start forward
        flatted = np.zeros((self.batchSize,self.inputSize))
        
        for b in range(self.batchSize):
            flatted[b] = inputs[b].flatten()
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
        self.batchNorm1d2.forward(output)
        estimation = self.batchNorm1d2.output
        self.crossEntropy.forward(estimation,labels)
        return self.crossEntropy.output
    def feedback(self,lr):
        #start feedback
        #self.crossEntropy.feedback()
        #self.batchNorm1d2.feedback(self.crossEntropy.dx,lr)
        #self.linear2.feedback(self.batchNorm1d2.dx,lr)
        #self.batchNorm1d1.feedback(self.linear2.dx,lr)
        #self.linear1.feedback(self.batchNorm1d1.dx,lr)
        #self.batchNorm1d0.feedback(self.linear1.dx,lr)
        #self.linear0.feedback(self.batchNorm1d0.dx,lr)
        self.crossEntropy.feedback()
        #self.batchNorm1d2.feedback(self.crossEntropy.dx,lr)
        self.linear2.feedback(self.crossEntropy.dx,lr)
        #self.batchNorm1d1.feedback(self.linear2.dx,lr)
        self.linear1.feedback(self.linear2.dx,lr)
        #self.batchNorm1d0.feedback(self.linear1.dx,lr)
        self.linear0.feedback(self.linear1.dx,lr)
