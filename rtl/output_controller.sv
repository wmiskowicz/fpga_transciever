module output_controller #(
    parameter int DATA_WIDTH = 8
)(
    // clocks and resets 
    input  logic                      clk_in, 
    input  logic                      rst_n_in,

    // read data
    input  logic [DATA_WIDTH-1:0]     rd_data,  
    
    // data output 
    output logic  [7:0]               tdata_out, 
    output logic                      tvalid_out, 
    output logic                      tlast_out, 
    input  logic                      tready_in
);


// constants definitions
   
// signals definitions

// signals assignments
assign tlast_out = 1'b0;
// assign tready_in = 1'b0;
assign tvalid_out = 1'b1;


always_ff @(posedge clk_in) 
begin
  if (!rst_n_in) begin
    tdata_out <= '0;
  end 
  else
  begin
    tdata_out <= rd_data;
  end
end


endmodule
