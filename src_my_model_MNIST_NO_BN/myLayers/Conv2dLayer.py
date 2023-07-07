import numpy as np
class Conv2dLayer ():
    def __init__(self,inputSize,outputSize,batchSize,kernelSize,lr,nChannelIn,nChannelOut):

        self.kernel = np.random.uniform(low=0, high=1, size=((nChannelOut,nChannelIn,inputSize,inputSize)))
        self.bias =  np.random.uniform(low=0, high=1, size=((nChannelOut,nChannelIn,inputSize,inputSize)))
        self.nChannelIn = nChannelIn
        self.nChannelOut = nChannelOut
        self.batchSize = batchSize
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.kernelSize = kernelSize
        # calculate ration between input and output : if we want to reduce output value, we have to dont convolute each pixel
        self.step = inputSize / outputSize
        #forward
        self.input = np.zero(self.batchSize,self.nChannelIn,self.inputSize,self.inputSize)
        self.output = np.zero(self.batchSize,self.nChannelOut,self.outputSize,self.outputSize)
        #feedback
        self.dx = np.zero(self.batchSize,self.inputSize,self.inputSize)
        self.lr = lr
        
    def forward(self,input,isPadded):
        i=0
        self.input = input
        # Check if padding is applyed
        bound = self.inputSize - 1 # if no padding is applied, we cannot apply pixel convolution to border of matrix,
        if(isPadded):
            #paddinput = np.zero(self.batchSize,self.inputSize+2,self.inputSize+2)
            #make padding for all input in mini batch
            for i in range(self.batchSize):
                for j in range (self.nChannelIn):
                    input = pad_matrix(input[j][i])
                    bound = bound +1 # increase by one te limit 
        
        convRange = int((self.kernelSize - 1)/2)
        #iteration over all image in the batch ( default : 16)
        for b in range(self.batchSize):
            for y in range(self.nChannelOut): 
                temp = np.zeros(self.inputSize,self.inputSize)
                for x in range(self.nChannelIn) :
                    # 1 channel convolution. sum of all input channel to create 1 new output channel
                    temp += self.oneChannelConv(bound,convRange,b,y,x,input)
                #all input channel has been summed. saved as output channel
                self.output[b][y] = temp 

    def oneChannelConv(self,bound,convRange,Nbatch,nChannelout,nChannelIn,input):
        # execution of convolution of 1 channel input giving 1 channel out put
        output = np.zeros(self.inputSize,self.inputSize)
        for i in range(1,bound,self.step):
            j=0
            for j in range(1,bound,self.step):
                #Pass only the sub-matrix of input usefull to convolution calculation,not the full input
                output[i][j] = self.pixelConv(input[Nbatch][(i-convRange):(i+convRange+1) ,(j-convRange):(j+convRange + 1)],self.kernel[nChannelout][nChannelIn],self.kernelSize) 
                #output[i][j] -=biases[i - 1][j - 1]    

    def pixelConv(self,input,kernel,kernelSize):
        i=0
        sum = 0
        for i in range(kernelSize):
            j=0
            for j in range(kernelSize):
                sum += kernel[i][j]*input[i][j]
        return sum
    
    def pad_matrix(matrix, padding_size):
        # Get the original shape of the matrix
        original_shape = matrix.shape

        # Calculate the new shape with padding
        new_shape = (original_shape[0] + 2 * padding_size, original_shape[1] + 2 * padding_size)

        # Create a new matrix with the new shape, filled with zeros
        padded_matrix = np.zeros(new_shape)

        # Copy the original matrix into the padded matrix, leaving the padding area as zeros
        padded_matrix[padding_size:-padding_size, padding_size:-padding_size] = matrix

        return padded_matrix
    
    def feedback(self,input):
        dw = 0
        convRange = int((self.outputSize - 1)/2)
        #dw : convolution between forward input and feedback input 
        for i in range(1,self.inputSize-1):
            j=0
            for j in range(1,self.inputSize-1):
                #Pass only the sub-matrix of input usefull to convolution calculation,not the full input
                dw = self.pixelConv(self.input[(i-convRange):(i+convRange+1) ,(j-convRange):(j+convRange + 1)],input,self.outputSize) 
                #output[i][j] -=biases[i - 1][j - 1]
                self.kernel = self.kernel - self.lr*dw
        #dx : convolution between padded feedack input and kernel
        paddedInput = pad_matrix(input,1)
        convRange = int((self.kernelSize - 1)/2)
        self.dx = np.zeros(self.inputSize,self.inputSize)
        for i in range(1,(self.outputSize)): 
            j=0
            for j in range(1,(self.outputSize)): 
                #Pass only the sub-matrix of input usefull to convolution calculation,not the full input
                self.dx = self.pixelConv(paddedInput[(i-convRange):(i+convRange+1) ,(j-convRange):(j+convRange + 1)],self.kernel,self.kernelSize) 
                #output[i][j] -=biases[i - 1][j - 1]



        



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