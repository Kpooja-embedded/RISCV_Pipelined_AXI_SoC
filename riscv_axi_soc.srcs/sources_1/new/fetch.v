module fetch (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,        // From hazard/cache unit
    input  wire        pc_src,       // 1 if branching, 0 if sequential
    input  wire [31:0] pc_target,    // Branch/Jump target address from Execute
    output reg  [31:0] pc_out
);

    wire [31:0] next_pc;
    wire [31:0] pc_plus_4;

    // Sequential PC increment
    assign pc_plus_4 = pc_out + 32'd4;

    // Next PC selection logic (Mux)
    assign next_pc = (pc_src) ? pc_target : pc_plus_4;

    // Program Counter Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 32'h00000000; // Reset vector (usually 0x00000000)
        end else if (!stall) begin
            pc_out <= next_pc;      // Update PC only if not stalled
        end
        // If stall is active, pc_out holds its previous value
    end

endmodule