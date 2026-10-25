module soc_top (
    input wire clk,
    input wire rst_n,
    
    // Interface directly matching your testbench memory model
    output wire [31:0] s_axi_araddr,
    output wire        s_axi_arvalid,
    input  wire        s_axi_arready,
    input  wire [31:0] s_axi_rdata,
    input  wire        s_axi_rvalid,
    output wire        s_axi_rready
);

    // Core <--> Cache Interconnect
    wire [31:0] i_addr, i_rdata, d_addr, d_wdata, d_rdata;
    wire        i_ready, i_req, d_we, d_ready, d_req;

    // Cache <--> AXI Master Interconnect
    wire [31:0] cache_axi_addr, cache_axi_rdata;
    wire        cache_axi_valid, cache_axi_ready, cache_axi_rdata_valid;

    // AXI Master <--> Interconnect Interconnect
    wire [31:0] m_axi_araddr, m_axi_rdata;
    wire        m_axi_arvalid, m_axi_arready, m_axi_rvalid, m_axi_rready;

    // 1. Instantiate Core
    riscv_top u_riscv_core (
        .clk(clk), .rst_n(rst_n),
        .icache_addr(i_addr), .icache_rdata(i_rdata), .icache_ready(i_ready), .icache_req(i_req),
        .dcache_addr(d_addr), .dcache_wdata(d_wdata), .dcache_rdata(d_rdata), .dcache_we(d_we), .dcache_ready(d_ready), .dcache_req(d_req)
    );

    // 2. Instantiate Cache Top (Combines I-Cache and D-Cache)
    cache_top u_cache_system (
        .clk(clk), .rst_n(rst_n),
        .icache_addr(i_addr), .icache_req(i_req), .icache_rdata(i_rdata), .icache_ready(i_ready),
        .dcache_addr(d_addr), .dcache_wdata(d_wdata), .dcache_rdata(d_rdata), .dcache_we(d_we), .dcache_req(d_req), .dcache_ready(d_ready),
        .cache_axi_addr(cache_axi_addr), .cache_axi_valid(cache_axi_valid), .cache_axi_ready(cache_axi_ready),
        .cache_axi_rdata(cache_axi_rdata), .cache_axi_rdata_valid(cache_axi_rdata_valid)
    );

    // 3. Instantiate AXI Master
    axi_master_interface u_axi_master (
        .clk(clk), .rst_n(rst_n),
        .ctrl_addr(cache_axi_addr), .ctrl_valid(cache_axi_valid), .ctrl_ready(cache_axi_ready),
        .ctrl_rdata(cache_axi_rdata), .ctrl_rdata_valid(cache_axi_rdata_valid),
        .m_axi_araddr(m_axi_araddr), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready)
    );

    // 4. Instantiate AXI Interconnect (Routes Master to Slave Memory)
    axi_interconnect u_interconnect (
        .m_axi_araddr(m_axi_araddr), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
        .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata), .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready)
    );

endmodule