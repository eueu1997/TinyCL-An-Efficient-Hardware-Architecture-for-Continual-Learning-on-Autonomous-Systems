import numpy as np

class FCLayer():
    
    def __init__(self,inputSize,outputSize,batchSize):

        #self.kernel = np.random.uniform(low=0, high=1, size=((batchSize,inputSize,outputSize)))
        self.kernel = np.full((inputSize,outputSize), 0.5 , float) # il kernel e i bias non cambiano per i batch
        self.bias = np.full((outputSize), 0.5 , float)
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.batchSize = batchSize
        #forward
        self.input = np.zeros((self.batchSize,self.inputSize))
        self.output =  np.zeros((self.batchSize,self.outputSize))
        #feedback
        self.dx = np.zeros((self.batchSize,self.inputSize))
    def forward (self,input):
        self.input = input
        #for k in range (self.batchSize):
            #for i in range(self.outputSize):
            #    for j in range(self.inputSize):
            #        self.output[k][i] += input[k][j]*self.kernel[j][i]  # kernel è scandito come j,i perche è moltiplicazione riga per colonna
            #    self.output[k][i] += self.bias[i] 
        self.output = np.matmul(input,self.kernel) + self.bias

        
    def feedback(self,input,lr):
        
        output = np.zeros((self.batchSize,self.inputSize))
        dw = np.zeros((self.inputSize,self.outputSize))
        derivative = 0
        #dx. the derivative of input on the ouput shall be the transposed of the kernel
        transpost = np.transpose(self.kernel)
        #for b in range(self.batchSize):
        #    for i in range(self.inputSize):
        #        for j in range(self.outputSize):
        #            output[b] = input[b][i]*transpost[b][i]
        output=np.matmul(input,transpost)
        #dw. the derivative of y over k11 ,k12 and k13 is x11,x21 and so on( the first number refer to batch size)
        ##for i in range(self.inputSize): # this input size is referred in forward, so now is the 
        #    for j in range(self.outputSize):
        #        for k in range(self.batchSize): # la derivata del kernel prima riga prima colonna è la somma di tutti i forward input di indice 1
        #            derivative += input[k][i]*self.input[k][j]
        #        self.kernel[i][j] -= self.lr*derivative 
        dw = np.matmul(np.transpose(self.input),input)
        #  riguarda gli appunti per ricordarti come mai
        #update bias vaules. the derivative is 1
        self.kernel = self.kernel - lr*dw
        self.bias   = self.bias - lr*input
        self.dx = output

if __name__ == '__main__':
    input = np.array([[3,3,2,1,0,5,2,7,5,9],[3,3,2,1,0,5,2,7,5,9],[3,3,2,1,0,5,2,7,5,9]])
    
    inputSize = 10
    outputSize = 10
    batchSize = 3
    fcLayer = FCLayer(inputSize,outputSize,batchSize)
    output = fcLayer.forward(input)
    output = fcLayer.feedback(input)
    print(output)
    # test passsed