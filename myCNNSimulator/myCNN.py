import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
#define
ChannelDim = [8,16,32]
featureDim = [32,16,8]
kernelSize = 3
nLayer = 3
nClasses = 10
# Here is the operation executed by the mac. 8 pixel*kernel are summed parallel and the sequentially summed for the whole kernel ( 3x3 or 5x5)
# Both kernel and image has a 3D shape
def MAC(feature,kernel):
    partialSum = 0
    for i in range(kernelSize):
        for j in range(kernelSize):
            partialSum = partialSum +feature[0][i][j]*kernel[0][i][j]+feature[1][i][j]*kernel[1][i][j]+feature[2][i][j]*kernel[2][i][j]+feature[3][i][j]*kernel[3][i][j]+feature[4][i][j]*kernel[4][i][j]+feature[5][i][j]*kernel[5][i][j]+feature[6][i][j]*kernel[6][i][j]+feature[7][i][j]*kernel[7][i][j]
    return partialSum
'''
# This convolution uses 1 different kernel for each pixel of the feature.
def Conv3dForward(featureIn,kernel,channelInDim,channelOutDim,featureDimIn,stride):
    #output feature
    featureOutDim = (featureDimIn//stride)
    featureOut = np.zeros((channelOutDim,featureOutDim,featureOutDim))
    for x in range(channelOutDim):
        for j in range(0,featureDimIn-2,stride):
            for k in range(0,featureDimIn-2,stride):
                for i in range(channelInDim//8):
                    featureOut[x][j//stride][k//stride] += MAC(featureIn[(i*8):((i+1)*8),j:(j+3),k:(k+3)],kernel[x,j//stride,k//stride,(i*8):((i+1)*8)])
    return featureOut
'''
def Conv3dForward(featureIn,kernel,channelInDim,channelOutDim,featureDimIn,stride):
    #output feature
    featureOutDim = (featureDimIn//stride)
    featureOut = np.zeros((channelOutDim,featureOutDim,featureOutDim))
    for i in range(channelOutDim):
        for j in range(featureOutDim):
            for k in range(featureOutDim):
                for l in range(channelInDim):
                    for m in range(0,featureDimIn-2,stride):
                        for n in range(0,featureDimIn-2,stride):
                            featureOut[i][j][k] += featureIn[l][(j-1)*stride+m][(k-1)*stride+n]*kernel[i][l][m][n]
    return featureOut

def Conv3dBackward(dy,x,kernel,nChannelOut,nChannelIn,kernelSize,featureInSize,featureOutSize,stride):
    
    dk = np.zeros((nChannelOut,nChannelIn,kernelSize,kernelSize))
    dx = np.zeros((nChannelIn,featureInSize,featureInSize))
    
    for i in range(nChannelOut):
        for j in range(nChannelIn):
            for k in range(kernelSize):
                for l in range(kernelSize):
                    for m in range(featureOutSize):
                        for n in range(featureOutSize):
                            dk[i][j][k][l] += dy[i][m][n] * x[j][(m-1)*stride + k][(n-1)*stride +l]
    for i in range(nChannelIn):
        for j in range(featureInSize):
            for k in range(featureInSize):
                for l in range(featureOutSize):
                    for m in range(kernelSize):
                        for n in range(featureOutSize):
                            for p in range(kernelSize):
                                for q in range(nChannelOut):
                                    if ((((l-1)*stride + m ) == j) and (((n-1)*stride + p) == k)):
                                        dx[i][j][k] += kernel[q][i][m][p] * dy[q][l][m]
    return dx,dk                            
    

def train(featureIn):
#featureIn has only 3 channel (RGB), We extend it in a 8 channel
    # channelOut  x (channelIn x kernelSize x kernelSize) <-- The parenthesis are done into MAC 
    kernelL1 = np.random.rand(16,8,3,3)
    kernelL2 = np.random.rand(32,16,3,3)
    kernelL3 = np.random.rand(64,32,3,3)
    fcLayer=FCLayer(64,10,1)
    trainLoader, testLoader = getLoader()
    for feature,labels in trainLoader:
        featureInExt = np.zeros((8,32,32))
        featureInExt[0:3] = feature.numpy()
    
        l1FeatureOut = Conv3dForward(featureInExt,kernelL1,8,16,32,2)
        l2FeatureOut = Conv3dForward(l1FeatureOut,kernelL2,16,32,16,2)
        l3FeatureOut = Conv3dForward(l2FeatureOut,kernelL3,32,64,8,2)
    
        l4FeatureMap = np.zeros((64))
        for i in range(64):
            l4FeatureMap[i] = np.average(l3FeatureOut[i])
        fcLayer.forward(l4FeatureMap)   
        #do cost
        #do feedback
         
    
def getLoader():
    transform = transforms.Compose([
    transforms.ToTensor(),             # Convert images to tensors
    transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))  # Normalize images
    ])
    train_dataset = torchvision.datasets.CIFAR10(root='./data', train=True, transform=transform, download=True)
    test_dataset = torchvision.datasets.CIFAR10(root='./data', train=False, transform=transform, download=True)
# Create DataLoader instances to load batches of data
    batch_size = 1
    train_loader = torch.utils.data.DataLoader(dataset=train_dataset, batch_size=batch_size, shuffle=True)
    test_loader = torch.utils.data.DataLoader(dataset=test_dataset, batch_size=batch_size, shuffle=False)
    return train_loader,test_loader

class FCLayer():
    
    def __init__(self,inputSize,outputSize,batchSize):
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
        self.bt = np.zeros((inputSize,outputSize),dtype="float32")
        self.btBias = np.zeros(outputSize,dtype="float32")

    def forward (self,input):

        self.input = input
        self.output = (self.input @ self.kernel) + self.bias
        
    def feedback(self,input,lr):
        
        trans = self.kernel.T
        self.dx = input @ trans
        self.kernel -= lr * np.transpose(self.input) @ input
        self.bias   -= lr * np.sum(input, axis=0, keepdims=True)[0]
           
if __name__ == '__main__':
    featureIn = np.random.rand(3,32,32)
    train(featureIn)
    a = 0