module data_mem #(
    parameter int ADDR_WIDTH = 8,     // Address width (number of addressable locations)
    parameter int DATA_WIDTH = 80      // Data width (size of each memory word)
)(
    // clocks and resets 
    input  logic                      clk_in, 
    input  logic                      rst_n_in,

    // input data
    input  logic [DATA_WIDTH-1:0]     wr_data,  
    input  logic [ADDR_WIDTH-1:0]     wr_addr,  
    input  logic                      wr_enabl, 

    output logic [DATA_WIDTH-1:0]     rd_data,  
    input  logic [ADDR_WIDTH-1:0]     rd_addr   
);

    localparam DATA_REG1_ADDR = 8'h00;
    localparam DATA_REG2_ADDR = 8'h04;
    localparam DATA_REG3_ADDR = 8'h08;
    localparam DATA_REG4_ADDR = 8'h0C;

    
    logic [79:0] data_reg1;
    logic [79:0] data_reg2;
    logic [79:0] data_reg3;
    logic [79:0] data_reg4;    


    // Write logic
    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (wr_enabl) 
        begin
            case (wr_addr)
                DATA_REG1_ADDR: 
                begin
                    data_reg1 <= wr_data;
                end
                DATA_REG2_ADDR: 
                begin
                    data_reg2 <= wr_data;
                end
                DATA_REG3_ADDR: 
                begin
                    data_reg3 <= wr_data;
                end
                DATA_REG4_ADDR: 
                begin
                    data_reg4 <= wr_data;
                end
                default: begin end
            endcase
        end
    end

    // Read logic
    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            rd_data <= '0;
        end 
        else 
        begin
            case (rd_addr)
                DATA_REG1_ADDR: 
                begin
                    rd_data <= data_reg1;
                end
                DATA_REG2_ADDR: 
                begin
                    rd_data <= data_reg2;
                end
                DATA_REG3_ADDR: 
                begin
                    rd_data <= data_reg3;
                end
                DATA_REG4_ADDR: 
                begin
                    rd_data <= data_reg4;
                end
                default: rd_data <= 80'hDEADDEAD;
            endcase
        end
    end

endmodule
