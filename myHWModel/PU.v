module PU
(

)
(
    output logic [] KernelAddr;
    input logic [0:7][(nBits-1):0] kernelVals;
    output logic [] featureInAddr;
    input logic  [0:7][(nBits-1):0] featureInVals;
    output logic [] partialSumOutAddr; // given by store command
    output logic [(nBits-1):0] partialSumOutVal; // given by store command
    output logic load;
    output logic store;
    output logic [] partialSumInAddr; // given by load command
    input logic [(nBits-1):0] partialSumInVals;
)
parameter int N_OF_MAC_ROWS = 3;
parameter int N_OF_MAC_CLMN = 3;

//TODO LIST : 
// . movimentazione kernel
// . enables mac
// . load and store

assign partialSumInLoc = (load = 0) ? (partialSum) : (partialSumInVals); // if a load is performed, load new partial sum in register



genvar i,j;
generate 
    for (i=0;i < N_OF_MAC_ROWS; i= i+1) begin 
        for(j=0;j < N_OF_MAC_CLMN; j= j+1)begin
            MAC MACij (.featureIn[0:7](featureInVals).featureIn[8](partialSumOut),,partialSum,enables[i][j]);
            register PSregister(partialSumInLoc,partialSumOut,clk,rst);
        end
    end
endgenerate
// pseudo code implementing load and store of partial sul on mac's during forwarding
// Dati l'address row e column usati per leggere da memoria feature in un pixel alla volta ( con 8 canali ) . Questo pixel andrà in piu mac
// sfruttando il fatto che, tranne che sui bordi dell'immagine, il pixel verra moltiplicato con 9 kernel
int addressOut_row, addressOut_colum
int addressMAC_colum,addressMAC_row
if clk then // per ora si ipotizza che gli address siano stati aggiornati. ora come ora( controllando su 0 e matrix_size) non fa convoluzione sui bordi e scende subito.tienine conto
    if addressOut_colum = 0 
        store(data = mac[addressMAC_row][0],address = [addressOut_row-3][0])
        store(data = mac[addressMAC_row][1],address = [addressOut_row-3][1])
        store(data = mac[addressMAC_row][2],address = [addressOut_row-3][2])
        mac[addressMAC_row][0] = load(address = [addressOut_row][0])
        mac[addressMAC_row][1] = load(address = [addressOut_row][1])
        mac[addressMAC_row][2] = load(address = [addressOut_row][2])
    else if addressOut_colum = MATRIX_SIZE
        store(data = mac[addressMAC_row][addressMAC_colum],address = [addressOut_row-3][addressOut_colum])
        store(data = mac[addressMAC_row][mod2(addressMAC_colum-1)],address = [addressOut_row-3][addressOut_colum-1])
        store(data = mac[addressMAC_row][mod2(addressMAC_colum-2)],address = [addressOut_row-3][addressOut_colum-2])
        mac[addressMAC_row][addressMAC_colum] = load(address = [addressOut_row][addressOut_colum])
        mac[addressMAC_row][mod2(addressMAC_colum-1)] = load(address = [addressOut_row][addressOut_colum-1])
        mac[addressMAC_row][mod2(addressMAC_colum-2)] = load(address = [addressOut_row][addressOut_colum-2])
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



//logic per enables dei MAC. la feature va in tutti i MAC, i kernel si muovono in sequenza, serve cmq un enable per evitare calcoli inutili in funzione di indirizzo