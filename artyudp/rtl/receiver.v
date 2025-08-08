//7-nov-2023
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module receiver #
(
	parameter WIDTH = 8,
    parameter NUM_FRAMES = 1024, //(8192)
	parameter messageType_w = 8, //1 byte
	parameter messageType_p = 0,  //1 byte
	parameter BITS_PER_PACKET = 24 //adc word width
)
(
    input wire clk,
    input wire rst,
    /*
     * payload RX interface
     */
    input wire [7:0] s_tdata,
    input wire s_tvalid,
    output wire s_tready,
    input wire s_tlast,
    input wire s_tuser,
    /*
     * payload TX interface
     */
    output wire [7:0] m_tdata,
    output wire m_tvalid,
    input wire m_tready,
    output wire m_tlast,
    output wire m_tuser,
    /*
     * process control parameters
     */
    input wire HEARTBEAT_ENABLE,
    input wire [31:0] heartbeat_interval,
    /*
     * process status indicators
     */
    output reg [7:0] debug64bitregister0 = "e",
    output reg [7:0] debug64bitregister1 = "f",
    output reg [7:0] debug64bitregister2 = "g",
    /*
     * adc signals
     */
    input wire [BITS_PER_PACKET-1:0] ch0_packet, // CH0 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch1_packet, // CH1 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch2_packet, // CH2 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch3_packet, // CH3 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch4_packet, // CH4 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch5_packet, // CH5 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch6_packet, // CH6 data packet (latched)
    input wire [BITS_PER_PACKET-1:0] ch7_packet, // CH7 data packet (latched)
    input wire data_ready,   // Goes high for at least 1 DCLK period after data is latched
    
    input  wire [3:0] btn,
    input  wire [3:0] sw,
    output wire       led0_r,
    output wire       led0_g,
    output wire       led0_b,
    output wire       led1_r,
    output wire       led1_g,
    output wire       led1_b,
    output wire       led2_r,
    output wire       led2_g,
    output wire       led2_b,
    output wire       led3_r,
    output wire       led3_g,
    output wire       led3_b,
    output wire       led4,
    output wire       led5,
    output wire       led6,
    output wire       led7
);

// the below configuration works - this is for testing
/*
assign m_tdata = s_tdata;
assign m_tlast = s_tlast;
assign m_tuser = s_tuser;
assign s_tready = m_tready;
assign m_tvalid = s_tvalid;
*/
//assign {led0_r,led0_g,led0_b} = {s_tlast,s_tready,s_tvalid};
//assign {led1_r,led1_g,led1_b} = {m_tlast,m_tready,m_tvalid};
assign {led0_r,led0_g,led0_b} = iid_state1;
assign {led1_r,led1_g,led1_b} = iid_state0;
assign {led7,led6,led5,led4} = {s_tvalid,s_tready,m_tready,m_tvalid}; 

//registers
reg [7:0] tdata_reg;
reg tlast_reg;
reg tuser_reg;
reg tready_reg;
reg tvalid_reg;
reg [2:0] packet_cnt;


//output connections
assign m_tdata = tdata_reg;
assign m_tlast = tlast_reg;
assign m_tuser = tuser_reg;
assign s_tready = tready_reg;
assign m_tvalid = tvalid_reg;




