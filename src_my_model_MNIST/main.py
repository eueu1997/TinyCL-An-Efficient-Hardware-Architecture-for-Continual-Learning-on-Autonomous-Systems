import torch, os, time
import numpy as np
from dataloader import VisionDataset 
from models import mnist, cifar, imagenet
from models.layers import FinalBlock
from torch import nn, optim
from opts import parse_args
from utils import AverageMeter, get_accuracy, cutmix_data, get_logger, seed_everything, save_model, load_model
from myLayers.MLPOnMNIST import MLPOnMIST
import matplotlib as mpl
import matplotlib.pyplot as plt
#class_mask : maschera per mascherare gli output in caso di task incremental ( tutti uno in caso di ci)
single_lr=0
acc_v = []
myAcc_v = []
lr_v = []
def experiment(opt, class_mask, train_loader, test_loader, model, logger, num_passes):
    best_prec1 = 0.0
    best_myPrec = 0.0
    best_lr    = 0.0
    model = model.half().cuda() # Better speed with little loss in accuracy. If loss in accuracy is big, use apex.
    myModel = MLPOnMIST()
    #criterion = cross entropy loss - calcola la differenze tra le uscite attuali e quelle aspettate
    criterion = nn.CrossEntropyLoss().cuda() #https://towardsdatascience.com/cross-entropy-loss-function-f38c4ec8643e
    # algoritmo per diminuire la cross entropy loss modificando i parametri
    optimizer = optim.SGD(model.parameters(), lr=opt.maxlr, momentum=0.9, weight_decay=opt.weight_decay)
    #setta il learning rate
    scheduler = optim.lr_scheduler.CosineAnnealingWarmRestarts(optimizer, T_0=1, T_mult=2, eta_min=opt.minlr) 

    logger.info("==> Opts for this training: "+str(opt))

    for epoch in range(num_passes):
        # Handle lr scheduling
        if single_lr == 0 :
            if epoch <= 0: # Warm start of 1 epoch
                for param_group in optimizer.param_groups:
                    param_group['lr'] = opt.maxlr * 0.1
            elif epoch == 1: # Then set to maxlr
                for param_group in optimizer.param_groups:
                    param_group['lr'] = opt.maxlr
            else: # Aand go!
                scheduler.step() # cambia i learning rate
        else:
            for param_group in optimizer.param_groups:
                param_group['lr'] = 0.0034224487073782153        
        # Train and test loop
        logger.info("==> Starting pass number: "+str(epoch)+", Learning rate: " + str(optimizer.param_groups[0]['lr']))
        model, optimizer = train(opt=opt, loader=train_loader, model=model, criterion=criterion, optimizer=optimizer, epoch=epoch, logger=logger,myModel = myModel,scheduler = scheduler)
        prec1,myPrec1 = test(loader=test_loader, model=model, criterion=criterion, class_mask=class_mask, logger=logger, epoch=epoch,myModel=myModel)
        
        # Log performance
        logger.info('==> Current accuracy: [{:.3f}]\t'.format(prec1))
        acc_v.append(float(prec1))
        myAcc_v.append(float(myPrec1))
        lr_v.append(float(optimizer.param_groups[0]['lr']))
        if prec1 > best_prec1:
            logger.info('==> Accuracies\tPrevious: [{:.3f}]\t'.format(best_prec1) + 'Current: [{:.3f}]\t'.format(prec1))
            best_prec1 = float(prec1)
            best_lr = optimizer.param_groups[0]['lr']
        if myPrec1 > best_myPrec:
            logger.info('==> MY Accuracies\tPrevious: [{:.3f}]\t'.format(best_myPrec) + 'Current: [{:.3f}]\t'.format(myPrec1))
            best_myPrec = float(myPrec1)
            best_lr = optimizer.param_groups[0]['lr']
        for param_group in optimizer.param_groups:
            print(param_group['lr'])

    logger.info('==> Training completed! Acc: [{0:.3f}] LR: [{best_lr:.8f}]'.format(best_prec1,best_lr = best_lr))
    fig, ax = plt.subplots()  # Create a figure containing a single axes.
    logger.info('==> My Training completed! Acc: [{0:.3f}] LR: [{best_lr:.8f}]'.format(best_myPrec,best_lr = best_lr))
    fig1, ax1 = plt.subplots()  # Create a figure containing a single axes.
    ax.plot(acc_v)
    ax1.plot(myAcc_v)
    fig.savefig(f'/home/thesis/eugenio.ressa/Desktop/GDumb/graphs/accuracy_test_{opt.memory_size}_{opt.num_passes}_{opt.model}_{opt.dataset}_{opt.inp_size}_original.png', dpi=200)
    fig1.savefig(f'/home/thesis/eugenio.ressa/Desktop/GDumb/graphs/my_accuracy_test_{opt.memory_size}_{opt.num_passes}_{opt.model}_{opt.dataset}_{opt.inp_size}_original.png', dpi=200)

    
    return best_prec1, model,best_myPrec


