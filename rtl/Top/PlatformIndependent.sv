module PlatformIndependent #(
    parameter DATABITWIDTH = 16
)(
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,
);
    
    localparam CLOCKDOMAINS = 4;
    wire [CLOCKDOMAINS-2:0] ResetClks = {src_clk2, src_clk1, src_clk0};
    wire [CLOCKDOMAINS-1:0] sync_rst_trigger = '0;
    wire [CLOCKDOMAINS-1:0] clk_en_out;
    wire [CLOCKDOMAINS-1:0] sync_rst_out;
    wire [CLOCKDOMAINS-1:0] init_out;
    TopLevelReset #(
        .RESETWAITCYCLES      (625000),
        .RESETCYCLELENGTH     (16),
        .OPERATIONALWAITCYCLES(25000),
        .INITIALIZEWAITCYCLES (1024),
        .CLOCKDOMAINS         (CLOCKDOMAINS)
    ) ResetSystem (
        .sys_clk
        .clk_en
        .async_rst_in
        .clks 
        .sync_rst_trigger
        .clk_en_out
        .sync_rst_out
        .init_out
    );

    SystemFlasher #(
        .MEMMAPSTARTADDR(),
        .MEMMAPENDADDR()
    )Flasher (
        .clk         (),
        .clk_en      (),
        .sync_rst    (),
        .FlashInit   (),
        .InstFlashEn (),
        .DataFlashEn (),
        .FlashAddr   (),
        .FlashData   (),
        .SystemEnable()
    );

    CPU_TopLevel #(
        .DATABITWIDTH(DATABITWIDTH)
    ) MainCPU (
        .clk                  (),
        .clk_en               (),
        .sync_rst             (),
        .SystemEn             (),
        .HaltOut              (),
        .IOOutACK             (),
        .IOOutREQ             (),
        .IOMinorOpcode        (),
        .IOOutAddress         (),
        .IOOutData            (),
        .IOOutDestReg         (),
        .IOInACK              (),
        .IOInREQ              (),
        .IOInDestReg          (),
        .IOInData             (),
        .RegisterWriteData_OUT(),
        .RegisterWriteEn_OUT  (),
        .RegisterWriteAddr_OUT()
    );
    

// IO Interfaces
    // $GEN$ CaseGen([8:Addr, 4:Output], CaseConfig.txt)
        IOManager #(

        ) IOInterface (

        );
        // Port Mapping

        // Module Generation

    // $GENEND$
//



endmodule