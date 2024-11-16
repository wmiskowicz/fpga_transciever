`timescale 1ns / 1ps

module tb_top();
  import logger_pkg::*;
  import packet_pkg::*;
  import simple_rx_driver_pkg::*;
  import simple_rx_monitor_pkg::*;
  import simple_rx_scoreboard_pkg::*;
  
  
  // SIMULATION SET
  parameter int NUMBER_OF_PACKETS = 1000;

  int packets_sent;
  int tlast_ctr;

  int sfd_err_ctr, type_err_ctr, size_err_ctr, fcs_err_ctr, rx_er_ctr;
  int invalid_packet_ctr;

  // Parameters
  parameter int G_MEM_SIZE = 256;
  parameter int CLK_PERIOD = 10ns;

  // Packet data
  logic [31:0]  sdf_in;   
  logic [15:0]  type_in;  
  logic [7:0]   size_in;
  logic [7:0]   payload_in [$];
  logic         pkt_rxer_in;


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


  // Class instances
  rx_in_if            rx_in_vif();
  axis_if             axis_vif(clk_in);
  packet              pkt;
  
  mailbox #(packet)   driver_in_mbox    = new();
  mailbox #(byte_q)   driver_out_mbox   = new();
  mailbox #(byte_q)   monitor_out_mbox  = new();
  simple_rx_driver    rx_drv;
  simple_rx_monitor   rx_monitor;
  simple_rx_scoreboard scoreboard;
  

  // Interface assignments
  assign rx_in_vif.clk  = clk_in;
  assign rxd_in         = rx_in_vif.rxd;
  assign rxdv_in        = rx_in_vif.rxdv;
  assign rxer_in        = rx_in_vif.rxer;

  assign axis_vif.tdata  = tdata_out;
  assign axis_vif.tvalid = tvalid_out;
  assign axis_vif.tlast  = tlast_out;
  assign tready_in = axis_vif.tready;

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

  initial begin : clk_proc
    clk_in = 0;
    forever #(CLK_PERIOD / 2) clk_in = ~clk_in;
  end

  initial begin : scoreboard_proc
    scoreboard = new(driver_out_mbox, monitor_out_mbox); 
    scoreboard.run(); 
  end
  
  initial begin : driver_proc
    rx_drv = new(rx_in_vif, driver_in_mbox, driver_out_mbox);
    
    rx_drv.run();

  end

  initial begin : monitor_proc
    rx_monitor = new(axis_vif, monitor_out_mbox);
    
    rx_monitor.run();
  end

  always @(posedge axis_vif.clk) begin
    if ($urandom_range(1, 10) <= 9) begin
      axis_vif.tready <= (~rst_n_in) ? 0 : 1; 
    end else begin
      axis_vif.tready <= 0;
    end
  end

  
  
  always @(negedge rxdv_in) packets_sent <= packets_sent+1;
  always @(posedge axis_vif.tlast) tlast_ctr <= tlast_ctr+1;
    

  
  
  // -----------------------------------------
  // -----------------------------------------
  // --------------- MAIN TEST ---------------
  // -----------------------------------------
  // -----------------------------------------
  initial begin : main_proc
    void'(logger::init());
    init_reset();
    
  
    `log_info("   _____ _____ ____ _____   ____ _____  _    ____ _____ ");
    `log_info("  |_   _| ____/ ___|_   _| / ___|_   _|/ \\  |  _ \\_   _|");
    `log_info("    | | |  _| \\___ \\ | |   \\___ \\ | | / _ \\ | |_) || |  ");
    `log_info("    | | | |___ ___) || |    ___) || |/ ___ \\|  _ < | |  ");
    `log_info("    |_| |_____|____/ |_|   |____/ |_/_/   \\_|_| \\_\\|_|  ");    
    wait_clock_cycles(5);




    for (int i = 0; i < NUMBER_OF_PACKETS; i++) 
    begin
      pkt = new();

      sdf_in  = (true_with_propability_of(95)) ? 32'h5555557f : 32'hDEADDEAD;
      type_in = (true_with_propability_of(95)) ? 16'h1234 : 16'hDEAD;
      size_in = (true_with_propability_of(60))  ? $urandom_range(7,13) : $urandom_range(13,64);
      pkt_rxer_in = true_with_propability_of(1);
      generate_payload(size_in, payload_in);

      if(sdf_in != 32'h5555557f || type_in != 16'h1234 || size_in < 8 || pkt_rxer_in) invalid_packet_ctr++;
      if (sdf_in == 32'hDEADDEAD)
      begin
        sfd_err_ctr++;
      end
      if(type_in == 16'hDEAD)
      begin
        type_err_ctr++;
      end
      if (size_in < 8)
      begin
        size_err_ctr++;
      end
      if (pkt_rxer_in)
      begin
        rx_er_ctr++;
      end
    

      pkt = create_packet(i, pkt_rxer_in, sdf_in, type_in, size_in, payload_in);
      driver_in_mbox.put(pkt);

      wait_clock_cycles($urandom_range(1,5));
    end

    wait(packets_sent == NUMBER_OF_PACKETS);
    wait_clock_cycles(1000);

    scoreboard.check();
    scoreboard.print_summary();
    `log_info($sformatf("Sent packets      = %0d", packets_sent));
    `log_info($sformatf("Recieved packets: = %0d", tlast_ctr));
    `log_info($sformatf("Invalid packets   = %0d", invalid_packet_ctr));
    `log_info($sformatf("Invalid sfd  = %0d", sfd_err_ctr));
    `log_info($sformatf("Invalid type = %0d", type_err_ctr));
    `log_info($sformatf("Invalid size = %0d", size_err_ctr));
    `log_info($sformatf("rxer asserted %0d times", rx_er_ctr));


    logger::summary();
    $finish;
  end


  // -----------------------------------------
  // -----------------------------------------
  // ---------- Funcions and tasks -----------
  // -----------------------------------------
  // -----------------------------------------


task wait_clock_cycles(input int cycles_to_wait);
  int i;
  for (i = 0; i < cycles_to_wait; i++) begin
    @ (posedge clk_in); 
  end
endtask

task init_reset();
  `log_info("Initial reset asserted");
  rst_n_in = 0;
  wait_clock_cycles(10);

  rst_n_in = 1;
  `log_info("Initial reset relased");
  wait_clock_cycles(3);
endtask

task automatic generate_payload(
  input  logic [7:0] size,
  output logic [7:0] payload_array [$]
);
  for (int i = 0; i < size; i++) begin
    payload_array[i] = $urandom % 256;
  end
endtask


function packet create_packet(
  input int          packet_ind,
  input logic        rxer_in,
  input logic [31:0] test_sdf,
  input logic [15:0] test_type,  
  input logic [7:0] test_size,        
  input logic [7:0] payload_data[]
);

  packet pkt;
  pkt = new();
  
  pkt.sfd = test_sdf;
  pkt.packet_id = packet_ind;

  pkt.packet_type = test_type;
  pkt.size = test_size;
  pkt.rxer = rxer_in;

  for (int i = 0; i < test_size; i++) begin
    pkt.payload[i] = payload_data[i];
  end

  pkt.build();

  return pkt;
endfunction


function true_with_propability_of(input int propability); //in % that out==1
  logic random;

  if ($urandom_range(1, 100) <= propability) begin
    random <= (~rst_n_in) ? 0 : 1; 
  end else begin
    random <= 0;
  end

  return random;
endfunction
  
endmodule

