module FlashROM_Data (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)
            //                     Data
            // 10'h000 : TempValue = 16'h0000;
            // 10'h001 : TempValue = 16'h0001;
            // 10'h002 : TempValue = 16'h0002;
            // 10'h003 : TempValue = 16'h0003;
            // 10'h004 : TempValue = 16'h0004;
            // 10'h005 : TempValue = 16'h0005;
            // 10'h006 : TempValue = 16'h0006;
            // 10'h007 : TempValue = 16'h0007;
            // 10'h008 : TempValue = 16'h0008;
            // 10'h009 : TempValue = 16'h0009;
            // 10'h00A : TempValue = 16'h000A;
            // 10'h00B : TempValue = 16'h000B;
            // 10'h00C : TempValue = 16'h000C;
            // 10'h00D : TempValue = 16'h000D;
            // 10'h00E : TempValue = 16'h000E;
            // 10'h00F : TempValue = 16'h000F;
            // 10'h010 : TempValue = 16'h0010;
            // 10'h011 : TempValue = 16'h0011;
            // 10'h012 : TempValue = 16'h0012;
            // 10'h013 : TempValue = 16'h0013;
            // 10'h014 : TempValue = 16'h0014;
            // 10'h015 : TempValue = 16'h0015;
            // 10'h016 : TempValue = 16'h0016;
            // 10'h017 : TempValue = 16'h0017;
            // 10'h018 : TempValue = 16'h0018;
            // 10'h019 : TempValue = 16'h0019;
            // 10'h01A : TempValue = 16'h001A;
            // 10'h01B : TempValue = 16'h001B;
            // 10'h01C : TempValue = 16'h001C;
            // 10'h01D : TempValue = 16'h001D;
            // 10'h01E : TempValue = 16'h001E;
            // 10'h01F : TempValue = 16'h001F;
            // 10'h020 : TempValue = 16'h0020;
            // 10'h021 : TempValue = 16'h0021;
            // 10'h022 : TempValue = 16'h0022;
            // 10'h023 : TempValue = 16'h0023;
            // 10'h024 : TempValue = 16'h0024;
            // 10'h025 : TempValue = 16'h0025;
            // 10'h026 : TempValue = 16'h0026;
            // 10'h027 : TempValue = 16'h0027;
            // 10'h028 : TempValue = 16'h0028;
            // 10'h029 : TempValue = 16'h0029;
            // 10'h02A : TempValue = 16'h002A;
            // 10'h02B : TempValue = 16'h002B;
            // 10'h02C : TempValue = 16'h002C;
            // 10'h02D : TempValue = 16'h002D;
            // 10'h02E : TempValue = 16'h002E;
            // 10'h02F : TempValue = 16'h002F;

            // GPIO Fib Test - Variable (With IO Reset)
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
                // IO Reset Test
            10'h010 : TempValue = 16'h900B; // JLI r0 [+11] - Jump and Link to "WRITE_AND_WAIT"
            10'h011 : TempValue = 16'h20E2; // RST b0010    - IO Reset
                // END Io Reset Test
            10'h012 : TempValue = 16'h047A; // MOV r4 rA    - Copy Current Fib to GPIO Write Value
            10'h013 : TempValue = 16'h9008; // JLI r0 [+8]  - Jump and Link to "WRITE_AND_WAIT"
            10'h014 : TempValue = 16'h0A0B; // ADD rA rB    - Perform Fib
            10'h015 : TempValue = 16'h0919; // INC r9 r9    - Increment Step Counter
            10'h016 : TempValue = 16'h0479; // MOV r4 r9    - Copy Step Counter to GPIO Write Value
            10'h017 : TempValue = 16'h9004; // JLI r0 [+4]  - Jump and Link to "WRITE_AND_WAIT"
            10'h018 : TempValue = 16'h0C7A; // MOV rC rA    - Flip the fib values
            10'h019 : TempValue = 16'hB3F8; // BZI r0 [-5]  - Jump to "LOOP_START"
            10'h01A : TempValue = 16'h0A7B; // MOV rA rB    - Flip the fib values
                    // GPIO Write and Wait 
                        // :WRITE_AND_WAIT 
            10'h01B : TempValue = 16'h0447; // AND r4 r7    - Mask Write Data
            10'h01C : TempValue = 16'hE404; // LUI r4 'h04  - (Append Command) GPIO Write Byte Addr:0 [000_001_00_00000000]
            10'h01D : TempValue = 16'h3455; // STW r4 r5    - Submit GPIO Write
                //Variable Wait Update
            10'h01E : TempValue = 16'hED18; // LUI rD 'h18  - GPIO Read Byte Addr:0 [000_110_00_00000000]
            10'h01F : TempValue = 16'h3D95; // ALW rD r5    - Load of GPIO Input
            10'h020 : TempValue = 16'h037D; // MOV r3 rD    - Move GPIO Input to Command Byte 2
            10'h021 : TempValue = 16'hE380; // LUI r3 'h80  - Load Timer Command Byte 3 [LUI Applies the proper masks automatically]
                // END Variable Wait Update
            10'h022 : TempValue = 16'h3351; // STW r3 r1    - Store Timer Command Upper [Timer Set]
            10'h023 : TempValue = 16'h0473; // MOV r4 r3    - Copy Command [Timer Set > Timer Wait]
            10'h024 : TempValue = 16'h3491; // ALW r4 r1    - Load Timer Command Upper [Timer Wait]
            10'h025 : TempValue = 16'h0074; // MOV r0 r4    - Wait for r4 to clear
            10'h026 : TempValue = 16'hA00F; // RET          - Jump back to Line X [negative Y]

            // Memory Maped Range 'd384('h181) - 'd511('h1ff)

            default : TempValue = 16'h0000;
        endcase
    end
    assign Value = TempValue;

endmodule