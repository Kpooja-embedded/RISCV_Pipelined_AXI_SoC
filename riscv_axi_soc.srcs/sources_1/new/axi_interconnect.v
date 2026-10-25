module axi_interconnect (
    // From Master (soc_top)
    input  wire [31:0] m_axi_araddr,
    input  wire        m_axi_arvalid,
    output wire        m_axi_arready,
    output wire [31:0] m_axi_rdata,
    output wire        m_axi_rvalid,
    input  wire        m_axi_rready,

    // To Slave (memory_model)
    output wire [31:0] s_axi_araddr,
    output wire        s_axi_arvalid,
    input  wire        s_axi_arready,
    input  wire [31:0] s_axi_rdata,
    input  wire        s_axi_rvalid,
    output wire        s_axi_rready
);

    // Direct 1-to-1 Pass-through routing mapping for single Master to single Slave
    assign s_axi_araddr  = m_axi_araddr;
    assign s_axi_arvalid = m_axi_arvalid;
    assign m_axi_arready = s_axi_arready;

    assign m_axi_rdata   = s_axi_rdata;
    assign m_axi_rvalid  = s_axi_rvalid;
    assign s_axi_rready  = m_axi_rready;

endmodule