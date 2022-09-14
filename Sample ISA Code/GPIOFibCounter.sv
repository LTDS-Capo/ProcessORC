module FlashROM_Instruction (
    input  [9:0] Address,
    output [15:0] Value
);

//                                                                            //
    //  Clock Conf Addr = 384-391
    //                  >  [13:0] - clk division (4x)
    //                  > [15:16] - clk source (4x)
    //       Timer Addr = 392-395
    //                  > [26:0] Wait time
    //                  >   [27] PreScaler
    //                  > - 0 : 1x
    //                  > - 1 : 32x
    //                  > [30:28] Timer Select
    //                  > [31] Command
    //                  > - 0 : Clear(Store)/Check(Load)
    //                  > - 1 : Set(Store)/Wait(Load)
    // GPIO MemMap Addr = 396-397
    //                  > Pulse of Length 0 Selects clock.
    //                  > GPIO (WriteBit[0], WriteByte[1], ClearBit[2], ReadStatus[3], ReadPin[4], ReadStatusByte[5], ReadPinByte[6], PulseBit(Length)[7]) - In, Out, OutEn
    //                  > - NonPulse
    //                  > [15:13] IOAddr
    //                  > [12:10] Command
    //                  >   [9:8] *Ignore*
    //                  >   [7:1] WriteByteValue/*Ignore*
    //                  >     [0] WriteByteValue/WriteBitValue/*Ignore*
    //                  > - Pulse
    //                  > [15:13] IOAddr
    //                  > [12:10] Command
    //                  >   [9:0] PulseLength
//                                                                            //
// Boot time segisters
    // r0 - ZR
    // r1 - Clock Base Pointer > *clear
    // r2 - Clock Config Command > *clear
    // r3 - *clear
    // r4 - *clear
    // r5 - *clear
    // r6 - *clear
    // r7 - *clear
    // r8 - *clear
    // r9 - *clear
    // rA - *clear
    // rB - *clear
    // rC - *clear
    // rD - *clear
    // rE - *clear
    // rF - *Return Pointer*
//                                                                            //
// Run time registers
    // r0 - ZR
    // r1 - GPIO Base Pointer
    // r2 - Timer Base Pointer
    // r3 - GPIO     Data [Lower Byte]
    // r4 - GPIO MetaData [Upper Byte]
    // r5 - GPIO  Command {MetaData, Data}
    // r6 - Timer Command [Lower 2 bytes]
    // r7 - Timer Command [Upper 2 bytes]
    // r8 - Fib Value
    // r9 - Itteration Counter
    // rA - 
    // rB - 
    // rC - 
    // rD - 
    // rE - Timer Wait Register
    // rF - *Return Pointer*
//                                                                            //

    
    
    
    // Load IO Addresses

    // Configure GPIO Clock

    // Read GPIO Byte

    // Write GPIO Byte











    logic [15:0] TempValue;
    always_comb begin : ROMBlock
        case (Address)
            //                  Instruction
            10'h000 : TempValue = 16'h0000;
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
