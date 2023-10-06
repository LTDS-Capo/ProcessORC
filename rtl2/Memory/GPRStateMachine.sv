module GPRStateMachine #(
    parameter PENDINGREADBITWIDTH = 8
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  InstructionValid,
    input  DirtyWrite,
    input  DirtyIssue,
    input  ToRunahead,
    input  FromRunahead,
    input  WritingBack,
    input  WritingTo,
    input  ReadingFrom,

    output IsClean,
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
    //     $display("> State:PendingRead - %4b:%0d", State, PendingReadCounter);
    // end
    
//? Register State
    //*  State - Name    - Trigger       - Next                              - Next Calculation
    // 4'b0001 - Clean   - CleanTrigger  - 4'b0010 ~OR~ 4'b0100              - {1'b0, (~DirtyIssue && ToRunahead && ReadingFrom), DirtyIssue, 1'b0}
    // 4'b0010 - Dirty   - DirtyTrigger  - 4'b0001 ~OR~ 4'b0010 ~OR~ 4'b1000 - {(~DirtyWrite && DirtyIssue), 1'b0, (DirtyWrite && DirtyIssue), (DirtyWrite && ~DirtyIssue)}
    // 4'b0100 - Soiled  - SoiledTrigger - 4'b1000 ~OR~ 4'b0001              - {WritingBack, 2'b00, FromRunahead}
    // 4'b1000 - P.Write - WritingTo     - 4'b0001 ~OR~ 4'b0100              - {1'b0, PendingRead, 1'b0, ~PendingRead}
    reg   [3:0] State;
    logic [4:0] StateVector;
    wire CleanTrigger = (DirtyIssue && InstructionValid) || (ReadingFrom && ToRunahead && InstructionValid);
    wire DirtyTrigger = DirtyWrite || (WritingTo && InstructionValid);
    wire SoiledTrigger = (WritingBack && ToRunahead) || (FromRunahead && ReadingFrom && LastPendingRead && InstructionValid);
    always_comb begin : StateUpdateMux
       case (State)
            //*                     Trigger     - Next State
            4'b0001 : StateVector = {CleanTrigger,  1'b0, (~DirtyIssue && ToRunahead && ReadingFrom), DirtyIssue, 1'b0};                        // Clean
            4'b0010 : StateVector = {DirtyTrigger,  (~DirtyWrite && WritingTo), 1'b0, (DirtyWrite && DirtyIssue), (DirtyWrite && ~DirtyIssue)}; // Dirty
            4'b0100 : StateVector = {SoiledTrigger, WritingBack, 2'b00, FromRunahead};                                                          // Soiled
            4'b1000 : StateVector = {WritingTo,     1'b0, PendingRead, 1'b0, ~PendingRead};                                                     // Pending Write
            default : StateVector = 5'b1_0001;
        endcase
    end
    wire [3:0] NextState = sync_rst ? 4'h0 : StateVector[3:0];
    wire       StateTrigger = sync_rst || (clk_en && StateVector[4]);
    always_ff @(posedge clk) begin
        if (StateTrigger) begin
            State <= NextState;
        end
    end
    assign IsClean = State[0];
    assign IsDirty = State[1];
    assign HasPendingWrite = State[3];
//

//? Pending Read
    reg  [PENDINGREADBITWIDTH-1:0] PendingReadCounter;
    wire [PENDINGREADBITWIDTH-1:0] PendingReadOffset = {{PENDINGREADBITWIDTH-1{~ToRunahead}}, 1'b1};
    wire [PENDINGREADBITWIDTH-1:0] NextPendingReadCounter = sync_rst ? {PENDINGREADBITWIDTH{1'b0}} : (PendingReadCounter + PendingReadOffset);
    wire PendingReadCounterTrigger = sync_rst || (clk_en && ReadingFrom && ToRunahead && InstructionValid) || (clk_en && ReadingFrom && FromRunahead && InstructionValid);
    always_ff @(posedge clk) begin
        if (PendingReadCounterTrigger) begin
            PendingReadCounter <= NextPendingReadCounter;
        end
    end
    wire [PENDINGREADBITWIDTH-1:0] PendingReadCheck = {PENDINGREADBITWIDTH{1'b0}};
    wire                           PendingRead = PendingReadCounter != PendingReadCheck;
    wire [PENDINGREADBITWIDTH-1:0] LastPendingReadCheck = {{PENDINGREADBITWIDTH-1{1'b0}}, 1'b1};
    wire                           LastPendingRead = PendingReadCounter == LastPendingReadCheck;
//

endmodule : GPRStateMachine