def test(loader, model, criterion, class_mask, logger, epoch,myModel):
        model.eval()
        losses,myLosses, batch_time, accuracy,myAccuracy, task_accuracy, myTaskAcc = AverageMeter(), AverageMeter(), AverageMeter(), AverageMeter(), AverageMeter(), AverageMeter(), AverageMeter()

        with torch.no_grad():
            start = time.time()
            for inputs, labels in loader:
                # Get outputs
                inputs, labels = inputs.half().cuda(non_blocking=True), labels.cuda(non_blocking=True)
                outputs = model(inputs)
                myOutputs = myModel.forward(inputs.cpu().numpy(),labels.cpu().numpy())
                loss = criterion(outputs, labels)
                losses.update(loss.data, inputs.size(0))
                myLosses.update(myOutputs, inputs.size(0))

                # Measure accuracy and task accuracy 
                prob = torch.nn.functional.softmax(outputs, dim=1)
                myProb = torch.from_numpy(myModel.crossEntropy.softmax).cuda()
                
                acc, task_acc = get_accuracy(prob, labels, class_mask)
                accuracy.update(acc, labels.size(0))
                task_accuracy.update(task_acc, labels.size(0))
                acc, task_acc = get_accuracy(myProb, labels, class_mask)
                myAccuracy.update(acc, labels.size(0))
                myTaskAcc.update(task_acc, labels.size(0))
                batch_time.update(time.time() - start)
                start = time.time()

        logger.info('==> Test: [{0}]\tTime:{batch_time.sum:.4f}\tLoss:{losses.avg:.4f}\tAcc:{acc.avg:.4f}\tTask Acc:{task_acc.avg:.4f}\t'
            .format(epoch, batch_time=batch_time, losses=losses, acc=accuracy, task_acc=task_accuracy))
        logger.info('==> MyTest: [{0}]\tTime:{batch_time.sum:.4f}\tLoss:{losses.avg:.4f}\tAcc:{acc.avg:.4f}\tTask Acc:{task_acc.avg:.4f}\t'
            .format(epoch, batch_time=batch_time, losses=myLosses, acc=myAccuracy, task_acc=myTaskAcc))
        return accuracy.avg,myAccuracy.avg

# loader is used to give the data used to train the model
# epoch passed only for print in logger
#logger passed to log
def train(opt, loader, model, criterion, optimizer, epoch, logger,myModel,scheduler):
        model.train()
        losses, data_time, batch_time = AverageMeter(), AverageMeter(), AverageMeter()
        start = time.time()

        for inputs, labels in loader:
            actSize = inputs.shape[0]
            if(actSize != myModel.batchSize):
                continue
            # Tweak inputs
            # Input are 16(# di immagini per batch)x3x32x32
            inputs, labels = inputs.half().cuda(non_blocking=True), (labels).cuda(non_blocking=True)
            do_cutmix = opt.regularization == 'cutmix' and np.random.rand(1) < opt.cutmix_prob
            if do_cutmix: inputs, labels_a, labels_b, lam = cutmix_data(x=inputs, y=labels, alpha=opt.cutmix_alpha)
            data_time.update(time.time() - start)
            
            # Forward, backward passes then step
            # Output given by input throught the model
            outputs = model(inputs)
            myOutputs =  myModel.forward(inputs.cpu().numpy(),labels.cpu().numpy()).mean()
            loss = lam * criterion(outputs, labels_a) + (1 - lam) * criterion(outputs, labels_b) if do_cutmix else criterion(outputs, labels)
            optimizer.zero_grad()
            loss.backward()
            myModel.feedback(scheduler.get_last_lr())
            torch.nn.utils.clip_grad_norm_(model.parameters(), opt.clip) # Always be safe than sorry
            optimizer.step() # Applica modifica ai parametri in base a cross entropy loss

            # Log losses
            losses.update(loss.data.item(), labels.size(0))
            batch_time.update(time.time() - start)
            start = time.time()

        logger.info('==> Train:[{0}]\tTime:{batch_time.sum:.4f}\tData:{data_time.sum:.4f}\tLoss:{loss.avg:.4f}\t'
            .format(epoch, batch_time=batch_time, data_time=data_time, loss=losses))
        return model, optimizer


