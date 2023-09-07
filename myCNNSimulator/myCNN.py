import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
import time
#define
ChannelDim = [8,16,32]
featureDim = [32,16,8]
kernelSize = 3
nLayer = 3
nClasses = 10
reluActive = 1
# Here is the operation executed by the mac. 8 pixel*kernel are summed parallel and the sequentially summed for the whole kernel ( 3x3 or 5x5)
# Both kernel and image has a 3D shape
def MAC(feature,kernel):
    partialSum = 0
    partialSum = np.sum(feature*kernel,(0,1,2))
    '''
    for c in range(0,len(feature),8):
        partialSum = partialSum +feature[c+0]*kernel[c+0]+feature[c+1]*kernel[c+1]+feature[c+2]*kernel[c+2]+feature[c+3]*kernel[c+3]+feature[c+4]*kernel[c+4]+feature[c+5]*kernel[c+5]+feature[c+6]*kernel[c+6]+feature[c+7]*kernel[c+7]

    nSTep dovrebbe essere il numero di ovlte che viene eseguuito il ciclo. si puo fare se trasformiamo feature e kernel in due vettori 1D.
    dobbiamo passare a una concezione 1D cosi da rendere il MAC piu generale e utilizzabile anche in back
    for c in range(0,channelInDim,8):
        for i in range(kernelSize):
            for j in range(kernelSize):
                partialSum = partialSum +feature[c+0][i][j]*kernel[c+0][i][j]+feature[c+1][i][j]*kernel[c+1][i][j]+feature[c+2][i][j]*kernel[c+2][i][j]+feature[c+3][i][j]*kernel[c+3][i][j]+feature[c+4][i][j]*kernel[c+4][i][j]+feature[c+5][i][j]*kernel[c+5][i][j]+feature[c+6][i][j]*kernel[c+6][i][j]+feature[c+7][i][j]*kernel[c+7][i][j]
    print(partialSum-partialSum2)'''
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
def rotateMatrix(mat):
 
    # Simply print from
    # last cell to first cell.
    
    
    if mat.shape == (1,1):
        out  = [[0,0],[0,0]]
        out[0][0]=0
        out[1][0]=0
        out[0][1]=0
        out[1][1]=mat[0][0]   
        return out 
    elif mat.shape == (2,2):
        out  = [[0,0],[0,0]]
        out[0][0]=mat[1][1]
        out[1][0]=mat[0][1]
        out[0][1]=mat[1][0]
        out[1][1]=mat[0][0]
        return out
    elif mat.shape == (1,2):
        out  = [[0,0],[0,0]]
        out[1][0]= mat[0][1]
        out[1][1]= mat[0][0]
        out[0][0]= 0
        out[0][1]= 0
        return out
    else:
        out  = [[0,0],[0,0]]
        out[0][1]=mat[1][0]
        out[1][1]=mat[0][0]
        out[0][0] = 0
        out[1][0] = 0
        return out
