import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
import time
import os,subprocess

def rotateMatrix(mat):
 
    # Simply print from
    # last cell to first cell.
    
    
    if mat[0].shape == (1,1):    
        out  = np.zeros((mat.shape[0],2,2))  
        out[:,0,0]=0
        out[:,1,0]=0
        out[:,0,1]=0
        out[:,1,1]=mat[:,0,0]   
        return out 
    elif mat[0].shape == (2,2):
        out  = np.zeros((mat.shape[0],2,2))
        out[:,0,0]=mat[:,1,1]
        out[:,1,0]=mat[:,0,1]
        out[:,0,1]=mat[:,1,0]
        out[:,1,1]=mat[:,0,0]
        return out
    elif mat[0].shape == (1,2):
        out  = np.zeros((mat.shape[0],2,2))
        out[:,1,0]= mat[:,0,1]
        out[:,1,1]= mat[:,0,0]
        out[:,0,0]= 0
        out[:,0,1]= 0
        return out
    elif mat[0].shape == (3,3):
        out  = np.zeros((mat.shape[0],3,3))
        out[:,0,0] = mat[:,2,2]
        out[:,0,1] = mat[:,2,1]
        out[:,0,2] = mat[:,2,0]
        out[:,1,2] = mat[:,1,0]
        out[:,2,2] = mat[:,0,0]
        out[:,2,1] = mat[:,0,1]
        out[:,2,0] = mat[:,0,2]
        out[:,1,0] = mat[:,1,2]
        out[:,1,1] = mat[:,1,1]
        return out
    else:
        out  = np.zeros((mat.shape[0],2,2))
        out[:,0,1]=mat[:,1,0]
        out[:,1,1]=mat[:,0,0]
        out[:,0,0] = 0
        out[:,1,0] = 0
        return out
class Conv3D():
    
    def __init__(self,channelInDim,featureInDim,channelOutDim,stride,kernelSize):
        self.kernel = (np.random.rand(channelOutDim,channelInDim,kernelSize,kernelSize)*0)+1
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
        self.featureIn = np.pad(featureIn, ((0,0), (0,2), (0,2)), mode='constant', constant_values=0)
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
        dx = np.zeros((self.channelInDim,self.featureInDim+2,self.featureInDim+2))
        dx1 = np.zeros((self.channelInDim,self.featureInDim+1,self.featureInDim+1))

        for i in range(self.channelOutDim):
            for j in range(self.channelInDim):
                for k in range(self.kernelSize):
                    for l in range(self.kernelSize):
                        subFeatureIn = self.featureIn[j,k:(self.featureOutDim*self.stride+k):self.stride,l:(self.featureOutDim*self.stride+l):self.stride]
                        #dk[i][j][k][l] = MAC(np.flatten(dy[i]),np.flatten(subFeatureIn))
                        dk[i][j][k][l] = np.sum(dy[i]*subFeatureIn,(0,1))
        for i in range(self.channelInDim):
            for l in range(self.featureOutDim):
                for m in range(self.kernelSize):
                    for n in range(self.featureOutDim):
                        for p in range(self.kernelSize):
                            for q in range(self.channelOutDim):
                                dx[i][((l)*self.stride + m )][((n)*self.stride + p)] += self.kernel[q][i][m][p] * dy[q][l][n] 
       
        dy = np.pad(dy, ((0,0), (2,0), (2,0)), mode='constant', constant_values=0)
        for i in range(self.channelInDim):
            #for q in range(self.channelOutDim):
            for j in range(self.featureInDim):
                for k in range(self.featureInDim):                   
                    temp = np.reshape(self.kernel[:,i],(self.channelOutDim,self.kernelSize,self.kernelSize))
                    dx1[i][j][k]  = np.sum( rotateMatrix(temp[:,(j%self.stride):self.kernelSize:self.stride,(k%self.stride):self.kernelSize:self.stride])
                    * dy[:,int(j/self.stride):int(j/self.stride)+(int(self.kernelSize/self.stride+0.5)),int(k/self.stride):int(k/self.stride)+(int(self.kernelSize/self.stride+0.5))],(0,1,2))
        
        self.dk += dk
        return dx[:,0:-2,0:-2]                       
    
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
reluActive = 0
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
        self.input_units = input_units
        self.output_units = output_units
        self.weight = np.random.randn(input_units, output_units)/input_units
        self.bias = np.zeros(output_units)
        self.dE_dw = np.zeros((input_units,input_units))
        self.dE_db = np.zeros(output_units)
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

    def back_prop(self, dE_dY):
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
            self.dE_dw = dZ_dw[np.newaxis].T @ dE_dZ[np.newaxis]
            self.dE_db = dE_dZ * dZ_db
            dE_dX = dZ_dX @ dE_dZ

            # Update parameters
            

            return dE_dX.reshape(self.original_shape)

    def paramUpdate(self,lr,batchSize):
        self.weight -= lr*self.dE_dw/batchSize
        self.bias -= lr*self.dE_db/batchSize
        self.dE_dw = np.zeros((self.input_units,self.input_units))
        self.dE_db = np.zeros(self.output_units)
        
