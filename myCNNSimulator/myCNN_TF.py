import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
import time
import tensorflow as tf
from tensorflow.keras import datasets, layers, models
import matplotlib.pyplot as plt
import random 
memorySize  = 10000

def getLoader(train,trainingClasses):

    data = [ [] for _ in range(trainingClasses) ]
    # Split feature for each labels
    for  i in range(len(train[1])) :
        for j in range(trainingClasses) :
            if (train[1][i] == j) :
                data[j].append(train[0][i])
                
    for i in range(trainingClasses):
        data[i] = list(zip(data[i],np.full(len(data[i]), i)))  
    
    returnList = []
    for i in range(trainingClasses):
        returnList += data[i][0:int(memorySize/trainingClasses)]
    random.shuffle(returnList)
    return list(zip(*returnList))
    

if __name__ == '__main__':
    
    (train_images,train_labels),(test_images,test_labels) = datasets.cifar10.load_data()
    train, test = (train_images / 255.0,train_labels), (test_images / 255.0,test_labels)

    test2class = getLoader(train,2)
    test4class = getLoader(train,4)
    testAllClass = getLoader(train,10)
    train2class = getLoader(train,2)
    train4class = getLoader(train,4)
    trainAllClass = getLoader(train,10)

    model = models.Sequential()
    model.add(layers.Conv2D(32, (3, 3),activation = 'relu', input_shape=(32, 32, 3))) 
    model.add(layers.Flatten())
    model.add(layers.Dense(10, activation='softmax'))
    
    print(" starting training")
    model.compile(optimizer='adam',
              loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
              metrics=['accuracy'])

    history2class = model.fit(np.array(train2class[0]), np.array(train2class[1]), epochs=1, 
                    validation_data=(np.array(test2class[0]), np.array(test2class[1])))
    history4class = model.fit(np.array(train4class[0]), np.array(train4class[1]), epochs=1, 
                    validation_data=(np.array(test4class[0]), np.array(test4class[1])))
    historyAllClass = model.fit(np.array(trainAllClass[0]), np.array(trainAllClass[1]), epochs=1, 
                    validation_data=(np.array(testAllClass[0]), np.array(testAllClass[1])))
    
    print(f"Training complete .Accuracy{history2class.history['accuracy']}")
    print(f"Training complete .validation  Accuracy{history2class.history['val_accuracy']}")
    print(f"Training complete .Accuracy{history4class.history['accuracy']}")
    print(f"Training complete .validation  Accuracy{history4class.history['val_accuracy']}")
    print(f"Training complete .Accuracy{historyAllClass.history['accuracy']}")
    print(f"Training complete .validation  Accuracy{historyAllClass.history['val_accuracy']}")
    plt.plot(historyAllClass.history['accuracy'], label='accuracy')
    plt.plot(historyAllClass.history['val_accuracy'], label = 'val_accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.ylim([0.5, 1])
    plt.legend(loc='lower right')

    test_loss, test_acc = model.evaluate(np.array(testAllClass[0]),  np.array(testAllClass[1]), verbose=2)