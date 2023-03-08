module RegisterStateCell (
    input clk,
    input clk_en,
    input sync_rst,

    input UsedAsA,
    input WillBeWritingToA,
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
        // Register will be written to by a multi-cycle operation
        // When to Set:   MultiCycle A Operand
        // When to Clear: MultiCycle Load Write
        reg  DirtyStatus;
        wire NextDirtyStatus = ~sync_rst && MarkDirty && UsedAsA && WillBeWritingToA;
        wire DirtyStatusTrigger = sync_rst || (clk_en && UsedAsA) || (clk_en && LoadValid);
        always_ff @(posedge clk) begin
            if (DirtyStatusTrigger) begin
                DirtyStatus <= NextDirtyStatus;
            end
        end
        assign Dirty = DirtyStatus;
    //

    // To Be Written
        // Register has a Pending WAR hazard in the Runahead Queue
        // When to Set:   When Pushing to Runahead Queue as A Operand
        // When to Clear: When Single Cycle Write
        reg  ToBeWrittenStatus;
        wire NextToBeWrittenStatus = (~sync_rst && UsedAsA && WillBeWritingToA && ~MarkDirty) || (~sync_rst && UsedAsA && WillBeWritingToA && MarkDirty && DirtyStatus);
        wire ToBeWrittenStatusTrigger = sync_rst || (clk_en && UsedAsA) || (clk_en && WritebackValid);
        always_ff @(posedge clk) begin
            if (ToBeWrittenStatusTrigger) begin
                ToBeWrittenStatus <= NextToBeWrittenStatus;
            end
        end
        assign ToBeWritten = ToBeWrittenStatus;
    //

    // To Be Read
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

endmodule : RegisterStateCell