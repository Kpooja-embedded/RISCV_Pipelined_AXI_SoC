module writeback (
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_rdata,
    input  wire        mem_to_reg, // Control signal: 0 = ALU, 1 = Mem
    output wire [31:0] wb_data
);
    assign wb_data = mem_to_reg ? mem_rdata : alu_result;
endmodule