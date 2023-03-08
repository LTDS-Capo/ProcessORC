module RegisterStateCell (
    input clk,
    input clk_en,
    input sync_rst,

    input UsedAsA,
    input WritingToA,
    input MarkDirty,
    input UsedAsB,
    input IssuedAsA,
    input IssuedAsB,

    input LoadValid,
    input WritebackValid,

    output Dirty,
    output ToBeWritten,
    output ToBeRead
);

    // Dirty Status
        // 
        // When to Set:   
        // When to Clear: 

    //

    // To Be Written
        // 
        // When to Set:   
        // When to Clear: 

    //

    // To Be Read
        // 
        // When to Increment +1: 
        // When to Decrement:    

    //

endmodule : RegisterStateCell