def fxdPointCnv(x):
    return format(int(x*4096) & 0xFFFF,'04X') #left shift of 8 position 
def twos_complement(hexstr, bits):
    value = int(hexstr, 16)
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value
def lossBackward(x,labels):
    #return ((x - labels) )
    return -(((1/x)*labels) )

def convOneHot(input):
    out = np.zeros(10)
    out[int(input.numpy())] = 1
    return out

def converter (input,isKernel):
    lines = input.split('\n')
    n=4
    

    # Remove the first 4 rows
    del lines[:3]
    
    for j in range ( len(lines) ):
        lines[j] = [lines[j][i:i+n] for i in range(0, len(lines[j]), n)]
        lines[j] = np.flip(lines[j]) # flip done because in SV the array was read and write in reverse order
    
    # Remove all occurrences of 'x' in each line
    newLines = list()
    for i in range(len(lines)):
        for j in range (len(lines[i])):
            newLines.append(lines[i][j].replace('x', '0'))
            
    output = [item for item in newLines if item != ""]
    output = [twos_complement(item,16)/4096  for item in output]
    output = np.array(output)
    
    if (isKernel == True):
        output = output[0:9]
        output = output.reshape((3,3))
    else:
        output = output.reshape((32,32))
    return output
if __name__ == '__main__':
    conv3d1 = Conv3D(8,32,8,1,3)
    relu1 = ReLU(32,32)
    soft1 = SoftmaxLayer(8*32*32,10)
    trainLoader, testLoader = getLoader()
    for feature,labels in trainLoader:
        featureInExt = np.zeros((8,32,32))
        for i in range(32):
            for j in range(32):
                featureInExt[0][i][j] = j / 4092 
        #featureInExt[0:3] = feature.numpy()
        f2 = np.vectorize(fxdPointCnv)
        # SAVE FEATURE INTO FILES 
        for i in range(3):
            fp = open(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gdumbs/{i}.txt","w")
            for j in range (32):
                for k in range (0,32,8):
                    fp.write(''.join(f2(np.flip(featureInExt[i,j,k:k+8].flatten(),0)))) # flip done because in SV the array was read and write in reverse order
                    fp.write("\n")
            fp.close()
            np.savetxt(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gdumbs/{i}2", f2(featureInExt.flatten()),fmt = '%s', delimiter='\n')
            np.savetxt(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gdumbs/{i}_float.txt", featureInExt.flatten(),fmt = '%s', delimiter='')
        #SAVE KERNELS INTO FILES
        for i in range(8):
            for j in range(8):
                np.savetxt(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_in/{i}_{j}.txt", f2(conv3d1.kernel[i][j].flatten()),fmt = '%s', delimiter='\n')
                np.savetxt(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_in/{i}_{j}_float", conv3d1.kernel[i][j].flatten(),fmt = '%s', delimiter='\n')
        #EXECUTE CONVOLUTION OF PYTHON
        l1FeatureOut = conv3d1.Conv3dForward(featureInExt)  
        featureOut = relu1.reluForward(l1FeatureOut)
        lOutput = soft1.forward_prop(featureOut)
        dx = lossBackward(lOutput,convOneHot(labels))
        dx = soft1.back_prop(dx)
        dx = relu1.reluBackward(dx)
        for i in range(8):
            fp = open(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_in/{i}.txt","w")
            for j in range (32):
                for k in range (0,32,8):
                    fp.write(''.join(f2(dx[i,j,k:k+8].flatten())))
                    fp.write("\n")
            fp.close()            
            np.savetxt(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_in/{i}_2.txt", f2(dx[i].flatten()),fmt = '%s', delimiter='\n')
            np.savetxt(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_in/{i}_float.txt", dx[i].flatten(),fmt = '%s', delimiter='\n')
        gradientOut = conv3d1.Conv3dBackward(dx)
        conv3d1.paramUpdate(0.0001,1)
        kernelOut = conv3d1.kernel
        break
    # Call verilog simulation. Output is on featureOut1.txt
    os.chmod('/home/thesis/eugenio.ressa/Desktop/myHWModel/init.sh', 0b111101101) # rwxr-xr-x make it executable                       
    process = subprocess.Popen(['/home/thesis/eugenio.ressa/Desktop/myHWModel/init.sh'])
    #process.communicate()
    process.wait() # Wait for process to complete.
    optiFeatureOut = ["" for x in range(8)]
    optiGradientOut =["" for x in range(8)]
    optiKernelOut = [["" for x in range(8)] for x in range(8)]
    for i in range (8):
        optiFeatureOut[i] = open(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/feature_out/{i}.txt","r").read()
    for i in range(8):
        for j in range(8):
            optiKernelOut[i][j] = open(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_out/{i}_{j}.txt","r").read()
    for i in range (8):
        optiGradientOut[i] = open(f"/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_out/{i}.txt","r").read()
    
    for i in range (8):
        optiFeatureOut[i] = converter(optiFeatureOut[i],False)
    for i in range (8):
        for j in range (8):
            optiKernelOut[i][j] = converter(optiKernelOut[i][j],True)
    for i in range (8):
        optiGradientOut[i] = converter(optiGradientOut[i],False)
        
    diffFeature = ((optiFeatureOut - featureOut)/featureOut)*100
    diffKernel = optiKernelOut - kernelOut
    diffGradient = optiGradientOut - gradientOut
    
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/featureOutOptiFeatureOut0.txt", fmt='%1.4f',X = optiFeatureOut[0])
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/featureOutFeatureOut0.txt", fmt='%1.4f',X = featureOut[1])
    np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/featureOutDiff0.txt", fmt='%2.1f',X = diffFeature[1])

'''
if (MEMORY_TYPE == "KERNEL") begin
                    $display("kernel Writing. Channel out : %s.Channel In : %s",CHANNEL_OUT,CHANNEL_IN);
                    code= $sscanf(file_path, "/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_out/%s_%s.txt", CHANNEL_OUT,CHANNEL_IN);
                    $writememh(file_path,mem);
                    $display("kernel reading. Channel In : %s. Channel out : %s",CHANNEL_IN,CHANNEL_OUT);
                    code=$sscanf(file_path, "/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/kernels_in/%s_%s.txt", CHANNEL_OUT,CHANNEL_IN);
                    $readmemh(file_path,mem);
                end else if (MEMORY_TYPE == "GRADIENT") begin
                    $display("gradient Writing. Channel out : %s",CHANNEL_OUT);
                    code=$sscanf(file_path, "/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_out/%s.txt", CHANNEL_OUT);
                    $writememh(file_path,mem);
                    $display("gradient reading. Channel out : %s",CHANNEL_IN);
                    code=$sscanf(file_path, "/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gradients_in/%s.txt", CHANNEL_IN);
                    $readmemh(file_path,mem);
                end else if (MEMORY_TYPE == "GDUMB")begin
                    $display("Gdumb  Writing. Channel In : %s",CHANNEL_IN);
                    code=$sscanf(file_path, "/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/gdumbs/%s.txt", CHANNEL_IN);
                    $readmemh(file_path,mem);
                end else if (MEMORY_TYPE == "FEATURE") begin
                    $display("Feature Writing. Channel out : %s",CHANNEL_OUT);
                    code=$sscanf(file_path, "/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/files/feature_out/%s.txt", CHANNEL_OUT);
                    $writememh(file_path,mem);      
                end else begin
                    $display("No file found!. Simulation will be terminated");
                    $finish;
                end
'''
  
    
        

    