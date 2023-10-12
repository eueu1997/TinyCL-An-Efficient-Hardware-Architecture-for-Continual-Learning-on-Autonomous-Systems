import os,subprocess
import numpy as np
def fxdPointCnv(x):
    return format(int(x*4096) & 0xFFFF,'04X') #left shift of 8 position 

def fixedToFP(hexstr, bits):
    value = int(hexstr, 16)
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value
feature = np.random.rand(100)*2-1
kernel = np.random.rand(100)*2-1
f2 = np.vectorize(fxdPointCnv)

np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/kernel.txt", f2(kernel),fmt = '%s', delimiter='\n')
np.savetxt("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/featureIn1.txt",f2(feature),fmt = '%s', delimiter='\n')
       

os.chmod('/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/init.sh', 0b111101101) # rwxr-xr-x make it executable                       
process = subprocess.Popen(['/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/init.sh'])
#process.communicate()
process.wait() # Wait for process to complete.

results = open("/home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/result.txt","r").read()

lines = results.split('\n')
# Remove the first 3 rows
del lines[:4]
del lines[-1]

results = [fixedToFP(item,16)/4096  for item in lines]
myResult = feature * kernel
diff = results - myResult[0:99]
avgErr = np.sum(diff)/100
print(f" python results :\n {myResult}")
print(f"verilog result :\n {results}")
print(f" diff result :\n {diff}")
print(avgErr)