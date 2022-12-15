module FlashROM_Data (
    input  [9:0] Address,
    output [15:0] Value
);

    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)
            //                     Data
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
            10'h027 : TempValue = 16'h0000;
            10'h028 : TempValue = 16'h0000;
            10'h02a : TempValue = 16'h0000;
            10'h02c : TempValue = 16'h0000;
            10'h02e : TempValue = 16'h0000;
            10'h030 : TempValue = 16'h0000;
            10'h032 : TempValue = 16'h0000;
            10'h034 : TempValue = 16'h0000;
            10'h036 : TempValue = 16'h0000;
            10'h038 : TempValue = 16'h0000;
            10'h03a : TempValue = 16'h0000;
            10'h03c : TempValue = 16'h0000;
            10'h03e : TempValue = 16'h0000;
            10'h040 : TempValue = 16'h0000;
            10'h042 : TempValue = 16'h0000;
            10'h044 : TempValue = 16'h0000;
            10'h046 : TempValue = 16'h0000;
            10'h048 : TempValue = 16'h0000;
            10'h04a : TempValue = 16'h0000;
            10'h04c : TempValue = 16'h0000;
            10'h04e : TempValue = 16'h0000;
            10'h050 : TempValue = 16'h0000;
            10'h052 : TempValue = 16'h0000;
            10'h054 : TempValue = 16'h0000;
            10'h056 : TempValue = 16'h0000;
            10'h058 : TempValue = 16'h0000;
            10'h05a : TempValue = 16'h0000;
            10'h05c : TempValue = 16'h0000;
            10'h05e : TempValue = 16'h0000;
            10'h060 : TempValue = 16'h0000;
            10'h062 : TempValue = 16'h0000;
            10'h064 : TempValue = 16'h0000;
            10'h066 : TempValue = 16'h0000;
            10'h068 : TempValue = 16'h0000;
            10'h06a : TempValue = 16'h0000;
            10'h06c : TempValue = 16'h0000;
            10'h06e : TempValue = 16'h0000;
            10'h070 : TempValue = 16'h0000;
            10'h072 : TempValue = 16'h0000;
            10'h074 : TempValue = 16'h0000;
            10'h076 : TempValue = 16'h0000;
            10'h078 : TempValue = 16'h0000;
            10'h07a : TempValue = 16'h0000;
            10'h07c : TempValue = 16'h0000;
            10'h07e : TempValue = 16'h0000;
            10'h080 : TempValue = 16'h0000;
            10'h082 : TempValue = 16'h0000;
            10'h084 : TempValue = 16'h0000;
            10'h086 : TempValue = 16'h0000;
            10'h088 : TempValue = 16'h0000;
            10'h08a : TempValue = 16'h0000;
            10'h08c : TempValue = 16'h0000;
            10'h08e : TempValue = 16'h0000;
            10'h090 : TempValue = 16'h0000;
            10'h092 : TempValue = 16'h0000;
            10'h094 : TempValue = 16'h0000;
            10'h096 : TempValue = 16'h0000;
            10'h098 : TempValue = 16'h0000;
            10'h09a : TempValue = 16'h0000;
            10'h09c : TempValue = 16'h0000;
            10'h09e : TempValue = 16'h0000;
            10'h0a0 : TempValue = 16'h0000;
            10'h0a2 : TempValue = 16'h0000;
            10'h0a4 : TempValue = 16'h0000;
            10'h0a6 : TempValue = 16'h0000;
            10'h0a8 : TempValue = 16'h0000;
            10'h0aa : TempValue = 16'h0000;
            10'h0ac : TempValue = 16'h0000;
            10'h0ae : TempValue = 16'h0000;
            10'h0b0 : TempValue = 16'h0000;
            10'h0b2 : TempValue = 16'h0000;
            10'h0b4 : TempValue = 16'h0000;
            10'h0b6 : TempValue = 16'h0000;
            10'h0b8 : TempValue = 16'h0000;
            10'h0ba : TempValue = 16'h0000;
            10'h0bc : TempValue = 16'h0000;
            10'h0be : TempValue = 16'h0000;
            10'h0c0 : TempValue = 16'h0000;
            10'h0c2 : TempValue = 16'h0000;
            10'h0c4 : TempValue = 16'h0000;
            10'h0c6 : TempValue = 16'h0000;
            10'h0c8 : TempValue = 16'h0000;
            10'h0ca : TempValue = 16'h0000;
            10'h0cc : TempValue = 16'h0000;
            10'h0ce : TempValue = 16'h0000;
            10'h0d0 : TempValue = 16'h0000;
            10'h0d2 : TempValue = 16'h0000;
            10'h0d4 : TempValue = 16'h0000;
            10'h0d6 : TempValue = 16'h0000;
            10'h0d8 : TempValue = 16'h0000;
            10'h0da : TempValue = 16'h0000;
            10'h0dc : TempValue = 16'h0000;
            10'h0de : TempValue = 16'h0000;
            10'h0e0 : TempValue = 16'h0000;
            10'h0e2 : TempValue = 16'h0000;
            10'h0e4 : TempValue = 16'h0000;
            10'h0e6 : TempValue = 16'h0000;
            10'h0e8 : TempValue = 16'h0000;
            10'h0ea : TempValue = 16'h0000;
            10'h0ec : TempValue = 16'h0000;
            10'h0ee : TempValue = 16'h0000;
            10'h0f0 : TempValue = 16'h0000;
            10'h0f2 : TempValue = 16'h0000;
            10'h0f4 : TempValue = 16'h0000;
            10'h0f6 : TempValue = 16'h0000;
            10'h0f8 : TempValue = 16'h0000;
            10'h0fa : TempValue = 16'h0000;
            10'h0fc : TempValue = 16'h0000;
            10'h0fe : TempValue = 16'h0000;
            10'h100 : TempValue = 16'h0000;
            10'h102 : TempValue = 16'h0000;
            10'h104 : TempValue = 16'h0000;
            10'h106 : TempValue = 16'h0000;
            10'h108 : TempValue = 16'h0000;
            10'h10a : TempValue = 16'h0000;
            10'h10c : TempValue = 16'h0000;
            10'h10e : TempValue = 16'h0000;
            10'h110 : TempValue = 16'h0000;
            10'h112 : TempValue = 16'h0000;
            10'h114 : TempValue = 16'h0000;
            10'h116 : TempValue = 16'h0000;
            10'h118 : TempValue = 16'h0000;
            10'h11a : TempValue = 16'h0000;
            10'h11c : TempValue = 16'h0000;
            10'h11e : TempValue = 16'h0000;
            10'h120 : TempValue = 16'h0000;
            10'h122 : TempValue = 16'h0000;
            10'h124 : TempValue = 16'h0000;
            10'h126 : TempValue = 16'h0000;
            10'h128 : TempValue = 16'h0000;
            10'h12a : TempValue = 16'h0000;
            10'h12c : TempValue = 16'h0000;
            10'h12e : TempValue = 16'h0000;
            10'h130 : TempValue = 16'h0000;
            10'h132 : TempValue = 16'h0000;
            10'h134 : TempValue = 16'h0000;
            10'h136 : TempValue = 16'h0000;
            10'h138 : TempValue = 16'h0000;
            10'h13a : TempValue = 16'h0000;
            10'h13c : TempValue = 16'h0000;
            10'h13e : TempValue = 16'h0000;
            10'h140 : TempValue = 16'h0000;
            10'h142 : TempValue = 16'h0000;
            10'h144 : TempValue = 16'h0000;
            10'h146 : TempValue = 16'h0000;
            10'h148 : TempValue = 16'h0000;
            10'h14a : TempValue = 16'h0000;
            10'h14c : TempValue = 16'h0000;
            10'h14e : TempValue = 16'h0000;
            10'h150 : TempValue = 16'h0000;
            10'h152 : TempValue = 16'h0000;
            10'h154 : TempValue = 16'h0000;
            10'h156 : TempValue = 16'h0000;
            10'h158 : TempValue = 16'h0000;
            10'h15a : TempValue = 16'h0000;
            10'h15c : TempValue = 16'h0000;
            10'h15e : TempValue = 16'h0000;
            10'h160 : TempValue = 16'h0000;
            10'h162 : TempValue = 16'h0000;
            10'h164 : TempValue = 16'h0000;
            10'h166 : TempValue = 16'h0000;
            10'h168 : TempValue = 16'h0000;
            10'h16a : TempValue = 16'h0000;
            10'h16c : TempValue = 16'h0000;
            10'h16e : TempValue = 16'h0000;
            10'h170 : TempValue = 16'h0000;
            10'h172 : TempValue = 16'h0000;
            10'h174 : TempValue = 16'h0000;
            10'h176 : TempValue = 16'h0000;
            10'h178 : TempValue = 16'h0000;
            10'h17a : TempValue = 16'h0000;
            10'h17c : TempValue = 16'h0000;
            10'h17e : TempValue = 16'h0000;
            10'h180 : TempValue = 16'h0000;
            // Memory Maped Range 'd384('h181) - 'd511('h1ff)
            10'h200 : TempValue = 16'h0000;
            10'h202 : TempValue = 16'h0000;
            10'h204 : TempValue = 16'h0000;
            10'h206 : TempValue = 16'h0000;
            10'h208 : TempValue = 16'h0000;
            10'h20a : TempValue = 16'h0000;
            10'h20c : TempValue = 16'h0000;
            10'h20e : TempValue = 16'h0000;
            10'h210 : TempValue = 16'h0000;
            10'h212 : TempValue = 16'h0000;
            10'h214 : TempValue = 16'h0000;
            10'h216 : TempValue = 16'h0000;
            10'h218 : TempValue = 16'h0000;
            10'h21a : TempValue = 16'h0000;
            10'h21c : TempValue = 16'h0000;
            10'h21e : TempValue = 16'h0000;
            10'h220 : TempValue = 16'h0000;
            10'h222 : TempValue = 16'h0000;
            10'h224 : TempValue = 16'h0000;
            10'h226 : TempValue = 16'h0000;
            10'h228 : TempValue = 16'h0000;
            10'h22a : TempValue = 16'h0000;
            10'h22c : TempValue = 16'h0000;
            10'h22e : TempValue = 16'h0000;
            10'h230 : TempValue = 16'h0000;
            10'h232 : TempValue = 16'h0000;
            10'h234 : TempValue = 16'h0000;
            10'h236 : TempValue = 16'h0000;
            10'h238 : TempValue = 16'h0000;
            10'h23a : TempValue = 16'h0000;
            10'h23c : TempValue = 16'h0000;
            10'h23e : TempValue = 16'h0000;
            10'h240 : TempValue = 16'h0000;
            10'h242 : TempValue = 16'h0000;
            10'h244 : TempValue = 16'h0000;
            10'h246 : TempValue = 16'h0000;
            10'h248 : TempValue = 16'h0000;
            10'h24a : TempValue = 16'h0000;
            10'h24c : TempValue = 16'h0000;
            10'h24e : TempValue = 16'h0000;
            10'h250 : TempValue = 16'h0000;
            10'h252 : TempValue = 16'h0000;
            10'h254 : TempValue = 16'h0000;
            10'h256 : TempValue = 16'h0000;
            10'h258 : TempValue = 16'h0000;
            10'h25a : TempValue = 16'h0000;
            10'h25c : TempValue = 16'h0000;
            10'h25e : TempValue = 16'h0000;
            10'h260 : TempValue = 16'h0000;
            10'h262 : TempValue = 16'h0000;
            10'h264 : TempValue = 16'h0000;
            10'h266 : TempValue = 16'h0000;
            10'h268 : TempValue = 16'h0000;
            10'h26a : TempValue = 16'h0000;
            10'h26c : TempValue = 16'h0000;
            10'h26e : TempValue = 16'h0000;
            10'h270 : TempValue = 16'h0000;
            10'h272 : TempValue = 16'h0000;
            10'h274 : TempValue = 16'h0000;
            10'h276 : TempValue = 16'h0000;
            10'h278 : TempValue = 16'h0000;
            10'h27a : TempValue = 16'h0000;
            10'h27c : TempValue = 16'h0000;
            10'h27e : TempValue = 16'h0000;
            10'h280 : TempValue = 16'h0000;
            10'h282 : TempValue = 16'h0000;
            10'h284 : TempValue = 16'h0000;
            10'h286 : TempValue = 16'h0000;
            10'h288 : TempValue = 16'h0000;
            10'h28a : TempValue = 16'h0000;
            10'h28c : TempValue = 16'h0000;
            10'h28e : TempValue = 16'h0000;
            10'h290 : TempValue = 16'h0000;
            10'h292 : TempValue = 16'h0000;
            10'h294 : TempValue = 16'h0000;
            10'h296 : TempValue = 16'h0000;
            10'h298 : TempValue = 16'h0000;
            10'h29a : TempValue = 16'h0000;
            10'h29c : TempValue = 16'h0000;
            10'h29e : TempValue = 16'h0000;
            10'h2a0 : TempValue = 16'h0000;
            10'h2a2 : TempValue = 16'h0000;
            10'h2a4 : TempValue = 16'h0000;
            10'h2a6 : TempValue = 16'h0000;
            10'h2a8 : TempValue = 16'h0000;
            10'h2aa : TempValue = 16'h0000;
            10'h2ac : TempValue = 16'h0000;
            10'h2ae : TempValue = 16'h0000;
            10'h2b0 : TempValue = 16'h0000;
            10'h2b2 : TempValue = 16'h0000;
            10'h2b4 : TempValue = 16'h0000;
            10'h2b6 : TempValue = 16'h0000;
            10'h2b8 : TempValue = 16'h0000;
            10'h2ba : TempValue = 16'h0000;
            10'h2bc : TempValue = 16'h0000;
            10'h2be : TempValue = 16'h0000;
            10'h2c0 : TempValue = 16'h0000;
            10'h2c2 : TempValue = 16'h0000;
            10'h2c4 : TempValue = 16'h0000;
            10'h2c6 : TempValue = 16'h0000;
            10'h2c8 : TempValue = 16'h0000;
            10'h2ca : TempValue = 16'h0000;
            10'h2cc : TempValue = 16'h0000;
            10'h2ce : TempValue = 16'h0000;
            10'h2d0 : TempValue = 16'h0000;
            10'h2d2 : TempValue = 16'h0000;
            10'h2d4 : TempValue = 16'h0000;
            10'h2d6 : TempValue = 16'h0000;
            10'h2d8 : TempValue = 16'h0000;
            10'h2da : TempValue = 16'h0000;
            10'h2dc : TempValue = 16'h0000;
            10'h2de : TempValue = 16'h0000;
            10'h2e0 : TempValue = 16'h0000;
            10'h2e2 : TempValue = 16'h0000;
            10'h2e4 : TempValue = 16'h0000;
            10'h2e6 : TempValue = 16'h0000;
            10'h2e8 : TempValue = 16'h0000;
            10'h2ea : TempValue = 16'h0000;
            10'h2ec : TempValue = 16'h0000;
            10'h2ee : TempValue = 16'h0000;
            10'h2f0 : TempValue = 16'h0000;
            10'h2f2 : TempValue = 16'h0000;
            10'h2f4 : TempValue = 16'h0000;
            10'h2f6 : TempValue = 16'h0000;
            10'h2f8 : TempValue = 16'h0000;
            10'h2fa : TempValue = 16'h0000;
            10'h2fc : TempValue = 16'h0000;
            10'h2fe : TempValue = 16'h0000;
            10'h300 : TempValue = 16'h0000;
            10'h302 : TempValue = 16'h0000;
            10'h304 : TempValue = 16'h0000;
            10'h306 : TempValue = 16'h0000;
            10'h308 : TempValue = 16'h0000;
            10'h30a : TempValue = 16'h0000;
            10'h30c : TempValue = 16'h0000;
            10'h30e : TempValue = 16'h0000;
            10'h310 : TempValue = 16'h0000;
            10'h312 : TempValue = 16'h0000;
            10'h314 : TempValue = 16'h0000;
            10'h316 : TempValue = 16'h0000;
            10'h318 : TempValue = 16'h0000;
            10'h31a : TempValue = 16'h0000;
            10'h31c : TempValue = 16'h0000;
            10'h31e : TempValue = 16'h0000;
            10'h320 : TempValue = 16'h0000;
            10'h322 : TempValue = 16'h0000;
            10'h324 : TempValue = 16'h0000;
            10'h326 : TempValue = 16'h0000;
            10'h328 : TempValue = 16'h0000;
            10'h32a : TempValue = 16'h0000;
            10'h32c : TempValue = 16'h0000;
            10'h32e : TempValue = 16'h0000;
            10'h330 : TempValue = 16'h0000;
            10'h332 : TempValue = 16'h0000;
            10'h334 : TempValue = 16'h0000;
            10'h336 : TempValue = 16'h0000;
            10'h338 : TempValue = 16'h0000;
            10'h33a : TempValue = 16'h0000;
            10'h33c : TempValue = 16'h0000;
            10'h33e : TempValue = 16'h0000;
            10'h340 : TempValue = 16'h0000;
            10'h342 : TempValue = 16'h0000;
            10'h344 : TempValue = 16'h0000;
            10'h346 : TempValue = 16'h0000;
            10'h348 : TempValue = 16'h0000;
            10'h34a : TempValue = 16'h0000;
            10'h34c : TempValue = 16'h0000;
            10'h34e : TempValue = 16'h0000;
            10'h350 : TempValue = 16'h0000;
            10'h352 : TempValue = 16'h0000;
            10'h354 : TempValue = 16'h0000;
            10'h356 : TempValue = 16'h0000;
            10'h358 : TempValue = 16'h0000;
            10'h35a : TempValue = 16'h0000;
            10'h35c : TempValue = 16'h0000;
            10'h35e : TempValue = 16'h0000;
            10'h360 : TempValue = 16'h0000;
            10'h362 : TempValue = 16'h0000;
            10'h364 : TempValue = 16'h0000;
            10'h366 : TempValue = 16'h0000;
            10'h368 : TempValue = 16'h0000;
            10'h36a : TempValue = 16'h0000;
            10'h36c : TempValue = 16'h0000;
            10'h36e : TempValue = 16'h0000;
            10'h370 : TempValue = 16'h0000;
            10'h372 : TempValue = 16'h0000;
            10'h374 : TempValue = 16'h0000;
            10'h376 : TempValue = 16'h0000;
            10'h378 : TempValue = 16'h0000;
            10'h37a : TempValue = 16'h0000;
            10'h37c : TempValue = 16'h0000;
            10'h37e : TempValue = 16'h0000;
            10'h380 : TempValue = 16'h0000;
            10'h382 : TempValue = 16'h0000;
            10'h384 : TempValue = 16'h0000;
            10'h386 : TempValue = 16'h0000;
            10'h388 : TempValue = 16'h0000;
            10'h38a : TempValue = 16'h0000;
            10'h38c : TempValue = 16'h0000;
            10'h38e : TempValue = 16'h0000;
            10'h390 : TempValue = 16'h0000;
            10'h392 : TempValue = 16'h0000;
            10'h394 : TempValue = 16'h0000;
            10'h396 : TempValue = 16'h0000;
            10'h398 : TempValue = 16'h0000;
            10'h39a : TempValue = 16'h0000;
            10'h39c : TempValue = 16'h0000;
            10'h39e : TempValue = 16'h0000;
            10'h3a0 : TempValue = 16'h0000;
            10'h3a2 : TempValue = 16'h0000;
            10'h3a4 : TempValue = 16'h0000;
            10'h3a6 : TempValue = 16'h0000;
            10'h3a8 : TempValue = 16'h0000;
            10'h3aa : TempValue = 16'h0000;
            10'h3ac : TempValue = 16'h0000;
            10'h3ae : TempValue = 16'h0000;
            10'h3b0 : TempValue = 16'h0000;
            10'h3b2 : TempValue = 16'h0000;
            10'h3b4 : TempValue = 16'h0000;
            10'h3b6 : TempValue = 16'h0000;
            10'h3b8 : TempValue = 16'h0000;
            10'h3ba : TempValue = 16'h0000;
            10'h3bc : TempValue = 16'h0000;
            10'h3be : TempValue = 16'h0000;
            10'h3c0 : TempValue = 16'h0000;
            10'h3c2 : TempValue = 16'h0000;
            10'h3c4 : TempValue = 16'h0000;
            10'h3c6 : TempValue = 16'h0000;
            10'h3c8 : TempValue = 16'h0000;
            10'h3ca : TempValue = 16'h0000;
            10'h3cc : TempValue = 16'h0000;
            10'h3ce : TempValue = 16'h0000;
            10'h3d0 : TempValue = 16'h0000;
            10'h3d2 : TempValue = 16'h0000;
            10'h3d4 : TempValue = 16'h0000;
            10'h3d6 : TempValue = 16'h0000;
            10'h3d8 : TempValue = 16'h0000;
            10'h3da : TempValue = 16'h0000;
            10'h3dc : TempValue = 16'h0000;
            10'h3de : TempValue = 16'h0000;
            10'h3e0 : TempValue = 16'h0000;
            10'h3e2 : TempValue = 16'h0000;
            10'h3e4 : TempValue = 16'h0000;
            10'h3e6 : TempValue = 16'h0000;
            10'h3e8 : TempValue = 16'h0000;
            10'h3ea : TempValue = 16'h0000;
            10'h3ec : TempValue = 16'h0000;
            10'h3ee : TempValue = 16'h0000;
            10'h3f0 : TempValue = 16'h0000;
            10'h3f2 : TempValue = 16'h0000;
            10'h3f4 : TempValue = 16'h0000;
            10'h3f6 : TempValue = 16'h0000;
            10'h3f8 : TempValue = 16'h0000;
            10'h3fa : TempValue = 16'h0000;
            10'h3fc : TempValue = 16'h0000;
            10'h3fe : TempValue = 16'h0000;
            default : TempValue = 16'h0000;
        endcase
    end
    assign Value = TempValue;

endmodule