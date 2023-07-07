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
        self.epsilon = 1e-6
        self.weightDecay = 1e-6
        self.momentumFC = 0.9
        self.momentumBN = 0.9

    # create model
        self.linear0 = FCLayer(self.inputSize,400,self.batchSize,self.weightDecay,0.1)
        self.batchNorm1d0 = BatchNorm1d(400,self.batchSize,self.epsilon,self.weightDecay,0.1)
        self.relu0 = ReLU1d(400,self.batchSize)
        self.linear1 = FCLayer(400,400,self.batchSize,self.weightDecay,0.5)
        self.batchNorm1d1 = BatchNorm1d(400,self.batchSize,self.epsilon,self.weightDecay,0.5)
        self.relu1 = ReLU1d(400,self.batchSize)
        self.linear2 = FCLayer(400,10,self.batchSize,self.weightDecay,0.9)
        self.batchNorm1d2 = BatchNorm1d(10,self.batchSize,self.epsilon,self.weightDecay,0.9)
        self.relu2 = ReLU1d(10,self.batchSize)
        self.crossEntropy = CrossEntropyLoss(self.nClasses,self.batchSize,self.epsilon)

    def forward(self,inputs,labels):
    #start forward
        flatted = np.zeros((self.batchSize,self.inputSize))
        
        for b in range(self.batchSize):
            flatted[b] = inputs[b].flatten()
        #normalize 0,1
        self.linear0.forward(flatted)
        output = self.linear0.output
        self.batchNorm1d0.myforward(output)
        compare = self.batchNorm1d0.forward(output)
        output = self.batchNorm1d0.output
        diff = np.sum((compare - output))
        self.relu0.forward(output)
        output = self.relu0.output
        self.linear1.forward(output)
        output = self.linear1.output
        self.batchNorm1d1.myforward(output)
        compare = self.batchNorm1d1.forward(output)
        output = self.batchNorm1d1.output
        diff = np.sum((compare - output))
        self.relu1.forward(output)
        output = self.relu1.output
        self.linear2.forward(output)
        output = self.linear2.output
        self.batchNorm1d2.myforward(output)
        compare = self.batchNorm1d2.forward(output)
        output = self.batchNorm1d2.output
        diff = np.sum((compare - output))
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
        compare = self.batchNorm1d2.backward(dx)
        self.batchNorm1d2.myfeedback(dx,lr)
        dx = self.batchNorm1d2.dx
        diff = np.sum((compare - dx))
        #dx = self.batchNorm1d2.dx
        self.linear2.feedback(dx,lr)
        dx = self.linear2.dx        
        self.relu1.feedback(dx)
        dx = self.relu1.dx
        compare = self.batchNorm1d1.backward(dx)
        self.batchNorm1d1.myfeedback(dx,lr)
        dx = self.batchNorm1d1.dx
        diff = np.sum((compare - dx))
        #dx = self.batchNorm1d1.dx
        self.linear1.feedback(dx,lr)
        dx = self.linear1.dx
        self.relu0.feedback(dx)
        dx = self.relu0.dx
        compare = self.batchNorm1d0.backward(dx)
        self.batchNorm1d0.myfeedback(dx,lr)
        dx = self.batchNorm1d0.dx
        diff = np.sum((compare - dx))
        #dx = self.batchNorm1d0.dx
        self.linear0.feedback(dx,lr)
        dx = self.linear0.dx

        #self.crossEntropy.feedback()
        #self.batchNorm1d2.feedback(self.crossEntropy.dx,lr)
        #self.linear2.feedback(self.crossEntropy.dx,lr)
        #self.batchNorm1d1.feedback(self.linear2.dx,lr)
        #self.linear1.feedback(self.linear2.dx,lr)
        #self.batchNorm1d0.feedback(self.linear1.dx,lr)
        #self.linear0.feedback(self.linear1.dx,lr)

def ConvToOneHot(input,batchSize,inputSize):
    b = np.zeros((batchSize, inputSize ))
    b[np.arange(input.size), input] = 1
    return b