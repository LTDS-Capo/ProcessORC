module InstructionROM (
    input  [15:0] InstructionAddress,
    output [15:0] InstructionOut
);

    logic [15:0] NextInstruction;
    always_comb begin : NextInstructionMux
        case (InstructionAddress[8:0])
            9'h001  : NextInstruction = 16'hC123; //  LI r1 #23
            9'h002  : NextInstruction = 16'hE185; // LUI r1 #85
            9'h003  : NextInstruction = 16'hD733; // LLI r4 #333
            9'h004  : NextInstruction = 16'hF8FF; // LNI r8 #0FF
            9'h005  : NextInstruction = 16'h900A; // JLI r0 #00A // Call
            9'h006  : NextInstruction = 16'h0616; // INC r6 r6
            9'h007  : NextInstruction = 16'h0000; // NOP
            9'h008  : NextInstruction = 16'hB000; // BZI r0 #0 
            9'h009  : NextInstruction = 16'h0000;
            9'h00a  : NextInstruction = 16'h12C4; // BSF r2 r4
            9'h00b  : NextInstruction = 16'hA00F; // BZR r0 r15 // Return
            9'h00c  : NextInstruction = 16'h0515; // INC r5 r5
            9'h00d  : NextInstruction = 16'h0000;
            9'h00e  : NextInstruction = 16'h0000;
            9'h00f  : NextInstruction = 16'h0000;
            // 9'h1FF : Next = SOMETHING; MAX ADDRESS FOR THIS ROM!!!!!!!!!!!!!!!
            default: NextInstruction = 0; // Default is also case 0
        endcase
    end
    
    assign InstructionOut = NextInstruction;

endmodule