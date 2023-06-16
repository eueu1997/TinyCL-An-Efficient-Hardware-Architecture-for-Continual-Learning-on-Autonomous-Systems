import numpy as np

class BatchNorm1d():
    def __init__(self,inputSize,batchSize,lr,epsilon):
        self.weights = np.random.uniform(low=0, high=1, size=((inputSize)))
        self.bias =  np.random.uniform(low=0, high=1, size=((inputSize)))
        #for test pourpose only
        #self.weights = np.full((inputSize,inputSize), 0.5 , float)
        #self.bias = np.full((inputSize,inputSize), 0.5 , float)
        self.lr = lr
        self.batchSize = batchSize
        self.inputSize = inputSize
        self.epsilon = epsilon
        #foward
        self.input = np.zeros((self.batchSize,self.inputSize),float)
        self.output = np.zeros((self.batchSize,self.inputSize),float)
        #feedback
        self.dx = np.zeros((self.batchSize,self.inputSize),float)
    def forward (self,input):
        
        self.input = input
        avg = np.zeros((self.inputSize))
        var = np.zeros((self.inputSize))
        output = np.zeros((self.batchSize,self.inputSize),float)
        #average calculation of each piel over the batch ( each pixel is average with same pixel in all image in batch)
        
        for j in range(self.inputSize):
            for k in range(self.batchSize):
                avg[j] += input[k][j]
            avg[j] = avg[j]/self.batchSize
        self.avg = avg

        #variance calculation
         
        for j in range(self.inputSize):
            for k in range(self.batchSize):
                var[j] += (input[k][j] - avg[j])**2
            var[j] = var[j]/self.batchSize
        self.var = var

        #output normalized calculation
        for k in range(self.batchSize):
            
            for j in range(self.inputSize):    
                output[k][j] = (input[k][j] - avg[j])/ np.sqrt(var[j] + self.epsilon)
        # the x^ is saved because is used to calculate the derivative over the weight is backward
        self.output = output
        #weight and bias application
        output = np.dot(output,self.weights) + self.bias
        return output
    
    def feedback(self,input):
        
       
        output = np.zeros((self.batchSize,self.inputSize,self.inputSize),float)
        #dy/dvar
        temp = (self.input - self.avg)(-self.weights/2)(self.var**2 + self.epsilon)**(-3/2)
        #dy/davg
        # TODO
        #output computation of chain
        output = np.matmul(self.weights,((1/self.var - self.epsilon) # dy/dxi
                                         +(1/self.batchSize)        #dy/d(avg)
                                        +((2*self.input - self.avg)*(1/self.batchSize)) )) #dy/d(var)
        
        #computation of parameters update
        #the derivative of input over weight is equal to the previous x^ multiplied with the current input coming from next layer( previous following backward )
        self.weights = self.weight - self.lr* np.matmul(self.output,input) 

        #return the oytput for the previous layer ( next following the backward)
        self.dx = output
        

    
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