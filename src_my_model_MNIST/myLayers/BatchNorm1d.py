import numpy as np

class BatchNorm1d():
    def __init__(self,inputSize,batchSize,epsilon,weightDecay,momentum):
        self.weights = np.random.rand(inputSize) * np.sqrt(2/inputSize)
        self.weights = self.weights.astype("float32")
        self.mybias = np.random.rand(inputSize) 
        self.mybias = self.mybias.astype("float32")
        self.gamma = self.weights
        self.bias =  self.mybias
        #for test pourpose only
        #self.weights = np.full((inputSize,inputSize), 0.5 , float)
        #self.bias = np.full((inputSize,inputSize), 0.5 , float)
        self.batchSize = batchSize
        self.inputSize = inputSize
        self.epsilon = epsilon
        #self.running_mean_x = np.zeros(0)
        #self.running_var_x = np.zeros(0)
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

          # forward params
        self.var_x = np.zeros(0)
        self.stddev_x = np.zeros(0)
        self.x_minus_mean = np.zeros(0)
        self.standard_x = np.zeros(0)
        self.num_examples = 0
        self.mean_x = np.zeros(0)
        self.running_avg_gamma = 0.9

        # backward params
        self.gamma_grad = np.zeros(0)
        self.bias_grad = np.zeros(0)
    '''    
    def update_running_variables(self) -> None:
        is_mean_empty = np.array_equal(np.zeros(0), self.running_mean_x)
        is_var_empty = np.array_equal(np.zeros(0), self.running_var_x)
        if is_mean_empty != is_var_empty:
            raise ValueError("Mean and Var running averages should be "
                             "initilizaded at the same time")
        if is_mean_empty:
            self.running_mean_x = self.mean_x
            self.running_var_x = self.var_x
        else:
            gamma = self.running_avg_gamma
            self.running_mean_x = gamma * self.running_mean_x + \
                                  (1.0 - gamma) * self.mean_x
            self.running_var_x = gamma * self.running_var_x + \
                                 (1. - gamma) * self.var_x'''
    '''
    def forward(self, x: np.ndarray, train: bool = True) -> np.ndarray:
        self.num_examples = x.shape[0]
        if train:
            self.mean_x = np.mean(x, axis=0, keepdims=True)
            self.var_x = np.mean((x - self.mean_x) ** 2, axis=0, keepdims=True)
            self.update_running_variables()
        else:
            self.mean_x = self.running_mean_x.copy()
            self.var_x = self.running_var_x.copy()

        self.var_x += self.epsilon
        self.stddev_x = np.sqrt(self.var_x)
        self.x_minus_mean = x - self.mean_x
        self.standard_x = self.x_minus_mean / self.stddev_x
        self.output = self.weights * self.standard_x + self.bias
        '''
    
    def myforward (self,input):
        
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
        
    def myfeedback(self,input,lr):
        
        #dx
        self.chainIn = input
        #Dy/Davg
        #self.dvar = self.DyDvar()
        #self.chainIn[b][i]*(self.input[b][i] - self.avg[i])*(-self.weights[i]/2)*((self.var[i] + self.epsilon)**(-3/2))
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
            '''dw = dw + self.weightDecay*self.weights[i]
            self.bt[i] = self.momentum*self.bt[i] + dw 
            dw = self.bt[i].copy()'''
            self.weights[i] =  self.weights[i] - lr[0]*dw 
            '''db = db + self.weightDecay*self.bias[i]
            self.btBias[i] = self.momentum*self.btBias[i] + db
            db = self.btBias[i].copy()'''
            self.mybias[i] = self.mybias[i] - lr[0]*db
            dw = 0
            db = 0
        self.gamma = self.weights
        self.bias = self.mybias
        #return the oytput for the previous layer ( next following the backward)
        #db

    '''
    def backward(self, grad_input: np.ndarray,lr) -> np.ndarray:
        standard_grad = grad_input * self.weights

        var_grad = np.sum(standard_grad * self.x_minus_mean * -0.5 * self.var_x ** (-3/2),
                          axis=0, keepdims=True)
        stddev_inv = 1 / self.stddev_x
        aux_x_minus_mean = 2 * self.x_minus_mean / self.num_examples

        mean_grad = (np.sum(standard_grad * -stddev_inv, axis=0,
                            keepdims=True) +
                            var_grad * np.sum(-aux_x_minus_mean, axis=0,
                            keepdims=True))

        self.gamma_grad = np.sum(grad_input * self.standard_x, axis=0,
                                 keepdims=True)
        self.bias_grad = np.sum(grad_input, axis=0, keepdims=True)
        self.weights -= lr * np.transpose(self.gamma_grad[0])
        self.bias -= lr * np.transpose(self.bias_grad[0])
        return standard_grad * stddev_inv + var_grad * aux_x_minus_mean + \
               mean_grad / self.num_examples
    '''

    def scalarMatrixPerMatrix(self,matrix1,matrix2,matrixSize):
        output = np.zeros((matrixSize,matrixSize))
        for j in range(matrixSize):
            output[j] = np.inner(matrix1,matrix2)
        return output
    
    def scalarArrayPerMatrix(self,array,matrix,matrixDepth,arrayLenght):
        output = np.zeros((matrixDepth,arrayLenght))
        for j in range(matrixDepth):
            output[j] = np.inner(array,matrix[j])
        return output
    def sumMatrixAndArray(self,array,matrix,matrixDepth,arrayLenght):
        output = np.zeros((matrixDepth,arrayLenght))
        for j in range(matrixDepth):
            output[j] = array + matrix[j]
        return output

    def avgCalculation(self):
        avg = np.zeros(self.inputSize)
        for j in range(self.inputSize):
            for k in range(self.batchSize):
                avg[j] += self.input[k][j]
            avg[j] = avg[j]/self.batchSize
        return avg

    def varCalculation(self):
        var = np.zeros(self.inputSize)
        for j in range(self.inputSize):
            for k in range(self.batchSize):
                var[j] += (self.input[k][j] - self.avg[j])**2
            var[j] = var[j]/self.batchSize
        return var
    
    def BNCalc(self):
        output = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        #output normalized calculation
        for k in range(self.batchSize):           
            for j in range(self.inputSize):    
                output[k][j] = (self.input[k][j] - self.avg[j])/ np.sqrt(self.var[j] + self.epsilon)
        return output
    
    def WnBApplication(self):
        output = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        #weight and bias application
        for b in range(self.batchSize):
            for i in range(self.inputSize):
                output[b][i] = self.xout[b][i]*self.weights[i]+ self.mybias[i]
        return output
    
    def  DyDvar(self):
        #dy/dvar
        dvar = np.zeros(self.inputSize)
        for i in range(self.inputSize):
            for b in range(self.batchSize):
                dvar[i] += self.chainIn[b][i]*(self.input[b][i] - self.avg[i])*(-self.weights[i]/2)*((self.var[i] + self.epsilon)**(-3/2))
        return dvar
    
    def update_running_variables(self) -> None:
        is_mean_empty = np.array_equal(np.zeros(0), self.running_mean_x)
        is_var_empty = np.array_equal(np.zeros(0), self.running_var_x)
        if is_mean_empty != is_var_empty:
            raise ValueError("Mean and Var running averages should be "
                             "initilizaded at the same time")
        if is_mean_empty:
            self.running_mean_x = self.mean_x
            self.running_var_x = self.var_x
        else:
            gamma = self.running_avg_gamma
            self.running_mean_x = gamma * self.running_mean_x + \
                                  (1.0 - gamma) * self.mean_x
            self.running_var_x = gamma * self.running_var_x + \
                                 (1. - gamma) * self.var_x

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