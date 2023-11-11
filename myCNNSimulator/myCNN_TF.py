import numpy as np

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
    print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))

    with tf.device('/CPU:0'):

        model = models.Sequential()
        model.add(layers.Conv2D(8, (3, 3),activation = 'relu', input_shape=(32, 32, 3))) 
        model.add(layers.Flatten())
        model.add(layers.Dense(10, activation='softmax'))

        '''model.add(layers.Conv2D(128, (3, 3), padding='same', input_shape=(32,32,3)))
        model.add(layers.Activation('relu'))

        model.add(layers.Conv2D(128, (3, 3)))
        model.add(layers.Activation('elu'))
        model.add(layers.MaxPooling2D(pool_size=(2, 2)))

        model.add(layers.Conv2D(256, (3, 3), padding='same'))
        model.add(layers.Activation('elu'))

        model.add(layers.Conv2D(256, (3, 3)))
        model.add(layers.Activation('elu'))
        model.add(layers.MaxPooling2D(pool_size=(2, 2)))
        model.add(layers.Dropout(0.25))

        model.add(layers.Conv2D(512, (3, 3), padding='same'))
        model.add(layers.Activation('elu'))

        model.add(layers.Conv2D(512, (3, 3)))
        model.add(layers.Activation('elu'))
        model.add(layers.MaxPooling2D(pool_size=(2, 2)))
        model.add(layers.Dropout(0.25))

        model.add(layers.Flatten())
        model.add(layers.Dense(1024))
        model.add(layers.Activation('elu'))
        model.add(layers.Dropout(0.5))
        model.add(layers.Dense(100))
        model.add(layers.Activation('softmax'))'''
        #layers = tf.keras.applications.resnet50.ResNet50().layers


        #print(model.summary())
        print(" starting training")
        model.compile(optimizer='sgd',
              loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=False),
              metrics=['accuracy'])
    
        '''prev = 0
        diff = 2
        while diff*100 > 1 :
        history2class = model.fit(np.array(train2class[0]), np.array(train2class[1]), epochs=1, 
                    validation_data=(np.array(test2class[0]), np.array(test2class[1])))
        diff = history2class.history['val_accuracy'][0] - prev 
        prev = history2class.history['val_accuracy'][0]
        print(f"Training complete of 20 classes .Accuracy{history2class.history['accuracy']}")
        print(f"Training complete .validation  Accuracy{history2class.history['val_accuracy']}")
        prev = 0
        diff = 2
        while diff*100 > 1 :    
        history4class = model.fit(np.array(train4class[0]), np.array(train4class[1]), epochs=1, 
                    validation_data=(np.array(test4class[0]), np.array(test4class[1])))
        diff = history4class.history['val_accuracy'][0] - prev 
        prev = history4class.history['val_accuracy'][0]
        print(f"Training complete of 40 classes .Accuracy{history4class.history['accuracy']}")
        print(f"Training complete .validation  Accuracy{history4class.history['val_accuracy']}")
        prev = 0
        diff = 2
        while diff*100 > 1:
        historyAllClass = model.fit(np.array(trainAllClass[0]), np.array(trainAllClass[1]), epochs=1, 
                    validation_data=(np.array(testAllClass[0]), np.array(testAllClass[1])))
        diff = historyAllClass.history['val_accuracy'][0] - prev 
        prev = historyAllClass.history['val_accuracy'][0]
        print(f"Training complete of 100 classes .Accuracy{historyAllClass.history['accuracy']}")
        print(f"Training complete .validation  Accuracy{historyAllClass.history['val_accuracy']}")
        '''

        start_time = time.time()



# Calculate elapsed time
        historyAllClass = model.fit(train[0], train[1], epochs=1, batch_size = 1
                    )
        end_time = time.time()
        elapsed_time = end_time - start_time
        print("Elapsed time: ", elapsed_time) 