/*always @(posedge clk)
begin
    if(rst)
    begin
        tdata_reg <= 8'h0;
        tlast_reg <= 0;
        tuser_reg <= 0;
        tready_reg <= 0;
        tvalid_reg <= 0;
        //adc_reg <= 0;
        //data_index <= 0;
        packet_cnt <= 0;
    end
    else
    begin
        //tdata_reg <= 8'h0;
        //tlast_reg <= 0;
        //tuser_reg <= 0;
        //tready_reg <= 0;
        //tvalid_reg <= 0;
        /*if(data_index)
        begin
            if(m_tready)
            begin
                data_index <= data_index - 1; //next byte
                case(data_index)
                    5'd24: begin tdata_reg <= adc_reg[8*24-1:8*(24-1)]; end
                    5'd23: begin tdata_reg <= adc_reg[8*23-1:8*(23-1)]; end
                    5'd22: begin tdata_reg <= adc_reg[8*22-1:8*(22-1)]; end
                    5'd21: begin tdata_reg <= adc_reg[8*21-1:8*(21-1)]; end
                    5'd20: begin tdata_reg <= adc_reg[8*20-1:8*(20-1)]; end
                    5'd19: begin tdata_reg <= adc_reg[8*19-1:8*(19-1)]; end
                    5'd18: begin tdata_reg <= adc_reg[8*18-1:8*(18-1)]; end
                    5'd17: begin tdata_reg <= adc_reg[8*17-1:8*(17-1)]; end
                    5'd16: begin tdata_reg <= adc_reg[8*16-1:8*(16-1)]; end
                    5'd15: begin tdata_reg <= adc_reg[8*15-1:8*(15-1)]; end
                    5'd14: begin tdata_reg <= adc_reg[8*14-1:8*(14-1)]; end
                    5'd13: begin tdata_reg <= adc_reg[8*13-1:8*(13-1)]; end
                    5'd12: begin tdata_reg <= adc_reg[8*12-1:8*(12-1)]; end
                    5'd11: begin tdata_reg <= adc_reg[8*11-1:8*(11-1)]; end
                    5'd10: begin tdata_reg <= adc_reg[8*10-1:8*(10-1)]; end
                    5'd9: begin tdata_reg <= adc_reg[8*9-1:8*(9-1)]; end
                    5'd8: begin tdata_reg <= adc_reg[8*8-1:8*(8-1)]; end
                    5'd7: begin tdata_reg <= adc_reg[8*7-1:8*(7-1)]; end
                    5'd6: begin tdata_reg <= adc_reg[8*6-1:8*(6-1)]; end
                    5'd5: begin tdata_reg <= adc_reg[8*5-1:8*(5-1)]; end
                    5'd4: begin tdata_reg <= adc_reg[8*4-1:8*(4-1)]; end
                    5'd3: begin tdata_reg <= adc_reg[8*3-1:8*(3-1)]; end
                    5'd2: begin tdata_reg <= adc_reg[8*2-1:8*(2-1)]; end
                    5'd1: begin tdata_reg <= adc_reg[8*1-1:8*(1-1)]; tlast_reg <= 1; end                
                endcase
                tvalid_reg <= 1;
            end
        end
        //else
        begin
            tready_reg <= 1;
            if(s_tvalid && m_tready)
            begin
                tdata_reg <= s_tdata;
                tlast_reg <= s_tlast;
                tuser_reg <= s_tuser;
                tvalid_reg <= 1;
                packet_cnt <= packet_cnt + s_tlast;
            end
        end
    end
end
*/


localparam [2:0] RX_META = 0, RX_DATA = 1, TX_DATA = 2, CHECK_MESSAGE_TYPE = 3, TX_HEART_BEAT0 = 4, TX_HEART_BEAT1 = 5, TX_HEART_BEAT2 = 6;

reg [31:0] heartbeat_counter;
reg [2:0] iid_state0, iid_state1;
reg [15:0] a_cnt0, b_cnt0;


