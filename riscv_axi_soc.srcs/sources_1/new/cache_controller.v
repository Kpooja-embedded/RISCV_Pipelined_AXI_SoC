module cache_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // Core Interface
    input  wire [31:0] cpu_addr,
    input  wire        cpu_req,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,
    
    // AXI Master Interface Connection
    output reg  [31:0] axi_req_addr,
    output reg         axi_req_valid,
    input  wire        axi_req_ready,
    input  wire [31:0] axi_rdata,
    input  wire        axi_rdata_valid
);

    // Cache Parameters: 1024 words, Direct Mapped
    // Address splitting: [31:12] Tag, [11:2] Index, [1:0] Byte Offset
    reg [19:0] tag_array [0:1023];
    reg [31:0] data_array [0:1023];
    reg        valid_array [0:1023];

    wire [9:0]  index = cpu_addr[11:2];
    wire [19:0] tag   = cpu_addr[31:12];

    // FSM States
    localparam IDLE  = 1'b0;
    localparam ALLOC = 1'b1;
    reg state;

    wire cache_hit = valid_array[index] && (tag_array[index] == tag);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cpu_ready <= 1'b1;
            axi_req_valid <= 1'b0;
            // Clear valid array loop omitted for brevity
        end else begin
            case (state)
                IDLE: begin
                    if (cpu_req) begin
                        if (cache_hit) begin
                            cpu_rdata <= data_array[index];
                            cpu_ready <= 1'b1; // Instant 1-cycle hit
                        end else begin
                            // Cache Miss: Start AXI Fetch
                            cpu_ready     <= 1'b0; 
                            axi_req_addr  <= cpu_addr;
                            axi_req_valid <= 1'b1;
                            state         <= ALLOC;
                        end
                    end
                end

                ALLOC: begin
                    if (axi_req_ready) begin
                        axi_req_valid <= 1'b0;
                    end
                    if (axi_rdata_valid) begin
                        // Update Cache Memory with incoming line
                        data_array[index]  <= axi_rdata;
                        tag_array[index]   <= tag;
                        valid_array[index] <= 1'b1;
                        
                        cpu_ready <= 1'b1; // Unstall the core
                        state     <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule