module memory_stage (
    input  wire [31:0] alu_result_in,
    input  wire [31:0] wdata_in,
    output wire [31:0] dcache_addr,
    output wire [31:0] dcache_wdata,
    input  wire [31:0] dcache_rdata,
    output wire [31:0] mem_rdata_out,
    output wire [31:0] alu_result_out
);
    // Directly maps pipeline variables to the external D-Cache boundary
    assign dcache_addr    = alu_result_in;
    assign dcache_wdata   = wdata_in;
    assign mem_rdata_out  = dcache_rdata;
    assign alu_result_out = alu_result_in; // Pass along for writeback
endmodule