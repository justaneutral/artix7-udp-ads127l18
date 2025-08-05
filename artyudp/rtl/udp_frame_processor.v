
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none


module udp_frame_processor #
(
    parameter DEPTH = 1024
)
(
    input wire clk,
    input wire rst,
    input wire clk1,
    input wire rst1,
    input wire tx_eth_hdr_ready,
    input wire [31:0] local_ip,
    //input UDP frame
    input wire rx_udp_hdr_valid,
    output wire rx_udp_hdr_ready,
    input wire [47:0] rx_udp_eth_dest_mac,
    input wire [47:0] rx_udp_eth_src_mac,
    input wire [15:0] rx_udp_eth_type,
    input wire [3:0] rx_udp_ip_version,
    input wire [3:0] rx_udp_ip_ihl,
    input wire [5:0] rx_udp_ip_dscp,
    input wire [1:0] rx_udp_ip_ecn,
    input wire [15:0] rx_udp_ip_length,
    input wire [15:0] rx_udp_ip_identification,
    input wire [2:0] rx_udp_ip_flags,
    input wire [12:0] rx_udp_ip_fragment_offset,
    input wire [7:0] rx_udp_ip_ttl,
    input wire [7:0] rx_udp_ip_protocol,
    input wire [15:0] rx_udp_ip_header_checksum,
    input wire [31:0] rx_udp_ip_source_ip,
    input wire [31:0] rx_udp_ip_dest_ip,
    input wire [15:0] rx_udp_source_port,
    input wire [15:0] rx_udp_dest_port,
    input wire [15:0] rx_udp_length,
    input wire [15:0] rx_udp_checksum,
    input wire [7:0] rx_udp_payload_axis_tdata, //(* mark_debug = "true" *)
    input wire rx_udp_payload_axis_tvalid,
    output wire rx_udp_payload_axis_tready,
    input wire rx_udp_payload_axis_tlast,
    input wire rx_udp_payload_axis_tuser,
    //output UDP constraint_mode
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
    output wire [7:0] tx_udp_payload_axis_tdata,
    output wire tx_udp_payload_axis_tvalid,
    input wire tx_udp_payload_axis_tready,
    output wire tx_udp_payload_axis_tlast,
    output wire tx_udp_payload_axis_tuser,
    /*
     * payload RX interface
     */
    output wire [7:0] m_tdata,
    output wire m_tvalid,
    input wire m_tready,
    output wire m_tlast,
    output wire m_tuser,
    /*
     * payload TX interface
     */
    input wire [7:0] s_tdata,
    input wire s_tvalid,
    output wire s_tready,
    input wire s_tlast,
    input wire s_tuser,
    /*
     * Status
     */
    output wire status_overflow,
    output wire status_bad_frame,
    output wire status_good_frame,
    output wire status_proc_overflow,
    output wire status_proc_bad_frame,
    output wire status_proc_good_frame
);

assign tx_udp_ip_source_ip = rx_udp_ip_dest_ip;
assign tx_udp_source_port = rx_udp_dest_port;
assign tx_udp_ip_dest_ip = rx_udp_ip_source_ip;
assign tx_udp_dest_port = rx_udp_source_port;

