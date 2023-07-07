import numpy as np

class FCLayer():
    
    def __init__(self,inputSize,outputSize,batchSize,weightDecay,momentum):
        self.kernel = np.random.rand(inputSize,outputSize) * np.sqrt(2/inputSize)
        self.bias = np.random.rand(outputSize)
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.batchSize = batchSize
        #forward
        self.input = np.zeros((self.batchSize,self.inputSize))
        self.output =  np.zeros((self.batchSize,self.outputSize))
        #feedback
        self.dx = np.zeros((self.batchSize,self.inputSize))
        self.bt = np.zeros((inputSize,outputSize))
        self.btBias = np.zeros(outputSize)
        self.weightDecay = weightDecay
        self.momentum = momentum
    def forward (self,input):
        self.input = input.copy()
        #for k in range (self.batchSize):
            #for i in range(self.outputSize):
            #    for j in range(self.inputSize):
            #        self.output[k][i] += input[k][j]*self.kernel[j][i]  # kernel è scandito come j,i perche è moltiplicazione riga per colonna
            #    self.output[k][i] += self.bias[i] 
        #for b in range(self.batchSize):
        #    self.output[b] = np.matmul(input[b],self.kernel) + self.bias
        self.output = (self.input @ self.kernel) + self.bias
        
    def feedback(self,input,lr):
        
        output = np.zeros((self.batchSize,self.inputSize))
        dw = np.zeros((self.inputSize,self.outputSize))
        #dx. the derivative of input on the ouput shall be the transposed of the kernel
        #for b in range(self.batchSize):
        #    for i in range(self.inputSize):
        #        for j in range(self.outputSize):
        #            output[b] = input[b][i]*transpost[b][i]
        #output=np.matmul(input,np.transpose(self.kernel))
        #dw. the derivative of y over k11 ,k12 and k13 is x11,x21 and so on( the first number refer to batch size)
        ##for i in range(self.inputSize): # this input size is referred in forward, so now is the 
        #    for j in range(self.outputSize):
        #        for k in range(self.batchSize): # la derivata del kernel prima riga prima colonna è la somma di tutti i forward input di indice 1
        #            derivative += input[k][i]*self.input[k][j]
        #        self.kernel[i][j] -= self.lr*derivative 
        #dw = np.matmul(np.transpose(self.input),input)
        #  riguarda gli appunti per ricordarti come mai
        #update bias vaules. the derivative is 1
        '''dw = dw + self.weightDecay*self.kernel
        self.bt = self.momentum*self.bt + dw 
        dw = self.bt.copy()
        self.kernel = self.kernel - lr[0]*dw
        db = np.zeros(self.outputSize)
        for i in range(self.outputSize):
            for b in range(self.batchSize):
                db[i] += input[b][i]
        db = db + self.weightDecay*self.bias
        self.btBias = self.momentum*self.btBias + db
        db = self.btBias.copy()
        self.bias   = self.bias - lr[0]*db
        self.dx = output.copy()'''
        self.dx = input @ np.transpose(self.kernel)
        self.kernel -= lr * np.transpose(self.input) @ input
        self.bias   -= lr * np.sum(input, axis=0, keepdims=True)[0]

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