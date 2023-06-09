import numpy as np
class Conv2dLayer ():
    def __init__(self,inputSize,outputSize,batchSize):

        self.kernel = np.random.uniform(low=0, high=1, size=((batchSize,inputSize,inputSize)))
        self.bias =  np.random.uniform(low=0, high=1, size=((batchSize,inputSize,inputSize)))
        self.batchSize = batchSize
        self.inputSize = inputSize
        self.outputSize = outputSize

    def forward(self,input,inputSize,isPadded):
        i=0
        outputSize = inputSize
        kernelSize = 3
        convRange = int((kernelSize - 1)/2)
        output = np.zeros((outputSize, outputSize))    
        for i in range(1,inputSize-1):
            j=0
            for j in range(1,inputSize-1):
                #Pass only the sub-matrix of input usefull to convolution calculation,not the full input
                output[i][j] = self.pixelConv(input[(i-convRange):(i+convRange+1) ,(j-convRange):(j+convRange + 1)],self.kernel,kernelSize) 
                #output[i][j] -=biases[i - 1][j - 1]
        return output
    
    def pixelConv(input,kernel,kernelSize):
        i=0
        sum = 0
        for i in range(kernelSize):
            j=0
            for j in range(kernelSize):
                sum += kernel[i][j]*input[i][j]
        return sum
        
if __name__ == '__main__':
    input = np.array([
            [3,3,2,1,0],
            [0,0,1,3,1],
            [3,1,2,2,3],
            [2,0,0,2,2],
            [2,0,0,0,1]])
    conv1 = Conv2dLayer()
    output = conv1.forward(input,5,False)
    print(output)

    # test passed