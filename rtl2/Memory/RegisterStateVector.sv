module RegisterStateMachine (
    input clk,
    input clk_en,
    input sync_rst,

    
);


genvar REGISTERINDEX;
generate
    for (REGISTERINDEX = 0; REGISTERINDEX < 16; REGISTERINDEX = REGISTERINDEX + 1) begin : RegisterStateGeneration
        if (REGISTERINDEX == 0) begin
            //* Zero Register State
            ZRStateMachine StateMachine (
                .clk             (clk),
                .clk_en          (clk_en),
                .sync_rst        (sync_rst),
                .InstructionValid(InstructionValid),
                .DirtyWrite      (),
                .DirtyIssue      (),
                .WritingTo       (),
                .IsDirty         (),
                .HasPendingWrite ()
            );
        end
        else if (REGISTERINDEX == 14) begin
           //* Top Of Stack State
           // -> assign these straight to pins from the stack cache
        end
        else begin
            //* General Purpose Register State
            GPRStateMachine #(
                .PENDINGREADBITWIDTH(8)
            ) StateMachine (
                .clk             (clk),
                .clk_en          (clk_en),
                .sync_rst        (sync_rst),
                .InstructionValid(InstructionValid),
                .DirtyWrite      (),
                .DirtyIssue      (),
                .ToRunahead      (),
                .FromRunahead    (),
                .WritingBack     (),
                .WritingTo       (),
                .ReadingFrom     (),
                .IsClean         (),
                .IsDirty         (),
                .HasPendingWrite ()
            );
        end
    end
endgenerate

endmodule : RegisterStateMachine