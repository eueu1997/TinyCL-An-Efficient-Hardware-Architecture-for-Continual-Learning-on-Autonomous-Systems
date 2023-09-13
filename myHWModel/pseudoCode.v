data una lettura sequenziale dei pixel della feature dove i, j sono gli indici dei pixel dell'immagine
int addressOut_row, addressOut_colum
int addressMAC_colum,addressMAC_row

if clk then // per ora si ipotizza che gli address siano stati aggiornati. ora come ora( controllando su 0 e matrix_size) non fa convoluzione sui bordi e scende subito.tienine conto
    if addressOut_colum = 0 
        store(data = mac[addressMAC_row][0],address = [addressOut_row-3][addressOut_colum])
        store(data = mac[addressMAC_row][1],address = [addressOut_row-3][addressOut_colum+1])
        store(data = mac[addressMAC_row][2],address = [addressOut_row-3][addressOut_colum+2])
        mac[addressMAC_row][0] = load(address = [addressOut_row][0])
        mac[addressMAC_row][1] = load(address = [addressOut_row][1])
        mac[addressMAC_row][2] = load(address = [addressOut_row][2])
    else if addressOut_colum = MATRIX_SIZE
        store(data = mac[addressMAC_row][0],address = [addressOut_row-3][addressOut_colum])
        store(data = mac[addressMAC_row][1],address = [addressOut_row-3][addressOut_colum-1])
        store(data = mac[addressMAC_row][2],address = [addressOut_row-3][addressOut_colum-2])
        mac[addressMAC_row][0] = load(address = [addressOut_row][0])
        mac[addressMAC_row][1] = load(address = [addressOut_row][1])
        mac[addressMAC_row][2] = load(address = [addressOut_row][2])
    else
        if addressOut_row[0] = 0 then // positive. going right. suppose all address has been updated 
            store(data = mac[addressMAC_row][addressMAC_colum],address = [addressOut_row][addressOut_colum-3])
            store(data = mac[mod2(addressMAC_row-1)][addressMAC_colum],address = [addressOut_row-1][addressOut_colum-3])
            store(data = mac[mod2(addressMAC_row-2)][addressMAC_colum],address = [addressOut_row-2][addressOut_colum-3])
            mac[addressMAC_row][addressMAC_colum] = load(address = [addressOut_row][addressOut_colum])
            mac[mod2(addressMAC_row-1)][addressMAC_colum] = load(address = [addressOut_row-1][addressOut_colum])
            mac[mod2(addressMAC_row-2)][addressMAC_colum] = load(address = [addressOut_row-2][addressOut_colum])
        else 
            store(data = mac[addressMAC_row][addressMAC_colum],address = [addressOut_row][addressOut_colum+1])
            store(data = mac[mod2(addressMAC_row-1)][addressMAC_colum],address = [addressOut_row-1][addressOut_colum+1])
            store(data = mac[mod2(addressMAC_row-2)][addressMAC_colum],address = [addressOut_row-2][addressOut_colum+1])
            mac[addressMAC_row][addressMAC_colum] = load(address = [addressOut_row][addressOut_colum-2])
            mac[mod2(addressMAC_row-1)][addressMAC_colum] = load(address = [addressOut_row-1][addressOut_colum-2])
            mac[mod2(addressMAC_row-2)][addressMAC_colum] = load(address = [addressOut_row-2][addressOut_colum-2])
 