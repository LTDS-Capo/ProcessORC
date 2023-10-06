module InstructionDecoder_pORC2 #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                     FetchedInstructionValid,
    input              [15:0] FetchedInstruction,
    output             [15:0] MajorOpcodeVector,
    output              [3:0] MinorOpcode,

    output                    BranchEnable,
    
    output              [3:0] OperandAAddr,
    output                    ReadingFromA,
    output                    WillBeWritingToA,
    output                    MarkADirty,
    output              [3:0] OperandBAddr,
    output                    ReadingFromB,
    output [DATABITWIDTH-1:0] ImmediateOut
);

    // Opcode Decoder
        logic [15:0] DecodedMajorOpcode;
        always_comb begin
            DecodedMajorOpcode = 0;
            DecodedMajorOpcode[FetchedInstruction[15:12]] = 1'b1;
        end
        assign MajorOpcodeVector = DecodedMajorOpcode;
        assign MinorOpcode = FetchedInstruction[7:4];
        assign BranchEnable = (FetchedInstruction[15] && ~FetchedInstruction[14]) || MinorOpcodeVector[17]; // Branch, J&L, ECall, EBreak, XReturn
    //

    // Immediate Generation
        logic    [DATABITWIDTH:0] TempImmediate;
        wire   [DATABITWIDTH-8:0] ImmediatePad8Bit = 0;
        wire                [7:0] UpperImmediateLowerPad = 0;
        wire  [DATABITWIDTH-16:0] UpperImmediateUpperPad = 0;
        wire  [DATABITWIDTH-10:0] BranchSignPad = {DATABITWIDTH-9{FetchedInstruction[9]}};
        wire  [DATABITWIDTH-10:0] Unsigned10BitPadd = 0;
        wire  [DATABITWIDTH-10:0] Negative10BitPadd = {DATABITWIDTH-9{1'b1}};
        always_comb begin : TempImmediateMux
            case (FetchedInstruction[14:12])
                3'b000 : TempImmediate = 0; //! Not Used
                3'b001 : TempImmediate = {BranchSignPad, FetchedInstruction[9:0]}; // JLI Relative
                3'b010 : TempImmediate = 0; //! Not Used
                3'b011 : TempImmediate = {BranchSignPad, FetchedInstruction[9:0]}; // BZI Relative
                3'b100 : TempImmediate = {ImmediatePad8Bit, FetchedInstruction[7:0]}; // Load Lower
                3'b101 : TempImmediate = {Unsigned10BitPadd, FetchedInstruction[9:0]}; // Load Unsigned Extended
                3'b110 : TempImmediate = {UpperImmediateUpperPad, FetchedInstruction[7:0], UpperImmediateLowerPad}; // Load Upper
                3'b111 : TempImmediate = {Negative10BitPadd, FetchedInstruction[9:0]}; // Load Negative
                default: TempImmediate = 0;
            endcase
        end
        assign ImmediateOut = TempImmediate[DATABITWIDTH-1:0];
    //

    // Operand Operation
        // Simple1, Simple0
        // > [2:0] WriteA, ReadA, ReadB
        // Memory, Complex
        // > [3:0] MarkADirty, WriteA, ReadA, ReadB
        // Priv
        // > [4:0] BranchEnable, MarkADirty, WriteA, ReadA, ReadB
        logic [17:0] MinorOpcodeVector;
        always_comb begin : Simple0OperandVectorMux
            case (MinorOpcode)
                //*                           Priv,         Memory,     Complex,    Simple1,  Simple0     - Privileged,           Memory,             Complex,    Simple1,           Simple0
                4'h0   : MinorOpcodeVector = {5'b1_0_0_0_0, 4'b1_1_0_1, 3'b1_1_1, 3'b1_1_1, 3'b1_1_1}; // ECall,                Load Byte,          Mult Lower, Bit Set,           Add
                4'h1   : MinorOpcodeVector = {5'b1_0_0_0_0, 4'b1_1_0_1, 3'b1_1_1, 3'b1_1_1, 3'b1_0_1}; // EBreak,               Load Word,          Mult Upper, Bit Clear,         Inc
                4'h2   : MinorOpcodeVector = {5'b1_0_0_1_0, 4'b1_1_0_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // XReturn,              Load Double,        Reserved,   Bit Flip,          Sub
                4'h3   : MinorOpcodeVector = {5'b0_0_0_0_0, 4'b1_1_0_1, 3'b0_0_0, 3'b1_1_1, 3'b1_0_1}; // Reserved,             Load Quad,          Reserved,   Bit Select,        Dec
                4'h4   : MinorOpcodeVector = {5'b0_1_1_0_1, 4'b0_0_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // CSR Load,             Store Byte,         Reserved,   Shift Right,       AND
                4'h5   : MinorOpcodeVector = {5'b0_1_1_0_1, 4'b0_0_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // CSR Load Upper,       Store Word,         Reserved,   Rotate Right,      XOR
                4'h6   : MinorOpcodeVector = {5'b0_1_1_1_1, 4'b0_0_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // CSR Swap,             Store Double,       Reserved,   Arithmetic Right,  OR
                4'h7   : MinorOpcodeVector = {5'b0_1_1_1_1, 4'b0_0_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_0_1}; // CSR Swap Upper,       Store Quad,         Reserved,   Shift Left,        Move
                4'h8   : MinorOpcodeVector = {5'b0_1_1_0_1, 4'b1_1_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // Stack Pick,           Atomic Load Byte,   Reserved,   Compare GTES,      Carry Check
                4'h9   : MinorOpcodeVector = {5'b0_0_0_1_1, 4'b1_1_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // Stack Place,          Atomic Load Word,   Reserved,   Compare LTS,       Implies
                4'hA   : MinorOpcodeVector = {5'b0_1_1_0_1, 4'b1_1_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // Swap Stack Pointer,   Atomic Load Double, Reserved,   Compare GTEU,      Borrow Check
                4'hB   : MinorOpcodeVector = {5'b0_0_0_0_0, 4'b1_1_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_1_1}; // Stack Pointer Modify, Atomic Load Quad,   Reserved,   Compare LTU,       Overflow Check
                4'hC   : MinorOpcodeVector = {5'b0_0_0_0_0, 4'b1_1_1_1, 3'b0_0_0, 3'b1_0_1, 3'b1_1_1}; // Reserved,             Status Load Byte,   Reserved,   Bit Scan Forward,  NAND
                4'hD   : MinorOpcodeVector = {5'b0_0_0_0_0, 4'b1_1_1_1, 3'b0_0_0, 3'b1_0_1, 3'b1_1_1}; // Fence,                Status Load Word,   Reserved,   Bit Scan Backward, XNOR
                4'hE   : MinorOpcodeVector = {5'b0_0_0_0_0, 4'b1_1_1_1, 3'b0_0_0, 3'b1_0_1, 3'b1_1_1}; // Software Reset,       Status Load Double, Reserved,   Reverse B,         NOR
                4'hF   : MinorOpcodeVector = {5'b0_0_0_0_0, 4'b1_1_1_1, 3'b0_0_0, 3'b1_1_1, 3'b1_0_1}; // Halt,                 Status Load Quad,   Reserved,   Compare Equal,     NOT B
                default: MinorOpcodeVector = 0;
            endcase
        end
        logic [3:0] MajorOpcodeOperandVector;
        always_comb begin : MajorOpcodeOperandVectorMux
            case (FetchedInstruction[15:12])
                4'h0   : MajorOpcodeOperandVector = {1'b0, MinorOpcodeVector[2:0]};   // Simple 0
                4'h1   : MajorOpcodeOperandVector = {1'b0, MinorOpcodeVector[5:3]};   // Simple 1
                4'h2   : MajorOpcodeOperandVector = {1'b1, MinorOpcodeVector[8:6]};   // Complex
                4'h3   : MajorOpcodeOperandVector = MinorOpcodeVector[12:9];          // Memory
                4'h4   : MajorOpcodeOperandVector = 4'b0_1_0_0;                       // Load Shifted Byte
                4'h5   : MajorOpcodeOperandVector = 4'b0_0_0_0;                       // - Reserved
                4'h6   : MajorOpcodeOperandVector = MinorOpcodeVector[16:13];         // Privileged
                4'h7   : MajorOpcodeOperandVector = 4'b0_0_0_0;                       // - Reserved
                4'h8   : MajorOpcodeOperandVector = 4'b0_0_1_1;                       // Jump and Link Register
                4'h9   : MajorOpcodeOperandVector = 4'b0_0_1_0;                       // Jump and Link Relative
                4'hA   : MajorOpcodeOperandVector = 4'b0_0_1_1;                       // Branch If0 Register
                4'hB   : MajorOpcodeOperandVector = 4'b0_0_1_0;                       // Branch If0 Relative
                4'hC   : MajorOpcodeOperandVector = 4'b0_1_0_0;                       // Load Unsigned Lower Immediate
                4'hD   : MajorOpcodeOperandVector = 4'b0_1_0_0;                       // Load Unsigned Extended Immediate
                4'hE   : MajorOpcodeOperandVector = 4'b0_1_0_0;                       // Load Upper Immediate
                4'hF   : MajorOpcodeOperandVector = 4'b0_1_0_0;                       // Load Negative Extended Immediate
                default: MajorOpcodeOperandVector = 0;
            endcase
        end
        assign ReadingFromA = MajorOpcodeOperandVector[1];
        assign WillBeWritingToA = MajorOpcodeOperandVector[2];
        assign MarkADirty = MajorOpcodeOperandVector[3];
        assign OperandAAddr = (FetchedInstruction[15] && FetchedInstruction[12]) ? {FetchedInstruction[11:10], 1'b0, FetchedInstruction[14]} : FetchedInstruction[11:8];
        assign ReadingFromB = MajorOpcodeOperandVector[0];
        assign OperandBAddr = FetchedInstruction[3:0];
    //


endmodule : InstructionDecoder_pORC2
