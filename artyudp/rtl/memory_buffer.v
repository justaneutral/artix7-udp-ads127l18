
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module memory_buffer #
(
    parameter NUM_FRAMES = 1024,
    parameter ADDR_WIDTH = $clog2(NUM_FRAMES)
)
(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [7:0] i_data,
    output wire [7:0] o_data
);
    (* ramstyle = "bram" *) reg [7:0] b[NUM_FRAMES-1:0];
    assign o_data = b[addr];
    always @(posedge clk)
    begin
        if(we)
        begin
            b[addr] <= i_data;
        end
    end

endmodule

`resetall
