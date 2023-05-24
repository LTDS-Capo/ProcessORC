module RegisterStateMachine (
    input clk,
    input clk_en,
    input sync_rst,

);
    // DirtyWrite = When a multicycle operation writesback
    // DirtyIssue = Attempting to Issue a multicycle operation
    // RunaheadEn = Instruction gets sent to the runahead queue
//! Always Stall when wanting to Read or Write a PendingWrite Register

    //? When to runahead:
    // ->


//*  State - Name    - Trigger - Next                              - Next Calculation
// 4'b0001 - Clean   -         - 4'b0010 ~OR~ 4'b0100              - {1'b0, (RunaheadEn && ToBeRead && ~DirtyIssue), DirtyIssue, 1'b0}
// 4'b0010 - Dirty   -         - 4'b0001 ~OR~ 4'b0010 ~OR~ 4'b1000 - {(~DirtyWrite && DirtyIssue), 1'b0, (DirtyWrite && DirtyIssue), (DirtyWrite && ~DirtyIssue)}
// 4'b0100 - Soiled  -         - 4'b1000 ~OR~ 4'b0001              -
// 4'b1000 - P.Write -         - 4'b0001 ~OR~ 4'b0100              - {1'b0, PendingRead, 1'b0, ~PendingRead};

reg   [3:0] State;
logic [4:0] StateVector;
always_comb begin : StateUpdateMux
   case (State)
        //*                     Trigger - Next State
        4'b0001 : StateVector = {, }; // Clean
        4'b0010 : StateVector = {, }; // Dirty
        4'b0100 : StateVector = {, }; // Soiled
        4'b1000 : StateVector = {, }; // Pending Write
        default : StateVector = 5'b1_0001;
    endcase
end
wire [3:0] NextState = sync_rst ? 0 : StateVector[3:0];
wire       StateTrigger = sync_rst || (clk_en && StateVector[4]);
always_ff @(posedge clk) begin
    if (StateTrigger) begin
        State <= NextState;
    end
end


endmodule : RegisterStateMachine