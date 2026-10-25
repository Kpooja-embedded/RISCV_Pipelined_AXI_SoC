module axi_master_interface (
    input  wire        clk,
    input  wire        rst_n,
    
    // Internal Controller Interface
    input  wire [31:0] ctrl_addr,
    input  wire        ctrl_valid,
    output reg         ctrl_ready,
    output reg  [31:0] ctrl_rdata,
    output reg         ctrl_rdata_valid,

    // Standard AXI4 Read Channels
    // Read Address Channel (AR)
    output reg  [31:0] m_axi_araddr,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,
    // Read Data Channel (R)
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);

    // Master Read FSM States
    localparam M_IDLE   = 2'b00;
    localparam M_RADDR  = 2'b01;
    localparam M_RDATA  = 2'b10;
    reg [1:0] r_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_state          <= M_IDLE;
            ctrl_ready       <= 1'b1;
            ctrl_rdata_valid <= 1'b0;
            m_axi_arvalid    <= 1'b0;
            m_axi_rready     <= 1'b0;
        end else begin
            case (r_state)
                M_IDLE: begin
                    ctrl_rdata_valid <= 1'b0;
                    if (ctrl_valid) begin
                        m_axi_araddr  <= ctrl_addr;
                        m_axi_arvalid <= 1'b1;
                        ctrl_ready    <= 1'b0;
                        r_state       <= M_RADDR;
                    end
                end

                M_RADDR: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1; // Ready to receive payload
                        r_state       <= M_RDATA;
                    end
                end

                M_RDATA: begin
                    if (m_axi_rvalid) begin
                        ctrl_rdata       <= m_axi_rdata;
                        ctrl_rdata_valid <= 1'b1;
                        m_axi_rready     <= 1'b0;
                        ctrl_ready       <= 1'b1;
                        r_state          <= M_IDLE;
                    end
                end
            endcase
        end
    end
endmodule