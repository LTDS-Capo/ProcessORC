module InstructionDecoder #(
    parameter DATABITWIDTH = 16
)(
    input                     clk,
    input              [15:0] InstructionIn,
    input                     InstructionInValid,

    output                    DirtyBitTrigger,
    output              [4:0] FunctionalUnitEnable,
    output              [1:0] WritebackSource,
    output              [3:0] MinorOpcodeOut,

    output                    ImmediateEn,
    output                    UpperImmediateEn,
    output [DATABITWIDTH-1:0] ImmediateOut,

    output                    RegAReadEn,
    output                    RegAWriteEn,
    output              [3:0] RegAAddr,

    output                    RegBReadEn,
    output              [3:0] RegBAddr,

    output                    BranchStall,
    output                    RelativeEn,
    output [DATABITWIDTH-1:0] BranchOffset,
    output                    JumpEn,
    output                    JumpAndLinkEn,

    output                    HaltEn
);
    wire   [7:0] HaltingComparison = {InstructionIn[15:12], InstructionIn[7:4]}; 
    assign       HaltEn = (HaltingComparison == 8'h2F) && InstructionInValid;

    assign JumpEn = ~BranchStall && ~JumpAndLink && OperationBitVector[15];
    wire   JumpAndLink = OperationBitVector[14];
    assign JumpAndLinkEn = JumpAndLink;
    assign RelativeEn = InstructionIn[12];
    assign BranchOffset = {'0, InstructionIn[7:4], 3'b0};

    // Register Addresss Assignment
    wire   UpperAAddrEn = InstructionIn[15] && InstructionIn[12];
    assign RegAAddr = UpperAAddrEn ? {InstructionIn[11:10], 1'b0, InstructionIn[14]} : InstructionIn[11:8];

    assign RegBAddr = InstructionIn[3:0];

    // Minor Opcode Assignment
    assign MinorOpcodeOut = ImmediateEn ? 4'h7 : InstructionIn[7:4];

    // Immediate Out Assignment
    logic [DATABITWIDTH:0] ImmediateOut_tmp;
    wire [1:0] ImmediateCondition;
    assign ImmediateCondition[0] = InstructionIn[12] || JumpEn || FunctionalUnitEnable[4];
    assign ImmediateCondition[1] = InstructionIn[13] || JumpEn || FunctionalUnitEnable[4];
    wire [DATABITWIDTH-1:0] SignedImmediate = (JumpEn || FunctionalUnitEnable[4]) ? {{DATABITWIDTH-10{InstructionIn[9]}}, InstructionIn[9:0]} : {{DATABITWIDTH-10{~OperationBitVector[15]}}, InstructionIn[9:0]};
    always_comb begin : ImmediateMux
        // case (InstructionIn[13:12])
		  case (ImmediateCondition)
            2'b01  : ImmediateOut_tmp = {'0, InstructionIn[9:0]};
            2'b10  : ImmediateOut_tmp = {'0, InstructionIn[7:0], 8'h0}; 
            2'b11  : ImmediateOut_tmp =  SignedImmediate;
            default: ImmediateOut_tmp = {'0, InstructionIn[7:0]}; 
        endcase
    end
    assign ImmediateOut = ImmediateOut_tmp[DATABITWIDTH-1:0];

    // FunctionalUnitEnable One-Hot Bitmap
    // b0 - Simple ALU 0 Enable
    // b1 - Simple ALU 1 Enable
    // b2 - Complex ALU Enable
    // b3 - Memory Enable
    // b4 - Branch Enable

    // Write Back Source Bitmap
    // 00 - RESERVED
    // 01 - Program Counter + 1
    // 10 - ALU 0 (Immediate)
    // 11 - ALU 1

    logic [15:0] OperationBitVector;
    // OperationBitVector Bitmap
    // b0   - DirtyBitTrigger
    // b5:1 - FunctionalUnitEnable
    // b7:6 - WritebackSource
    // b8   - ImmediateEn
    // b9   - UpperImmediateEn
    // b10  - RegAReadEn
    // b11  - RegAWriteEn
    // b12  - RegBReadEn
    // b13  - BranchStall
    // b14  - JumpAndLink (Local for Reg A Addr)
    // b15  - PCEn (Local for Unconditional Jump Optimization)
    wire BranchStall_tmp = ~(RegAAddr == 0);
    wire [4:0] InstructionConditon = {InstructionInValid, InstructionIn[15:12]};
    always_comb begin : InstructionDecoderDecoder
        casez (InstructionConditon)
            5'b1_0000 : OperationBitVector = 16'b00_0_1_1_1_0_0_10_00001_0; // ALU O
            5'b1_0001 : OperationBitVector = 16'b00_0_1_1_1_0_0_11_00010_0; // ALU 1
            5'b1_0010 : OperationBitVector = 16'b00_0_1_0_1_0_0_00_00100_1; // Complex
            5'b1_0011 : OperationBitVector = 16'b00_0_1_0_1_0_0_00_01000_1; // Memory
            5'b1_1000 : OperationBitVector = {2'b11, 1'b1, 13'b1_1_1_0_0_01_10000_0}; // J&L Reg
            5'b1_1001 : OperationBitVector = {2'b11, 1'b1, 13'b0_1_1_0_1_01_10000_0}; // J&L Imm
            5'b1_1010 : OperationBitVector = {2'b10, BranchStall_tmp, 7'b1_0_1_0_0_00, BranchStall_tmp, 5'b0000_0}; // Branch Reg
            5'b1_1011 : OperationBitVector = {2'b10, BranchStall_tmp, 7'b0_0_1_0_1_00, BranchStall_tmp, 5'b0000_0}; // Branch Imm
            5'b1_1110 : OperationBitVector = 16'b00_0_0_1_1_1_1_10_00000_0; // Upper Immediate
            5'b1_11?? : OperationBitVector = 16'b00_0_0_1_0_0_1_10_00000_0; // Immediate
            default   : OperationBitVector = 0;
        endcase
    end
    // assign DirtyBitTrigger = OperationBitVector[0] && ~MinorOpcodeOut[3] && ~MinorOpcodeOut[2];
    assign DirtyBitTrigger = OperationBitVector[0] && (MinorOpcodeOut[3:2] != 2'b01);
    assign FunctionalUnitEnable = OperationBitVector[5:1];
    assign WritebackSource = OperationBitVector[7:6];
    assign ImmediateEn = OperationBitVector[8];
    assign UpperImmediateEn = OperationBitVector[9];
    assign RegAReadEn = OperationBitVector[10];
    assign RegAWriteEn = OperationBitVector[11];
    assign RegBReadEn = OperationBitVector[12];
    assign BranchStall = OperationBitVector[13];

endmodule