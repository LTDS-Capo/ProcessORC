module LoadStoreUnit #(
    parameter DATABITWIDTH = 16,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    output                       LoadStore_REQ,
    input                        LoadStore_ACK,
    input                  [3:0] LoadStore_MinorOpcode,
    input     [DATABITWIDTH-1:0] LoadStore_MemoryAddress,
    input     [DATABITWIDTH-1:0] LoadStore_StoreValue,
    input  [REGADDRBITWIDTH-1:0] LoadStore_DestinationRegister,


    input                        IOManager_REQ,
    output                       IOManager_ACK,
    output                 [3:0] IOManager_MinorOpcode,
    output    [DATABITWIDTH-1:0] IOManager_MemoryAddress,
    output    [DATABITWIDTH-1:0] IOManager_StoreValue,
    output [REGADDRBITWIDTH-1:0] IOManager_DestinationRegister,

    input                        Cache_REQ,
    output                       Cache_ACK,
    output                 [3:0] Cache_MinorOpcode,
    output    [DATABITWIDTH-1:0] Cache_MemoryAddress,
    output    [DATABITWIDTH-1:0] Cache_StoreValue,
    output [REGADDRBITWIDTH-1:0] Cache_DestinationRegister,

    input                        FixedMemory_REQ,
    output                       FixedMemory_ACK,
    output                 [3:0] FixedMemory_MinorOpcode,
    output    [DATABITWIDTH-1:0] FixedMemory_MemoryAddress,
    output    [DATABITWIDTH-1:0] FixedMemory_StoreValue,
    output [REGADDRBITWIDTH-1:0] FixedMemory_DestinationRegister

);

    // MemoryAddress Generation
        wire [DATABITWIDTH-1:0] MemoryAddress = LoadStore_MemoryAddress;
    //

    // PortSel Generation
        wire CacheSel = MemoryAddress > 1023;
        wire IOSel = (MemoryAddress < 512) && (MemoryAddress > 383);
        wire [1:0] PortSel = {CacheSel, IOSel};
    //

    // Input Handshake
        logic [3:0] ACKMask;
        always_comb begin : ACKMaskGen
            ACKMask = 0;
            ACKMask[PortSel] = LoadStore_ACK;
        end
        logic LoadStore_REQ_Tmp;
        always_comb begin : LoadStore_REQMux
            case (PortSel)
                2'b01  : LoadStore_REQ_Tmp = IOManager_REQ;
                2'b10  : LoadStore_REQ_Tmp = Cache_REQ;
                2'b11  : LoadStore_REQ_Tmp = 1'b0;
                default: LoadStore_REQ_Tmp = FixedMemory_REQ; // Default is also case 0
            endcase
        end
        assign LoadStore_REQ = LoadStore_REQ_Tmp;
    //

    // IOManager
        assign IOManager_ACK = ACKMask[1];
        assign IOManager_MinorOpcode = LoadStore_MinorOpcode;
        assign IOManager_MemoryAddress = LoadStore_MemoryAddress;
        assign IOManager_StoreValue = LoadStore_StoreValue;
        assign IOManager_DestinationRegister = LoadStore_DestinationRegister;
    //

    // Cache
        assign Cache_ACK = ACKMask[2];
        assign Cache_MinorOpcode = LoadStore_MinorOpcode;
        assign Cache_MemoryAddress = LoadStore_MemoryAddress;
        assign Cache_StoreValue = LoadStore_StoreValue;
        assign Cache_DestinationRegister = LoadStore_DestinationRegister;
    //

    // FixedMemory
        assign FixedMemory_ACK = ACKMask[0];
        assign FixedMemory_MinorOpcode = LoadStore_MinorOpcode;
        assign FixedMemory_MemoryAddress = LoadStore_MemoryAddress;
        assign FixedMemory_StoreValue = LoadStore_StoreValue;
        assign FixedMemory_DestinationRegister = LoadStore_DestinationRegister;
    //

endmodule