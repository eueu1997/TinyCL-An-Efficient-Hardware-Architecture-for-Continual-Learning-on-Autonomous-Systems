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
        #self.softmax = SoftmaxLayer()
        self.crossEntropy = CrossEntropyLoss(self.nClasses,self.batchSize,self.epsilon)

    def forward(self,inputs,labels):
    #start forward
        flatted = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        output = list()
        for b in range(self.batchSize):
            flatted[b] = inputs[b].flatten()
        #normalize 0,1
        self.linear0.forward(flatted)
        output.append(self.linear0.output)
        self.batchNorm1d0.forward(output[0])
        output.append(self.batchNorm1d0.output)
        self.relu0.forward(output[1])
        output.append(self.relu0.output)
        self.linear1.forward(output[2])
        output.append(self.linear1.output)
        self.batchNorm1d1.forward(output[3])
        output.append(self.batchNorm1d1.output)
        self.relu1.forward(output[4])
        output.append(self.relu1.output)
        self.linear2.forward(output[5])
        output.append(self.linear2.output)
        self.relu2.forward(output[6])
        output.append(self.relu2.output)

        #output.append(self.softmax.forward(output[7]))
        output.append(self.crossEntropy.forward(output[7],ConvToOneHot(labels,self.batchSize,self.nClasses)))
        return  output
    def feedback(self,lr):
        dx = [None]*8
        #start feedback
        #cross entropy feedback
        dx[7] = self.crossEntropy.feedback()
        #softmax feedback
        #dx[7] = self.softmax.feedback(dx[8])
        #relu feedback
        self.relu2.feedback(dx[7])
        dx[6] = self.relu2.dx
        #linear 2 feed back
        self.linear2.feedback(dx[6],lr)
        dx[5] = self.linear2.dx
        # relu 1 feedback        
        self.relu1.feedback(dx[5])
        dx[4] = self.relu1.dx
        # b4atch 1 feed back
        self.batchNorm1d1.feedback(dx[4],lr)
        dx[3] = self.batchNorm1d1.dx
        #linear 1 feed back
        self.linear1.feedback(dx[3],lr)
        dx[2] = self.linear1.dx
        #relu 0 feed back
        self.relu0.feedback(dx[2])
        dx[1] = self.relu0.dx
        #batch 0 feedback
        self.batchNorm1d0.feedback(dx[1],lr)
        dx[0] = self.batchNorm1d0.dx
        #linear 0 feed back
        self.linear0.feedback(dx[0],lr)
        return dx
def ConvToOneHot(input,batchSize,inputSize):
    b = np.zeros((batchSize, inputSize ),dtype="float32")
    b[np.arange(input.size), input] = 1
    return b