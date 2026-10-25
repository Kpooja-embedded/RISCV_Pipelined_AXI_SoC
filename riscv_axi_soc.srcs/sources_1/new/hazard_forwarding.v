module hazard_forwarding (
    input  wire       global_stall, // From Cache Controller (Miss processing)
    output reg        stall_fetch,
    output reg        stall_decode,
    output reg        flush_execute
);
    always @(*) begin
        if (global_stall) begin
            // Freeze the entire front-end of the pipeline
            stall_fetch   = 1'b1;
            stall_decode  = 1'b1;
            flush_execute = 1'b0;
        end else begin
            stall_fetch   = 1'b0;
            stall_decode  = 1'b0;
            flush_execute = 1'b0;
        end
    end
endmodule