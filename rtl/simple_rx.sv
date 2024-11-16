module simple_rx #(
    parameter int             G_MEM_SIZE = 256
  ) (
    input  logic              clk_in,
    input  logic              rst_n_in,

    input  logic  [ 7: 0]     rxd_in,
    input  logic              rxdv_in,
    input  logic              rxer_in,

    output logic  [ 7: 0]     tdata_out,
    output logic              tvalid_out,
    output logic              tlast_out,
    input  logic              tready_in,

    // statistics counters
    output logic  [15: 0]     stat_packet_vld_cnt,
    output logic  [15: 0]     stat_packet_err_cnt
  );

// constants definitions
  localparam int                ADDR_WIDTH = 8;
  localparam int                MAX_PACKET_CNT_VAL = 20;
  localparam int                DATA_WIDTH = 8;
  localparam logic [31:0]       C_SFD = 32'h5555557F;
  localparam logic [15:0]       C_PACKET_TYPE = 16'h1234;
  localparam logic [ 7:0]       C_SIZE_MIN = 8'h08;

// types definitions
  typedef enum {IDLE, PCK_SFD, PCK_TYPE, PCK_SIZE, PCK_PAYLOAD, PCK_FCS, PCK_WAIT} state_t;


// signals definitions
  logic [G_MEM_SIZE-1:0][DATA_WIDTH-1:0] data_mem;

  logic [ADDR_WIDTH-1 : 0] wr_addr, rd_addr;
  logic [DATA_WIDTH-1 : 0] wr_data, rd_data;

  logic  wr_enabl, reading;
  logic  clr_last_flag;

// fifo
  wire  [ADDR_WIDTH-1 : 0] last_addr;
  logic [7:0] data_size_in;
  logic fifo_write_en;
  logic fifo_read_en;
  logic [ADDR_WIDTH-1 : 0] last_addr_out;
  logic [7:0] data_size_out;
  logic reading_del;
  logic empty;
  logic full;

  assign tvalid_out = reading_del;
  assign reading = (rd_addr != (last_addr_out + data_size_out)) && !empty;
  assign fifo_read_en = !reading;


  rx_fsm #(
    .ADDR_WIDTH         (ADDR_WIDTH),
    .MAX_PACKET_CNT_VAL (MAX_PACKET_CNT_VAL),
    .DATA_WIDTH         (DATA_WIDTH),
    .G_MEM_SIZE         (G_MEM_SIZE),
    .C_SFD              (C_SFD),
    .C_PACKET_TYPE      (C_PACKET_TYPE),
    .C_SIZE_MIN         (C_SIZE_MIN)
  )
  rx_fsm_0 (
    .clk_in   (clk_in),
    .rst_n_in (rst_n_in),

    .rxd_in   (rxd_in),
    .rxdv_in  (rxdv_in),
    .rxer_in  (rxer_in),

    .stat_packet_vld_cnt(stat_packet_vld_cnt),
    .stat_packet_err_cnt(stat_packet_err_cnt),

    .wr_data  (wr_data),
    .wr_addr  (wr_addr),
    .wr_enabl (wr_enabl),

    .last_data_addr (last_addr),
    .data_size      (data_size_in),
    .fifo_wr_enabl  (fifo_write_en)

  );

// ==========================
// ======== DATA MEM ========
// ==========================

  always_ff @(posedge clk_in)
  begin : DATA_MEM_BLK
    if(~rst_n_in)
    begin
      data_mem  <= '0;
      rd_addr   <= '0;
      rd_data   <= '0;
      tlast_out <= '0;
      clr_last_flag <= '1;
    end
    else
    begin
      // WRITE
      if (wr_enabl)
      begin
        data_mem[wr_addr] <= wr_data;
      end

      // READ
      if (reading && (tready_in || tlast_out || !tvalid_out))
      begin
        rd_data   <= data_mem[rd_addr];
        rd_addr   <= (rd_addr + 1) % G_MEM_SIZE;
        tlast_out <= '0;
        clr_last_flag <= '0;
      end
      else
      begin
        tlast_out <= (rd_addr == last_addr_out + data_size_out) && ~clr_last_flag;
        clr_last_flag <= '1;
      end

    end
  end

  fifo #(
    .DEPTH(16)
  )
  u_fifo (
    .clk          (clk_in),
    .rst_n        (rst_n_in),
    .data_size_in (data_size_in),
    .data_size_out(data_size_out),
    .empty        (empty),
    .full         (full),
    .last_addr_in (last_addr),
    .last_addr_out(last_addr_out),
    .read_en      (fifo_read_en),
    .write_en     (fifo_write_en)
  );


  signal_delay #(
    .DELAY_CYCLES(1)
  )
  u_reading_del (
    .clk       (clk_in),
    .in_signal (reading),
    .out_signal(reading_del),
    .rst_n     (rst_n_in)
  );

  always_ff @(posedge clk_in)
  begin : out_controller
    if (!rst_n_in)
    begin
      tdata_out  <= '0;
    end
    else
    begin
      tdata_out  <= rd_data;
    end
  end

endmodule
