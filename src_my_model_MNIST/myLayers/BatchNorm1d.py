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
        #foward
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

    def forward (self,input):
        
        self.input = input

        #average calculation of each piel over the batch ( each pixel is average with same pixel in all image in batch)
        self.avg = np.mean(self.input, axis=0, keepdims=True)[0]
            
        #variance calculation
        self.var = np.mean((self.input - self.avg) ** 2, axis=0, keepdims=True)[0]
        
        #Batch normalization calculation
        self.xout =  (self.input - self.avg)/ np.sqrt((self.var + self.epsilon),dtype="float32")
        self.xout = self.xout.astype("float32")
        
        #Weight and biases application
        self.output = self.weights * self.xout + self.bias
        
    def feedback(self,input,lr):
        
        #dx
        self.chainIn = input
        #Dy/Davg

        standard_grad = self.chainIn * self.weights
        self.dvar = np.sum(standard_grad * (self.input -self.avg)  * -0.5 * (self.var + self.epsilon) ** (-3/2),
                          axis=0, keepdims=True)[0]
        
        #sum of 2 partial term
        #self.davg = invDvar + temp1
        self.stddevInv = 1/np.sqrt(self.var + self.epsilon ,dtype="float32")
        self.auxXMinusMean = (2)*(self.input - self.avg)/(self.batchSize)
        self.davg = (np.sum(standard_grad *  -self.stddevInv, axis=0,
                            keepdims=True) +
                            self.dvar * np.sum(-self.auxXMinusMean , axis=0,
                            keepdims=True))[0]
        #final calc of dx
          
        self.dx = (standard_grad*self.stddevInv) + self.dvar*self.auxXMinusMean + self.davg*(1/self.batchSize)

        #dw
        #computation of parameters update
        #the derivative of input over weight is equal to the previous x^ multiplied with the current input coming from next layer( previous following backward )
        dw = 0
        db = 0
        for i in range(self.inputSize):
            for b in range(self.batchSize):
                dw += self.xout[b][i]*input[b][i]
                db += input[b][i]
            self.weights[i] =  self.weights[i] - lr*dw
            self.bias[i] = self.bias[i] - lr*db
            dw = 0
            db = 0



'''
    def forward(self, x: np.ndarray, train: bool = True) -> np.ndarray:
        self.num_examples = x.shape[0]
        if train:
            self.mean_x = np.mean(x, axis=0, keepdims=True)
            self.var_x = np.mean((x - self.mean_x) ** 2, axis=0, keepdims=True)
            #self.update_running_variables()
        else:
            self.mean_x = self.running_mean_x.copy()
            self.var_x = self.running_var_x.copy()

        self.var_x += self.epsilon
        self.stddev_x = np.sqrt(self.var_x)
        self.x_minus_mean = x - self.mean_x
        self.standard_x = self.x_minus_mean / self.stddev_x
        return self.gamma * self.standard_x + self.bias

    def backward(self, grad_input: np.ndarray) -> np.ndarray:
        standard_grad = grad_input * self.gamma

        self.var_grad = np.sum(standard_grad * self.x_minus_mean * -0.5 * self.var_x ** (-3/2),
                          axis=0, keepdims=True)
        self.stddev_inv = 1 / self.stddev_x
        self.aux_x_minus_mean = 2 * self.x_minus_mean / self.num_examples

        self.mean_grad = (np.sum(standard_grad * -self.stddev_inv, axis=0,
                            keepdims=True) +
                            self.var_grad * np.sum(-self.aux_x_minus_mean, axis=0,
                            keepdims=True))

        self.gamma_grad = np.sum(grad_input * self.standard_x, axis=0,
                                 keepdims=True)
        self.bias_grad = np.sum(grad_input, axis=0, keepdims=True)

        return standard_grad * self.stddev_inv + self.var_grad * self.aux_x_minus_mean + \
               self.mean_grad / self.num_examples
'''   
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