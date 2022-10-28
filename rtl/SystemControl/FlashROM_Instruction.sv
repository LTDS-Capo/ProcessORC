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
        // // Timer Prep
        //     10'h000 : TempValue = 16'hD188; // Load Timer Base Address
        //     10'h001 : TempValue = 16'hC2C0; // Load Timer Command Byte 0
        //     10'h002 : TempValue = 16'hE2E1; // Load Timer Command Byte 1
        //     10'h003 : TempValue = 16'hC3E4; // Load Timer Command Byte 2
        //     10'h004 : TempValue = 16'hE380; // Load Timer Command Byte 3
        //     10'h005 : TempValue = 16'h3251; // Store Timer Command Lower [32 cycles]
        //     10'h006 : TempValue = 16'h0111; // Increment Timer Pointer
        //     10'h007 : TempValue = 16'h0111; // Increment Timer Pointer
        // // GPIO Prep
        //     10'h008 : TempValue = 16'hD58C; // GPIO Base Address
        //     10'h009 : TempValue = 16'hC650; // GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
        //     10'h00A : TempValue = 16'hE604; // GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
        //     10'h00B : TempValue = 16'hC7FF; // GPIO Data Mask
        // // GPIO Loop
        //     10'h00C : TempValue = 16'h3655; // Submit a GPIO write
        //     10'h00D : TempValue = 16'h39D5; // Read the most recent GPIO Command back out
        //     10'h00E : TempValue = 16'h0A19; // Increment most recent command value
        //     10'h00F : TempValue = 16'h0A47; // Apply value mask
        //     10'h010 : TempValue = 16'h067A; // Move Write Value to GPIO Command Lower
        //     10'h011 : TempValue = 16'h9004; // Jump and Link to Timer Routine
        //     10'h012 : TempValue = 16'hE604; // GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
        //     10'h013 : TempValue = 16'hB3F9; // Jump to begining of GPIO loop
        //     10'h014 : TempValue = 16'h0000; // NOP
        // // Timer Set & Wait
        //     10'h015 : TempValue = 16'h3351; // Store Timer Command Upper [Timer Set]
        //     10'h016 : TempValue = 16'h3411; // Load Timer Command Upper [Timer Wait]
        //     10'h017 : TempValue = 16'h0074; // Wait for r4 to clear
        //     10'h018 : TempValue = 16'hA00F; // Jump back to Line X [negative Y] 

            // GPIO Fib Test - Variable
            10'h000 : TempValue = 16'hD188; // LEI r1 'd392 - Load Timer Base Address
            10'h001 : TempValue = 16'hC220; // LLI r2 'h20  - Load Timer Command Byte 0 [Timer waits 14,999,840 cycles]
            10'h002 : TempValue = 16'hE200; // LUI r2 'hE1  - Load Timer Command Byte 1
            10'h003 : TempValue = 16'hC300; // LLI r3 'hE4  - Load Timer Command Byte 2
            10'h004 : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3
            10'h005 : TempValue = 16'h3251; // STW r2 r1    - Store Timer Command Lower [14,999,840 cycles]
            10'h006 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            10'h007 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
                    // GPIO Prep
            10'h008 : TempValue = 16'hD58C; // LEI r5 'd396 - GPIO Base Address
            10'h009 : TempValue = 16'hC7FF; // LLI r7 'hFF  - GPIO Data Mask
                    // Fib Prep
            10'h00A : TempValue = 16'hCA01; // LLI rA 'h1   - Preload Initial Fib Values
            10'h00B : TempValue = 16'hCB00; // LLI rB 'h0   - Preload Initial Fib Values
            10'h00C : TempValue = 16'h0970; // MOV r9 r0    - Clear r9
                    // Main Loop
            10'h00D : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            10'h00E : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
                        // :LOOP_START
            10'h00F : TempValue = 16'h0B7C; // MOV rB rC    - Flip the fib values
            10'h010 : TempValue = 16'h047A; // MOV r4 rA    - Copy Current Fib to GPIO Write Value
            10'h011 : TempValue = 16'h9008; // JLI r0 [+8]    - Jump and Link to "WRITE_AND_WAIT"
            10'h012 : TempValue = 16'h0A0B; // ADD rA rB    - Perform Fib
            10'h013 : TempValue = 16'h0919; // INC r9 r9    - Increment Step Counter
            10'h014 : TempValue = 16'h0479; // MOV r4 r9    - Copy Step Counter to GPIO Write Value
            10'h015 : TempValue = 16'h9004; // JLI r0 [+4]    - Jump and Link to "WRITE_AND_WAIT"
            10'h016 : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            10'h017 : TempValue = 16'hB3F8; // BZI r0 [-3]    - Jump to "LOOP_START"
            10'h018 : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
                    // GPIO Write and Wait 
                        // :WRITE_AND_WAIT 
            10'h019 : TempValue = 16'h0447; // AND r4 r7    - Mask Write Data
            10'h01A : TempValue = 16'hE404; // LUI r4 'h04  - (Append Command) GPIO Write Byte Addr:0 [000_001_00_00000000]
            10'h01B : TempValue = 16'h3455; // STW r4 r5    - Submit GPIO Write
                //Variable Wait Update
            10'h01C : TempValue = 16'hED18; // LUI rD 'h18  - GPIO Read Byte Addr:0 [000_110_00_00000000]
            10'h01D : TempValue = 16'h3D95; // ALW rD r5    - Load of GPIO Input
            10'h01E : TempValue = 16'h037D; // MOV r3 rD    - Move GPIO Input to Command Byte 2
            10'h01F : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3 [LUI Applies the proper masks automatically]
                // END Variable Wait Update
            10'h020 : TempValue = 16'h3351; // STW r3 r1    - Store Timer Command Upper [Timer Set]
            10'h021 : TempValue = 16'h0473; // MOV r4 r3    - Copy Command [Timer Set > Timer Wait]
            10'h022 : TempValue = 16'h3491; // ALW r4 r1    - Load Timer Command Upper [Timer Wait]
            10'h023 : TempValue = 16'h0074; // MOV r0 r4    - Wait for r4 to clear
            10'h024 : TempValue = 16'hA00F; // RET          - Jump back to Line X [negative Y] 
            // //     // END Variable Wait Update
            // 10'h01C : TempValue = 16'h3351; // STW r3 r1    - Store Timer Command Upper [Timer Set]
            // 10'h01D : TempValue = 16'h0473; // MOV r4 r3    - Copy Command [Timer Set > Timer Wait]
            // 10'h01E : TempValue = 16'h3491; // ALW r4 r1    - Load Timer Command Upper [Timer Wait]
            // 10'h01F : TempValue = 16'h0074; // MOV r0 r4    - Wait for r4 to clear
            // 10'h020 : TempValue = 16'hA00F; // RET          - Jump back to Line X [negative Y] 

            // // GPIO Fib Test
            // 10'h000 : TempValue = 16'hD188; // LEI r1 'd392 - Load Timer Base Address
            // 10'h001 : TempValue = 16'hC220; // LLI r2 'h20  - Load Timer Command Byte 0 [Timer waits 14,999,840 cycles]
            // 10'h002 : TempValue = 16'hE2E1; // LUI r2 'hE1  - Load Timer Command Byte 1
            // 10'h003 : TempValue = 16'hC3E4; // LLI r3 'hE4  - Load Timer Command Byte 2
            // 10'h004 : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3
            // 10'h005 : TempValue = 16'h3251; // STW r2 r1    - Store Timer Command Lower [14,999,840 cycles]
            // 10'h006 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            // 10'h007 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            //         // GPIO Prep
            // 10'h008 : TempValue = 16'hD58C; // LEI r5 'd396 - GPIO Base Address
            // 10'h009 : TempValue = 16'hC600; // LLI r6 'h00  - GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
            // 10'h00A : TempValue = 16'hE604; // LUI r6 'h04  - GPIO Write Byte Addr:0, Value 'hA6 [0000_01_00_00000000]
            // 10'h00B : TempValue = 16'hC7FF; // LLI r7 'hFF  - GPIO Data Mask
            //         // Fib Prep
            // 10'h00C : TempValue = 16'hCA01; // LLI rA 'h1   - Preload Initial Fib Values
            // 10'h00D : TempValue = 16'hCB00; // LLI rB 'h0   - Preload Initial Fib Values
            // 10'h00E : TempValue = 16'h0970; // MOV r9 r0    - Clear r9
            //         // Main Loop
            // 10'h00F : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            // 10'h010 : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
            //             // :LOOP_START
            // 10'h011 : TempValue = 16'h0B7C; // MOV rB rC    - Flip the fib values
            // 10'h012 : TempValue = 16'h047A; // MOV r4 rA    - Copy Current Fib to GPIO Write Value
            // 10'h013 : TempValue = 16'h9008; // JLI r0 [+8]    - Jump and Link to "WRITE_AND_WAIT"
            // 10'h014 : TempValue = 16'h0A0B; // ADD rA rB    - Perform Fib
            // 10'h015 : TempValue = 16'h0919; // INC r9 r9    - Increment Step Counter
            // 10'h016 : TempValue = 16'h0479; // MOV r4 r9    - Copy Step Counter to GPIO Write Value
            // 10'h017 : TempValue = 16'h9004; // JLI r0 [+4]    - Jump and Link to "WRITE_AND_WAIT"
            // 10'h018 : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            // 10'h019 : TempValue = 16'hB3F8; // BZI r0 [-3]    - Jump to "LOOP_START"
            // 10'h01A : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
            //         // GPIO Write and Wait 
            //             // :WRITE_AND_WAIT 
            // 10'h01B : TempValue = 16'h0447; // AND r4 r7    - Mask Write Data
            // 10'h01C : TempValue = 16'h0466; // IOR r4 r6    - Append Command
            // 10'h01D : TempValue = 16'h3455; // STW r4 r5    - Submit GPIO Write
            // 10'h01E : TempValue = 16'h3351; // STW r3 r1    - Store Timer Command Upper [Timer Set]
            // 10'h01F : TempValue = 16'h3411; // LDW r4 r1    - Load Timer Command Upper [Timer Wait]
            // 10'h020 : TempValue = 16'h0074; // MOV r0 r4    - Wait for r4 to clear
            // 10'h021 : TempValue = 16'hA00F; // RET          - Jump back to Line X [negative Y] 



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