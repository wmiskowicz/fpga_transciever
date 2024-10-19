module output_controller #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 80
)(
    // clocks and resets 
    input  logic                      clk_in, 
    input  logic                      rst_n_in,

    // read data
    input  logic [DATA_WIDTH-1:0]     rd_data,  
    output logic [ADDR_WIDTH-1:0]     rd_addr,  
    
    // data output 
    output logic  [7:0]               tdata_out, 
    output logic                      tvalid_out, 
    output logic                      tlast_out, 
    input  logic                      tready_in
);

    // Internal signals
    logic [ADDR_WIDTH-1:0] addr_counter;  // Counter to iterate over addresses 0x00 to 0x0C
    logic [3:0] byte_counter;             // Byte counter to send data byte by byte from each 80-bit word
    logic [7:0] byte_buffer [0:9];        // Buffer to store the 10 bytes of each 80-bit read



    assign tlast_out = 1'b0;
    assign tready_in = 1'b0;

    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) 
        begin
            addr_counter <= 8'h00;       // Reset address counter to 0x00
            byte_counter <= 4'h0;        // Reset byte counter
        end 
        else 
        begin
            if (1) begin
                tdata_out <= byte_buffer[byte_counter];
                
                if (byte_counter == 9) 
                begin
                    byte_counter <= '0;
                    if (addr_counter == 8'hC)
                    begin
                        addr_counter <= '0;
                    end
                    else
                    begin
                        addr_counter <= addr_counter + 8'h4;
                    end
                end 
                else 
                begin
                    byte_counter <= byte_counter + 1;
                end
            end
        end
    end


    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            byte_buffer[0] <= '0;
            byte_buffer[1] <= '0;
            byte_buffer[2] <= '0;
            byte_buffer[3] <= '0;
            byte_buffer[4] <= '0;
            byte_buffer[5] <= '0;
            byte_buffer[6] <= '0;
            byte_buffer[7] <= '0;
            byte_buffer[8] <= '0;
            byte_buffer[9] <= '0;
        end 
        else 
        begin
            if (byte_counter == 0) begin
                rd_addr <= addr_counter;
                byte_buffer[9] <= rd_data[7:0];
                byte_buffer[8] <= rd_data[15:8];
                byte_buffer[7] <= rd_data[23:16];
                byte_buffer[6] <= rd_data[31:24];
                byte_buffer[5] <= rd_data[39:32];
                byte_buffer[4] <= rd_data[47:40];
                byte_buffer[3] <= rd_data[55:48];
                byte_buffer[2] <= rd_data[63:56];
                byte_buffer[1] <= rd_data[71:64];
                byte_buffer[0] <= rd_data[79:72];
            end
        end
    end

endmodule
