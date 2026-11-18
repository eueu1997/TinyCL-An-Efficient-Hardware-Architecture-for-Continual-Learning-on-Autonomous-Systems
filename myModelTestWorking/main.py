from src.feed_forward.neural_network import NeuralNetwork
from src.feed_forward.layers import LinearLayer, SigmoidLayer, BatchNormLayer
from typing import Tuple
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import math
from src.feed_forward.myLayers.MLPOnMNIST import MLPOnMIST

learning_rate = 0.1
batch_size = 60
neurons = 100
steps = 20000
mnist_dir = "C:/Users/eueu/Documents/Personale/Tesi/GDumb/MSThesis/myModelTestWorking/data"


def pre_process_data(location: str,dataType: str) -> Tuple[np.ndarray, np.ndarray]:
    temp = 2**(8*np.dtype(dataType).itemsize -1 )-1
    csv_train = pd.read_csv(location)
    X = csv_train.values[:, 1:].astype(dataType)
    if(dataType == "int8"):
        X = X>>1
    elif ( dataType == "int16"):
        X = X<<7
    else:
        X = X<<23
    y = csv_train.values[:, 0]
    y_one_hot = np.zeros((y.size, y.max()+1)).astype(dataType)
    y_one_hot[np.arange(y.size), y] = temp
    return X, y_one_hot



x_train8, y_train8 = pre_process_data(f"{mnist_dir}/mnist_train.csv","int8")
x_test8, y_test8 = pre_process_data(f"{mnist_dir}/mnist_test.csv","int8")
model_bn8 = NeuralNetwork([LinearLayer(x_train8.shape[1], neurons,"int8"),
                          SigmoidLayer("int8"),
                          LinearLayer(neurons, neurons,"int8"),
                          SigmoidLayer("int8"),
                          LinearLayer(neurons, neurons,"int8"),
                          SigmoidLayer("int8"),
                          LinearLayer(neurons, y_train8.shape[1],"int8"),
                          SigmoidLayer("int8")])
x_train16, y_train16 = pre_process_data(f"{mnist_dir}/mnist_train.csv","int16")
x_test16, y_test16 = pre_process_data(f"{mnist_dir}/mnist_test.csv","int16")
model_bn16 = NeuralNetwork([LinearLayer(x_train16.shape[1], neurons,"int16"),
                          SigmoidLayer("int16"),
                          LinearLayer(neurons, neurons,"int16"),
                          SigmoidLayer("int16"),
                          LinearLayer(neurons, neurons,"int16"),
                          SigmoidLayer("int16"),
                          LinearLayer(neurons, y_train16.shape[1],"int16"),
                          SigmoidLayer("int16")])
x_train32, y_train32 = pre_process_data(f"{mnist_dir}/mnist_train.csv","int32")
x_test32, y_test32 = pre_process_data(f"{mnist_dir}/mnist_test.csv","int32")
model_bn32 = NeuralNetwork([LinearLayer(x_train32.shape[1], neurons,"int32"),
                          SigmoidLayer("int32"),
                          LinearLayer(neurons, neurons,"int32"),
                          SigmoidLayer("int32"),
                          LinearLayer(neurons, neurons,"int32"),
                          SigmoidLayer("int32"),
                          LinearLayer(neurons, y_train32.shape[1],"int32"),
                          SigmoidLayer("int32")])
'''
model_baseline = NeuralNetwork([LinearLayer(x_train.shape[1], neurons),
                                SigmoidLayer(),
                                LinearLayer(neurons, neurons),
                                SigmoidLayer(),
                                LinearLayer(neurons, neurons),
                                SigmoidLayer(),
                                LinearLayer(neurons, y_train.shape[1]),
                                SigmoidLayer()])'''
#myModel = MLPOnMIST(28,100)
'''
print("Training myModel")
myModel_accuracy = myModel.fit(x_train, y_train, steps=steps,
                                       learning_rate=learning_rate,
                                       batch_size=batch_size,
                                       x_test=x_test, y_test=y_test)
print("Training Baseline")
baseline_accuracy = model_baseline.fit(x_train, y_train, steps=steps,
                                       learning_rate=learning_rate,
                                       batch_size=batch_size,
                                       x_test=x_test, y_test=y_test)[:, 1]'''
print("Training Model w/ Batch Norm")
bn_accuracy8 = model_bn8.fit(x_train8, y_train8, steps=steps,
                           learning_rate=learning_rate,
                           batch_size=batch_size, x_test=x_test8,
                           y_test=y_test8,dataType="int8")[:, 1]


num_batches = math.ceil(x_train16.shape[0] / batch_size)
num_batches = math.ceil(x_train16.shape[0] / batch_size)
#steps_axis = np.linspace(1, steps/num_batches, len(baseline_accuracy)//10+1)
steps_axis = np.linspace(1, steps/num_batches, len(bn_accuracy8)//10+1)
steps_axis = steps_axis.astype("int")

plt.plot(bn_accuracy8, label="model 8 bit int")

plt.ylabel("Test Accuracy")
plt.xlabel("Steps")
plt.title("Results on MNIST")
locs = np.linspace(0, len(bn_accuracy8)-1, len(bn_accuracy8)//10+1)
plt.xticks(locs, [str(x)+"k" for x in steps_axis])
plt.grid()
plt.legend()
plt.show()
bn_accuracy32 = model_bn32.fit(x_train32, y_train32, steps=steps,
                           learning_rate=learning_rate,
                           batch_size=batch_size, x_test=x_test32,
                           y_test=y_test32,dataType="int32")[:, 1]
bn_accuracy16 = model_bn16.fit(x_train16, y_train16, steps=steps,
                           learning_rate=learning_rate,
                           batch_size=batch_size, x_test=x_test16,
                           y_test=y_test16,dataType="int16")[:, 1]

plt.plot(bn_accuracy16, label="model 16 bit int")
plt.plot(bn_accuracy32, label="model 32 bit inmt")
plt.ylabel("Test Accuracy")
plt.xlabel("Steps")
plt.title("Results on MNIST")
locs = np.linspace(0, len(bn_accuracy8)-1, len(bn_accuracy8)//10+1)
plt.xticks(locs, [str(x)+"k" for x in steps_axis])
plt.grid()
plt.legend()
plt.show()