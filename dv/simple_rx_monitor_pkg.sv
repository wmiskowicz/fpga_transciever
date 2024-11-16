package simple_rx_monitor_pkg;

  import logger_pkg::*;
  import packet_pkg::*;

  class simple_rx_monitor;
    virtual interface axis_if axis_vif;
    mailbox #(byte_q) out_mbox;

    e_pkt_result parse_result;
    logic del_tready;
    int   rx_packet_ctr;

    function new(virtual interface axis_if axis_vif, mailbox #(byte_q) out_mbox);
      this.axis_vif = axis_vif;
      this.out_mbox = out_mbox;
      this.rx_packet_ctr = 0;
    endfunction

    task run();
      byte_q data_queue;

      forever begin
        @(posedge axis_vif.clk) del_tready <= axis_vif.tvalid ? axis_vif.tready : '1;

        if ((axis_vif.tvalid && del_tready)) 
        begin
          data_queue.push_back(axis_vif.tdata); 
        end

          if (axis_vif.tlast) 
          begin
            rx_packet_ctr++;
            `log_info($sformatf("Completed recieving packet %d.", rx_packet_ctr));

            out_mbox.put(data_queue); 
            data_queue.delete();      
          end
        
      end
    endtask
  endclass
endpackage