class Conv3D():
    
    def __init__(self,channelInDim,featureInDim,channelOutDim,stride,kernelSize):
        self.kernel = (np.random.rand(channelOutDim,channelInDim,kernelSize,kernelSize)*2)-1
        self.channelInDim = channelInDim
        self.featureInDim = featureInDim
        self.channelOutDim = channelOutDim
        self.featureOutDim = (featureInDim//stride)
        self.stride = stride
        self.kernelSize = kernelSize

    def Conv3dForward(self,featureIn):
    #output feature
        featureOut = np.zeros((self.channelOutDim,self.featureOutDim,self.featureOutDim))
        self.featureIn = np.pad(featureIn, ((0,0), (1, 1), (1, 1)), mode='constant', constant_values=0)
        for i in range(self.channelOutDim):
            for j in range(self.featureOutDim):
                for k in range(self.featureOutDim):
                    subFeatureIn = self.featureIn[:,int(j*self.stride):int(j*self.stride+self.kernelSize),int(k*self.stride):int(k*self.stride+self.kernelSize)]
                    #featureOut[i][j][k] = MAC(np.flatten(subFeatureIn),np.flatten(self.kernel[i]))
                    featureOut[i][j][k] = np.sum(subFeatureIn*self.kernel[i],(0,1,2))
        return featureOut

    def Conv3dBackward(self,dy):
        dk = np.zeros((self.channelOutDim,self.channelInDim,self.kernelSize,self.kernelSize))
        dx = np.zeros((self.channelInDim,self.featureInDim+1,self.featureInDim+1))
        dx1 = np.zeros((self.channelInDim,self.featureInDim+1,self.featureInDim+1))

        for i in range(self.channelOutDim):
            for j in range(self.channelInDim):
                for k in range(self.kernelSize):
                    for l in range(self.kernelSize):
                        subFeatureIn = self.featureIn[j,k:(self.featureOutDim*self.stride+k):self.stride,l:(self.featureOutDim*self.stride+l):self.stride]
                        #dk[i][j][k][l] = MAC(np.flatten(dy[i]),np.flatten(subFeatureIn))
                        dk[i][j][k][l] = np.sum(dy[i]*subFeatureIn,(0,1))
        '''                         
        for i in range(self.channelInDim):
            for l in range(self.featureOutDim):
                for m in range(self.kernelSize):
                    for n in range(self.featureOutDim):
                        for p in range(self.kernelSize):
                            for q in range(self.channelOutDim):
                                dx[i][((l)*self.stride + m )][((n)*self.stride + p)] += self.kernel[q][i][m][p] * dy[q][l][n]  '''
        dy = np.pad(dy, ((0,0), (1,0), (1,0)), mode='constant', constant_values=0)
        for i in range(self.channelInDim):
            for q in range(self.channelOutDim):
                for j in range(self.featureInDim):
                    for k in range(self.featureInDim):                   
                        #temp = dy[q,int(j/self.stride):int(j/self.stride)+(int(self.kernelSize/self.stride)+1),int(k/self.stride):int(k/self.stride)+(int(self.kernelSize/self.stride)+1)]
                        #temp1 = rotateMatrix(self.kernel[q,i,(j%self.stride):self.kernelSize:self.stride,(k%self.stride):self.kernelSize:self.stride])
                        #temp2= np.sum( temp1* temp,(0,1))
                        dx1[i][j][k]  += np.sum( rotateMatrix(self.kernel[q,i,(j%self.stride):self.kernelSize:self.stride,(k%self.stride):self.kernelSize:self.stride])* dy[q,int(j/self.stride):int(j/self.stride)+(int(self.kernelSize/self.stride)+1),int(k/self.stride):int(k/self.stride)+(int(self.kernelSize/self.stride)+1)],(0,1))
        #diff = dx1-dx
        #print (dx1 - dx)
        self.kernel -= dk*0.005
        return dx[:,0:-1,0:-1]                       
    

def train():
#featureIn has only 3 channel (RGB), We extend it in a 8 channel
    # channelOut  x (channelIn x kernelSize x kernelSize) <-- The parenthesis are done into MAC 
    conv3d1 = Conv3D(8,32,16,2,3) # 8x32x32 -> 16x16x16
    relu1 = ReLU(16,16) # 16x16x16 -> 16x16x16 
    conv3d2 = Conv3D(16,16,32,2,3) # 16x16x16 -> 32x8x8
    relu2 = ReLU(32,8) #32x8x8 -> 32x8x8
    soft1 = SoftmaxLayer(8*8*32,10) # 32x8x8 -> 10
    '''
    conv3d2 = Conv3D(16,16,32,2,3) # 16x16x16 -> 32x8x8
    relu2 = ReLU(32,8)
    conv3d3 = Conv3D(32,8,64,2,3)
    relu3 = ReLU(64,8)
    fcLayer=FCLayer(64,10,1)'''
    trainLoader, testLoader = getLoader()
    cycleCount = 0
    accuracy = 0
    for feature,labels in trainLoader:
        featureInExt = np.zeros((8,32,32))
        featureInExt[0:3] = feature.numpy()
        
        l1FeatureOut = conv3d1.Conv3dForward(featureInExt)
        l1FeatureOutAct = relu1.reluForward(l1FeatureOut)
        l2FeatureOut = conv3d2.Conv3dForward(l1FeatureOutAct)
        l2FeatureOutAct = relu2.reluForward(l2FeatureOut)
        l5Output = soft1.forward_prop(l2FeatureOutAct)
        '''
        l1FeatureOutAct = relu1.reluForward(l1FeatureOut)
        l2FeatureOut = conv3d2.Conv3dForward(l1FeatureOutAct)
        l2FeatureOutAct = relu2.reluForward(l2FeatureOut)
        l3FeatureOut = conv3d3.Conv3dForward(l2FeatureOutAct)
        l3FeatureOutAct = relu3.reluForward(l3FeatureOut)
        l4FeatureMap = np.zeros((64))
        #average 
        for i in range(64):
            l4FeatureMap[i] = np.average(l3FeatureOutAct[i])
        l5Output = fcLayer.forward(l4FeatureMap)   
        '''
        #cost calc
        cost = lossForward(l5Output,convOneHot(labels))
        accuracy += 1 if np.argmax(l5Output) == labels else 0
        cycleCount += 1
        if(cycleCount%100 == 0):
            print(f"Train accuracy{accuracy/cycleCount}at cycle {cycleCount}")
        dx = lossBackward(l5Output,convOneHot(labels))
        
        '''
        dx = fcLayer.feedback(dx,0.0001)
        #feedback average. divide by 4*4=16 ( is the shape of the input ). during averaging each value has been multiplied by 1/16. the value is then increase from 64x1 to 64x4x4
        dx = dx/16
        temp = np.ones((64,4,4))
        dx= np.transpose(dx)
        for i in range (64):
            temp[i] = temp[i]*dx[i] 
        dx = temp
        dx = relu3.reluBackward(dx)
        dx= conv3d3.Conv3dBackward(dx)
        dx = relu2.reluBackward(dx)
        dx= conv3d2.Conv3dBackward(dx)
        dx = relu1.reluBackward(dx)
        '''
        dx = soft1.back_prop(dx,0.005)
        dx = relu2.reluBackward(dx)
        dx= conv3d2.Conv3dBackward(dx)
        dx = relu1.reluBackward(dx)
        dx= conv3d1.Conv3dBackward(dx)
    print(f"Train accuracy{accuracy/cycleCount}")
    cycleCount = 0
    accuracy = 0
    for feature,labels in testLoader:     
        featureInExt = np.zeros((8,32,32))
        featureInExt[0:3] = feature.numpy()
        
        l1FeatureOut = conv3d1.Conv3dForward(featureInExt)
        l5Output = soft1.forward_prop(l1FeatureOut)
        
        accuracy += 1 if np.argmax(l5Output) == labels else 0
        cycleCount += 1
        if(cycleCount%100 == 0):
            print(f"test accuracy{accuracy/cycleCount} at cycle {cycleCount}")
    print(f"Test accuracy{accuracy/cycleCount}")
def convOneHot(input):
    out = np.zeros(10)
    out[int(input.numpy())] = 1
    return out
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
        return self.output
        
    def feedback(self,input,lr):
        
        trans = self.kernel.T
        self.dx = input @ trans
        self.kernel -= lr * np.reshape(self.input,(64,1)) @ input
        self.bias   -= lr * np.sum(input, axis=0, keepdims=True)[0]
        return self.dx
       

def lossForward(x,labels):
    #return -(labels * np.log(x) + (1-labels) * np.log(1 - x) )
    return -(labels * np.log(x) )

def lossBackward(x,labels):
    #return ((x - labels) )
    return -(((1/x)*labels) )
    
class ReLU():
    def __init__(self,channelInDim,featureInDim) -> None:
        self.channelInDim = channelInDim
        self.featureInDim = featureInDim
        self.featureIn = np.zeros((self.channelInDim,self.featureInDim,self.featureInDim))
    def reluForward(self,x):
        self.featureIn = x
        self.featureOut = x
        if(reluActive == 1):
            self.featureOut[self.featureIn < 0.0] = 0.0
        return  self.featureOut

    def reluBackward(self,grad_input):
        temp = grad_input
        if(reluActive == 1):
            temp[self.featureIn < 0.0] = 0.0
        return temp
    
class SoftmaxLayer:
    """
    Takes the volume coming from convolutional & pooling layers. It flattens it and it uses it in the next layers.
    """
    def __init__(self, input_units, output_units):
        # Initiallize weights and biases
        self.weight = np.random.randn(input_units, output_units)/input_units
        self.bias = np.zeros(output_units)

    def forward_prop(self, image):
        self.original_shape = image.shape # stored for backprop
        # Flatten the image
        image_flattened = image.flatten()
        self.flattened_input = image_flattened # stored for backprop
        # Perform matrix multiplication and add bias
        first_output = np.dot(image_flattened, self.weight) + self.bias
        self.output = first_output
        # Apply softmax activation
        softmax_output = np.exp(first_output) / np.sum(np.exp(first_output), axis=0)
        return softmax_output

    def back_prop(self, dE_dY, alpha):
        for i, gradient in enumerate(dE_dY):
            if gradient == 0:
                continue
            transformation_eq = np.exp(self.output)
            S_total = np.sum(transformation_eq)

            # Compute gradients with respect to output (Z)
            dY_dZ = -transformation_eq[i]*transformation_eq / (S_total**2)
            dY_dZ[i] = transformation_eq[i]*(S_total - transformation_eq[i]) / (S_total**2)

            # Compute gradients of output Z with respect to weight, bias, input
            dZ_dw = self.flattened_input
            dZ_db = 1
            dZ_dX = self.weight

            # Gradient of loss with respect ot output
            dE_dZ = gradient * dY_dZ

            # Gradient of loss with respect to weight, bias, input
            dE_dw = dZ_dw[np.newaxis].T @ dE_dZ[np.newaxis]
            dE_db = dE_dZ * dZ_db
            dE_dX = dZ_dX @ dE_dZ

            # Update parameters
            self.weight -= alpha*dE_dw
            self.bias -= alpha*dE_db

            return dE_dX.reshape(self.original_shape)

if __name__ == '__main__':
    train()
    a = 0