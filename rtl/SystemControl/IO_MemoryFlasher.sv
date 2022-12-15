module IO_MemoryFlasher #(
    parameter MEMMAPSTARTADDR = 384,
    parameter MEMMAPENDADDR = 511
)(
    input clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input         FlashInit,

    output        InstFlashEn,
    output        DataFlashEn,
    output  [9:0] FlashAddr,
    output [15:0] FlashData,

    input         SoftwareResetIn,
    input   [3:0] ResetVectorIn,
    output        ResetResponseOut,

    output        ResetTriggerOut,
    output        CPUResetLockoutOut,
    output        IOResetLockoutOut,

    output        SystemEnable,

    input         IOOut_ACK,
    output        IOOut_REQ,
    input         IOOut_ResponseRequested,
    input   [3:0] IOOut_DestReg,
    input  [31:0] IOOut_Data,

    output        IOIn_ACK,
    input         IOIn_REQ,
    output        IOIn_RegResponseFlag,
    output        IOIn_MemResponseFlag,
    output  [3:0] IOIn_DestReg,
    output [31:0] IOIn_Data
);

    wire        FlashReadEn;

    IO_MemoryFlasher_Flasher #(
        .MEMMAPSTARTADDR(MEMMAPSTARTADDR),
        .MEMMAPENDADDR(MEMMAPENDADDR)
    ) Flasher (
        .clk               (clk),
        .clk_en            (clk_en),
        .sync_rst          (sync_rst),
        .FlashInit         (FlashInit),
        .SoftwareResetIn   (SoftwareResetIn),
        .ResetVectorIn     (ResetVectorIn),
        .ResetResponseOut  (ResetResponseOut),
        .ResetTriggerOut   (ResetTriggerOut),
        .CPUResetLockoutOut(CPUResetLockoutOut),
        .IOResetLockoutOut (IOResetLockoutOut),
        .InstFlashEn       (InstFlashEn),
        .DataFlashEn       (DataFlashEn),
        .FlashAddr         (FlashAddr),
        .FlashDataOut      (FlashData),
        .SystemEnable      (SystemEnable),
        .FlashReadEn       (FlashReadEn),
        .FlashDataIn       (IOIn_Data[15:0])
    );

    IO_MemoryFlasher_IOMemory IOMemory (
        .clk                    (clk),
        .clk_en                 (clk_en),
        .sync_rst               (sync_rst),
        .FlashReadEn            (FlashReadEn),
        .FlashAddr              (FlashAddr),
        .IOOut_ACK              (IOOut_ACK),
        .IOOut_REQ              (IOOut_REQ),
        .IOOut_ResponseRequested(IOOut_ResponseRequested),
        .IOOut_DestReg          (IOOut_DestReg),
        .IOOut_Data             (IOOut_Data),
        .IOIn_ACK               (IOIn_ACK),
        .IOIn_REQ               (IOIn_REQ),
        .IOIn_RegResponseFlag   (IOIn_RegResponseFlag),
        .IOIn_MemResponseFlag   (IOIn_MemResponseFlag),
        .IOIn_DestReg           (IOIn_DestReg),
        .IOIn_Data              (IOIn_Data)
    );

endmodule