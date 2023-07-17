import numpy as np

class BatchNorm1d():
    def __init__(self,inputSize,batchSize,epsilon,weightDecay,momentum):
        self.weights = np.random.rand(inputSize) * np.sqrt(2/inputSize)
        self.weights = self.weights.astype("float32")
        self.bias = np.random.rand(inputSize) 
        self.bias = self.bias.astype("float32")
        self.batchSize = batchSize
        self.inputSize = inputSize
        self.epsilon = epsilon
        self.input = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        self.xout = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        self.output = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        #feedback
        self.chainIn = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        self.chainOut = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        self.dx = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        self.bt = np.zeros(inputSize,dtype="float32")
        self.btBias = np.zeros(inputSize,dtype="float32")
        self.weightDecay = weightDecay
        self.momentum = momentum

          # forward params
        self.var_x = np.zeros(0)
        self.stddev_x = np.zeros(0)
        self.x_minus_mean = np.zeros(0)
        self.standard_x = np.zeros(0)
        self.num_examples = 0
        self.mean_x = np.zeros(0)
        self.running_avg_gamma = 0.9
    
    def forward (self,input):
        
        self.input = input

        #average calculation of each piel over the batch ( each pixel is average with same pixel in all image in batch)
        self.avg = np.mean(self.input, axis=0, keepdims=True)[0]
            
        #variance calculation
        self.var = np.mean((self.input - self.avg) ** 2, axis=0, keepdims=True)[0]
        
        #Batch normalization calculation
        self.xout =  (self.input - self.avg)/ np.sqrt((self.var + self.epsilon),dtype="float32")
        
        #Weight and biases application
        self.output = self.weights * self.xout + self.bias
        
    def feedback(self,chainIn,lr):
        
        #dx
        self.chainIn = chainIn
        #Dy/Davg
        standard_grad = self.chainIn * self.weights
        self.dvar = np.sum(standard_grad * (self.input -self.avg)  * -0.5 * (self.var + self.epsilon) ** (-3/2),
                          axis=0, keepdims=True)[0]
        #dy/Davg
        self.stddevInv = 1/np.sqrt(self.var + self.epsilon ,dtype="float32")
        self.auxXMinusMean = (2)*(self.input - self.avg)/(self.batchSize)
        self.davg = (np.sum(standard_grad *  -self.stddevInv, axis=0,
                            keepdims=True) +
                            self.dvar * np.sum(-self.auxXMinusMean , axis=0,
                            keepdims=True))[0]
        #final calc of dx  
        self.dx = (standard_grad*self.stddevInv) + self.dvar*self.auxXMinusMean + self.davg*(1/self.batchSize)
        #parameters update
        self.gamma_grad = np.sum(self.chainIn * self.xout, axis=0,
                                 keepdims=True)
        self.bias_grad = np.sum(self.chainIn, axis=0, keepdims=True)
    
if __name__ == '__main__':
    input = np.array([[
            [1,1,1,1,1],
            [1,1,1,1,1],
            [1,1,1,1,1],
            [1,1,1,1,1],
            [1,1,1,1,1]],
            [[2,2,2,2,2],
            [2,2,2,2,2],
            [2,2,2,2,2],
            [2,2,2,2,2],
            [2,2,2,2,2]],
            [[3,3,3,3,3],
            [3,3,3,3,3],
            [3,3,3,3,3],
            [3,3,3,3,3],
            [3,3,3,3,3]]])
            
    fcLayer = BatchNorm(5,3)
    output = fcLayer.forward(input,0.1)
    print(output)
    # test passsed