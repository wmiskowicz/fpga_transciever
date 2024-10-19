module simple_rx_tb;

    // Parameters
    parameter int G_MEM_SIZE = 512;
    parameter int CLK_FREQ = 100_000_000; 
    parameter int CLK_PERIOD = 5ns; 
    parameter SIZE = 10;
    int i;

    // Packet data
    logic [7:0] TEST_SFD_OK [3:0] = '{8'h55, 8'h44, 8'h55, 8'h7F};
    logic [7:0] TEST_TYPE_OK [1:0] = '{8'h12, 8'h34};
    logic [7: 0] TEST_SIZE_OK = 8'hA; //min 0x8
    logic [7:0] TEST_PAYLOAD [SIZE-1:0] = '{8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77, 8'h88, 8'h99, 8'haa}; 
    logic [7:0] TEST_FCS = calculate_checksum({TEST_TYPE_OK[1], TEST_TYPE_OK[0]}, TEST_SIZE_OK, TEST_PAYLOAD);
    

  
    // Clock and reset signals
    logic clk_in;
    logic rst_n_in;
  
    // Data input signals
    logic [7:0] rxd_in;
    logic rxdv_in;
    logic rxer_in;
  
    // Data output signals
    logic [7:0] tdata_out;
    logic tvalid_out;
    logic tlast_out;
    logic tready_in;
  
    // Statistics counters
    logic [15:0] stat_packet_vld_cnt;
    logic [15:0] stat_packet_err_cnt;

    
  
    // Instantiate the DUT (Device Under Test)
    simple_rx #(
      .G_MEM_SIZE(G_MEM_SIZE)
    ) dut (
      .clk_in     (clk_in),
      .rst_n_in   (rst_n_in),
      .rxd_in     (rxd_in),
      .rxdv_in    (rxdv_in),
      .rxer_in    (rxer_in),
      .tdata_out  (tdata_out),
      .tvalid_out (tvalid_out),
      .tlast_out  (tlast_out),
      .tready_in  (tready_in),
      .stat_packet_vld_cnt(stat_packet_vld_cnt),
      .stat_packet_err_cnt(stat_packet_err_cnt)
    );
  
    // Clock generation
    initial begin
        clk_in = 0;
        forever #(CLK_PERIOD / 2) clk_in = ~clk_in;
    end
  
  
    // Testbench logic
    initial begin

      rxd_in = 8'b0;
      rxdv_in = 1'b0;
      rxer_in = 1'b0;
      tready_in = 1'b0;
      i = 0;

      init_reset();
      
      rxdv_in = '1;
      for (i = 3; i >= 0; i--)
      begin
        rxd_in = TEST_SFD_OK[i];
        wait_clock_cycles(1);
      end
      
      for (i = 1; i >= 0; i--)
      begin
        rxd_in = TEST_TYPE_OK[i];
        wait_clock_cycles(1);
      end

      rxd_in = TEST_SIZE_OK;
      wait_clock_cycles(1);
      
      for (i = SIZE-1; i >= 0; i--)
      begin
        rxd_in = TEST_PAYLOAD[i];
        wait_clock_cycles(1);
      end

      rxd_in = TEST_FCS;
      wait_clock_cycles(1);
      rxdv_in = 1'b0;
      
      
      

      


      // TODO: Implement stimulus logic to drive inputs
      // Example:
      // rxd_in = 8'hFF;
      // rxdv_in = 1'b1;
      // #10;
      // rxdv_in = 1'b0;
      // ...
  
      // TODO: Monitor the outputs and check expected behavior
      // Example:
      // if (tvalid_out == 1 && tdata_out == 8'hFF) begin
      //   $display("Test passed");
      // end else begin
      //   $display("Test failed");
      // end
  
      // End simulation after some time
      #100 $finish;
    end

    task wait_clock_cycles(input int cycles_to_wait);
        int i;
        for (i = 0; i < cycles_to_wait; i++) begin
          @ (posedge clk_in);  // Wait for each positive edge of the clock
        end
      endtask

    task init_reset();
      rst_n_in = 0;
      wait_clock_cycles(10);
      rst_n_in = 1;
      wait_clock_cycles(3);
    endtask

    function logic [7:0] calculate_checksum(
        input logic [15:0] type_field,    
        input logic [7:0] size_field,     
        input logic [7:0] payload[]
    );
        logic [31:0] sum;  // Use a wider register to accumulate the sum
        int i;
    
        sum = 0;
    
        sum += type_field[15:8];  
        sum += type_field[7:0];   
        sum += size_field;
    
        for (i = 0; i < size_field; i++) begin
            sum += payload[i];
        end
    
        return sum[7:0];
    endfunction
      
  
  endmodule
  