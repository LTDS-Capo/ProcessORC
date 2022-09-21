module FlashROM_Instruction (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)
            //                   Instruction
            10'h000 : TempValue = 16'hE180;
            10'h001 : TempValue = 16'hC301;
            10'h002 : TempValue = 16'hC602;
            // Clock 4;
            10'h003 : TempValue = 16'h0473;
            10'h004 : TempValue = 16'h0442;
            10'h005 : TempValue = 16'hB402;
            10'h006 : TempValue = 16'h1243;
            10'h007 : TempValue = 16'h3715;
            10'h008 : TempValue = 16'h1751;
            10'h009 : TempValue = 16'h0106;
            // Clock 5;
            10'h00A : TempValue = 16'h0473;
            10'h00B : TempValue = 16'h0442;
            10'h00C : TempValue = 16'hB402;
            10'h00D : TempValue = 16'h1243;
            10'h00E : TempValue = 16'h3715;
            10'h00F : TempValue = 16'h1751;
            10'h010 : TempValue = 16'h0106;
            // Clock 6;
            10'h011 : TempValue = 16'h0473;
            10'h012 : TempValue = 16'h0442;
            10'h013 : TempValue = 16'hB402;
            10'h014 : TempValue = 16'h1243;
            10'h015 : TempValue = 16'h3715;
            10'h016 : TempValue = 16'h1751;
            10'h017 : TempValue = 16'h0106;
            // Clock 7;
            10'h018 : TempValue = 16'h0473;
            10'h019 : TempValue = 16'h0442;
            10'h01A : TempValue = 16'hB402;
            10'h01B : TempValue = 16'h1243;
            10'h01C : TempValue = 16'h3715;
            10'h01D : TempValue = 16'h1751;
            // 10'h01E : TempValue = A00F // Return
            10'h01E : TempValue = 16'h20F0; // HALT
            default : TempValue = 16'h0000;
        endcase
    end
    assign Value = TempValue;

endmodule