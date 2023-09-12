data una lettura sequenziale dei pixel della feature dove i, j sono gli indici dei pixel dell'immagine
int addressOut_row, addressOut_colum
int addressMAC_colum,addressMAC_row

if clk then
    if addressOut_colum = 0 
        store(data = mac[addressMAC_row][addressMAC_colum],address = [addressOut_row-2][addressOut_colum-3])
        store(data = mac[addressMAC_row][addressMAC_colum],address = [addressOut_row-1][addressOut_colum-3])
        store(data = mac[addressMAC_row][addressMAC_colum],address = [addressOut_row][addressOut_colum-3])
        mac[addressMAC_row][0] = load(address = [addressOut_row][0])
        mac[addressMAC_row][1] = load(address = [addressOut_row][1])
        mac[addressMAC_row][2] = load(address = [addressOut_row][2])
    else if addressOut_colum = MATRIX_SIZE

    else
        if addressOut_row[0] = 0 then // positive. going right. suppose all address has been updated 
            store(data = mac[0][addressMAC_colum],address = [addressOut_row-2][addressOut_colum-3])
            store(data = mac[1][addressMAC_colum],address = [addressOut_row-1][addressOut_colum-3])
            store(data = mac[2][addressMAC_colum],address = [addressOut_row][addressOut_colum-3])
            mac[2][addressMAC_colum] = load(address = [addressOut_row][addressOut_colum])
            mac[1][addressMAC_colum] = load(address = [addressOut_row-1][addressOut_colum])
            mac[0][addressMAC_colum] = load(address = [addressOut_row-2][addressOut_colum])
        else 
            store(data = mac[0][addressMAC_colum],address = [addressOut_row-2][addressOut_colum+1])
            store(data = mac[1][addressMAC_colum],address = [addressOut_row-1][addressOut_colum+1])
            store(data = mac[2][addressMAC_colum],address = [addressOut_row][addressOut_colum+1])
            mac[2][addressMAC_colum] = load(address = [addressOut_row][addressOut_colum-2])
            mac[1][addressMAC_colum] = load(address = [addressOut_row-1][addressOut_colum-2])
            mac[0][addressMAC_colum] = load(address = [addressOut_row-2][addressOut_colum-2])
 