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
  localparam logic [31:0]       C_SFD = 32'h5544557F; 
  localparam logic [15:0]       C_PACKET_TYPE = 16'h1234; 
  localparam logic [ 7:0]       C_SIZE_MIN = 8'h08; 
   
  // types definitions 
  typedef enum {IDLE, PCK_SFD, PCK_TYPE, PCK_SIZE, PCK_PAYLOAD, PCK_FCS, PCK_WAIT} state_t;   
  
  
  // signals definitions 
  state_t state; 
  logic [7:0] data_mem [G_MEM_SIZE]; 
  int n, i;
  logic [7:0] checksum; 
  logic [7:0] data_buff [C_MEM_SIZE_LOG2-1:0];
  logic [7:0] packet_type_buff [1:0];
  logic [7:0] a_packet_type_buff [1:0];
  logic [7:0] sdf_buff [3:0];
  logic [7:0] a_sdf_buff [3:0];
  logic [7:0] size_buff;
  logic packet_vld, packet_err;
   



 /* pozostaly kod 
 */ 

 always_ff @(posedge clk_in)
 begin
    if(~rst_n_in)
    begin
        state <= IDLE;
        stat_packet_vld_cnt <= '0;
        stat_packet_err_cnt <= '0;
        n <= 0;
    end
    else
    begin
        case (state)
            IDLE: 
            begin
                if(rxdv_in)
                begin
                    state <= PCK_SFD;
                    sdf_buff[0] <= rxd_in;
                    n <= 1;
                end
                else
                begin
                    state <= IDLE;
                    n <= 0;
                end             
            end
            PCK_SFD:  
            begin
                if(n < 4)
                begin
                    sdf_buff[n] = rxd_in;
                    n <= n + 1;
                end
                
                if({sdf_buff[3], sdf_buff[2], sdf_buff[1], sdf_buff[0]} == C_SFD)
                begin
                    state <= PCK_TYPE;
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
                if(n < 4)
                begin
                    packet_type_buff[n] = rxd_in;
                    n <= n + 1;
                end
                else if({packet_type_buff[1], packet_type_buff[0]} == C_PACKET_TYPE)
                begin
                    state <= PCK_SIZE;
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
                state <= (size_buff >= C_SIZE_MIN) ? PCK_PAYLOAD : PCK_WAIT;
                data_buff[0] <= rxd_in;
                n <= 1;
            end
            PCK_PAYLOAD: 
            begin
                if(n < C_MEM_SIZE_LOG2)
                begin
                    packet_type_buff[n] = rxd_in;
                    n <= n + 1;
                end
                else
                begin
                    state <= PCK_FCS;
                    n <= 0;
                end  
            end
            PCK_FCS:
            begin
                if(rxd_in == 8'hFF)
                begin
                    packet_vld <= 1'b1;
                    packet_err <= 1'b0;
                end
                else
                begin
                    packet_vld <= 1'b0;
                    packet_err <= 1'b1;
                end
                state      <= PCK_WAIT;
            end
            PCK_WAIT:
            begin
                if(packet_vld)
                begin
                    stat_packet_vld_cnt <= stat_packet_vld_cnt + 1;
                end
                else if(packet_err)
                begin
                    stat_packet_err_cnt <= stat_packet_err_cnt + 1;
                end
                
                packet_vld <= 1'b0;
                packet_err <= 1'b0;
                state <= rxdv_in ? PCK_WAIT : IDLE;
            end
            default:  state <= IDLE;
        endcase
    end
 end


 always_comb 
 begin
    case (state)
        IDLE: 
        PCK_SFD:
        begin
            a_sdf_buff[] = rxd_in
        end
        default: 
    endcase
 end



 function logic [7:0] calculate_checksum(
    input logic [15:0] type_field,    
    input logic [7:0] size_field,     
    input logic [7:0] payload[]
);
    logic [31:0] sum;  // Use a wider register to accumulate the sum
    int i;

    sum = 0;

    sum += type_field[15:8];  
    sum += type_field[7:0];   
    sum += size_field;

    for (i = 0; i < size_field; i++) begin
        sum += payload[i];
    end

    return sum[7:0];
endfunction

 
endmodule 