
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none


module udp_frame_originator #
(
    parameter DEPTH = 64,
    parameter WIDTH = 64,
    parameter KEEP_WIDTH = (WIDTH+7)>>3,
    parameter UDP_WIDTH = 8,
    parameter UDP_KEEP_WIDTH = (UDP_WIDTH+7)>>3
)
(
    /*
     * parameters
     */
    input wire [31:0] local_ip,
    input wire [15:0] rx_udp_dest_port,
    /*
     * input payload frame
     */
    input wire s_clk,
    input wire s_rst,
    input wire [WIDTH-1:0] s_tdata,
    input wire [KEEP_WIDTH-1:0] s_tkeep,
    input wire s_tvalid,
    output wire s_tready,
    input wire s_tlast,
    input wire s_tuser,
    /*
     * output UDP frame
     */
    input wire tx_clk,
    input wire tx_rst,
    output wire tx_udp_hdr_valid,
    input wire tx_udp_hdr_ready,
    output wire [5:0] tx_udp_ip_dscp,
    output wire [1:0] tx_udp_ip_ecn,
    output wire [7:0] tx_udp_ip_ttl,
    output wire [31:0] tx_udp_ip_source_ip,
    output wire [31:0] tx_udp_ip_dest_ip,
    output wire [15:0] tx_udp_source_port,
    output wire [15:0] tx_udp_dest_port,
    output wire [15:0] tx_udp_length,
    output wire [15:0] tx_udp_checksum,
    output wire [UDP_WIDTH-1:0] tx_udp_payload_axis_tdata,
    output wire [UDP_KEEP_WIDTH-1:0] tx_udp_payload_axis_tkeep,
    output wire tx_udp_payload_axis_tvalid,
    input wire tx_udp_payload_axis_tready,
    output wire tx_udp_payload_axis_tlast,
    output wire tx_udp_payload_axis_tuser,
    /*
     * Status
     */
    output wire s_status_overflow,
    output wire s_status_bad_frame,
    output wire s_status_good_frame,
    output wire tx_status_overflow,
    output wire tx_status_bad_frame,
    output wire tx_status_good_frame
);



axis_async_fifo_adapter #
(
    .DEPTH(DEPTH),// = 4096,
    .S_DATA_WIDTH(WIDTH),
    .M_DATA_WIDTH(UDP_WIDTH),// = 8,
    .RAM_PIPELINE(2),// = 2,
    .FRAME_FIFO(0),// = 0,
    .DROP_BAD_FRAME(0),// = 0,
    .DROP_WHEN_FULL(0) // = 0
)
udp_payload_tx_fifo
(
    /*
     * AXI input
     */
    .s_clk(s_clk),
    .s_rst(s_rst),
    .s_axis_tdata(s_tdata),
    .s_axis_tkeep(s_tkeep),
    .s_axis_tvalid(s_tvalid),
    .s_axis_tready(s_tready), //out
    .s_axis_tlast(s_tlast),
    .s_axis_tid(0),
    .s_axis_tdest(0),
    .s_axis_tuser(s_tuser),

    /*
     *  AXI output
     */
    .m_clk(tx_clk),
    .m_rst(tx_rst),
    .m_axis_tdata(tx_udp_payload_axis_tdata),
    .m_axis_tkeep(tx_udp_payload_axis_tkeep),
    .m_axis_tvalid(tx_udp_payload_axis_tvalid),
    .m_axis_tready(tx_udp_payload_axis_tready), //inp
    .m_axis_tlast(tx_udp_payload_axis_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(tx_udp_payload_axis_tuser),
    
    /*
     * status
     */
    .s_status_overflow(s_status_overflow),
    .s_status_bad_frame(s_status_bad_frame),
    .s_status_good_frame(s_status_good_frame),
    .m_status_overflow(tx_status_overflow),
    .m_status_bad_frame(tx_status_bad_frame),
    .m_status_good_frame(tx_status_good_frame)

);


assign tx_udp_length = 16'b0;
assign tx_udp_checksum = 0;
assign tx_udp_ip_dscp = 0;
assign tx_udp_ip_ecn = 0;
assign tx_udp_ip_ttl = 64;
assign tx_udp_ip_source_ip = local_ip;
assign tx_udp_ip_dest_ip = {8'd239, 8'd2, 8'd2, 8'd6};
assign tx_udp_source_port = rx_udp_dest_port;
assign tx_udp_dest_port = 21007;


wire sending_header = tx_udp_hdr_ready && tx_udp_hdr_valid;
wire sending_data = tx_udp_payload_axis_tvalid && tx_udp_payload_axis_tready;
wire sending_last = sending_data && tx_udp_payload_axis_tlast;
wire receiving_data = s_tvalid && s_tready;
wire receiving_last = receiving_data && s_tlast;

assign tx_udp_hdr_valid = (tx_udp_payload_axis_tvalid && !tx_udp_payload_axis_tready && tx_udp_hdr_ready && (delay_counter > 16'd0))  ? 1'b1 : 1'b0;
reg [15:0] delay_counter = 16'b0;
always @(posedge tx_clk) begin
    delay_counter <= 16'b0;
    if(tx_udp_hdr_ready)
    begin
        if(~delay_counter)
        begin 
            delay_counter <= delay_counter + 1;
        end else
        begin
            delay_counter <= delay_counter;
        end
    end
    if(tx_rst) begin
        delay_counter <= 16'b0;
    end
end

endmodule

`resetall


