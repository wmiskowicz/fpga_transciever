module fifo #(
  parameter int DEPTH = 16
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [7:0]   last_addr_in,
    input  logic [7:0]   data_size_in,
    input  logic         write_en, 
    input  logic         read_en,
    output logic [7:0]   last_addr_out,
    output logic [7:0]   data_size_out,
    output logic         empty,
    output logic         full
);


  typedef struct packed {
    logic [7:0] last_addr;
    logic [7:0] data_size;
  } fifo_entry_t;

  fifo_entry_t fifo_mem[DEPTH];
  
  logic [$clog2(DEPTH)     : 0] read_ptr;
  logic [$clog2(DEPTH)     : 0] write_ptr;
  logic [$clog2(DEPTH+1)-1 : 0] item_ctr;

  logic write_en_del, read_en_del;

  // Outputs
  assign empty = (item_ctr == 0);
  assign full  = (item_ctr == DEPTH);
  assign last_addr_out = fifo_mem[read_ptr].last_addr;
  assign data_size_out = fifo_mem[read_ptr].data_size;

  // Write
  always_ff @(posedge clk) 
  begin : write_blk
    if (~rst_n) 
    begin
      write_ptr <= '0;

      for(int i = 0; i < DEPTH; i++) fifo_mem[i] <= '0;
    end 
    else if (write_en && !full) 
    begin
      fifo_mem[write_ptr].last_addr <= last_addr_in;
      fifo_mem[write_ptr].data_size <= data_size_in;
      write_ptr <= (write_ptr + 1) % DEPTH;
    end
  end

  // Read
  always_ff @(posedge clk) 
  begin : read_blk
    if (!rst_n) 
    begin
      read_ptr <= 0;
    end 
    else if (read_en && !empty) 
    begin
      read_ptr <= (read_ptr + 1) % DEPTH;
    end
  end


  always_ff @(posedge clk) 
  begin : item_ctr_blk
    if (~rst_n) 
    begin
      write_en_del <= '0;
      read_en_del  <= '0;
      item_ctr     <= '0;
    end
    else 
    begin
      if(!(write_en_del || read_en_del) && (write_en && read_en)) // concurrently wr_en and rd_en
      begin
        item_ctr <= item_ctr;
      end
      else if(write_en && !full)
      begin
        item_ctr <= item_ctr + 1;
      end
      else if (read_en && !empty) 
      begin
        item_ctr <= item_ctr - 1;
      end
      write_en_del <= write_en;
      read_en_del  <= read_en;
    end


  end

endmodule
