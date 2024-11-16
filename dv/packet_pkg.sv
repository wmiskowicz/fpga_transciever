package packet_pkg;

  import logger_pkg::*;

  typedef enum {VALID = 0, ERR_SFD, ERR_TYPE, ERR_SIZE_MIN, ERR_TOO_SHORT, ERR_FCS} e_pkt_result;
  typedef bit [7:0] byte_q [$];

  class packet;
    
    bit     [31:0]  sfd;
    bit     [15:0]  packet_type;
    bit     [ 7:0]  size;
    bit     [ 7:0]  payload[$];
    bit     [ 7:0]  fcs;
    
    bit     [ 7:0]  raw[$];
    bit             rxer;

    int             packet_id;
    localparam MIN_PACKET_SIZE = 8;
    
    
    function new();

    endfunction
    
    function e_pkt_result parse(byte_q data_queue);
      raw = data_queue;
    
      if (raw.size() < 4 || raw[0] != 8'h55 || raw[1] != 8'h55 || raw[2] != 8'h55 || raw[3] != 8'h7F) begin
        `log_err("Invalid SFD");
        return ERR_SFD;
      end
    
      packet_type = {raw[4], raw[5]};
      size = raw[6];
    
      if (size < MIN_PACKET_SIZE) begin
        `log_err("Invalid packet size: less than minimum required size");
        return ERR_SIZE_MIN;
      end
    
      if (raw.size() < 7 + size) begin
        `log_err("Packet too short for specified payload size");
        return ERR_TOO_SHORT;
      end
    
      for (int i = 0; i < size; i++) begin
        payload[i] = raw[7 + i];
      end
    
      // Sprawdzanie FCS
      fcs = raw[7 + size];
      if (fcs != calculate_checksum(packet_type, size, {payload[0], payload[1], payload[2], payload[3]})) begin
        `log_err("FCS error");
        return ERR_FCS;
      end
    
      return VALID;
    endfunction
    

    function void build();
    
      // SFD
      raw[0] = sfd[31:24];
      raw[1] = sfd[23:16];
      raw[2] = sfd[15:8];
      raw[3] = sfd[7:0];
    
      // packet_type
      raw[4] = packet_type[15:8];
      raw[5] = packet_type[7:0];
    
      // size
      raw[6] = size;
    
      // payload
      for (int i = 0; i < size; i++) begin
        raw[7 + i] = payload[i];
      end
    
      // fcs
      fcs = calculate_checksum(packet_type, size, {payload[0], payload[1], payload[2], payload[3]});
      raw[7 + size] = fcs;
    endfunction

    function packet clone();
      packet pkt_copy = new();
    
      pkt_copy.packet_type = this.packet_type;
      pkt_copy.size = this.size;
      pkt_copy.fcs = this.fcs;
    
      pkt_copy.payload = this.payload;   
      pkt_copy.raw = this.raw;
    
      return pkt_copy;
    endfunction
    

    
    
    
    function logic [7:0] calculate_checksum(
      input logic [15:0] type_field,    
      input logic [7:0] size_field,     
      input logic [31:0] payload
  );
      logic [31:0] sum;
      int i, n;
  
      sum = 0;
    
      sum += size_field;
      sum += type_field[15:8];
      sum += type_field[7:0];
      
  
      sum += payload[31:24];
      sum += payload[23:16];
      sum += payload[15:8];
      sum += payload[7:0];
      
  
      return sum[7:0];
  endfunction
    

  endclass

endpackage
