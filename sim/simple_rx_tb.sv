module simple_rx_tb;

    // Parameters
    parameter int G_MEM_SIZE = 512;
    parameter int CLK_FREQ = 100_000_000; 
    parameter int CLK_PERIOD = 5ns; 
    parameter SIZE = 10;
    int i;

    // Packet data
    logic [7:0] TEST_SFD_OK  [3:0] = '{8'h55, 8'h55, 8'h55, 8'h7F};
    logic [7:0] TEST_SFD_ERR [3:0] = '{8'h22, 8'h44, 8'h55, 8'h7F};

    logic [7:0] TEST_TYPE_OK  [1:0] = '{8'h12, 8'h34};
    logic [7:0] TEST_TYPE_ERR [1:0] = '{8'haa, 8'h34};

    logic [7:0] TEST_SIZE_OK  = 8'hA; //min 0x8
    logic [7:0] TEST_SIZE_ERR = 8'h3;

    logic [7:0] test_payload [SIZE-1:0] = '{8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66, 8'h77, 8'h88, 8'h99, 8'haa}; 
    logic [7:0] test_fcs_ok = '0;    
    logic [7:0] test_fcs_err = '1;    

  
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
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b0);
      send_packet(TEST_SFD_ERR,TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b0);
      send_packet(TEST_SFD_OK, TEST_TYPE_ERR,TEST_SIZE_OK,  test_fcs_ok, 1'b0);
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_ERR, test_fcs_ok, 1'b0);
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b0); 
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b1); 

      wait_clock_cycles(10);
      rxer_in = 1'b0;
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b0);
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b0);
      send_packet(TEST_SFD_OK, TEST_TYPE_OK, TEST_SIZE_OK,  test_fcs_ok, 1'b0);


      #1000 $finish;
    end

    task wait_clock_cycles(input int cycles_to_wait);
        int i;
        for (i = 0; i < cycles_to_wait; i++) begin
          @ (posedge clk_in); 
        end
      endtask

    task init_reset();
      rst_n_in = 0;
      wait_clock_cycles(10);
      rst_n_in = 1;
      wait_clock_cycles(3);
    endtask

    task automatic send_packet(
      input logic [7:0] test_sdf [3:0],   
      input logic [7:0] test_type [1:0],  
      input logic [7:0] test_size,        
      input logic [7:0] test_fcs,
      input logic test_rxer              
  );
      int i;
      rxdv_in = 1'b1;
  
      for (i = 3; i >= 0; i--) begin
          rxd_in = test_sdf[i];
          wait_clock_cycles(1);
      end
  
      for (i = 1; i >= 0; i--) begin
          rxd_in = test_type[i];
          wait_clock_cycles(1);
      end
  
      rxer_in = test_rxer;
      rxd_in = test_size;
      wait_clock_cycles(1);
  
      generate_payload(test_payload);
      for (i = SIZE-1; i >= 0; i--) begin
          rxd_in = test_payload[i];
          wait_clock_cycles(1);
      end
      
  
      rxd_in = calculate_checksum(TEST_TYPE_OK, TEST_SIZE_OK, test_payload) + test_fcs;
      wait_clock_cycles(1);
  
      rxdv_in = 1'b0;
      wait_clock_cycles(1);
  endtask

  task automatic generate_payload(
    output logic [7:0] payload_array [SIZE-1:0]
  );
    for (int i = 0; i < SIZE; i++) begin
        payload_array[i] = $urandom % 256;
    end
  endtask
  

    function logic [7:0] calculate_checksum(
      input logic [7:0] type_field[1:0],    
      input logic [7:0] size_field,     
      input logic [7:0] payload[SIZE-1:0]
  );
      logic [31:0] sum;
      int i, n;
  
      sum = 0;
    
      sum += size_field;
      for (n = 0; n < 2; n++)
      begin
          sum += type_field[n];
      end
  
      for (i = 0; i < SIZE; i++)
      begin
          sum += payload[i];
      end
  
      return sum[7:0];
  endfunction
      
  
  endmodule
  