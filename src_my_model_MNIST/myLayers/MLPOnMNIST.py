from .FCLayer import FCLayer
from .BatchNorm1d import BatchNorm1d
from .ReLU import ReLU1d 
import numpy as np
from .CrossEntropyLoss import CrossEntropyLoss,CrossEntropyLoss2
from .CrossEntropyLoss import SoftmaxLayer
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
        self.linear0 = FCLayer(self.inputSize,400,self.batchSize,self.weightDecay,0.1)
        self.batchNorm1d0 = BatchNorm1d(400,self.batchSize,self.epsilon,self.weightDecay,0.1)
        self.relu0 = ReLU1d(400,self.batchSize)
        self.linear1 = FCLayer(400,400,self.batchSize,self.weightDecay,0.5)
        self.batchNorm1d1 = BatchNorm1d(400,self.batchSize,self.epsilon,self.weightDecay,0.5)
        self.relu1 = ReLU1d(400,self.batchSize)
        self.linear2 = FCLayer(400,10,self.batchSize,self.weightDecay,0.9)
        self.relu2 = ReLU1d(10,self.batchSize)
        #self.crossEntropy = CrossEntropyLoss2()
        self.softmax = SoftmaxLayer()
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

        argmax = self.softmax.forward(estimation)
        return self.crossEntropy.forward(argmax,ConvToOneHot(labels,self.batchSize,self.nClasses))
    def feedback(self,lr):

        #start feedback
        #cross entropy feedback
        dx = self.crossEntropy.feedback()
        #softmax feedback
        dx = self.softmax.feedback(dx)
        #relu feedback
        self.relu2.feedback(dx)
        dx = self.relu2.dx
        #linear 2 feed back
        self.linear2.feedback(dx,lr)
        dx = self.linear2.dx
        # relu 1 feedback        
        self.relu1.feedback(dx)
        dx = self.relu1.dx
        # batch 1 feed back
        self.batchNorm1d1.feedback(dx,lr)
        dx = self.batchNorm1d1.dx
        #linear 1 feed back
        self.linear1.feedback(dx,lr)
        dx = self.linear1.dx
        #relu 0 feed back
        self.relu0.feedback(dx)
        dx = self.relu0.dx
        #batch 0 feedback
        self.batchNorm1d0.feedback(dx,lr)
        dx = self.batchNorm1d0.dx
        #linear 0 feed back
        self.linear0.feedback(dx,lr)
        dx = self.linear0.dx

def ConvToOneHot(input,batchSize,inputSize):
    b = np.zeros((batchSize, inputSize ),dtype="float32")
    b[np.arange(input.size), input] = 1
    return b