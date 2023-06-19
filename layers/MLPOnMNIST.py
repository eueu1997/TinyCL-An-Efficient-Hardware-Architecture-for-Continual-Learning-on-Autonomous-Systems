from BatchNorm1d import BatchNorm1d
from FCLayer import FCLayer
from ReLU import ReLU1d
import numpy as np
from CrossEntropyLoss import CrossEntropyLoss

class MLPOnMIST():

    def __init__(self,scheduler):
 
        inputData = int(28)
        inputSize = int(inputData*inputData)
        nClasses  = 10
        batchSize = 16
        epsilon = 1e-6

    # create model
        self.linear0 = FCLayer(inputSize,400,batchSize)
        self.batchNorm1d0 = BatchNorm1d(400,batchSize,epsilon)
        self.relu0 = ReLU1d(400,16)
        self.linear1 = FCLayer(400,400,16)
        self.batchNorm1d1 = BatchNorm1d(400,16,epsilon)
        self.relu1 = ReLU1d(400,16)
        self.linear2 = FCLayer(400,10,16)
        self.batchNorm1d2 = BatchNorm1d(10,16,epsilon)
        self.crossEntropy = CrossEntropyLoss(nClasses,batchSize)

    def forward(self,inputs,labes):
    #start forward
        self.linear0.forward(inputs)
        self.batchNorm1d0.forward(self.linear0.output)
        self.relu0.forward(self.batchNorm1d0.output)
        self.linear1.forward(self.relu0.output)
        self.batchNorm1d1.forward(self.linear1.output)
        self.relu1.forward(self.batchNorm1d1.output)
        self.linear2.forward(self.relu1.output)
        self.batchNorm1d2.forward(self.linear2.output)
        estimation = self.batchNorm1d2.output
        self.crossEntropy.forward(self.estimation,label)
        return self.crossEntropy.output
    def feedback(self,lr):
        #start feedback
        self.crossEntropy.feedback()
        self.batchNorm1d2.feedback(self.crossEntropy.dx,lr)
        self.linear2.feedback(self.batchNorm1d2.dx,lr)
        self.batchNorm1d1.feedback(self.linear2.dx,lr)
        self.linear1.feedback(self.batchNorm1d1.dx,lr)
        self.batchNorm1d0.feedback(self.linear1.dx,lr)
        self.linear0.feedback(self.batchNorm1d0.dx,lr)
