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

if __name__ == '__main__':
    
    (train_images,train_labels),(test_images,test_labels) = datasets.cifar10.load_data()
    train, test = (train_images / 255.0,train_labels), (test_images / 255.0,test_labels)

    train_0 = []
    train_1 = []
    train_2 = []
    train_3 = []
    train_4 = []
    train_5 = []
    train_6 = []
    train_7 = []
    train_8 = []
    train_9 = []
    test_0 = []
    test_1 = []
    test_2 = []
    test_3 = []
    test_4 = []
    test_5 = []
    test_6 = []
    test_7 = []
    test_8 = []
    test_9 = []
    for  i in range(len(train[1])) :
        if (train[1][i] == 0) :
            train_0.append(train[0][i])
        if (train[1][i] == 1) :
            train_1.append(train[0][i])
        if (train[1][i] == 2) :
            train_2.append(train[0][i])
        if (train[1][i] == 3) :
            train_3.append(train[0][i])
        if (train[1][i] == 4) :
            train_4.append(train[0][i])
        if (train[1][i] == 5) :
            train_5.append(train[0][i])
        if (train[1][i] == 6) :
            train_6.append(train[0][i])
        if (train[1][i] == 7) :
            train_7.append(train[0][i])
        if (train[1][i] == 8) :
            train_8.append(train[0][i])
        if (train[1][i] == 9) :
            train_9.append(train[0][i])
        
    train_0 = list(zip(train_0,np.full(len(train_0), 0)))  
    train_1 = list(zip(train_1,np.full(len(train_1), 1)))    
    train_2 = list(zip(train_2,np.full(len(train_2), 2)))    
    train_3 = list(zip(train_3,np.full(len(train_3), 3)))    
    train_4 = list(zip(train_4,np.full(len(train_4), 4)))    
    train_5 = list(zip(train_5,np.full(len(train_5), 5)))    
    train_6 = list(zip(train_6,np.full(len(train_6), 6)))    
    train_7 = list(zip(train_7,np.full(len(train_7), 7)))    
    train_8 = list(zip(train_8,np.full(len(train_8), 8)))    
    train_9 = list(zip(train_9,np.full(len(train_9), 9)))     
    train2class = train_0[0:int(memorySize/2)] + train_1[0:int(memorySize/2)]
    train4class = train_0[0:int(memorySize/4)] + train_1[0:int(memorySize/4)] + train_2[0:int(memorySize/4)] + train_3[0:int(memorySize/4)]
    trainAllClass = train_0[0:int(memorySize/10)] + train_1[0:int(memorySize/10)] + train_2[0:int(memorySize/10)] + train_3[0:int(memorySize/10)] + train_4[0:int(memorySize/10)] + train_5[0:int(memorySize/10)] + train_6[0:int(memorySize/10)] + train_7[0:int(memorySize/10)] + train_8[0:int(memorySize/10)] + train_9[0:int(memorySize/10)]
    random.shuffle(train2class)
    random.shuffle(train4class)
    random.shuffle(trainAllClass)
    
    for  i in range(len(test[1])) :
        if (test[1][i] == 0) :
            test_0.append(test[0][i])
        if (test[1][i] == 1) :
            test_1.append(test[0][i])
        if (test[1][i] == 2) :
            test_2.append(test[0][i])
        if (test[1][i] == 3) :
            test_3.append(test[0][i])
        if (test[1][i] == 4) :
            test_4.append(test[0][i])
        if (test[1][i] == 5) :
            test_5.append(test[0][i])
        if (test[1][i] == 6) :
            test_6.append(test[0][i])
        if (test[1][i] == 7) :
            test_7.append(test[0][i])
        if (test[1][i] == 8) :
            test_8.append(test[0][i])
        if (test[1][i] == 9) :
            test_9.append(test[0][i])
      
    test_0 = list(zip(test_0,np.full(len(test_0), 0)))  
    test_1 = list(zip(test_1,np.full(len(test_1), 1)))    
    test_2 = list(zip(test_2,np.full(len(test_2), 2)))    
    test_3 = list(zip(test_3,np.full(len(test_3), 3)))    
    test_4 = list(zip(test_4,np.full(len(test_4), 4)))    
    test_5 = list(zip(test_5,np.full(len(test_5), 5)))    
    test_6 = list(zip(test_6,np.full(len(test_6), 6)))    
    test_7 = list(zip(test_7,np.full(len(test_7), 7)))    
    test_8 = list(zip(test_8,np.full(len(test_8), 8)))    
    test_9 = list(zip(test_9,np.full(len(test_9), 9)))     
    test2class = test_0[0:int(memorySize/2)] + test_1[0:int(memorySize/2)]
    test4class = test_0[0:int(memorySize/4)] + test_1[0:int(memorySize/4)] + test_2[0:int(memorySize/4)] + test_3[0:int(memorySize/4)]
    testAllClass = test_0[0:int(memorySize/10)] + test_1[0:int(memorySize/10)] + test_2[0:int(memorySize/10)] + test_3[0:int(memorySize/10)] + test_4[0:int(memorySize/10)] + test_5[0:int(memorySize/10)] + test_6[0:int(memorySize/10)] + test_7[0:int(memorySize/10)] + test_8[0:int(memorySize/10)] + test_9[0:int(memorySize/10)]
    random.shuffle(test2class)
    random.shuffle(test4class)
    random.shuffle(testAllClass)

    test2class = list(zip(*test2class))
    test4class = list(zip(*test4class))
    testAllClass = list(zip(*testAllClass))
    train2class = list(zip(*train2class))
    train4class = list(zip(*train4class))
    trainAllClass = list(zip(*trainAllClass))

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