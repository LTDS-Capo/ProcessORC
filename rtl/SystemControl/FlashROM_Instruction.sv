module FlashROM_Instruction (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)

            10'h000 : TempValue = 16'hD188;
            10'h001 : TempValue = 16'hC220;
            10'h002 : TempValue = 16'hC300;
            10'h003 : TempValue = 16'hE380;
            10'h004 : TempValue = 16'h3251;
            10'h005 : TempValue = 16'h0111;
            10'h006 : TempValue = 16'h0111;
            10'h007 : TempValue = 16'h3351;
            10'h008 : TempValue = 16'h3411;
            10'h009 : TempValue = 16'h0074;
            10'h00A : TempValue = 16'hB3FD;

            // GPIO Fib Test
            // 10'h000 : TempValue = 16'hD18C;
            // 10'h001 : TempValue = 16'hD988;
            // 10'h002 : TempValue = 16'h0270;
            // 10'h003 : TempValue = 16'h0470;
            // 10'h004 : TempValue = 16'hC505;
            // 10'h005 : TempValue = 16'hC720;
            // 10'h006 : TempValue = 16'hE7BC;
            // 10'h007 : TempValue = 16'hC8BE;
            // 10'h008 : TempValue = 16'hC880;
            // 10'h009 : TempValue = 16'h3759;
            // 10'h00A : TempValue = 16'h0919;
            // 10'h00B : TempValue = 16'h0A70;
            // 10'h00C : TempValue = 16'hEA04;
            // 10'h00D : TempValue = 16'hCBFF;
            // // Display Counter [Starts at 0]
            // 10'h00E : TempValue = 16'h067B; // :LOOP_START
            // 10'h00F : TempValue = 16'h0642;
            // 10'h010 : TempValue = 16'h066A;
            // 10'h011 : TempValue = 16'h3651;
            // 10'h012 : TempValue = 16'h0212;
            // 10'h013 : TempValue = 16'h9014; // [+20] Aliased (LEI rD :TIMER_WAIT, JLR r0 rD) or (JLI r0 [Relative to :TIMER_WAIT])
            // // First Fib
            // 10'h014 : TempValue = 16'h067B;
            // 10'h015 : TempValue = 16'h0644;
            // 10'h016 : TempValue = 16'h066A;
            // 10'h017 : TempValue = 16'h3651;
            // 10'h018 : TempValue = 16'h0212;
            // 10'h019 : TempValue = 16'h900E; // [+14] Aliased (LEI rD :TIMER_WAIT, JLR r0 rD) or (JLI r0 [Relative to :TIMER_WAIT])
            // // Display Counter
            // 10'h01A : TempValue = 16'h067B;
            // 10'h01B : TempValue = 16'h0642;
            // 10'h01C : TempValue = 16'h066A;
            // 10'h01D : TempValue = 16'h3651;
            // 10'h01E : TempValue = 16'h0212;
            // 10'h01F : TempValue = 16'h9008; //  [+8] Aliased (LEI rD :TIMER_WAIT, JLR r0 rD) or (JLI r0 [Relative to :TIMER_WAIT])
            // // Second Fib
            // 10'h020 : TempValue = 16'h067B;
            // 10'h021 : TempValue = 16'h0645;
            // 10'h022 : TempValue = 16'h066A;
            // 10'h023 : TempValue = 16'h3651;
            // 10'h024 : TempValue = 16'h0212;
            // 10'h025 : TempValue = 16'h9002; //  [+2] Aliased (LEI rD :TIMER_WAIT, JLR r0 rD) or (JLI r0 [Relative to :TIMER_WAIT])
            // 10'h026 : TempValue = 16'hB3DC; // [-24] LOOP_START
            // // Timer Wait
            // 10'h027 : TempValue = 16'h3859; // :TIMER_WAIT
            // 10'h028 : TempValue = 16'h3E19;
            // 10'h029 : TempValue = 16'h007E;
            // 10'h02A : TempValue = 16'hA00F;

            // Clock Config Test
            // //                   Instruction
            // 10'h000 : TempValue = 16'hE180;
            // 10'h001 : TempValue = 16'hC301;
            // 10'h002 : TempValue = 16'hC602;
            // // Clock 4;
            // 10'h003 : TempValue = 16'h0473;
            // 10'h004 : TempValue = 16'h0442;
            // 10'h005 : TempValue = 16'hB402;
            // 10'h006 : TempValue = 16'h1243;
            // 10'h007 : TempValue = 16'h3715;
            // 10'h008 : TempValue = 16'h1751;
            // 10'h009 : TempValue = 16'h0106;
            // // Clock 5;
            // 10'h00A : TempValue = 16'h0473;
            // 10'h00B : TempValue = 16'h0442;
            // 10'h00C : TempValue = 16'hB402;
            // 10'h00D : TempValue = 16'h1243;
            // 10'h00E : TempValue = 16'h3715;
            // 10'h00F : TempValue = 16'h1751;
            // 10'h010 : TempValue = 16'h0106;
            // // Clock 6;
            // 10'h011 : TempValue = 16'h0473;
            // 10'h012 : TempValue = 16'h0442;
            // 10'h013 : TempValue = 16'hB402;
            // 10'h014 : TempValue = 16'h1243;
            // 10'h015 : TempValue = 16'h3715;
            // 10'h016 : TempValue = 16'h1751;
            // 10'h017 : TempValue = 16'h0106;
            // // Clock 7;
            // 10'h018 : TempValue = 16'h0473;
            // 10'h019 : TempValue = 16'h0442;
            // 10'h01A : TempValue = 16'hB402;
            // 10'h01B : TempValue = 16'h1243;
            // 10'h01C : TempValue = 16'h3715;
            // 10'h01D : TempValue = 16'h1751;
            // // 10'h01E : TempValue = A00F // Return
            // 10'h01E : TempValue = 16'h20F0; // HALT
            default : TempValue = 16'h0000;
        endcase
    end
    assign Value = TempValue;

endmodule