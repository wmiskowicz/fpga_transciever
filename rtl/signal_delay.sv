module signal_delay #(
  parameter int DELAY_CYCLES = 1  
)(
  input  logic  clk,        
  input  logic  rst_n,      
  input  logic  in_signal,  
  output logic  out_signal  
);

  logic [DELAY_CYCLES-1:0] shift_register;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_register <= '0;
      out_signal     <= 0;
    end else begin
      shift_register <= {shift_register[DELAY_CYCLES-2:0], in_signal};
      out_signal     <= shift_register[DELAY_CYCLES-1];
    end
  end

endmodule
