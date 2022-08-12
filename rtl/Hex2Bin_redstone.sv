module Hex2Bin #(
  parameter TICKDELAY = 4;
)(
  input clk,
  input clk_en,
  input sync_rst,

  input  [3:0] dust,

  output       bin3,
  output       bin2,
  output       bin1,
  output       bin0
);

    genvar DelayIndex;
    wire [TICKDELAY-1:0] [3:0] DelayedDust;
    generate
        for (DelayIndex = 0; DelayIndex < TICKDELAY; DelayIndex = DelayIndex + 1) begin
            if (DelayIndex = 0) begin
                reg  [3:0] DelayRegister;
                wire       DelayRegisterTrigger = clk_en || sync_rst;
                wire [3:0] NextDelayRegister = (sync_rst) ? 0 : dust;
                always_ff @(posedge clk) begin
                    if (DelayRegisterTrigger) begin
                        DelayRegister <= NextDelayRegister;
                    end
                end
                assign DelayedDust[DelayIndex] = DelayRegister;
            end
            else begin
                reg  [3:0] DelayRegister;
                wire       DelayRegisterTrigger = clk_en || sync_rst;
                wire [3:0] NextDelayRegister = (sync_rst) ? 0 : DelayedDust[DelayIndex-1];
                always_ff @(posedge clk) begin
                    if (DelayRegisterTrigger) begin
                        DelayRegister <= NextDelayRegister;
                    end
                end
                assign DelayedDust[DelayIndex] = DelayRegister;
            end
        end
    endgenerate

    assign bin3 = DelayedDust[TICKDELAY-1][3];
    assign bin2 = DelayedDust[TICKDELAY-1][2];
    assign bin1 = DelayedDust[TICKDELAY-1][1];
    assign bin0 = DelayedDust[TICKDELAY-1][0];

endmodule