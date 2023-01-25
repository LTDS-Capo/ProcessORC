module FlashROM_Instruction (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)

            10'h000 : TempValue = 16'hD18E; // LEI r1 'd398
            10'h001 : TempValue = 16'hD590; // LEI r5 'd400
            10'h002 : TempValue = 16'hC426; // LLI r4 'h26
            10'h003 : TempValue = 16'h0674; // MOV r6 r4
            //                             :Loop
            10'h004 : TempValue = 16'h0606; // ADD r6 r6
            // 10'h005 : TempValue = 16'h3214; // LDW r2 r6
            10'h005 : TempValue = 16'h3216; // LDW r2 r6
            10'h006 : TempValue = 16'h3251; // STW r2 r1
            10'h007 : TempValue = 16'h3455; // STW r4 r5
            10'h008 : TempValue = 16'hB404; // BZI r4 :Reset[+1]
            10'h009 : TempValue = 16'h0434; // DEC r4 r4
            10'h00A : TempValue = 16'hB3FA; // BZI r0 :Loop[-6]
            10'h00B : TempValue = 16'h0674; // MOV r6 r4
            //                             :Reset
            10'h00C : TempValue = 16'h3495; // ALW r4 r5
            10'h00D : TempValue = 16'h0074; // MOV r0 r4
            10'h00E : TempValue = 16'h20E7; // RST 'b0111

            // 10'h000 : TempValue = 16'hD18E; // LEI r1 'd398
            // 10'h001 : TempValue = 16'hD590; // LEI r5 'd400
            // 10'h002 : TempValue = 16'hC44C; // LLI r4 'h26*2
            // 10'h003 : TempValue = 16'hC701; // LLI r7 'h01
            // 10'h004 : TempValue = 16'h3214; // LDW r2 r4
            // //                             :Loop
            // 10'h005 : TempValue = 16'h3251; // STW r2 r1
            // 10'h006 : TempValue = 16'h0674; // MOV r6 r4
            // 10'h007 : TempValue = 16'h1647; // SHR r6 r7
            // 10'h008 : TempValue = 16'h3655; // STW r6 r5
            // 10'h009 : TempValue = 16'hB405; // BZI r4 :Reset[+5]
            // 10'h00A : TempValue = 16'h0434; // DEC r4 r4
            // 10'h00B : TempValue = 16'h0434; // DEC r4 r4
            // 10'h00C : TempValue = 16'hB3F9; // BZI r0 :Loop[-7]
            // 10'h00D : TempValue = 16'h3214; // LDW r2 r4
            // //                             :Reset
            // 10'h00E : TempValue = 16'h3495; // ALW r4 r5
            // 10'h00F : TempValue = 16'h0074; // MOV r0 r4
            // 10'h010 : TempValue = 16'h20E7; // RST 'b0111


            // // GPIO Fib Test - Variable (With IO Reset)
            // 10'h000 : TempValue = 16'hD188; // LEI r1 'd392 - Load Timer Base Address
            // 10'h001 : TempValue = 16'hC220; // LLI r2 'h20  - Load Timer Command Byte 0 [Timer waits 14,999,840 cycles]
            // 10'h002 : TempValue = 16'hE203; // LUI r2 'hE1  - Load Timer Command Byte 1
            // 10'h003 : TempValue = 16'hC300; // LLI r3 'hE4  - Load Timer Command Byte 2
            // 10'h004 : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3
            //         // GPIO Prep
            // 10'h005 : TempValue = 16'hD58C; // LEI r5 'd396 - GPIO Base Address
            // 10'h006 : TempValue = 16'hC7FF; // LLI r7 'hFF  - GPIO Data Mask
            //         // Fib Prep
            // 10'h007 : TempValue = 16'hCA01; // LLI rA 'h1   - Preload Initial Fib Values
            // 10'h008 : TempValue = 16'hCB00; // LLI rB 'h0   - Preload Initial Fib Values
            // 10'h009 : TempValue = 16'h0970; // MOV r9 r0    - Clear r9
            //         // Main Loop
            // 10'h00A : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            // 10'h00B : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
            //             // :LOOP_START
            // 10'h00C : TempValue = 16'h0B7C; // MOV rB rC    - Flip the fib values
            //     // IO Reset Test
            // 10'h00D : TempValue = 16'h900B; // JLI r0 [+11] - Jump and Link to "WRITE_AND_WAIT"
            // 10'h00E : TempValue = 16'h047A; // MOV r4 rA    - Copy Current Fib to GPIO Write Value
            // 10'h00F : TempValue = 16'h20E2; // RST b0010    - IO Reset
            //         // reset the IO Lower command
            // 10'h010 : TempValue = 16'hD188; // LEI r1 'd392 - Load Timer Base Address
            // 10'h011 : TempValue = 16'h3251; // STW r2 r1    - Store Timer Command Lower [14,999,840 cycles]
            // 10'h012 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            // 10'h013 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            //     // END Io Reset Test
            // 10'h014 : TempValue = 16'h9008; // JLI r0 [+8]  - Jump and Link to "WRITE_AND_WAIT"
            // 10'h015 : TempValue = 16'h0A0B; // ADD rA rB    - Perform Fib
            // 10'h016 : TempValue = 16'h0919; // INC r9 r9    - Increment Step Counter
            // 10'h017 : TempValue = 16'h0479; // MOV r4 r9    - Copy Step Counter to GPIO Write Value
            // 10'h018 : TempValue = 16'h9004; // JLI r0 [+4]  - Jump and Link to "WRITE_AND_WAIT"
            // 10'h019 : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            // 10'h01A : TempValue = 16'hB3F1; // BZI r0 [-15]  - Jump to "LOOP_START"
            // 10'h01B : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
            //         // GPIO Write and Wait 
            //             // :WRITE_AND_WAIT 
            // 10'h01C : TempValue = 16'h0447; // AND r4 r7    - Mask Write Data
            // 10'h01D : TempValue = 16'hE404; // LUI r4 'h04  - (Append Command) GPIO Write Byte Addr:0 [000_001_00_00000000]
            // 10'h01E : TempValue = 16'h3455; // STW r4 r5    - Submit GPIO Write
            //     //Variable Wait Update
            // 10'h01F : TempValue = 16'hED18; // LUI rD 'h18  - GPIO Read Byte Addr:0 [000_110_00_00000000]
            // 10'h020 : TempValue = 16'h3D95; // ALW rD r5    - Load of GPIO Input
            // 10'h021 : TempValue = 16'h037D; // MOV r3 rD    - Move GPIO Input to Command Byte 2
            // 10'h022 : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3 [LUI Applies the proper masks automatically]
            //     // END Variable Wait Update
            // 10'h023 : TempValue = 16'h3351; // STW r3 r1    - Store Timer Command Upper [Timer Set]
            // 10'h024 : TempValue = 16'h0473; // MOV r4 r3    - Copy Command [Timer Set > Timer Wait]
            // 10'h025 : TempValue = 16'h3491; // ALW r4 r1    - Load Timer Command Upper [Timer Wait]
            // 10'h026 : TempValue = 16'h0074; // MOV r0 r4    - Wait for r4 to clear
            // 10'h027 : TempValue = 16'hA00F; // RET          - Jump back to Line X [negative Y]


            // // GPIO Fib Test - Variable
            // 10'h000 : TempValue = 16'hD188; // LEI r1 'd392 - Load Timer Base Address
            // 10'h001 : TempValue = 16'hC220; // LLI r2 'h20  - Load Timer Command Byte 0 [Timer waits 14,999,840 cycles]
            // 10'h002 : TempValue = 16'hE200; // LUI r2 'hE1  - Load Timer Command Byte 1
            // 10'h003 : TempValue = 16'hC300; // LLI r3 'hE4  - Load Timer Command Byte 2
            // 10'h004 : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3
            // 10'h005 : TempValue = 16'h3251; // STW r2 r1    - Store Timer Command Lower [14,999,840 cycles]
            // 10'h006 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            // 10'h007 : TempValue = 16'h0111; // INC r1 r1    - Increment Timer Pointer
            //         // GPIO Prep
            // 10'h008 : TempValue = 16'hD58C; // LEI r5 'd396 - GPIO Base Address
            // 10'h009 : TempValue = 16'hC7FF; // LLI r7 'hFF  - GPIO Data Mask
            //         // Fib Prep
            // 10'h00A : TempValue = 16'hCA01; // LLI rA 'h1   - Preload Initial Fib Values
            // 10'h00B : TempValue = 16'hCB00; // LLI rB 'h0   - Preload Initial Fib Values
            // 10'h00C : TempValue = 16'h0970; // MOV r9 r0    - Clear r9
            //         // Main Loop
            // 10'h00D : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            // 10'h00E : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
            //             // :LOOP_START
            // 10'h00F : TempValue = 16'h0B7C; // MOV rB rC    - Flip the fib values
            // 10'h010 : TempValue = 16'h047A; // MOV r4 rA    - Copy Current Fib to GPIO Write Value
            // 10'h011 : TempValue = 16'h9008; // JLI r0 [+8]  - Jump and Link to "WRITE_AND_WAIT"
            // 10'h012 : TempValue = 16'h0A0B; // ADD rA rB    - Perform Fib
            // 10'h013 : TempValue = 16'h0919; // INC r9 r9    - Increment Step Counter
            // 10'h014 : TempValue = 16'h0479; // MOV r4 r9    - Copy Step Counter to GPIO Write Value
            // 10'h015 : TempValue = 16'h9004; // JLI r0 [+4]  - Jump and Link to "WRITE_AND_WAIT"
            // 10'h016 : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            // 10'h017 : TempValue = 16'hB3F8; // BZI r0 [-3]  - Jump to "LOOP_START"
            // 10'h018 : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
            //         // GPIO Write and Wait 
            //             // :WRITE_AND_WAIT 
            // 10'h019 : TempValue = 16'h0447; // AND r4 r7    - Mask Write Data
            // 10'h01A : TempValue = 16'hE404; // LUI r4 'h04  - (Append Command) GPIO Write Byte Addr:0 [000_001_00_00000000]
            // 10'h01B : TempValue = 16'h3455; // STW r4 r5    - Submit GPIO Write
            //     //Variable Wait Update
            // 10'h01C : TempValue = 16'hED18; // LUI rD 'h18  - GPIO Read Byte Addr:0 [000_110_00_00000000]
            // 10'h01D : TempValue = 16'h3D95; // ALW rD r5    - Load of GPIO Input
            // 10'h01E : TempValue = 16'h037D; // MOV r3 rD    - Move GPIO Input to Command Byte 2
            // 10'h01F : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3 [LUI Applies the proper masks automatically]
            //     // END Variable Wait Update
            // 10'h020 : TempValue = 16'h3351; // STW r3 r1    - Store Timer Command Upper [Timer Set]
            // 10'h021 : TempValue = 16'h0473; // MOV r4 r3    - Copy Command [Timer Set > Timer Wait]
            // 10'h022 : TempValue = 16'h3491; // ALW r4 r1    - Load Timer Command Upper [Timer Wait]
            // 10'h023 : TempValue = 16'h0074; // MOV r0 r4    - Wait for r4 to clear
            // 10'h024 : TempValue = 16'hA00F; // RET          - Jump back to Line X [negative Y]


            default : TempValue = 16'h0000;
        endcase
    end
    assign Value = TempValue;

endmodule