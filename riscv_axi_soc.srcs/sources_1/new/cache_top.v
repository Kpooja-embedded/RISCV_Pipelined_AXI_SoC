module cache_top (
    input  wire        clk,
    input  wire        rst_n,

    // Core Instruction Interface
    input  wire [31:0] icache_addr,
    input  wire        icache_req,
    output wire [31:0] icache_rdata,
    output wire        icache_ready,

    // Core Data Interface
    input  wire [31:0] dcache_addr,
    input  wire [31:0] dcache_wdata,
    output wire [31:0] dcache_rdata,
    input  wire        dcache_we,
    input  wire        dcache_req,
    output wire        dcache_ready,

    // Interface to AXI Master
    output reg  [31:0] cache_axi_addr,
    output reg         cache_axi_valid,
    input  wire        cache_axi_ready,
    input  wire [31:0] cache_axi_rdata,
    input  wire        cache_axi_rdata_valid
);

    // Internal wires connecting individual controllers
    wire [31:0] i_axi_addr, d_axi_addr;
    wire        i_axi_valid, d_axi_valid;
    wire        i_axi_ready, d_axi_ready;

    // 1. Instruction Cache Controller Instance
    cache_controller u_icache (
        .clk(clk), .rst_n(rst_n),
        .cpu_addr(icache_addr), .cpu_req(icache_req), .cpu_rdata(icache_rdata), .cpu_ready(icache_ready),
        .axi_req_addr(i_axi_addr), .axi_req_valid(i_axi_valid), .axi_req_ready(i_axi_ready),
        .axi_rdata(cache_axi_rdata), .axi_rdata_valid(cache_axi_rdata_valid && !d_axi_valid) // Priority to Data
    );

    // 2. Data Cache Controller Instance 
    cache_controller u_dcache (
        .clk(clk), .rst_n(rst_n),
        .cpu_addr(dcache_addr), .cpu_req(dcache_req), .cpu_rdata(dcache_rdata), .cpu_ready(dcache_ready),
        .axi_req_addr(d_axi_addr), .axi_req_valid(d_axi_valid), .axi_req_ready(d_axi_ready),
        .axi_rdata(cache_axi_rdata), .axi_rdata_valid(cache_axi_rdata_valid && d_axi_valid)
    );

    // 3. Simple Fixed-Priority Arbiter (Data Cache over Instruction Cache)
    always @(*) begin
        if (d_axi_valid) begin
            cache_axi_addr  = d_axi_addr;
            cache_axi_valid = d_axi_valid;
        end else begin
            cache_axi_addr  = i_axi_addr;
            cache_axi_valid = i_axi_valid;
        end
    end

    assign d_axi_ready = d_axi_valid ? cache_axi_ready : 1'b0;
    assign i_axi_ready = !d_axi_valid ? cache_axi_ready : 1'b0;

endmodule