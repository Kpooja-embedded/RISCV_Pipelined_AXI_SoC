module memory_model (
    input  wire        clk,
    input  wire        rst_n,

    // AXI Slave Interface
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    output reg  [31:0] s_axi_rdata,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Simple 4KB Memory Array
    reg [31:0] mem [0:1023];

    // Initialize Memory with dummy Program/Data
    initial begin
        mem[0] = 32'h00500113; // li x2, 5  (Example RISC-V Instruction)
        mem[1] = 32'h00600193; // li x3, 6
        mem[2] = 32'h00310233; // add x4, x2, x3
    end

    // Simple Read Handshaking Model
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_arready <= 1'b0;
                // Add fake latency if desired: here it responds immediately next cycle
                s_axi_rdata   <= mem[s_axi_araddr[11:2]]; 
                s_axi_rvalid  <= 1'b1;
            end
            
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end
endmodule