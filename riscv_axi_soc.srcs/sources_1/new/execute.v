module execute (
    input  wire [31:0] pc_in,
    input  wire [31:0] alu_src_a, // From RegFile rs1 (or forwarded)
    input  wire [31:0] reg_b_val, // From RegFile rs2 (or forwarded)
    input  wire [31:0] imm_ext,   // From Decode
    input  wire        alu_src_b_sel, // 0 = reg_b_val, 1 = imm_ext
    input  wire [3:0]  alu_control,   // From Control Unit
    output wire [31:0] alu_result,
    output wire [31:0] pc_target
);
    wire [31:0] alu_operand_b = alu_src_b_sel ? imm_ext : reg_b_val;
    
    // Branch/Jump Target Generation
    assign pc_target = pc_in + imm_ext;

    // Simple ALU core operations
    reg [31:0] alu_out;
    assign alu_result = alu_out;

    always @(*) begin
        case (alu_control)
            4'b0000: alu_out = alu_src_a + alu_operand_b; // ADD
            4'b0001: alu_out = alu_src_a - alu_operand_b; // SUB
            4'b0010: alu_out = alu_src_a & alu_operand_b; // AND
            4'b0011: alu_out = alu_src_a | alu_operand_b; // OR
            4'b0100: alu_out = alu_src_a ^ alu_operand_b; // XOR
            4'b0101: alu_out = alu_src_a << alu_operand_b[4:0]; // SLL
            4'b0110: alu_out = alu_src_a >> alu_operand_b[4:0]; // SRL
            default: alu_out = 32'b0;
        endcase
    end
endmodule