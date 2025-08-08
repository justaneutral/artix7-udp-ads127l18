
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none


module udp_frame_terminator #
(
    parameter DEPTH = 1024
)
(
    /*
     * eth state
     */
    input wire tx_eth_hdr_ready,
    /*
     * input UDP frame
     */
    input wire rx_clk,
    input wire rx_rst,
    input wire rx_udp_hdr_valid,			//not used yet
    output wire rx_udp_hdr_ready,
    input wire [47:0] rx_udp_eth_dest_mac,		//not used yet
    input wire [47:0] rx_udp_eth_src_mac,		//not used yet
    input wire [15:0] rx_udp_eth_type,			//not used yet
    input wire [3:0] rx_udp_ip_version,			//not used yet
    input wire [3:0] rx_udp_ip_ihl,			//not used yet
    input wire [5:0] rx_udp_ip_dscp,			//not used yet
    input wire [1:0] rx_udp_ip_ecn,			//not used yet
    input wire [15:0] rx_udp_ip_length,			//not used yet
    input wire [15:0] rx_udp_ip_identification,		//not used yet
    input wire [2:0] rx_udp_ip_flags,			//not used yet
    input wire [12:0] rx_udp_ip_fragment_offset,	//not used yet
    input wire [7:0] rx_udp_ip_ttl,			//not used yet
    input wire [7:0] rx_udp_ip_protocol,		//not used yet
    input wire [15:0] rx_udp_ip_header_checksum,	//not used yet
    input wire [31:0] rx_udp_ip_source_ip,		//not used yet
    input wire [31:0] rx_udp_ip_dest_ip,
    input wire [15:0] rx_udp_source_port,		//not used yet
    input wire [15:0] rx_udp_dest_port,
    input wire [15:0] rx_udp_length,			//not used yet
    input wire [15:0] rx_udp_checksum,			//not used yet
    input wire [7:0] rx_udp_payload_axis_tdata,
    input wire rx_udp_payload_axis_tvalid,
    output wire rx_udp_payload_axis_tready,
    input wire rx_udp_payload_axis_tlast,
    input wire rx_udp_payload_axis_tuser,
    /*
     * output payload frame
     */
    input wire m_clk,
    input wire m_rst,
    output wire [7:0] m_tdata,
    output wire m_tvalid,
    input wire m_tready,
    output wire m_tlast,
    output wire m_tuser,
    /*
     * Status
     */
    output wire rx_status_overflow,
    output wire rx_status_bad_frame,
    output wire rx_status_good_frame,
    output wire m_status_overflow,
    output wire m_status_bad_frame,
    output wire m_status_good_frame
);


wire [7:0] rx_fifo_udp_payload_axis_tdata; //(* mark_debug = "true" *)
wire rx_fifo_udp_payload_axis_tvalid;
wire rx_fifo_udp_payload_axis_tready;
wire rx_fifo_udp_payload_axis_tlast;
wire rx_fifo_udp_payload_axis_tuser;

// Filter UDP
wire match_cond = (rx_udp_dest_port == 1234 /*21001*/) && (rx_udp_ip_dest_ip == {8'd192, 8'd168, 8'd1, 8'd128}/*{8'd239, 8'd2, 8'd3, 8'd1}*/);
wire no_match = !match_cond;

reg match_cond_reg = 0;
reg no_match_reg = 0;

always @(posedge rx_clk) begin
	if (rx_rst) begin
	    match_cond_reg <= 0;
	    no_match_reg <= 0;
	end else begin
	    if (rx_udp_payload_axis_tvalid) begin
		if ((!match_cond_reg && !no_match_reg) ||
		    (rx_udp_payload_axis_tvalid && rx_udp_payload_axis_tready && rx_udp_payload_axis_tlast)) begin
		    match_cond_reg <= match_cond;
		    no_match_reg <= no_match;
		end
	    end else begin
		match_cond_reg <= 0;
		no_match_reg <= 0;
	    end
	end
end

assign rx_fifo_udp_payload_axis_tdata = rx_udp_payload_axis_tdata;
assign rx_fifo_udp_payload_axis_tvalid = rx_udp_payload_axis_tvalid && match_cond_reg;
assign rx_udp_payload_axis_tready = (rx_fifo_udp_payload_axis_tready && match_cond_reg) || no_match_reg;
assign rx_fifo_udp_payload_axis_tlast = rx_udp_payload_axis_tlast;
assign rx_fifo_udp_payload_axis_tuser = rx_udp_payload_axis_tuser;
assign rx_udp_hdr_ready = ((tx_eth_hdr_ready && match_cond) || no_match);

axis_async_fifo_adapter #
(
    .DEPTH(DEPTH),// = 4096,
    .S_DATA_WIDTH(8),// = 8,
    .M_DATA_WIDTH(8),// = 8,
    .RAM_PIPELINE(2),// = 2,
    .FRAME_FIFO(0),// = 0,
    .DROP_BAD_FRAME(0),// = 0,
    .DROP_WHEN_FULL(0) // = 0
)
udp_payload_rx_fifo
(
    /*
     * AXI input
     */
    .s_clk(rx_clk),
    .s_rst(rx_rst),
    .s_axis_tdata(rx_fifo_udp_payload_axis_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(rx_fifo_udp_payload_axis_tvalid),
    .s_axis_tready(rx_fifo_udp_payload_axis_tready), //out
    .s_axis_tlast(rx_fifo_udp_payload_axis_tlast),
    .s_axis_tid(0),
    .s_axis_tdest(0),
    .s_axis_tuser(rx_fifo_udp_payload_axis_tuser),

    /*
     * AXI output
     */
    .m_clk(m_clk),
    .m_rst(m_rst),
    .m_axis_tdata(m_tdata),
    .m_axis_tkeep(),
    .m_axis_tvalid(m_tvalid),
    .m_axis_tready(m_tready), //inp
    .m_axis_tlast(m_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(m_tuser),
    
    /*
     * status
     */
    .s_status_overflow(rx_status_overflow),
    .s_status_bad_frame(rx_status_bad_frame),
    .s_status_good_frame(rx_status_good_frame),
    .m_status_overflow(m_status_overflow),
    .m_status_bad_frame(m_status_bad_frame),
    .m_status_good_frame(m_status_good_frame)

);



endmodule

`resetall


