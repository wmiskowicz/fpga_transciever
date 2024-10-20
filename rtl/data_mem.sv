module data_mem #(
    parameter int ADDR_WIDTH = 4,  
    parameter int DATA_WIDTH = 8,
    parameter int SIZE       = 10 
)(
    // clocks and resets 
    input  logic                      clk_in, 
    input  logic                      rst_n_in,

    // input data
    input  logic [DATA_WIDTH-1:0]     wr_data,  
    input  logic [ADDR_WIDTH-1:0]     wr_addr,  
    input  logic                      wr_enabl, 

    output logic [DATA_WIDTH-1:0]     rd_data,
    input  logic [ADDR_WIDTH-1:0]     rd_addr,
    output logic                      rd_start
);


    // types definitions
    typedef enum {IDLE, READ } rd_state_t;

    // constants definitions
    localparam REG1_ADDR = 4'h00;
    localparam REG2_ADDR = 4'h02;
    localparam REG3_ADDR = 4'h04;
    localparam REG4_ADDR = 4'h06;
    localparam REG5_ADDR = 4'h08;
    localparam REG6_ADDR = 4'h0A;
    localparam REG7_ADDR = 4'h0C;
    localparam REG8_ADDR = 4'h0E;
    localparam IND_WIDTH = $clog2(SIZE);


    // signals definitions
    logic [IND_WIDTH-1 : 0] read_ind, write_ind;
    rd_state_t state;
    logic [DATA_WIDTH-1 : 0] data_reg1   [SIZE-1 : 0];
    logic [DATA_WIDTH-1 : 0] data_reg2   [SIZE-1 : 0];
    logic [DATA_WIDTH-1 : 0] data_reg3   [SIZE-1 : 0];
    logic [DATA_WIDTH-1 : 0] data_reg4   [SIZE-1 : 0]; 
    logic [DATA_WIDTH-1 : 0] data_reg5   [SIZE-1 : 0];
    logic [DATA_WIDTH-1 : 0] data_reg6   [SIZE-1 : 0];
    logic [DATA_WIDTH-1 : 0] data_reg7   [SIZE-1 : 0];
    logic [DATA_WIDTH-1 : 0] data_reg8   [SIZE-1 : 0];   
  

    // --------------------------
    // ------ WRITE BRIDGE ------
    // --------------------------
    always_ff @(posedge clk_in)
    begin
        if (~rst_n_in) 
        begin
            write_ind <= '0;
            rd_start <= '0;
        end
        else
        begin
            if(wr_enabl && write_ind < SIZE)
            begin
                case (wr_addr)
                    REG1_ADDR: 
                    begin
                        data_reg1[write_ind] <= wr_data;
                    end
                    REG2_ADDR: 
                    begin
                        data_reg2[write_ind] <= wr_data;
                    end
                    REG3_ADDR: 
                    begin
                        data_reg3[write_ind] <= wr_data;
                    end
                    REG4_ADDR: 
                    begin
                        data_reg4[write_ind] <= wr_data;
                    end
                    REG5_ADDR: 
                    begin
                        data_reg1[write_ind] <= wr_data;
                    end
                    REG6_ADDR: 
                    begin
                        data_reg2[write_ind] <= wr_data;
                    end
                    REG7_ADDR: 
                    begin
                        data_reg3[write_ind] <= wr_data;
                    end
                    REG8_ADDR: 
                    begin
                        data_reg4[write_ind] <= wr_data;
                    end
                    default: begin end
                endcase
                write_ind <= (write_ind == SIZE-1) ? '0 : write_ind + 1;
                rd_start <= (write_ind == SIZE-1);
            end
            else
            begin
                write_ind <= '0;
                rd_start <= '0;
            end
        end
    end

    // --------------------------
    // ------ READ BRIDGE -------
    // --------------------------
    always_ff @(posedge clk_in)
    begin
        if (~rst_n_in) 
        begin
            read_ind <= '0;
            state <= IDLE;
        end
        else
        begin
            case (state)
                IDLE: 
                begin
                    state <= (rd_start) ? READ : IDLE;
                    read_ind <= '0;
                end
                READ:
                begin
                    state <= (read_ind == SIZE-1) ? IDLE : READ;
                    case (rd_addr)
                        REG1_ADDR: 
                        begin
                            rd_data <= data_reg1[read_ind];
                        end
                        REG2_ADDR: 
                        begin
                            rd_data <= data_reg2[read_ind];
                        end
                        REG3_ADDR: 
                        begin
                            rd_data <= data_reg3[read_ind];
                        end
                        REG4_ADDR: 
                        begin
                            rd_data <= data_reg4[read_ind];
                        end
                        REG5_ADDR: 
                        begin
                            rd_data <= data_reg1[read_ind];
                        end
                        REG6_ADDR: 
                        begin
                            rd_data <= data_reg2[read_ind];
                        end
                        REG7_ADDR: 
                        begin
                            rd_data <= data_reg3[read_ind];
                        end
                        REG8_ADDR: 
                        begin
                            rd_data <= data_reg4[read_ind];
                        end
                        default: rd_data <= 'x;
                    endcase
                    read_ind <= read_ind + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
