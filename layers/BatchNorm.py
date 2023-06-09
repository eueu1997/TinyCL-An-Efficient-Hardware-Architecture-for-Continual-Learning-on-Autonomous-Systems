import numpy as np

class BatchNorm():
    def __init__(self,inputSize,batchSize,lr):
        #self.weights = np.random.uniform(low=0, high=1, size=((inputSize,inputSize)))
        #self.bias =  np.random.uniform(low=0, high=1, size=((inputSize,inputSize)))
        self.weights = np.full((inputSize,inputSize), 0.5 , float)
        self.bias = np.full((inputSize,inputSize), 0.5 , float)
        self.lr = lr
        self.batchSize = batchSize
        self.inputSize = inputSize
    def forward (self,input,epsilon):
        
        self.input = input
        avg = np.zeros((self.inputSize,self.inputSize))
        var = np.zeros((self.inputSize,self.inputSize))
        output = np.zeros((self.batchSize,self.inputSize,self.inputSize),float)
        self.epsilon = epsilon
        #average calculation of each piel over the batch ( each pixel is average with same pixel in all image in batch)
        for i in range(self.inputSize):
            for j in range(self.inputSize):
                for k in range(self.batchSize):
                    avg[i][j] += input[k][i][j]
                avg[i][j] = avg[i][j]/self.batchSize
        self.avg = avg
        #variance calculation
        for i in range(self.inputSize):
            for j in range(self.inputSize):
                for k in range(self.batchSize):
                    var[i][j] += (input[k][i][j] - avg[i][j])**2
                var[i][j] = var[i][j]/self.batchSize
        self.var = var
        #output normalized calculation
        for k in range(self.batchSize):
            for i in range(self.inputSize):
                for j in range(self.inputSize):    
                    output[k][i][j] = (input[k][i][j] - avg[i][j])/ np.sqrt(var[i][j] + self.epsilon)
        #weight and bias application
        output = np.dot(output,self.weights) + self.bias
        self.output = output
        return output
    
    def feedback(self,input):
        
       
        output = np.zeros((self.batchSize,self.inputSize,self.inputSize),float)
        
        #output computation of chain
        output = np.matmul(self.weights,((1/self.var - self.epsilon) # dy/dxi
                                         +(1/self.batchSize)        #dy/d(avg)
                                        +((2*self.input - self.avg)*(1/self.batchSize)) )) #dy/d(var)
        
        #computation of parameters update
        #the derivative of input over weight is equal to the previous output multiplied with the current input coming from next layer( previous following backward )
        self.weights = self.weight - self.lr* np.matmul(self.output,input) 

        #return the oytput for the previous layer ( next following the backward)
        return output
        

    
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