package simple_rx_driver_pkg;
  
  import logger_pkg::*;
  import packet_pkg::*;
  
  class simple_rx_driver;
    virtual interface rx_in_if vif;
    mailbox #(packet) packet_mbx;
    mailbox #(byte_q) out_mbox;
    
    function new(virtual interface rx_in_if vif, mailbox #(packet) packet_mbx, mailbox #(byte_q) out_mbox);
      this.vif = vif;
      this.packet_mbx = packet_mbx;
      this.out_mbox = out_mbox;
    endfunction
    
    task run();
      packet pkt;
      byte_q raw_data_queue; 
      
      forever begin
        packet_mbx.get(pkt);
        `log_info($sformatf("Driver received input packet %0d", pkt.packet_id)); 
        `log_info($sformatf("Packet sdf=0x%h, type=0x%h, size=%0d", pkt.sfd, pkt.packet_type, pkt.size));
        raw_data_queue.delete();        

        if(pkt.sfd == 32'h5555557f && pkt.packet_type == 16'h1234 && pkt.size >= 8 && !pkt.rxer)
        begin
          `log_info("Valid packet sent to driver_out_mbox");
          for (int i=0; i < pkt.size; i++) begin
            raw_data_queue.push_back(pkt.raw[i + 7]);
          end
          out_mbox.put(raw_data_queue);
        end


        `log_info("Starting packet transmission");
        foreach (pkt.raw[i]) begin
          @(posedge vif.clk);      
          vif.rxd <= pkt.raw[i]; 
          vif.rxdv <= 1;

          vif.rxer <= pkt.rxer;
          if (pkt.rxer) `log_warn("rxer set to 1 for the entire packet");
        end

        @(posedge vif.clk);
        vif.rxdv <= 0;
        `log_info($sformatf("Completed transmission of packet, %0d", pkt.packet_id));
      end
      
    endtask
  endclass

endpackage
