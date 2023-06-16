from BatchNorm1d import BatchNorm1d
from FCLayer import FCLayer
from ReLU import ReLU1d
import numpy as np
if __name__ == '__main__':
    #define 
    inputData = 28
    inputSize = inputData*inputData
    nClasses  = 10
    trainingData  = 1000
    batchSize = 16
    epsilon = 0.1
    dataset = np.zeros(trainingData,inputData,inputData)
    # load dataset 

    #load lr
    lr = 0.05 # TODO to be set dynamic lr
    # create model
    linear0 = FCLayer(inputSize,400,batchSize,lr)
    batchNorm1d0 = BatchNorm1d(400,batchSize,lr,epsilon)
    relu0 = ReLU1d(400,16)
    linear1 = FCLayer(400,400,16,lr)
    batchNorm1d1 = BatchNorm1d(400,16,lr,epsilon)
    relu1 = ReLU1d(400,16)
    linear2 = FCLayer(400,10,16,lr)
    batchNorm1d2 = BatchNorm1d(10,16,lr,epsilon)
    for start_x in range(0, trainingData, batchSize):
        #iterate over a batch of dataset
        end_x = start_x + batchSize
        submatrix = dataset[start_x:end_x, :, :]
        #start forward
        linear0.forward(submatrix)
        batchNorm1d0.forward(linear0.output)
        relu0.forward(batchNorm1d0.output)
        linear1.forward(relu0.output)
        batchNorm1d1.forward(linear1.output)
        relu1.forward(batchNorm1d1.output)
        linear2.forward(relu1.output)
        batchNorm1d2.forward(linear1.output)
        estimation = batchNorm1d2.output
        