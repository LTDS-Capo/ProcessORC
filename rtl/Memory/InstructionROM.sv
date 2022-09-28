module InstructionROM (
    input  [15:0] InstructionAddress,
    output [15:0] InstructionOut
);

    logic [15:0] NextInstruction;
    always_comb begin : NextInstructionMux
        case (InstructionAddress[8:0])
            9'd001 : NextInstruction = 16'hb00e; //call main
            9'd002 : NextInstruction = 16'h0000; //print:
            9'd003 : NextInstruction = 16'h0000; //hlt:
            9'd004 : NextInstruction = 16'h0000; //hlt:
            9'd005 : NextInstruction = 16'hb005; //call hlt
            9'd006 : NextInstruction = 16'h0000; //nop
            9'd007 : NextInstruction = 16'h0000; //foo:
            9'd008 : NextInstruction = 16'hc100; //set r1 0
            9'd009 : NextInstruction = 16'h010d; //r1 += r13
            9'd010 : NextInstruction = 16'h010c; //r1 += r12
            9'd011 : NextInstruction = 16'h0e71; //add r14, r13, r12
            9'd012 : NextInstruction = 16'hb005; //call hlt
            9'd013 : NextInstruction = 16'h0000; //nop
            9'd014 : NextInstruction = 16'h0000; //main:
            9'd015 : NextInstruction = 16'hcd07; //mov r13, #7
            9'd016 : NextInstruction = 16'hcc0b; //mov r12, #11
            9'd017 : NextInstruction = 16'hb008; //call foo
            9'd018 : NextInstruction = 16'h0000; //nop
            9'd019 : NextInstruction = 16'h0d7e; //mov r13, r14
            9'd020 : NextInstruction = 16'hb003; //call print
            9'd021 : NextInstruction = 16'h0000; //nop
            //9'h1FF : Next = SOMETHING; MAX ADDRESS FOR THIS ROM!!!!!!!!!!!!!!!
            default: NextInstruction = 0; // Default is also case 0
        endcase
    end
    
    assign InstructionOut = NextInstruction;

endmodule