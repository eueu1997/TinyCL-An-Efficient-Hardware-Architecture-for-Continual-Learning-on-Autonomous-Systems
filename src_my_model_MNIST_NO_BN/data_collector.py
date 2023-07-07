min_memory = 5000
max_memory = 37000
memory_step = 4000
acc_list = list()
best_lr_list = list()
for memory in range(min_memory,max_memory,memory_step):
    with open(f'/home/thesis/eugenio.ressa/Desktop/GDumb/logs/CIFAR_{memory}/checkpoint.log', 'r') as f:
        last_line = f.readlines()[-1]
        start = last_line.find('[', last_line.find('[') + 1) + 1
        end = last_line.find(']', start)
        acc_list.append(last_line[start:end])
        start = last_line.find('[', start) + 1
        end = last_line.find(']', start)
        best_lr_list.append(last_line[start:end])
print("LR dynamic")
print(acc_list)
print(best_lr_list)

acc_list = list()
best_lr_list = list()
for memory in range(min_memory,max_memory,memory_step):
    with open(f'/home/thesis/eugenio.ressa/Desktop/GDumb/logs/CIFAR_{memory}_slr/checkpoint.log', 'r') as f:
        last_line = f.readlines()[-1]
        start = last_line.find('[', last_line.find('[') + 1) + 1
        end = last_line.find(']', start)
        acc_list.append(last_line[start:end])
        start = last_line.find('[', start) + 1
        end = last_line.find(']', start)
        best_lr_list.append(last_line[start:end])

print("LR static at 0.0034224487073782153")
print(acc_list)
print(best_lr_list)