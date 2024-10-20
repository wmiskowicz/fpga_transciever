module output_controller #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8,
    parameter int SIZE       = 10 
)(
    // clocks and resets 
    input  logic                      clk_in, 
    input  logic                      rst_n_in,

    // read data
    input  logic [DATA_WIDTH-1:0]     rd_data,  
    output logic [ADDR_WIDTH-1:0]     rd_addr,
    input  logic                      rd_enabl,  
    
    // data output 
    output logic  [7:0]               tdata_out, 
    output logic                      tvalid_out, 
    output logic                      tlast_out, 
    input  logic                      tready_in
);


// constants definitions
localparam IND_WIDTH = $clog2(SIZE);
   
// signals definitions

// signals assignments
assign tlast_out = 1'b0;
assign tready_in = 1'b0;
assign tvalid_out = 1'b1;


always_ff @(posedge clk_in) 
begin
    if (!rst_n_in) begin
        tdata_out <= '0;
        rd_addr   <= 4'hE;
    end 
    else
    begin
        if(rd_enabl)
        begin
            rd_addr   <= rd_addr + 4'h2;
        end
        tdata_out <= rd_data;
    end
end


endmodule
