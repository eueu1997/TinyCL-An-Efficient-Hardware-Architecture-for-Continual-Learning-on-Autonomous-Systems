import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
import time
import os,subprocess

def rotateMatrix(mat):
 
    # Simply print from
    # last cell to first cell.
    
    out  = np.zeros((mat.shape[0],2,2))
    if mat[0].shape == (1,1):
        
        out[:,0,0]=0
        out[:,1,0]=0
        out[:,0,1]=0
        out[:,1,1]=mat[:,0,0]   
        return out 
    elif mat[0].shape == (2,2):
        out[:,0,0]=mat[:,1,1]
        out[:,1,0]=mat[:,0,1]
        out[:,0,1]=mat[:,1,0]
        out[:,1,1]=mat[:,0,0]
        return out
    elif mat[0].shape == (1,2):
        out[:,1,0]= mat[:,0,1]
        out[:,1,1]= mat[:,0,0]
        out[:,0,0]= 0
        out[:,0,1]= 0
        return out
    else:
        out[:,0,1]=mat[:,1,0]
        out[:,1,1]=mat[:,0,0]
        out[:,0,0] = 0
        out[:,1,0] = 0
        return out
class Conv3D():
    
    def __init__(self,channelInDim,featureInDim,channelOutDim,stride,kernelSize):
        self.kernel = (np.random.rand(channelOutDim,channelInDim,kernelSize,kernelSize)*2)-1
        self.dk = np.zeros((channelOutDim,channelInDim,kernelSize,kernelSize))
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
        f = open("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/logConv.txt", "w")
        for i in range(self.channelOutDim):
            for j in range(self.featureOutDim):
                for k in range(self.featureOutDim):
                    subFeatureIn = self.featureIn[:,int(j*self.stride):int(j*self.stride+self.kernelSize),int(k*self.stride):int(k*self.stride+self.kernelSize)]
                    #featureOut[i][j][k] = MAC(np.flatten(subFeatureIn),np.flatten(self.kernel[i]))
                    f.write( f"Calculus of {i},{j},{k} feature out position. \nsub feature in {subFeatureIn}\n kernels {self.kernel[i]}\n\n\n")
                    featureOut[i][j][k] = np.sum(subFeatureIn*self.kernel[i],(0,1,2))
        f.close()
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
        dy = np.pad(dy, ((0,0), (1,0), (1,0)), mode='constant', constant_values=0)
        for i in range(self.channelInDim):
            #for q in range(self.channelOutDim):
            for j in range(self.featureInDim):
                for k in range(self.featureInDim):                   
                    temp = np.reshape(self.kernel[:,i],(self.channelOutDim,self.kernelSize,self.kernelSize))
                    dx[i][j][k]  = np.sum( rotateMatrix(temp[:,(j%self.stride):self.kernelSize:self.stride,(k%self.stride):self.kernelSize:self.stride])
                    * dy[:,int(j/self.stride):int(j/self.stride)+(int(self.kernelSize/self.stride)+1),int(k/self.stride):int(k/self.stride)+(int(self.kernelSize/self.stride)+1)],(0,1,2))
        
        self.dk += dk
        return dx[:,0:-1,0:-1]                       
    
    def paramUpdate(self,lr,batchSize):
        self.kernel -= self.dk/batchSize*lr
        self.dk = np.zeros((self.channelOutDim,self.channelInDim,self.kernelSize,self.kernelSize))
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

def fxdPointCnv(x):
    return format(int(x*256) & 0xFFFF,'04X') #left shift of 8 position 
def twos_complement(hexstr, bits):
    value = int(hexstr, 16)
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value
if __name__ == '__main__':
    conv3d1 = Conv3D(8,32,8,1,3)
    trainLoader, testLoader = getLoader()
    for feature,labels in trainLoader:
        featureInExt = np.zeros((8,32,32))
        featureInExt[0:3] = feature.numpy()
        print(conv3d1.kernel.shape)
        f2 = np.vectorize(fxdPointCnv)
        np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureIn1.txt", f2(featureInExt.flatten()),fmt = '%s', delimiter='\n')
        np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureIn1float.txt", featureInExt.flatten(),fmt = '%s', delimiter='\n')
        break
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/kernel.txt", f2(conv3d1.kernel.flatten()),fmt = '%s', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/kernelFloat.txt", conv3d1.kernel.flatten(),fmt = '%s', delimiter='\n')
    # Call verilog simulation. Output is on featureOut1.txt
    os.chmod('/home/thesis/eugenio.ressa/Desktop/myHWModel/init.sh', 0b111101101) # rwxr-xr-x make it executable                       
    process = subprocess.Popen(['/home/thesis/eugenio.ressa/Desktop/myHWModel/init.sh'])
    #process.communicate()
    process.wait() # Wait for process to complete.
    l1FeatureOut = conv3d1.Conv3dForward(featureInExt)
    optiFeatureOut = open("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutVerilogHex.txt","r").read()
    
    lines = optiFeatureOut.split('\n')
    
    # Remove the first 4 rows
    del lines[:3]
    
    # Remove all occurrences of 'x' in each line
    for i in range(len(lines)):
        lines[i] = lines[i].replace('x', '0')
    
    optiFeatureOut = [item for item in lines if item != ""]
    optiFeatureOut = [twos_complement(item,16)/256  for item in optiFeatureOut]
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutVerilogFP.txt",optiFeatureOut,fmt = '%f', delimiter='\n')
    
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych0.txt",l1FeatureOut[0],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych1.txt",l1FeatureOut[1],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych2.txt",l1FeatureOut[2],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych3.txt",l1FeatureOut[3],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych4.txt",l1FeatureOut[4],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych5.txt",l1FeatureOut[5],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych6.txt",l1FeatureOut[6],fmt = '%f', delimiter='\n')
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/featureOutPych7.txt",l1FeatureOut[7],fmt = '%f', delimiter='\n')




  
    
        

    