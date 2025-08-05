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
	parameter messageType_p = 0  //1 byte
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
    output reg [7:0] debug64bitregister2 = "g"

);

// the below configuration works - this is for testing
/*
assign m_tdata = s_tdata;
assign m_tlast = s_tlast;
assign m_tuser = s_tuser;
assign s_tready = m_tready;
assign m_tvalid = s_tvalid;
*/

//registers
reg [7:0] tdata_reg;
reg tlast_reg;
reg tuser_reg;
reg tready_reg;
reg tvalid_reg;
reg [1:0] iid_state0 = 0;
//reg [15:0] a_cnt0 = 16'b0;
//reg [15:0] b_cnt0 = 16'b0;
reg [31:0] heartbeat_counter = 32'b0;


//output connections
assign m_tdata = tdata_reg;
assign m_tlast = tlast_reg;
assign m_tuser = tuser_reg;
assign s_tready = tready_reg;
assign m_tvalid = tvalid_reg;


always @(posedge clk)
begin
    tdata_reg <= 8'h0;
    tlast_reg <= 0;
    tuser_reg <= 0;
    tready_reg <= 0;
    tvalid_reg <= 0;
    if(rst == 1'b0)
    begin
        tready_reg <= 1;
        if(s_tvalid && m_tready)
        begin
            tdata_reg <= s_tdata;
            tlast_reg <= s_tlast;
            tuser_reg <= s_tuser;
            tvalid_reg <= 1'b1;
        end
    end
end

/*
localparam state_width = 8;
localparam [state_width-1:0]
    RX_META = 0,
    RX_DATA = 1,        //get frame header
    CHECK_MESSAGE_TYPE = 2,
    TX_DATA = 3,
    TX_HEART_BEAT0 = 4,
    TX_HEART_BEAT1 = 5,
    TX_HEART_BEAT2 = 6;




always @(posedge clk)
begin    
    tdata_reg <= tdata_reg;
    tlast_reg <= tlast_reg;
    tuser_reg <= tuser_reg;
    tready_reg <= 1'b0;
    tvalid_reg <= 1'b0;
    iid_state0 <= iid_state0;
    heartbeat_counter <= 32'b0;
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
            if(HEARTBEAT_ENABLE)
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
        iid_state0 <= RX_META;
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
*/

endmodule

`resetall


