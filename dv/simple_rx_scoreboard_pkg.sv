package simple_rx_scoreboard_pkg;

  import logger_pkg::*;
  import packet_pkg::*;


  class simple_rx_scoreboard;
    mailbox #(byte_q) monitor_mbox;
    mailbox #(byte_q) driver_mbox;

    byte_q rx_buffer_queue[$]; 
    byte_q tx_buffer_queue[$]; 

    int num_rx_packets        = 0;
    int num_tx_packets        = 0;
    int total_rx_bytes        = 0;
    int total_tx_bytes        = 0;
    int num_fcs_errors        = 0;
    int num_correct_packets   = 0;
    int num_incorrect_packets = 0;

    function new(mailbox #(byte_q) driver_mbox, mailbox #(byte_q) monitor_mbox);
      this.monitor_mbox = monitor_mbox;
      this.driver_mbox = driver_mbox;
    endfunction

    task run();
      fork
        forever 
        begin
          byte_q rx_data;
          monitor_mbox.get(rx_data);
          rx_buffer_queue.push_back(rx_data);
        end

        forever 
        begin
          byte_q tx_data;
          driver_mbox.get(tx_data);
          tx_buffer_queue.push_back(tx_data);
        end
      join
    endtask

    function void check();
      int min_size = (rx_buffer_queue.size() < tx_buffer_queue.size()) ? 
                     rx_buffer_queue.size() : tx_buffer_queue.size();

        // Sent packets
        for (int pkg_idx = 0; pkg_idx < min_size; pkg_idx++) 
        begin

          $display("\n\n");
          `log_info($sformatf("PACKET %0d ", pkg_idx));
          for (int byte_idx = 0; byte_idx < rx_buffer_queue[pkg_idx].size(); byte_idx++) 
          begin
              
              `log_info($sformatf("Packet %0d, byte %0d: RX = 0x%0h, TX = 0x%0h",
                                 pkg_idx, byte_idx, rx_buffer_queue[pkg_idx][byte_idx], tx_buffer_queue[pkg_idx][byte_idx]));
          end
        end

        // Mismatch check
        for (int pkg_idx = 0; pkg_idx < min_size; pkg_idx++) 
        begin
          
          for (int byte_idx = 0; byte_idx < rx_buffer_queue[pkg_idx].size(); byte_idx++) 
          begin
              if(rx_buffer_queue[pkg_idx][byte_idx] != tx_buffer_queue[pkg_idx][byte_idx])
              begin
                `log_warn($sformatf("Data mismatch at packet %0d, byte %0d: RX = 0x%0h, TX = 0x%0h",
                                 pkg_idx, byte_idx, rx_buffer_queue[pkg_idx][byte_idx], tx_buffer_queue[pkg_idx][byte_idx]));
                num_incorrect_packets++;  
                break;           
              end
              else if(byte_idx == rx_buffer_queue[pkg_idx].size()-1) num_correct_packets++;
          end
        end

      if (rx_buffer_queue.size() != tx_buffer_queue.size()) begin
        `log_warn($sformatf("Buffer size mismatch: RX size = %0d, TX size = %0d",
                            rx_buffer_queue.size(), tx_buffer_queue.size()));
      end

      // Statistics
      num_rx_packets = rx_buffer_queue.size();
      num_tx_packets = tx_buffer_queue.size();
      total_rx_bytes = calculate_total_bytes(rx_buffer_queue);
      total_tx_bytes = calculate_total_bytes(tx_buffer_queue);
    endfunction 

    function void print_summary();
      `log_info(" ____  _   _ __  __ __  __    _    ______   __");
      `log_info("/ ___|| | | |  \\/  |  \\/  |  / \\  |  _ \\ \\ / /");
      `log_info("\\___ \\| | | | |\\/| | |\\/| | / _ \\ | |_) \\ V / ");
      `log_info(" ___) | |_| | |  | | |  | |/ ___ \\|  _ < | |  ");
      `log_info("|____/ \\___/|_|  |_|_|  |_/_/   \\_|_| \\_\\|_|  ");
      

      `log_info($sformatf("Packets successful:   %d", num_correct_packets));
      `log_info($sformatf("Packets unsuccessful: %d", num_incorrect_packets));
      // `log_info($sformatf("total_rx_bytes: %d", total_rx_bytes));
      // `log_info($sformatf("total_tx_bytes: %d", total_tx_bytes));
    endfunction

    function int calculate_total_bytes(byte_q buffer[$]);
      int total = 0;
      foreach (buffer[i]) begin
        total += buffer[i].size();
      end
      return total;
    endfunction
  endclass

endpackage
