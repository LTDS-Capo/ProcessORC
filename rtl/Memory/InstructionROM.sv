module InstructionROM (
    input  [15:0] InstructionAddress,
    output [15:0] InstructionOut
);
    
    logic [15:0] NextInstruction;
    always_comb begin : NextInstructionMux
        case (InstructionAddress[8:0])
            9'h000  : NextInstruction = 16'h0000;
            9'h001  : NextInstruction = 16'h0000;
            9'h002  : NextInstruction = 16'h0000;
            9'h003  : NextInstruction = 16'h0000;
            9'h004  : NextInstruction = 16'h0000;
            9'h005  : NextInstruction = 16'h0000;
            9'h006  : NextInstruction = 16'h0000;
            9'h007  : NextInstruction = 16'h0000;
            9'h008  : NextInstruction = 16'h0000;
            9'h009  : NextInstruction = 16'h0000;
            9'h00a  : NextInstruction = 16'h0000;
            9'h00b  : NextInstruction = 16'h0000;
            9'h00c  : NextInstruction = 16'h0000;
            9'h00d  : NextInstruction = 16'h0000;
            9'h00e  : NextInstruction = 16'h0000;
            9'h00f  : NextInstruction = 16'h0000;
            // 9'h1FF : Next = SOMETHING; MAX ADDRESS FOR THIS ROM!!!!!!!!!!!!!!!
            default: Next = 0; // Default is also case 0
        endcase
    end
    
    assign InstructionOut = NextInstruction;

endmodule