module rx_fsm#(
  parameter int                C_MEM_SIZE_LOG2 = 9,
  parameter int                MAX_PACKET_CNT_VAL = 20,
  parameter logic [31:0]       C_SFD = 32'h5544557F,
  parameter logic [15:0]       C_PACKET_TYPE = 16'h1234,
  parameter logic [ 7:0]       C_SIZE_MIN = 8'h08
)(
    // clocks and resets 
    input  logic              clk_in, 
    input  logic              rst_n_in,

    // data input 
    input  logic  [ 7: 0]     rxd_in, 
    input  logic              rxdv_in, 
    input  logic              rxer_in,
    
    // statistics counters 
    output logic  [15: 0]     stat_packet_vld_cnt, 
    output logic  [15: 0]     stat_packet_err_cnt,

    // write data
    output  logic [79:0]               wr_data, 
    output  logic [7:0]                wr_addr, 
    output  logic                      wr_enabl
);

// types definitions 
typedef enum {IDLE, PCK_SFD, PCK_TYPE, PCK_SIZE, PCK_PAYLOAD, PCK_FCS, PCK_WAIT} state_t;   
  
  
// signals definitions 
state_t state; 
int n, i;
logic [7:0] data_buff [9:0];
logic [7:0] packet_type_buff [1:0];
logic [7:0] sdf_buff [3:0];
logic [7:0] size_buff, fcs_buff;
logic [7:0] checksum;
logic packet_vld, packet_err;




always_ff @(posedge clk_in)
 begin
    if(~rst_n_in)
    begin
        state <= IDLE;
        stat_packet_vld_cnt <= '0;
        stat_packet_err_cnt <= '0;
        n <= 0;
        wr_enabl <= 1'b0;
        wr_addr  <= '0;
        wr_data <= '0;
    end
    else
    begin
        case (state)
            IDLE: 
            begin
                if(rxdv_in)
                begin
                    state <= rxer_in ? PCK_WAIT : PCK_SFD;
                    sdf_buff[0] <= rxd_in;
                    n <= 1;
                end
                else
                begin
                    state <= IDLE;
                    n <= 0;
                end      
                wr_enabl <= 1'b0;    
            end
            PCK_SFD:  
            begin
                if(n < 4)
                begin
                    sdf_buff[n] = rxd_in;
                    n <= n + 1;
                end
                else if({sdf_buff[0], sdf_buff[1], sdf_buff[2], sdf_buff[3]} == C_SFD)
                begin
                    state <= rxer_in ? PCK_WAIT : PCK_TYPE;
                    packet_type_buff[0] <= rxd_in; 
                    n <= 1;
                end
                else
                begin
                    state <= PCK_WAIT;
                    n <= 0;
                end
            end
            PCK_TYPE: 
            begin 
                if(n < 2)
                begin
                    packet_type_buff[n] = rxd_in;
                    n <= n + 1;
                end
                else if({packet_type_buff[0], packet_type_buff[1]} == C_PACKET_TYPE)
                begin
                    state <= rxer_in ? PCK_WAIT : PCK_SIZE;
                    size_buff <= rxd_in;
                    n <= 0;
                end
                else
                begin
                    state <= PCK_WAIT;
                end
            end
            PCK_SIZE: 
            begin
                if(size_buff >= C_SIZE_MIN)
                begin
                    state <= PCK_PAYLOAD;
                    data_buff[0] <= rxd_in;
                    n <= 1;
                end
                else
                begin
                    state <= PCK_WAIT;
                    n <= 0;
                end
                
            end
            PCK_PAYLOAD: 
            begin
                if(n < size_buff)
                begin
                    data_buff[n] = rxd_in;
                    n <= n + 1;
                end
                else
                begin
                    state <= rxer_in ? PCK_WAIT : PCK_FCS;
                    fcs_buff <= rxd_in;
                    checksum <= calculate_checksum({packet_type_buff[0], packet_type_buff[1]}, size_buff, data_buff);
                    wr_enabl <= 1'b1;
                    wr_data <= {data_buff[0], data_buff[1], data_buff[2], data_buff[3], data_buff[4], 
                                data_buff[5], data_buff[6], data_buff[7], data_buff[8], data_buff[9]};
                    n <= 0;
                end  
            end
            PCK_FCS:
            begin
                if(fcs_buff == checksum)
                begin
                    packet_vld <= 1'b1;
                    packet_err <= 1'b0;
                end
                else
                begin
                    packet_vld <= 1'b0;
                    packet_err <= 1'b1;
                end
                state <= PCK_WAIT;
                wr_enabl <= '0;
                wr_data  <= '0;
                wr_addr  <= wr_addr + 8'h4;
            end
            PCK_WAIT:
            begin
                if(packet_vld)
                begin
                    stat_packet_vld_cnt <= (stat_packet_vld_cnt >= MAX_PACKET_CNT_VAL) ? stat_packet_vld_cnt : stat_packet_vld_cnt + 1;
                end
                else if(packet_err)
                begin
                    stat_packet_err_cnt <= (stat_packet_err_cnt >= MAX_PACKET_CNT_VAL) ? stat_packet_err_cnt : stat_packet_err_cnt + 1;
                end
                
                packet_vld <= 1'b0;
                packet_err <= 1'b0;
                wr_enabl <= 1'b0;
                wr_data <= '0;
                state <= rxdv_in ? PCK_WAIT : IDLE;
            end
            default:  state <= IDLE;
        endcase
    end
 end


 function logic [7:0] calculate_checksum(
    input logic [15:0] type_field,    
    input logic [7:0] size_field,     
    input logic [7:0] payload[10]
);
    logic [31:0] sum;  // Use a wider register to accumulate the sum
    int i;

    sum = 0;

    sum += type_field[15:8];  
    sum += type_field[7:0];   
    sum += size_field;

    for (i = 0; i < 10; i++)
    begin
        sum += payload[i];
    end

    return sum[7:0];
endfunction

endmodule
