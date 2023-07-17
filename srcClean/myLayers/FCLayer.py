import numpy as np

class FCLayer():
    
    def __init__(self,inputSize,outputSize,batchSize,weightDecay,momentum):
        self.kernel = np.random.normal(0.0, 0.1,
                                        size=inputSize * outputSize)
        self.kernel = self.kernel.reshape(inputSize, outputSize)
        self.kernel = self.kernel.astype("float32")
        self.bias = np.zeros((1, outputSize)).astype("float32")
        self.inputSize = inputSize
        self.outputSize = outputSize
        self.batchSize = batchSize
        #forward
        self.input = np.zeros((self.batchSize,self.inputSize),dtype="float32")
        self.output =  np.zeros((self.batchSize,self.outputSize),dtype="float32")
        #feedback
        self.dx = np.zeros((self.batchSize,self.inputSize),dtype="float32")

    def forward (self,input):
        # salva input per feedback
        self.input = input
        self.output = (self.input @ self.kernel) + self.bias
        
    def feedback(self,input,lr):
        # calcola il valore di chain rule
        self.dx = input @ np.transpose(self.kernel)
        # applica modifiche ai weights e ai bias
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