module rx_fsm #(
        parameter int                ADDR_WIDTH = 8,
        parameter int                MAX_PACKET_CNT_VAL = 20,
        parameter int                DATA_WIDTH = 8,
        parameter int                G_MEM_SIZE = 256,
        parameter logic [31:0]       C_SFD = 32'h5555557F,
        parameter logic [15:0]       C_PACKET_TYPE = 16'h1234,
        parameter logic [ 7:0]       C_SIZE_MIN = 8'h08
    )(
        input  logic              clk_in,
        input  logic              rst_n_in,

        input  logic  [7:0]       rxd_in,
        input  logic              rxdv_in,
        input  logic              rxer_in,

        // statistics counters
        output logic  [15: 0]     stat_packet_vld_cnt,
        output logic  [15: 0]     stat_packet_err_cnt,

        // write data
        output  logic [DATA_WIDTH-1:0]       wr_data,
        output  logic [ADDR_WIDTH-1:0]       wr_addr,
        output  logic                        wr_enabl,
        output  logic [ADDR_WIDTH-1:0]       last_data_addr,
        output  logic [7:0]                  data_size,
        output  logic                        fifo_wr_enabl
    );

    // types definitions
    typedef enum {IDLE, PCK_SFD, PCK_TYPE, PCK_SIZE, PCK_PAYLOAD, PCK_FCS, PCK_WAIT} state_t;


    // signals definitions
    state_t state;
    logic [7:0] write_ind;
    logic [7:0] data_buff [19:0];
    logic [7:0] type_buff [1:0];
    logic [7:0] sdf_buff [3:0];
    logic [7:0] size_buff, fcs_buff;
    logic [7:0] checksum;

    assign data_size = size_buff;


    // --------------------------
    // --------- RX FSM ---------
    // --------------------------
    always_ff @(posedge clk_in)
    begin
        if(~rst_n_in)
        begin
            state <= IDLE;
            stat_packet_vld_cnt <= '0;
            stat_packet_err_cnt <= '0;
            write_ind           <= '0;
            wr_enabl            <= 1'b0;
            wr_addr             <= '0;
            wr_data             <= '0;
            last_data_addr      <= '0;
            fifo_wr_enabl       <= 1'b0;
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
                        write_ind <= 1;
                    end
                    else
                    begin
                        state <= IDLE;
                        write_ind <= '0;
                    end
                    fifo_wr_enabl <= 1'b0;
                    wr_enabl <= 1'b0;
                end
                PCK_SFD:
                begin
                    if(write_ind < 4)
                    begin
                        sdf_buff[write_ind] <= rxd_in;
                        write_ind <= write_ind + 1;
                    end
                    else if({sdf_buff[0], sdf_buff[1], sdf_buff[2], sdf_buff[3]} == C_SFD)
                    begin
                        state <= rxer_in ? PCK_WAIT : PCK_TYPE;
                        type_buff[0] <= rxd_in;
                        write_ind    <= 1;
                    end
                    else
                    begin
                        state     <= PCK_WAIT;
                        write_ind <= '0;
                    end
                end
                PCK_TYPE:
                begin
                    if(write_ind < 2)
                    begin
                        type_buff[write_ind] <= rxd_in;
                        write_ind            <= write_ind + 1;
                    end
                    else if({type_buff[0], type_buff[1]} == C_PACKET_TYPE)
                    begin
                        state     <= rxer_in ? PCK_WAIT : PCK_SIZE;
                        size_buff <= rxd_in;
                        write_ind <= '0;
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
                        wr_data   <= rxd_in;
                        wr_enabl  <= 1'b1;
                        write_ind <= 1;
                        last_data_addr <= wr_addr;
                    end
                    else
                    begin
                        state <= PCK_WAIT;
                        write_ind <= '0;
                    end
                end
                PCK_PAYLOAD:
                begin
                    if(write_ind < size_buff)
                    begin
                        data_buff[write_ind] <= rxd_in;
                        wr_data <= rxd_in;
                        write_ind <= write_ind + 1;
                    end
                    else
                    begin
                        state <= rxer_in ? PCK_WAIT : PCK_FCS;
                        fcs_buff <= rxd_in;
                        wr_enabl <= 1'b0;
                        checksum <= calculate_checksum({type_buff[0], type_buff[1]}, size_buff, {data_buff[0], data_buff[1], data_buff[2], data_buff[3]});
                        write_ind <= '0;
                    end
                    wr_addr  <= (wr_addr + 1) % G_MEM_SIZE;
                end
                PCK_FCS:
                begin
                    if(fcs_buff == checksum)
                    begin
                        stat_packet_vld_cnt <= (stat_packet_vld_cnt >= MAX_PACKET_CNT_VAL) ? stat_packet_vld_cnt : stat_packet_vld_cnt + 1;
                        fifo_wr_enabl <= 1'b1;
                    end
                    else
                    begin
                        stat_packet_err_cnt <= (stat_packet_err_cnt >= MAX_PACKET_CNT_VAL) ? stat_packet_err_cnt : stat_packet_err_cnt + 1;
                        fifo_wr_enabl <= 1'b0;
                    end

                    state    <= IDLE;
                    wr_enabl <= '0;
                    wr_data  <= '0;
                end
                PCK_WAIT:
                begin
                    wr_enabl <= 1'b0;
                    wr_data  <= '0;
                    state    <= (rxdv_in == 0) ? IDLE : PCK_WAIT;
                end
                default:  state <= IDLE;
            endcase
        end
    end


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

endmodule