always @(posedge clk)
begin    
    tdata_reg <= tdata_reg;
    tlast_reg <= tlast_reg;
    tuser_reg <= tuser_reg;
    tready_reg <= 1'b0;
    tvalid_reg <= 1'b0;
    iid_state0 <= iid_state0;
    iid_state1 <= iid_state1;
    heartbeat_counter <= heartbeat_counter;
    a_cnt0 <= a_cnt0;
    b_cnt0 <= b_cnt0;
   
    debug64bitregister0 <= debug64bitregister0; 
    debug64bitregister1 <= debug64bitregister1; 
    debug64bitregister2 <= debug64bitregister2; 

 
    case(iid_state0)
    RX_META:
    begin
        a_cnt0 <= 16'b0;
        b_cnt0 <= 16'b0;
        iid_state0 <= RX_DATA;
        tready_reg <= 1'b1;
    end
    
    RX_DATA:
    begin
        tready_reg <= 1'b1;//m_tready;
        if(s_tvalid && s_tready)
        begin
            a_cnt0 <= a_cnt0 + 1;
            if(s_tlast)
            begin
                tready_reg <= 1'b0;
                iid_state0 <= CHECK_MESSAGE_TYPE;
            end
        end
        else //not yet received first word of UDP frame
        begin
            if(HEARTBEAT_ENABLE && sw == 4'hf)
            begin
                heartbeat_counter <= heartbeat_counter + 1;
		        debug64bitregister0 <= heartbeat_counter;
		        debug64bitregister1 <= heartbeat_interval;
                if(heartbeat_counter >= heartbeat_interval)
                begin
                    iid_state0 <= TX_HEART_BEAT0;
		            debug64bitregister2 <= 1;                
                end
            end
	        else
	        begin
		       debug64bitregister0 <= 0;
		       debug64bitregister1 <= 0;
		       debug64bitregister2 <= 0;
	        end
        end
    end



    TX_DATA:
    begin
        tvalid_reg <= 1'b1;
        if(m_tready)
        begin
            tdata_reg <= o_dinv;
            tuser_reg <= 1'b0;
            if(a_cnt0 == b_cnt0)
            begin
                tlast_reg <=  1'b1;
                iid_state0 <= RX_META;
            end
            else
            begin
                tlast_reg <=  1'b0;
        	    b_cnt0 <= b_cnt0 + 1;
            end
        end
    end
 
    TX_HEART_BEAT0:
    begin
        tvalid_reg <= 1'b1;
        if(m_tready)
        begin
            tdata_reg <= "a";
            tuser_reg <= 1'b0;
            tlast_reg <= 1'b0;
            iid_state0 <= TX_HEART_BEAT1;
        end
    end
    
    TX_HEART_BEAT1:
    begin
        tvalid_reg <= 1'b1;
        if(m_tready)
        begin
            tdata_reg <= "b";
            tuser_reg <= 1'b0;
            tlast_reg <= 1'b0;
            iid_state0 <= TX_HEART_BEAT2;
        end
    end
    
    TX_HEART_BEAT2:
    begin
        tvalid_reg <= 1'b1;
        if(m_tready)
        begin
            tdata_reg <= "c";
            tuser_reg <= 1'b0;
            tlast_reg <= 1'b1;
            iid_state0 <= RX_META;
        end
    end

    ///////// processing //////////////
    CHECK_MESSAGE_TYPE:
    begin
        iid_state0 <= TX_DATA;
    end

    endcase
    
    if(rst)
    begin
        memory_addr_reg <= {ADDR_WIDTH{1'b0}};
        tdata_reg <= 0;
        tlast_reg <= 0;
        tuser_reg <= 0;
        tready_reg <= 0;
        tvalid_reg <= 0;

        heartbeat_counter <= 32'b0;
        a_cnt0 <= 16'b0;
        b_cnt0 <= 16'b0;
        iid_state0 <= RX_META;
    
        debug64bitregister0 <= 8'b0;
        debug64bitregister1 <= 8'b0;
        debug64bitregister2 <= 8'b0;
    end
end


///////// useful wires ///////

////////// frame header //////////
//to memory

//from memory




///////// memory buffer instantiation //////////
localparam ADDR_WIDTH = $clog2(NUM_FRAMES);
wire we_w = s_tvalid && s_tready;
wire [WIDTH-1:0] o_data;
wire [WIDTH-1:0] o_dinv = o_data;
wire [WIDTH-1:0] s_dinv = s_tdata;
reg we;
reg [ADDR_WIDTH-1:0] memory_buffer_addr;
reg [WIDTH-1:0] s_data;
reg [ADDR_WIDTH-1:0] memory_addr_reg;

always @*
begin
    we = 0;
    memory_buffer_addr = 0;
    s_data = 0;
    case(iid_state0)
    //// Rx /////
    RX_DATA: begin memory_buffer_addr = a_cnt0; s_data = s_dinv; we = we_w; end
    //// Tx ////

    TX_DATA: begin memory_buffer_addr = b_cnt0; end
    
    //// Read values and do processing ////
    
    //// Write modified walues /////
    
    default:
    begin
        memory_buffer_addr = 0;
    end
    
    endcase
end

memory_buffer #
(
    .NUM_FRAMES(NUM_FRAMES),
    .ADDR_WIDTH(ADDR_WIDTH)
)
memory_buffer_inst
(
    .clk(clk),
    .we(we),
    .addr(memory_buffer_addr),
    .i_data(s_data),
    .o_data(o_data)
);


endmodule

`resetall


