module ProgramCounter #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                     PCEn,
    input                     StallEn,

    input                     BranchEn,
    input  [DATABITWIDTH-1:0] ComparisonValue,
    input  [DATABITWIDTH-1:0] BranchDest,

    input                     JumpEn,
    input  [DATABITWIDTH-1:0] JumpDest,

    output [DATABITWIDTH-1:0] InstructionAddrOut,
    output [DATABITWIDTH-1:0] JumpAndLinkAddrOut
);

    reg    [DATABITWIDTH-1:0] ProgramCounter;
    wire                      AEqualsZero = ComparisonValue == 0;
    wire                      ProgramCounterTrigger = (JumpEn && PCEn && ~StallEn && clk_en) || (AEqualsZero && BranchEn && PCEn && ~StallEn && clk_en) || (~BranchEn && PCEn && ~StallEn && clk_en) || sync_rst;
    logic  [DATABITWIDTH-1:0] NextProgramCounter;
    wire   [DATABITWIDTH-1:0] ProgramCounterPlusOne = ProgramCounter + 1;
    wire   [1:0] NextPCCondition;
    assign       NextPCCondition[0] = ~JumpEn && PCEn && ~sync_rst;
    assign       NextPCCondition[1] = (JumpEn || BranchEn) && ~sync_rst;
    always_comb begin : NextRegMux
        case (NextPCCondition)
            2'b01  : NextProgramCounter = ProgramCounterPlusOne;
            2'b10  : NextProgramCounter = JumpDest;
            2'b11  : NextProgramCounter = BranchDest;
            default: NextProgramCounter = '0; // Default is also case 0
        endcase
    end
    always_ff @(posedge clk) begin
        if (ProgramCounterTrigger) begin
            ProgramCounter <= NextProgramCounter;
        end
    end
    
    assign InstructionAddrOut = ProgramCounter;
    assign JumpAndLinkAddrOut = ProgramCounterPlusOne;

    // Debug
        always_ff @(posedge clk) begin
            $display("NextPCCondition - %0h", NextPCCondition);
        end
    //

endmodule