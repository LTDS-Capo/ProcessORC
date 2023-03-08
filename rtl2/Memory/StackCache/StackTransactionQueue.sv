module StackTransactionQueue (
    input clk,
    input clk_en,
    input sync_rst,

    output         StackDirty,
    output         StackToBeWritten,
    output         StackToBeRead,

);

    // Read Queue
    // 3bit counter to limit max in flight


    // 4bit counter to index next one hot write
    // 3x 16bit one hot vector to allocate tags from - Dirty, ToBeRead, ToBeWritten 

    
    // Read Queue
        // Address, ID

    // Write Queue
        // Value, ID


    // Speculative Rollback Queue
        // Value, Address


endmodule : StackTransactionQueue