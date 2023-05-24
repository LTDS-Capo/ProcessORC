module RegisterState_Cell (
    input clk,
    input clk_en,
    input sync_rst,

    input InstructionIsARunahead,

    input UsedAsA,
    input WillBeWritingToA,
    input MarkDirty,

    input UsedAsB,
    input IssuedAsA,
    input IssuedAsB,
    input DirtyB,

    input LoadValid,
    input WritebackValid,

    output Dirty,
    output ToBeWritten,
    output ToBeRead
);


//? State Machine
//! Requirements:
// -> Two deep write Hazard protection

// Pending Read         - Count of how many instructions are in the RunAheadQueue that are reading from a given operand
// Dirty                - Operand has a currently In-Flight instruction that is writing back to it
// Pending Write Hazard - Operand has pending operations AND a Pending Write in the RunAhead Queue


//? Situations
//* WaWaW Hazard
// -> Add  2 4 -   - Stalls on 2:PendingWrite
// -> Sub  4 5 -   - Allowed to Execute
// -> Add  2 3 - r - 2:PendingWrite
// -> Load 2 1 -   - 2:Dirty

//* WaWaR Hazard
// -> Add  2 4 - r - 2:PendingWrite
// -> Sub  4 5 -   - Allowed to Execute
// -> Load 2 3 -   - 2:Dirty
// -> Add  1 2 -   - Allowed to Execute

//* WaRaW Hazard
// -> Load 3 6 -   - 3:Dirty
// -> Add  2 3 -   - Stalled on 2:PendingWrite, 3:++PendingRead
// -> Add  2 4 - r - 2:PendingWrite AND ++PendingRead, 4:++PendingRead
// -> Sub  4 5 -   - Allowed to Execute
// -> Add  3 2 - r - 3:Soiled, 2:++PendingRead
// -> Load 2 1 -   - 2:Dirty

//* WaRaR Hazard
// -> Load 3 4
// -> Add  2 3
// -> Add  1 3

//* RaWaW Hazard

//* RaWaR Hazard

//* RaRaW Hazard

//* RaRaR Hazard



























    // Dirty Status
        //TODO:
        // Register will be written to by a multi-cycle operation
        // When to Set:   MultiCycle A Operand ~OR~ (A Operand when Reading a Dirty B WHILE A Operand is NOT ToBeRead)
        // When to Clear: All Write
        reg  DirtyStatus;
        wire NextDirtyStatus = ~sync_rst && MarkDirty && UsedAsA && WillBeWritingToA;
        wire DirtyStatusTrigger = sync_rst || (clk_en && UsedAsA) || (clk_en && LoadValid);
        // wire NextDirtyStatus = ~sync_rst && MarkDirty && UsedAsA && WillBeWritingToA;
        // wire DirtyStatusTrigger = sync_rst || (clk_en && UsedAsA) || (clk_en && LoadValid);
        always_ff @(posedge clk) begin
            if (DirtyStatusTrigger) begin
                DirtyStatus <= NextDirtyStatus;
            end
        end
        assign Dirty = DirtyStatus;
    //

    // Soiled Status 
        // Only used Locally for a ToBeWritten Check along side Dirty.... 
        // Covers operands that are ToBeRead but are used as a Write Operand... Prevents Dead Lock
        //* NOTE 0: If an instruction has a MarkDirtyFlag AND the operand is ToBeRead... DO NOT mark dirty, Mark Soiled....
        //* -> The above note covers the use case where you have Load to a ToBeRead Operand, and the Load gets pushed to the Runahead Queue...
        //*    If the Load is allowed to be marked Dirty... it will deadlock the system when it reaches the head of the Runahead Queue.
        //! NOTE 1: If an operands Soiled status is set to 1, and the incoming instruction is a Runahead instruction,
        //! -> Allow it to proceed WITHOUT marking the operand ToBeWritten 

    // To Be Written
        //TODO:
        // Register has a Pending WAR hazard in the Runahead Queue
        // When to Set:   When Pushing an instruction with a Dirty Write A Operand -OR- Pushing an Instruction with a ToBeRead Write A Operand
        // When to Clear: When A Operand is written to.
        reg  ToBeWrittenStatus;
        wire NextToBeWrittenStatus = ~sync_rst && ~WritebackValid && ~LoadValid && DirtyStatus && WillBeWritingToA;
        wire ToBeWrittenStatusTrigger = sync_rst || (clk_en && WritebackValid) || (clk_en && WritebackValid) || (clk_en && WillBeWritingToA);
        always_ff @(posedge clk) begin
            if (ToBeWrittenStatusTrigger) begin
                ToBeWrittenStatus <= NextToBeWrittenStatus;
            end
        end
        assign ToBeWritten = ToBeWrittenStatus;
    //

    // To Be Read
        //TODO:
        //! Need to refactor to only count when an instruction is actually going to the runahead queue
        // Register has a Pending RAW hazard in the Runahead Queue
        // When to Increment +1: A Operand and B Operand, respectively 
        // When to Decrement:    Instruction Has Issued using Register as A or B Operand
        reg    [3:0] ToBeReadCounter;
        logic  [3:0] NextToBeReadCounter;
        wire   [1:0] NextToBeReadCounterCondition;
        assign       NextToBeReadCounterCondition[0] = (UsedAsA || UsedAsB) && ~sync_rst;
        assign       NextToBeReadCounterCondition[1] = (IssuedAsA || IssuedAsB) && ~sync_rst;
        always_comb begin : NextToBeReadCounterMux
            case (NextToBeReadCounterCondition)
                2'b00  : NextToBeReadCounter = 4'b0; // Default sync_rst output
                2'b01  : NextToBeReadCounter = ToBeReadCounter + 1;
                2'b10  : NextToBeReadCounter = ToBeReadCounter - 1;
                2'b11  : NextToBeReadCounter = ToBeReadCounter;
                default: NextToBeReadCounter = 4'b0;
            endcase
        end
        wire       ToBeReadTrigger = sync_rst || (clk_en && UsedAsA) || (clk_en && UsedAsB) || (clk_en && IssuedAsA) || (clk_en && IssuedAsB);
        always_ff @(posedge clk) begin
            if (ToBeReadTrigger) begin
                ToBeReadCounter <= NextToBeReadCounter;
            end
        end
        reg  ToBeReadStatus;
        logic  NextToBeReadStatus;
        wire   [1:0] NextToBeReadStatusCondition;
        assign       NextToBeReadStatusCondition[0] = (IssuedAsA || IssuedAsB) && ~sync_rst;
        wire                 ToBeReadCounterNotZero = |ToBeReadCounter;
        assign       NextToBeReadStatusCondition[1] = ToBeReadCounterNotZero && ~sync_rst;
        always_comb begin : Mux
            case (NextToBeReadStatusCondition)
                2'b00  : NextToBeReadStatus = ~sync_rst; // Default sync_rst output
                2'b01  : NextToBeReadStatus = UsedAsA || UsedAsB;
                2'b10  : NextToBeReadStatus = 1'b1;
                2'b11  : NextToBeReadStatus = UsedAsA || UsedAsB;
                default: NextToBeReadStatus = 1'b0;
            endcase
        end
        always_ff @(posedge clk) begin
            if (ToBeReadTrigger) begin
                ToBeReadStatus <= NextToBeReadStatus;
            end
        end
        assign ToBeRead = ToBeReadStatus;
    //

endmodule : RegisterState_Cell