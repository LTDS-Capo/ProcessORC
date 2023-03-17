module Decode0 #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    // From Fetch 1
    input        FetchedInstructionValid,
    input [15:0] FetchedInstruction,
    input        RunaheadInstructionValid,
    input [15:0] RunaheadInstruction,


    // To Stall Control
    output RegisterToBeWrittenStall,


    // To/From Speculation Control
    input CurrentlySpeculating,
    input BranchPredicted,
    input BranchMispredicted,
);



endmodule : Decode0