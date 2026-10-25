module riscv_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // Instruction Cache Interface
    output wire [31:0] icache_addr,
    input  wire [31:0] icache_rdata,
    input  wire        icache_ready,
    output wire        icache_req,
    
    // Data Cache Interface
    output wire [31:0] dcache_addr,
    output wire [31:0] dcache_wdata,
    input  wire [31:0] dcache_rdata,
    output wire        dcache_we,
    input  wire        dcache_ready,
    output wire        dcache_req
);

    // Interconnect wires between stages
    wire [31:0] pc_fetch, pc_decode, pc_execute;
    wire [31:0] instr_decode;
    wire [4:0]  rs1_dec, rs2_dec, rd_dec;
    wire [31:0] imm_dec;
    wire [31:0] alu_res_exec, pc_tgt_exec;
    wire [31:0] mem_rdata_mem, alu_res_mem;
    wire [31:0] wb_data;

    wire stall_fetch, stall_decode, flush_execute;
    wire global_stall = !icache_ready || (dcache_req && !dcache_ready);

    // 1. Fetch Stage
    fetch u_fetch (
        .clk(clk), .rst_n(rst_n),
        .stall(stall_fetch || global_stall),
        .pc_src(1'b0), .pc_target(32'b0),
        .pc_out(pc_fetch)
    );
    assign icache_addr = pc_fetch;
    assign icache_req  = rst_n;

    // 2. Decode Stage
    decode u_decode (
        .clk(clk), .rst_n(rst_n),
        .stall(stall_decode || global_stall), .flush(flush_execute),
        .pc_in(pc_fetch), .instr_in(icache_rdata),
        .pc_out(pc_decode), .instr_out(instr_decode),
        .rs1(rs1_dec), .rs2(rs2_dec), .rd(rd_dec), .imm_ext(imm_dec)
    );

    // 3. Execute Stage
    execute u_execute (
        .pc_in(pc_decode), .alu_src_a(32'b0), .reg_b_val(32'b0),
        .imm_ext(imm_dec), .alu_src_b_sel(1'b1), .alu_control(4'b0000),
        .alu_result(alu_res_exec), .pc_target(pc_tgt_exec)
    );

    // 4. Memory Stage
    memory_stage u_memory_stage (
        .alu_result_in(alu_res_exec), .wdata_in(32'b0),
        .dcache_addr(dcache_addr), .dcache_wdata(dcache_wdata), .dcache_rdata(dcache_rdata),
        .mem_rdata_out(mem_rdata_mem), .alu_result_out(alu_res_mem)
    );
    assign dcache_we  = 1'b0; 
    assign dcache_req = 1'b0; 

    // 5. Writeback Stage
    writeback u_writeback (
        .alu_result(alu_res_mem), .mem_rdata(mem_rdata_mem),
        .mem_to_reg(1'b0), .wb_data(wb_data)
    );

    // Hazard Unit
    hazard_forwarding u_hazard (
        .global_stall(global_stall),
        .stall_fetch(stall_fetch), .stall_decode(stall_decode), .flush_execute(flush_execute)
    );

endmodule