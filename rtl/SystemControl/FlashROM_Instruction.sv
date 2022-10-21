module FlashROM_Instruction (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)

            // 10'h000 : TempValue = 16'hD188;
            // 10'h001 : TempValue = 16'hC220;
            // 10'h002 : TempValue = 16'hC300;
            // 10'h003 : TempValue = 16'hE380;
            // 10'h004 : TempValue = 16'h3251;
            // 10'h005 : TempValue = 16'h0111;
            // 10'h006 : TempValue = 16'h0111;
            // 10'h007 : TempValue = 16'h3351;
            // 10'h008 : TempValue = 16'h3411;
            // 10'h009 : TempValue = 16'h0074;
            // // 10'h00A : TempValue = 16'hB3FD;
            // 10'h00A : TempValue = 16'hB3FC;

            // GPIO Increment and Timer Test
        // Timer Prep
            10'h000 : TempValue = 16'hD188; // Load Timer Base Address
            10'h001 : TempValue = 16'hC220; // Load Timer Command Byte 0
            10'h002 : TempValue = 16'hC300; // Load Timer Command Byte 2
            10'h003 : TempValue = 16'hE380; // Load Timer Command Byte 3
            10'h004 : TempValue = 16'h3251; // Store Timer Command Lower [32 cycles]
            10'h005 : TempValue = 16'h0111; // Increment Timer Pointer
            10'h006 : TempValue = 16'h0111; // Increment Timer Pointer
        // GPIO Prep
            10'h007 : TempValue = 16'hD58C; // GPIO Base Address
            10'h008 : TempValue = 16'hC655; // GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000] 55 for testing
            10'h009 : TempValue = 16'hE604; // GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
            10'h00A : TempValue = 16'hC7FF; // GPIO Data Mask
        // GPIO Loop
            10'h00B : TempValue = 16'h3655; // Submit a GPIO write
            10'h00C : TempValue = 16'h39D5; // Read the most recent GPIO Command back out
            10'h00D : TempValue = 16'h0A19; // Increment most recent command value
            10'h00E : TempValue = 16'h0A47; // Apply value mask
            10'h00F : TempValue = 16'h067A; // Move Write Value to GPIO Command Lower
            10'h010 : TempValue = 16'h9004; // Jump and Link to Timer Routine
            10'h011 : TempValue = 16'hE604; // GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
            10'h012 : TempValue = 16'hB3F9; // Jump to begining of GPIO loop
            10'h013 : TempValue = 16'h0000; // NOP
        // Timer Set & Wait
            10'h014 : TempValue = 16'h3351; // Store Timer Command Upper [Timer Set]
            10'h015 : TempValue = 16'h3411; // Load Timer Command Upper [Timer Wait]
            10'h016 : TempValue = 16'h0074; // Wait for r4 to clear
            10'h017 : TempValue = 16'hA00F; // Jump back to Line X [negative Y] 

            // // GPIO Fib Test
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