if __name__ == '__main__':
    # Parse arguments
    opt = parse_args()
    seed_everything(seed=opt.seed) # Default seed 0. Set seeds for random generator
    torch.autograd.set_detect_anomaly(True)
    # Setup logger
    console_logger = get_logger(folder=opt.log_dir+'/'+opt.exp_name+'/')
    
    # Handle fixed class orders. Note: Class ordering code hacky. Would need to manually adjust here to test for different datasets.
    console_logger.debug("==> Loading dataset..")
    class_order = [87, 0, 52, 58, 44, 91, 68, 97, 51, 15, 94, 92, 10, 72, 49, 78, 61, 14, 8, 86, 84, 96, 18, 24, 32, 45, 88, 11, 4, 67, 69, 66, 77, 47, 79, 93, 29, 50, 57, 83, 17, 81, 41, 12, 37, 59, 25, 20, 80, 73, 1, 28, 6, 46, 62, 82, 53, 9, 31, 75, 38, 63, 33, 74, 27, 22, 36, 3, 16, 21, 60, 19, 70, 90, 89, 43, 5, 42, 65, 76, 40, 30, 23, 85, 2, 95, 56, 48, 71, 64, 98, 13, 99, 7, 34, 55, 54, 26, 35, 39] #Currently testing using iCARL test order-- restricted to CIFAR100. For the other class orders refer to https://github.com/arthurdouillard/incremental_learning.pytorch/tree/master/options/data
    if opt.dataset != 'CIFAR100' and opt.dataset !='ImageNet100': class_order=None

    # Handle 'path does not exist errors' 
    if not os.path.isdir(opt.log_dir+'/'+opt.exp_name):
        os.mkdir(opt.log_dir+'/'+opt.exp_name)
    if opt.old_exp_name!='test' and not os.path.isdir(opt.log_dir+'/'+opt.old_exp_name):
        os.mkdir(opt.log_dir+'/'+opt.old_exp_name)    

    # Set pretraining and continual dataloaders
    dobj = VisionDataset(opt, class_order=class_order)
    dobj.gen_cl_mapping()

    # Scenario #1: First pretraining on n classes, then do continual learning    
    if opt.num_pretrain_classes > 0: 
        opt.num_classes = opt.num_pretrain_classes
        if opt.inp_size == 28: model = getattr(mnist, opt.model)(opt)
        if opt.inp_size == 32 or opt.inp_size == 64: model = getattr(cifar, opt.model)(opt)
        if opt.inp_size == 224: model = getattr(imagenet, opt.model)(opt)      
        
        if not os.path.isfile(opt.log_dir+opt.old_exp_name+'/pretrained_model.pth.tar'):
            console_logger.debug("==> Starting pre-training..") 
            _, model = experiment(opt=opt, class_mask=torch.ones(opt.num_classes,opt.num_classes).cuda(), train_loader=dobj.pretrain_loader, \
                                    test_loader=dobj.pretest_loader, model=model, logger=console_logger, num_passes=opt.num_pretrain_passes)
            save_model(opt, model) # Saves the pretrained model. Subsequent CL experiments directly load the pretrained model.
        else:
            model = load_model(opt, model, console_logger)
        # Reset the final block to new set of classes
        opt.num_classes = opt.num_classes_per_task*opt.num_tasks
        model.final = FinalBlock(opt, model.dim_out)
    
    # Scenario #2: Directly do continual learning from scratch
    else: 
        opt.num_classes = opt.num_classes_per_task*opt.num_tasks
        if opt.inp_size == 28: model = getattr(mnist, opt.model)(opt)
        if opt.inp_size == 32 or opt.inp_size == 64: model = getattr(cifar, opt.model)(opt)
        if opt.inp_size ==224: model = getattr(imagenet, opt.model)(opt)  
    #print("////////////////////////MODEL//////////////////////////")
    print(opt.memory_size)
    # print("///////////////////////END/////////////////////////////")
    console_logger.debug("==> Starting Continual Learning Training..")
    best_acc1, model,best_myAcc = experiment(opt=opt, class_mask=dobj.class_mask, train_loader=dobj.cltrain_loader, test_loader=dobj.cltest_loader, \
                                        model=model, logger=console_logger, num_passes=opt.num_passes)
    console_logger.debug("==> Completed!")
