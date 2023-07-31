import math
import numpy as np

class CrossEntropyLoss():
    def __init__(self,numberOfClasses,batchSize,epsilon) :
        self.nOfClasses = numberOfClasses
        self.batchSize = batchSize
        self.epsilon = epsilon
        # forward params
        self.p = np.zeros(0)
        #forward
        self.expected = np.zeros(numberOfClasses,dtype="float32")
        self.output = np.zeros(batchSize,dtype="float32")
        #self.softmax = np.zeros((self.batchSize,self.nOfClasses),dtype="float32")
        self.input = np.zeros((batchSize,numberOfClasses)) # input will be a matrix, each line are the value of probability for each class, this for each image in bathc
        #feedback
        self.dx = np.zeros((batchSize,numberOfClasses),dtype="float32")
        self.epsilon = 10 ** -3

    def forward(self, x, y) :
        self.p = np.clip(x, self.epsilon, 1.0 - self.epsilon)
        self.y = np.clip(y, self.epsilon, 1.0 - self.epsilon)
        return -(self.y * np.log(self.p) + (1-self.y) * np.log(1 - self.p))
        

    def feedback(self ):

        return  (self.p - self.y) / (self.p - self.p ** 2)
        

class SoftmaxLayer():

    def __init__(self) -> None:
        self.next_x = np.zeros(0)

    def forward(self, x: np.ndarray, train: bool = True) -> np.ndarray:
        self.output = np.exp(x) / np.sum(np.exp(x), axis=1, keepdims=True)
        return self.output

    def feedback(self, grad_input: np.ndarray) -> np.ndarray:
        return grad_input  # è vuoto perche nel feedback di cross entrpy loss ( p-t ) dovrebbe contenere anche il feedback del softmax layer come spiegato qua : https://www.pinecone.io/learn/cross-entropy-loss/

class CrossEntropyLoss2():

    def __init__(self):
        

        # forward params
        self.p = np.zeros(0)

    def forward(self, x: np.ndarray,y, train: bool = True) -> np.ndarray:
        self.y = y
        self.p = x
        return -(self.y * np.log(self.p) + (1-self.y) * np.log(1 - self.p))

    def backward(self) -> np.ndarray:
        layer_error = (self.p - self.y) / (self.p - self.p ** 2)
        return layer_error 

