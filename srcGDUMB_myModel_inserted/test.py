from myLayers.MLPOnMNIST import MLPOnMIST
import numpy as np

if __name__ == '__main__':
    myModel = MLPOnMIST(3)
    inputs = [
        [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9],
        [0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.1],
        [0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.1,0.2],
        [0.4,0.5,0.6,0.7,0.8,0.9,0.1,0.2,0.3],
        ]
    labels = np.zeros((4,10))
    myOutputs =  myModel.forward(inputs,labels) 
    myModel.feedback(0.05)
