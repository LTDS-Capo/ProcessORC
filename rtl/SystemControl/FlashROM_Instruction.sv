module FlashROM_Instruction (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)
            //                  Instruction
            10'h001 : TempValue = 16'h0000;
            10'h002 : TempValue = 16'h0000;
            10'h003 : TempValue = 16'h0000;
            10'h004 : TempValue = 16'h0000;
            10'h005 : TempValue = 16'h0000;
            10'h006 : TempValue = 16'h0000;
            10'h007 : TempValue = 16'h0000;
            10'h008 : TempValue = 16'h0000;
            10'h009 : TempValue = 16'h0000;
            10'h00a : TempValue = 16'h0000;
            10'h00b : TempValue = 16'h0000;
            10'h00c : TempValue = 16'h0000;
            10'h00d : TempValue = 16'h0000;
            10'h00e : TempValue = 16'h0000;
            10'h00f : TempValue = 16'h0000;
            default : TempValue = 16'h0000;
        endcase
    end
    assign Value = TempValue;

endmodule