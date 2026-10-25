`timescale 1ns / 1ps

module tb_soc_top();

    reg clk;
    reg rst_n;

    // Interconnect wires between SoC and Memory Model
    wire [31:0] axi_addr;
    wire        axi_valid;
    wire        axi_ready;
    wire [31:0] axi_rdata;
    wire        axi_rvalid;
    wire        axi_rready;

    // 1. Instantiate your newly structured SoC
    soc_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_araddr(axi_addr),
        .s_axi_arvalid(axi_valid),
        .s_axi_arready(axi_ready),
        .s_axi_rdata(axi_rdata),
        .s_axi_rvalid(axi_rvalid),
        .s_axi_rready(axi_rready)
    );

    // 2. Instantiate the External Memory Model 
    memory_model u_mem (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_araddr(axi_addr),
        .s_axi_arvalid(axi_valid),
        .s_axi_arready(axi_ready),
        .s_axi_rdata(axi_rdata),
        .s_axi_rvalid(axi_rvalid),
        .s_axi_rready(axi_rready)
    );

    // Clock Generator (50MHz)
    always #10 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;

        // Hold reset for 100ns
        #100;
        rst_n = 1;
        
        // Let it run for 1000ns to see instruction fetches
        #1000;
        $finish;
    end

endmodule