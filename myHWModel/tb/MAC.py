def twos_complement(hexstr, bits):
    value = int(hexstr, 16)
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value
feature = ["02A0","0280","0180","0180","0380","FE00","0110","0110"]
kernel = ["0230","0230","0230","02C0","02A0","0220","0220","0220"]
partial = ["05be","0578","0348","0420","0930","FBC0","0242","0242"]
feature = [twos_complement(item,16)/256  for item in feature]
kernel = [twos_complement(item,16)/256  for item in kernel]
partial = [twos_complement(item,16)/256 for item in partial]
acc = 0
hexAcc = 0
for i in range(len(feature)):
    print(f"feature : {feature[i]}, kernel: {kernel[i]}, product : {feature[i]*kernel[i]} \n")
    print(f"My partial is {partial[i]}\n")
    acc += feature[i]*kernel[i]
    hexAcc += partial[i]
print(f"Python result is {acc}")
print(f"My accumulation result is : {twos_complement('1C12',16)/256}")
feature = ["0033","0001","0009","0031","0029","fffb","002d","002b"]
kernel = ["ff89","ff46","ff81","ffef","ff3e","ff20","ffbf","00f1"]
partial = ["ffe8","ffff","fffb","fffc","ffe0","0004","fff4","0028"]
feature = [twos_complement(item,16)/256  for item in feature]
kernel = [twos_complement(item,16)/256  for item in kernel]
partial = [twos_complement(item,16)/256 for item in partial]
acc = 0
hexAcc = 0
for i in range(len(feature)):
    print(f"feature : {feature[i]}, kernel: {kernel[i]}, product : {feature[i]*kernel[i]} \n")
    print(f"My partial is {partial[i]}\n")
    acc += feature[i]*kernel[i]
    hexAcc += partial[i]
print(f"Python result is {acc}")
print(f"My accumulation result is : {twos_complement('ffde',16)/256}")

