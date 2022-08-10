module InstructionROM (
    input  [15:0] InstructionAddress,
    output [15:0] InstructionOut
);

    logic [15:0] NextInstruction;
    always_comb begin : NextInstructionMux
        case (InstructionAddress[8:0])
            // Register Map
            // r1: MemPointer
            // r2: Fib Value 1
            // r3: Fib Value 2
            // r4: Memory Echo
            9'h001  : NextInstruction = 16'h0170; // MOV r1 r0
            9'h002  : NextInstruction = 16'h0270; // MOV r2 r0
            9'h003  : NextInstruction = 16'hC301; // LLI r3 #01
            9'h004  : NextInstruction = 16'h0470; // MOV r4 r0
            9'h005  : NextInstruction = 16'h3251; // STW r2 r1 : LoopStart
            9'h006  : NextInstruction = 16'h3411; // LDW r4 r1
            9'h007  : NextInstruction = 16'h0111; // INC r1 r1
            9'h008  : NextInstruction = 16'h0302; // ADD r3 r2
            9'h009  : NextInstruction = 16'h3351; // STW r3 r1
            9'h00a  : NextInstruction = 16'h3411; // LDW r4 r1
            9'h00b  : NextInstruction = 16'h0111; // INC r1 r1
            9'h00c  : NextInstruction = 16'h0203; // ADD r2 r3 
            9'h00d  : NextInstruction = 16'hB005; // BZI r0 #05
            9'h00e  : NextInstruction = 16'h0000;
            9'h00f  : NextInstruction = 16'h0000;
            // 9'h1FF : Next = SOMETHING; MAX ADDRESS FOR THIS ROM!!!!!!!!!!!!!!!
            default: NextInstruction = 0; // Default is also case 0
        endcase
    end
    
    assign InstructionOut = NextInstruction;

endmodule