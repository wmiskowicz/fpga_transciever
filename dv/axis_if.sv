interface axis_if(input logic clk);
  logic [7:0] tdata;
  logic       tvalid;
  logic       tlast;
  logic       tready;

//  modport master(input clk, tready, output tdata, tvalid, tlast);
//  modport slave (input clk, tdata, tvalid, tlast, output tready);
endinterface
