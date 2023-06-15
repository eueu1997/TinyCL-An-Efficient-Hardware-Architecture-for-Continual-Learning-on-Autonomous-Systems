import numpy as np

class FCLayer():
    
    def __init__(self,inputSize,outputSize,batchSize,lr):
        #self.kernel = np.random.uniform(low=0, high=1, size=((batchSize,inputSize,outputSize)))
        self.kernel = np.full((inputSize,outputSize), 0.5 , float) # il kernel e i bias non cambiano per i batch
        self.bias = np.full((outputSize), 0.5 , float)
        self.lr = lr
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.batchSize = batchSize
    
    def forward (self,input):
        output = np.zeros((self.batchSize,self.outputSize))
        self.input = input
        for k in range (self.batchSize):
            for i in range(self.outputSize):
                for j in range(self.inputSize):
                    output[k][i] += input[k][j]*self.kernel[j][i]  # kernel è scandito come j,i perche è moltiplicazione riga per colonna
                output[k][i] += self.bias[i] 

        return output
    def feedback(self,input):
        
        output = np.zeros((self.batchSize,self.inputSize))
        derivative = 0
        #update chain rule. the derivative of input on the ouput shall be the transposed of the kernel
        transpost = np.transpose(self.kernel)
        for i in range(self.batchSize):
            output[i] = np.matmul(input[i],transpost)
        #update parameters. the derivative of y over k11 ,k12 and k13 is x11,x21 and so on( the first number refer to batch size)
        for i in range(self.inputSize): # this input size is referred in forward, so now is the 
            for j in range(self.outputSize):
                for k in range(self.batchSize): # la derivata del kernel prima riga prima colonna è la somma di tutti i forward input di indice 1
                    derivative += input[k][i]*self.input[k][j]
                self.kernel[i][j] -= self.lr*derivative 
        #  riguarda gli appunti per ricordarti come mai
        #update bias vaules. the derivative is 1

        return output

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