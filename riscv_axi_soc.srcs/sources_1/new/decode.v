module decode (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,        // Freeze decode pipeline register
    input  wire        flush,        // Clear instruction on branch misprediction
    
    // Inputs from Fetch Stage
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    
    // Outputs to Execute Stage
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [4:0]  rd,
    output reg  [31:0] imm_ext
);

    // Internal wires for combinational splitting
    wire [4:0]  rs1_comb = instr_in[19:15];
    wire [4:0]  rs2_comb = instr_in[24:20];
    wire [4:0]  rd_comb  = instr_in[11:7];
    wire [6:0]  opcode   = instr_in[6:0];
    reg  [31:0] imm_comb;

    // Combinational Immediate Generator (Supports I-type, S-type, B-type, U-type, J-type)
    always @(*) begin
        case (opcode)
            7'h13, 7'h03, 7'h67: // I-type (ALU Imm, Loads, JALR)
                imm_comb = {{20{instr_in[31]}}, instr_in[31:20]};
            7'h23: // S-type (Stores)
                imm_comb = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]};
            7'h63: // B-type (Branches)
                imm_comb = {{20{instr_in[31]}}, instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
            7'h37, 7'h17: // U-type (LUI, AUIPC)
                imm_comb = {instr_in[31:12], 12'b0};
            7'h6f: // J-type (JAL)
                imm_comb = {{12{instr_in[31]}}, instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};
            default: 
                imm_comb = 32'b0;
        endcase
    end

    // Pipeline Register Allocation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out    <= 32'b0;
            instr_out <= 32'h00000013; // Reset to NOP instruction (addi x0, x0, 0)
            rs1       <= 5'b0;
            rs2       <= 5'b0;
            rd        <= 5'b0;
            imm_ext   <= 32'b0;
        end else if (flush) begin
            // Insert NOP if a pipeline flush is requested
            pc_out    <= 32'b0;
            instr_out <= 32'h00000013; 
            rs1       <= 5'b0;
            rs2       <= 5'b0;
            rd        <= 5'b0;
            imm_ext   <= 32'b0;
        end else if (!stall) begin
            // Normal operation: Pass signals forward
            pc_out    <= pc_in;
            instr_out <= instr_in;
            rs1       <= rs1_comb;
            rs2       <= rs2_comb;
            rd        <= rd_comb;
            imm_ext   <= imm_comb;
        end
        // If stall is active, all registers hold their data intact
    end

endmodule