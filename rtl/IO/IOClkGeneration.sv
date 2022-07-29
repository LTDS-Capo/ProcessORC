module IOClkGeneration (
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input   [1:0] ConfigurationAddr,
    input         ConfigWriteEnUpper,
    input         ConfigWriteEnLower,
    input  [15:0] ConfigInput,
    output [15:0] ConfigOutput,


    output [7:0]       divided_clk_out,
    output [3:0] [1:0] divided_clk_sel_out
);
    
    // clk0: sys_clk
    // clk1: src_clk0
    // clk2: src_clk1
    // clk3: src_clk2
    // clk4: divided_clk0
    // clk5: divided_clk1
    // clk6: divided_clk2
    // clk7: divided_clk3

    // divided_clk Config bits
    // >  [13:0] - clk division
    // > [15:24] - clk source

    // Config Decoder
        logic [3:0] ClkDecoder;
        always_comb begin
            ClkDecoder = 0;
            ClkDecoder[ConfigurationAddr] = 1'b1;
        end
    //

    // divided_clk Deneration
        wire   [3:0] [15:0] ConfigOutputs;
        wire   [3:0]        divided_clks;
        wire   [3:0]  [1:0] ConfigSelOutputs;
        genvar ClkGen;
        generate
            for (ClkGen = 0; ClkGen < 4; ClkGen = ClkGen + 1) begin : ClkDivisionGeneration
                wire        Local_ConfigWriteEnUpper = ClkDecoder && ConfigWriteEnUpper;
                wire        Local_ConfigWriteEnLower = ClkDecoder && ConfigWriteEnLower;
                wire [15:0] ConfigInput = DataIn;
                wire [15:0] ConfigOutput;
                wire        divided_clk;
                wire  [1:0] divided_clk_sel;
                IOClkGeneration ClkDivisionGen (
                    .sys_clk           (sys_clk),
                    .clk_en            (clk_en),
                    .sync_rst          (sync_rst),
                    .async_rst         (async_rst),
                    .src_clk0          (src_clk0),
                    .src_clk1          (src_clk1),
                    .src_clk2          (src_clk2),
                    .ConfigWriteEnUpper(Local_ConfigWriteEnUpper),
                    .ConfigWriteEnLower(Local_ConfigWriteEnLower),
                    .ConfigInput       (ConfigInput),
                    .ConfigOutput      (ConfigOutput),
                    .divided_clk       (divided_clk),
                    .divided_clk_sel   (divided_clk_sel)
                );
                assign ConfigOutputs[ClkGen] = ConfigOutput;
                assign divided_clks[ClkGen] = divided_clk;
                assign ConfigSelOutputs[ClkGen] = divided_clk_sel;
            end
        endgenerate
    //

    // Configuration Read
        assign ConfigOutput = ConfigOutputs[ConfigurationAddr];
    //

    // divided_clk output assignment
        assign divided_clk_out = {divided_clks, src_clk2, src_clk1, src_clk0, sys_clk};
        assign divided_clk_sel_out = ConfigSelOutputs;
    //

endmodule