module tb_RundownCounter #(
    parameter RUNDOWNCYCLECOUNT = 8
)(
    input clk,
    input async_rst,
    input RundownTrigger
);

    localparam RUNDOWNBITWIDTH = (RUNDOWNCYCLECOUNT == 1) ? 1 : $clog2(RUNDOWNCYCLECOUNT);

    reg  Active;
    wire ActiveTrigger = RundownTrigger;
    wire NextActive = RundownTrigger;
    always_ff @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            Active <= 0;
        end
        else if (ActiveTrigger) begin
            Active <= NextActive;
        end
    end

    reg  [RUNDOWNBITWIDTH:0] RundownCounter;
    wire                     RundownCounterTrigger = RundownTrigger || Active;
    wire                     RundownExpired = RundownCounter == RUNDOWNCYCLECOUNT;
    wire [RUNDOWNBITWIDTH:0] NextRundownCounter = RundownCounter + 1;
    always_ff @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            RundownCounter <= 0;
        end
        else if (RundownCounterTrigger) begin
            RundownCounter <= NextRundownCounter;
        end
        if (RundownExpired) begin
    		$display("><><><><><><>< Rundown Cycle Limit of %0d Expired ><><><><><><>< ", RUNDOWNCYCLECOUNT);
    		$finish;
    	end
    end

endmodule