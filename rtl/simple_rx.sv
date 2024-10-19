module simple_rx #( 
    parameter int             G_MEM_SIZE = 512 
  ) ( 
    // clocks and resets 
    input  logic              clk_in, 
    input  logic              rst_n_in, 
     
    // data input 
    input  logic  [ 7: 0]     rxd_in, 
    input  logic              rxdv_in, 
    input  logic              rxer_in, 
 
    // data output 
    output logic  [ 7: 0]     tdata_out, 
    output logic              tvalid_out, 
    output logic              tlast_out, 
    input  logic              tready_in, 
     
    // statistics counters 
    output logic  [15: 0]     stat_packet_vld_cnt, 
    output logic  [15: 0]     stat_packet_err_cnt 
  ); 
   
  // constants definitions 
  localparam int                C_MEM_SIZE_LOG2 = $clog2(G_MEM_SIZE); 
  localparam int                MAX_PACKET_CNT_VAL = 20;
  localparam logic [31:0]       C_SFD = 32'h5544557F; 
  localparam logic [15:0]       C_PACKET_TYPE = 16'h1234; 
  localparam logic [ 7:0]       C_SIZE_MIN = 8'h08; 
   
  // types definitions 
  typedef enum {IDLE, PCK_SFD, PCK_TYPE, PCK_SIZE, PCK_PAYLOAD, PCK_FCS, PCK_WAIT} state_t;   
  
  
  // signals definitions 
  state_t state; 
  logic [7:0] data_mem [G_MEM_SIZE]; 
  int n, i;
  logic [7:0] data_buff [9:0];
  logic [7:0] packet_type_buff [1:0];
  logic [7:0] sdf_buff [3:0];
  logic [7:0] size_buff, fcs_buff;
  logic [7:0] checksum;
  logic packet_vld, packet_err;
   
  wire [7 :0] wr_addr, rd_addr;
  wire [79:0] wr_data, rd_data;
  wire wr_enabl;


 /* pozostaly kod 
 */ 
rx_fsm #(
  .C_MEM_SIZE_LOG2    (C_MEM_SIZE_LOG2),
  .MAX_PACKET_CNT_VAL (MAX_PACKET_CNT_VAL),
  .C_SFD              (C_SFD),
  .C_PACKET_TYPE      (C_PACKET_TYPE),
  .C_SIZE_MIN         (C_SIZE_MIN)
) u_rx_fsm (
  .clk_in(clk_in),                     
  .rst_n_in(rst_n_in), 

  .rxd_in(rxd_in),                     
  .rxdv_in(rxdv_in),                   
  .rxer_in(rxer_in),
  
  // statistics counters 
  .stat_packet_vld_cnt(stat_packet_vld_cnt), 
  .stat_packet_err_cnt(stat_packet_err_cnt),


  .wr_data(wr_data),
  .wr_addr(wr_addr),
  .wr_enabl(wr_enabl)
);

data_mem #(
    .ADDR_WIDTH(8),        
    .DATA_WIDTH(80)         
)
data_mem_inst (
    .clk_in(clk_in),
    .rst_n_in(rst_n_in),
    .wr_data(wr_data),
    .wr_addr(wr_addr),
    .wr_enabl(wr_enabl),
    .rd_data(rd_data),
    .rd_addr(rd_addr)
);


output_controller #(
    .ADDR_WIDTH(8),
    .DATA_WIDTH(80)
  ) u_output_controller (
    .clk_in(clk_in),
    .rst_n_in(rst_n_in),
    .rd_data(rd_data),
    .rd_addr(rd_addr),
    .tdata_out(tdata_out),
    .tvalid_out(tvalid_out),
    .tlast_out(tlast_out),
    .tready_in(tready_in)
  );




 
endmodule 