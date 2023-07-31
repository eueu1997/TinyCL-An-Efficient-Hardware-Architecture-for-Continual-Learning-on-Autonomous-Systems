from .FCLayer import FCLayer
from .BatchNorm1d import BatchNorm1d
from .ReLU import ReLU1d 
import numpy as np
from .CrossEntropyLoss import CrossEntropyLoss,CrossEntropyLoss2
from .CrossEntropyLoss import SoftmaxLayer
import math
from tqdm import tqdm
class MLPOnMIST():

    def __init__(self,inputDataSize):
 
        self.inputData = int(inputDataSize)
        self.inputSize = int(self.inputData*self.inputData)
        self.nClasses  = 10
        self.batchSize = 60
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
        output.append(self.crossEntropy.forward(output[7],labels))
        return  output
    
    def evaluate_model(self, test_x: np.ndarray, 
                       test_y: np.ndarray,num_examples) :
        """Returns loss and accuracy in the test set"""

       
        for index_batch in range(0, num_examples, self.batchSize):
            
            mini_batch_x = test_x[index_batch: index_batch + self.batchSize]
            mini_batch_y = test_y[index_batch: index_batch + self.batchSize]
            if(mini_batch_x.shape[0] == self.batchSize):
                temp = self.forward(mini_batch_x,mini_batch_y)
                loss = temp[8]
                output = temp[7]
                y_pred_labels = np.argmax(output, axis=1)
                y_labels = np.argmax(mini_batch_y, axis=1)
                if(index_batch == 0):
                    accuracy =  np.sum(y_labels == y_pred_labels) / mini_batch_x.shape[0]
                else:
                    accuracy = (accuracy + np.sum(y_labels == y_pred_labels) / mini_batch_x.shape[0])/2
        return float(np.mean(loss)), accuracy

    def fit(self, x_train: np.ndarray, y_train: np.ndarray,
            learning_rate: float, steps: int,
            batch_size: int, x_test: np.ndarray,
            y_test: np.ndarray) -> np.array:
        num_examples = x_train.shape[0]
        num_batches = math.ceil(num_examples/batch_size)
        metrics = np.zeros((steps//num_batches, 2))  # loss, accuracy
        random_index = np.linspace(0, num_examples-1, num_examples).astype(int)
        for epoch in tqdm(range(steps//num_batches)):
            np.random.shuffle(random_index)
            x_train = x_train[random_index]
            y_train = y_train[random_index]
            for index_batch in range(0, num_examples, batch_size):
                mini_batch_x = x_train[index_batch: index_batch + batch_size]
                mini_batch_y = y_train[index_batch: index_batch + batch_size]
                y_pred = self.forward(mini_batch_x,mini_batch_y)
                self.feedback(learning_rate)
               
            loss, accuracy = self.evaluate_model(x_test, y_test,num_examples)
            metrics[epoch, :] = loss, accuracy
        

        return metrics
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