module ZRStateMachine #(
    parameter ZEROREGISTEREXCEPTION = 0
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  InstructionValid,
    input  DirtyWrite,
    input  DirtyIssue,
    input  WritingTo,

    output IsDirty,
    output HasPendingWrite
);

    // DirtyWrite = When a multicycle operation writesback
    // DirtyIssue = Attempting to Issue a multicycle operation
    // ToRunahead = Instruction gets sent to the Runahead Queue
    // FromRunahead = Instruction being issued comes from the Runahead Queue
    // WritingBack = Instruction is writing to this register upon commit
    // WritingTo = Any active writes to this register
    // ReadingFrom = Instruction is Reading from this register for operand use
    // LastPendingRead = Raised when Pending Read Counter equals 1
//! Always Stall when wanting to Read or Write a PendingWrite Register

    //? When to runahead:
    // -> Either Operand is Dirty
    // -> Write Operand is Soiled

    // always_ff @(posedge clk) begin
    //     $display("> State - %4b", State);
    // end
    
//? Register State
    //*  State - Name    - Trigger      - Next
    // 4'b001 - Clean   - CleanTrigger  - 3'b010      
    // 4'b010 - Dirty   - DirtyTrigger  - 3'b100 OR 3'b010 OR 3'b001
    // 4'b100 - P.Write - WritingTo     - 4'b000
    reg   [2:0] State;
    logic [3:0] StateVector;
    wire CleanTrigger = (DirtyIssue && InstructionValid);
    wire DirtyTrigger = DirtyWrite || (WritingTo && InstructionValid);
    always_comb begin : StateUpdateMux
       case (State)
            //*                     Trigger     - Next State
            3'b001 : StateVector = {CleanTrigger,  3'b010};                                                                               // Clean
            3'b010 : StateVector = {DirtyTrigger,  (~DirtyWrite && WritingTo), (DirtyWrite && DirtyIssue), (DirtyWrite && ~DirtyIssue)}; // Dirty
            3'b100 : StateVector = {WritingTo,     3'b000};                                                                               // Pending Write
            default : StateVector = 4'b1_001;
        endcase
    end
    wire [2:0] NextState = sync_rst ? 3'h0 : StateVector[2:0];
    wire       StateTrigger = sync_rst || (clk_en && StateVector[3]);
    always_ff @(posedge clk) begin
        if (StateTrigger) begin
            State <= NextState;
        end
    end
    assign IsDirty = State[1];
    assign HasPendingWrite = State[2];
//

endmodule : ZRStateMachine