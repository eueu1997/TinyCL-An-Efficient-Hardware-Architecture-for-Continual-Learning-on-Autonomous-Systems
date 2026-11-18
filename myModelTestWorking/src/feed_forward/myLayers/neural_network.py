import numpy as np
from typing import Tuple, List, Union
from myLayers.layers import CrossEntropyLoss, ParamLayer, Layer
from tqdm import tqdm
import math
import matplotlib.pyplot as plt


class NeuralNetwork:

    def __init__(self, layers: List[Layer]):
        self.layers = layers[:]
        self.loss_layer: Union[Layer, None] = None
    
    def backward_propagation(self, output: np.ndarray) -> None:
        grad_input = self.loss_layer.backward(np.ones_like(output)) 
        for layer_index in range(len(self.layers)-1, -1, -1):
            grad_input = self.layers[layer_index].backward(grad_input)

    def update_params(self, learning_rate: float) -> None:
        for layer_index in range(len(self.layers)):
            layer = self.layers[layer_index]
            if isinstance(layer, ParamLayer):
                layer.apply_gradients(learning_rate)

    def evaluate_model(self, test_x: np.ndarray, 
                       test_y: np.ndarray) -> Tuple[float, float]:
        """Returns loss and accuracy in the test set"""
        self.loss_layer = CrossEntropyLoss(test_y)
        y_pred = self.predict(test_x)
        y_pred_labels = np.argmax(y_pred, axis=1)
        y_labels = np.argmax(test_y, axis=1)
        loss = self.loss_layer.forward(y_pred)
        accuracy = np.sum(y_labels == y_pred_labels) / test_x.shape[0]
        return float(np.mean(loss)), accuracy

    def fit(self, train: np.ndarray,  test: np.ndarray,
            ) -> np.array:
        metrics = list()
        for inputs, labels in train:
            flatted = np.zeros((16,784),dtype="float32")
            for b in range(16):
                flatted[b] = inputs[b].flatten()
            self.loss_layer = CrossEntropyLoss(ConvToOneHot(labels.numpy(),16,10))
            y_pred = self.predict(flatted, train=True)
            self.loss_layer.forward(y_pred)
            self.backward_propagation(y_pred)
            self.update_params(0.0001)
        for inputs, labels in test:
            flatted = np.zeros((16,784),dtype="float32")
            for b in range(16):
                flatted[b] = inputs[b].flatten()
            loss, accuracy = self.evaluate_model(flatted, ConvToOneHot(labels.numpy(),16,10))
            metrics.append((loss, accuracy))
      

        return metrics

    def predict(self, x_test: np.ndarray, train: bool = False) -> np.ndarray:
        for layer in self.layers:
            x_test = layer.forward(x_test, train=train)
        return x_test

def ConvToOneHot(input,batchSize,inputSize):
    b = np.zeros((batchSize, inputSize ),dtype="float32")
    b[np.arange(input.size), input] = 1
    return b
