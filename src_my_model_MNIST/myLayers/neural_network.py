import numpy as np
from typing import Tuple, List, Union
from myLayers.layers import CrossEntropyLoss, ParamLayer, Layer
from tqdm import tqdm
import math


class NeuralNetwork:

    def __init__(self, layers: List[Layer]):
        self.layers = layers[:]
        self.loss_layer: Union[Layer, None] = None
    
    def backward_propagation(self, output: np.ndarray) -> None:
        grad_input = [None] * 9
        grad_input[len(self.layers)] = self.loss_layer.backward(np.ones_like(output)) 
        for layer_index in range(len(self.layers)-1, -1, -1):
            grad_input[layer_index] = self.layers[layer_index].backward(grad_input[layer_index +1 ])
        return grad_input

    def update_params(self, learning_rate: float) -> None:
        for layer_index in range(len(self.layers)):
            layer = self.layers[layer_index]
            if isinstance(layer, ParamLayer):
                layer.apply_gradients(learning_rate)

    def evaluate_model(self, test_x: np.ndarray, 
                       test_y: np.ndarray) -> Tuple[float, float]:
        """Returns loss and accuracy in the test set"""
        
        y_pred = self.predict(test_x)
        y_pred_labels = np.argmax(y_pred[-1], axis=1)
        y_labels = np.argmax(test_y, axis=1)
        loss = self.loss_layer.forward(y_pred[-1])
        accuracy = np.sum(y_labels == y_pred_labels) / test_x.shape[0]
        return float(np.mean(loss)), accuracy

    def fit_train(self, x_train: np.ndarray, y_train: np.ndarray,
            learning_rate: float) -> np.array:
        flatted = np.zeros((16,784),dtype="float32")
        for b in range(16):
            flatted[b] = x_train[b].flatten()
        self.loss_layer = CrossEntropyLoss(ConvToOneHot(y_train,16,10))
        forward_output = self.predict(flatted, train=True)
        forward_output.append(self.loss_layer.forward(forward_output[-1]))
        backward_output = self.backward_propagation(forward_output[-2])
        self.update_params(learning_rate)
        return forward_output,backward_output

    def fit_test(batch_size: int, x_test: np.ndarray,y_test: np.ndarray) -> np.array:

        return  self.evaluate_model(x_test, ConvToOneHot(y_test,16,10))
        
    def predict(self, x_test: np.ndarray, train: bool = False) -> np.ndarray:
        xTest = list()
        xTest.append(x_test)
        for layer in self.layers:
            xTest.append(layer.forward(xTest[-1], train=train))
        return xTest


def ConvToOneHot(input,batchSize,inputSize):
    b = np.zeros((batchSize, inputSize ),dtype="float32")
    b[np.arange(input.size), input] = 1
    return b