udp_frame_terminator #
(
    .DEPTH(DEPTH)
)
udp_terminator
(
    /*
     * eth state
     */
    .tx_eth_hdr_ready(tx_eth_hdr_ready),
    /*
     * input UDP frame
     */
    .rx_clk(clk),
    .rx_rst(rst),
    .rx_udp_hdr_valid(rx_udp_hdr_valid),
    .rx_udp_hdr_ready(rx_udp_hdr_ready),
    .rx_udp_eth_dest_mac(rx_udp_eth_dest_mac),
    .rx_udp_eth_src_mac(rx_udp_eth_src_mac),
    .rx_udp_eth_type(rx_udp_eth_type),
    .rx_udp_ip_version(rx_udp_ip_version),
    .rx_udp_ip_ihl(rx_udp_ip_ihl),
    .rx_udp_ip_dscp(rx_udp_ip_dscp),
    .rx_udp_ip_ecn(rx_udp_ip_ecn),
    .rx_udp_ip_length(rx_udp_ip_length),
    .rx_udp_ip_identification(rx_udp_ip_identification),
    .rx_udp_ip_flags(rx_udp_ip_flags),
    .rx_udp_ip_fragment_offset(rx_udp_ip_fragment_offset),
    .rx_udp_ip_ttl(rx_udp_ip_ttl),
    .rx_udp_ip_protocol(rx_udp_ip_protocol),
    .rx_udp_ip_header_checksum(rx_udp_ip_header_checksum),
    .rx_udp_ip_source_ip(rx_udp_ip_source_ip),
    .rx_udp_ip_dest_ip(rx_udp_ip_dest_ip),
    .rx_udp_source_port(rx_udp_source_port),
    .rx_udp_dest_port(rx_udp_dest_port),
    .rx_udp_length(rx_udp_length),
    .rx_udp_checksum(rx_udp_checksum),
    .rx_udp_payload_axis_tdata(rx_udp_payload_axis_tdata),
    .rx_udp_payload_axis_tvalid(rx_udp_payload_axis_tvalid),
    .rx_udp_payload_axis_tready(rx_udp_payload_axis_tready),
    .rx_udp_payload_axis_tlast(rx_udp_payload_axis_tlast),
    .rx_udp_payload_axis_tuser(rx_udp_payload_axis_tuser),
    /*
     * output payload frame
     */
    .m_clk(clk1),
    .m_rst(rst1),
    .m_tdata(m_tdata),
    .m_tvalid(m_tvalid),
    .m_tready(m_tready),
    .m_tlast(m_tlast),
    .m_tuser(m_tuser),
    /*
     * Status
     */
    .rx_status_overflow(status_rx_overflow),
    .rx_status_bad_frame(status_rx_bad_frame),
    .rx_status_good_frame(status_rx_good_frame),
    .m_status_overflow(status_m_overflow),
    .m_status_bad_frame(status_m_bad_frame),
    .m_status_good_frame(status_m_good_frame)
);



udp_frame_originator #
(
    .DEPTH(DEPTH)
)

udp_originator
(
    /*
     * parameters
     */
    .local_ip(local_ip),
    .rx_udp_dest_port(rx_udp_dest_port),
    /*
     * input frame
     */
    .s_clk(clk1),
    .s_rst(rst1),
    .s_tdata(s_tdata),
    .s_tvalid(s_tvalid),
    .s_tready(s_tready),
    .s_tlast(s_tlast),
    .s_tuser(s_tuser),
    /*
     * output UDP frame
     */
    .tx_clk(clk),
    .tx_rst(rst),
    .tx_udp_hdr_valid(tx_udp_hdr_valid),
    .tx_udp_hdr_ready(tx_udp_hdr_ready),
    .tx_udp_ip_dscp(tx_udp_ip_dscp),
    .tx_udp_ip_ecn(tx_udp_ip_ecn),
    .tx_udp_ip_ttl(tx_udp_ip_ttl),
    .tx_udp_ip_source_ip(), //tx_udp_ip_source_ip if different from sender's ip.
    .tx_udp_ip_dest_ip(), //tx_udp_ip_dest_ip if different from sender's port
    .tx_udp_source_port(), //tx_udp_source_port if different from sender's port.
    .tx_udp_dest_port(), //tx_udp_dest_port if different from sender's port.
    .tx_udp_length(tx_udp_length),
    .tx_udp_checksum(tx_udp_checksum),
    .tx_udp_payload_axis_tdata(tx_udp_payload_axis_tdata),
    .tx_udp_payload_axis_tvalid(tx_udp_payload_axis_tvalid),
    .tx_udp_payload_axis_tready(tx_udp_payload_axis_tready),
    .tx_udp_payload_axis_tlast(tx_udp_payload_axis_tlast),
    .tx_udp_payload_axis_tuser(tx_udp_payload_axis_tuser),
    /*
     * Status
     */
    .s_status_overflow(status_s_overflow),
    .s_status_bad_frame(status_s_bad_frame),
    .s_status_good_frame(status_s_good_frame),
    .tx_status_overflow(status_tx_overflow),
    .tx_status_bad_frame(status_tx_bad_frame),
    .tx_status_good_frame(status_tx_good_frame)
);


wire status_rx_overflow, status_rx_bad_frame, status_rx_good_frame, status_tx_overflow, status_tx_bad_frame, status_tx_good_frame;
wire status_s_overflow, status_s_bad_frame, status_s_good_frame, status_m_overflow, status_m_bad_frame, status_m_good_frame;

assign {status_overflow, status_bad_frame, status_good_frame} = {status_tx_overflow || status_rx_overflow, status_tx_bad_frame || status_rx_bad_frame, status_tx_good_frame || status_rx_good_frame};
assign {status_proc_overflow, status_proc_bad_frame, status_proc_good_frame} = {status_s_overflow || status_m_overflow, status_s_bad_frame || status_m_bad_frame, status_s_good_frame || status_m_good_frame};

endmodule

`resetall


