import numpy as np

class BatchNorm1d():
    def __init__(self,inputSize,batchSize,epsilon,weightDecay,momentum):
        #self.weights = np.random.rand(inputSize)
        self.weights = np.random.rand(inputSize) * np.sqrt(2/inputSize)
        self.bias = np.random.rand(inputSize) 
        #for test pourpose only
        #self.weights = np.full((inputSize,inputSize), 0.5 , float)
        #self.bias = np.full((inputSize,inputSize), 0.5 , float)
        self.batchSize = batchSize
        self.inputSize = inputSize
        self.epsilon = epsilon
        #foward
        self.input = np.zeros((self.batchSize,self.inputSize),float)
        self.xout = np.zeros((self.batchSize,self.inputSize))
        self.output = np.zeros((self.batchSize,self.inputSize),float)
        #feedback
        self.dx = np.zeros((self.batchSize,self.inputSize),float)
        self.bt = np.zeros(inputSize)
        self.btBias = np.zeros(inputSize)
        self.weightDecay = weightDecay
        self.momentum = momentum

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
        self.avg = avg.copy()

        #variance calculation
         
        for j in range(self.inputSize):
            for k in range(self.batchSize):
                var[j] += (input[k][j] - avg[j])**2
            var[j] = var[j]/self.batchSize
        self.var = var.copy()

        #output normalized calculation
        for k in range(self.batchSize):           
            for j in range(self.inputSize):    
                output[k][j] = (input[k][j] - avg[j])/ np.sqrt(var[j] + self.epsilon)
        # the x^ is saved because is used to calculate the derivative over the weight is backward
        self.xout = output.copy()
        #weight and bias application
        for b in range(self.batchSize):
            for i in range(self.inputSize):
                output[b][i] = output[b][i]*self.weights[i]+ self.bias[i]
        self.output = output.copy()
    
    def feedback(self,input,lr):
        
        #dx
        output = np.zeros((self.batchSize,self.inputSize))
        
        #dy/dvar
        dvar = np.zeros(self.inputSize)
        for i in range(self.inputSize):
            for b in range(self.batchSize):
                dvar[i] += input[b][i]*(self.input[b][i] - self.avg[i])*(-self.weights[i]/2)*((self.var[i] + self.epsilon)**(-3/2))
        
        #dy/davg
        invDvar = np.zeros((self.inputSize))
        temp = np.zeros(self.inputSize)
        
        #first term
        for i in range(self.inputSize):
            for b in range(self.batchSize):
                invDvar[i] += input[b][i]*(-self.weights[i]/np.sqrt(self.var[i] + self.epsilon))
        
        #second term
        temp1 = np.zeros(self.inputSize)
        for i in range(self.inputSize): # sum over batch size
            for b in range(self.batchSize): # sum all difference betwen value and average of the same pizel in batch
                TEMP = (-2)*(self.input[b][i] - self.avg[i])
                temp1[i] += TEMP
            temp1[i] = (temp1[i]/self.batchSize)*dvar[i]
        
        davg = np.zeros(self.inputSize)
        #sum of 2 partial term
        davg = invDvar + temp1

        #final calc of dx
        for b in range(self.batchSize):
            for i in range(self.inputSize):
                self.dx[b][i] = (input[b][i]*self.weights[i]*(1/np.sqrt(self.var[i] + self.epsilon))) + dvar[i]*(2*(self.input[b][i] - self.avg[i]))*(1/self.batchSize) + davg[i]*(1/self.batchSize)
        #dw
        #computation of parameters update
        #the derivative of input over weight is equal to the previous x^ multiplied with the current input coming from next layer( previous following backward )
        dw = 0
        db = 0
        for i in range(self.inputSize):
            for b in range(self.batchSize):
                dw += self.xout[b][i]*input[b][i]
                db += input[b][i]
            dw = dw + self.weightDecay*self.weights[i]
            self.bt[i] = self.momentum*self.bt[i] + dw 
            dw = self.bt[i].copy()
            self.weights[i] =  self.weights[i] - lr[0]*dw 
            db = db + self.weightDecay*self.bias[i]
            self.btBias[i] = self.momentum*self.btBias[i] + db
            db = self.btBias[i].copy()
            self.bias[i] = self.bias[i] - lr[0]*db
            dw = 0
            db = 0
        #return the oytput for the previous layer ( next following the backward)
        #db

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