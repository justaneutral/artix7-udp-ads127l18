
`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 100MHz
     * Reset: Push button, active low
     */
    input  wire       clk,
    input  wire       reset_n,

    /*
     * GPIO
     */
    input  wire [3:0] sw,
    input  wire [3:0] btn,
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
    output wire       led7,

    /*
     * Ethernet: 100BASE-T MII
     */
    output wire       phy_ref_clk,
    input  wire       phy_rx_clk,
    input  wire [3:0] phy_rxd,
    input  wire       phy_rx_dv,
    input  wire       phy_rx_er,
    input  wire       phy_tx_clk,
    output wire [3:0] phy_txd,
    output wire       phy_tx_en,
    input  wire       phy_col,
    input  wire       phy_crs,
    output wire       phy_reset_n,

    /*
     * UART: 500000 bps, 8N1
     */
    input  wire       uart_rxd,
    output wire       uart_txd,
    
    /*
    * PORTS
    */
    input wire       gpio_jb1,//1-t63  FSYNC
    input wire       gpio_jb2,//1-t61  DOUT7
    input wire       gpio_jb3,//1-t59  DOUT5
    input wire       gpio_jb4,//1-t57  DOUT3
    input wire       gpio_jb7,//1-t62  DCLK 
    input wire       gpio_jb8,//1-t60  DOUT6
    input wire       gpio_jb9,//1-t58  DOUT4
    input wire       gpio_jb10,//1-t56 DOUT2
    output wire       gpio_jc1, // first top right pin - internal clock for reference.
    output wire      gpio_jc3, //2-"GND" data_ready_out
    input wire       gpio_jc4, //2-t16 DOUT0
    input wire       gpio_jc10 //2-t17 DOUT1
);

//speed test
reg [2:0] testcounter;
assign gpio_jc1 = testcounter[2];
always @(posedge clk_int)
begin
    testcounter <= testcounter+1;
    if(rst_int) testcounter <= 3'b0;
end

// Clock and reset

wire clk_ibufg;

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire rst_int;

wire mmcm_rst = ~reset_n;
wire mmcm_locked;
wire mmcm_clkfb;

IBUFG
clk_ibufg_inst(
    .I(clk),
    .O(clk_ibufg)
);

wire clk_25mhz_mmcm_out;
wire clk_25mhz_int;

// MMCM instance
// 100 MHz in, 125 MHz out
// PFD range: 10 MHz to 550 MHz
// VCO range: 600 MHz to 1200 MHz
// M = 10, D = 1 sets Fvco = 1000 MHz (in range)
// Divide by 8 to get output frequency of 125 MHz
// Divide by 40 to get output frequency of 25 MHz
// 1000 / 5 = 200 MHz
MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT1_DIVIDE(40),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKFBOUT_MULT_F(10),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(10.0),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(clk_ibufg),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(clk_25mhz_mmcm_out),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked)
);

BUFG
clk_bufg_inst (
    .I(clk_mmcm_out),
    .O(clk_int)
);

BUFG
clk_25mhz_bufg_inst (
    .I(clk_25mhz_mmcm_out),
    .O(clk_25mhz_int)
);

sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~mmcm_locked),
    .out(rst_int)
);

// GPIO
wire [3:0] btn_int;
wire [3:0] sw_int;

debounce_switch #(
    .WIDTH(8),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_int),
    .rst(rst_int),
    .in({btn,
        sw}),
    .out({btn_int,
        sw_int})
);

wire uart_rxd_int;

sync_signal #(
    .WIDTH(1),
    .N(2)
)
sync_signal_inst (
    .clk(clk_int),
    .in({uart_rxd}),
    .out({uart_rxd_int})
);

assign phy_ref_clk = clk_25mhz_int;

fpga_core #(
    .TARGET("XILINX"),
    .LANE_COUNT(8),
    .BITS_PER_PACKET(24)
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .rst(rst_int),
    /*
     * GPIO
     */
    .btn(btn_int),
    .sw(sw_int),
    .led0_r(led0_r),//
    .led0_g(led0_g),//
    .led0_b(led0_b),//
    .led1_r(led1_r),//
    .led1_g(led1_g),//
    .led1_b(led1_b),//
    .led2_r(led2_r),//
    .led2_g(led2_g),//
    .led2_b(led2_b),//
    .led3_r(led3_r),//
    .led3_g(led3_g),//
    .led3_b(led3_b),//led3_b
    .led4(led4),//led4
    .led5(led5),//led5
    .led6(led6),//led6
    .led7(led7),//led7
    /*
     * Ethernet: 100BASE-T MII
     */
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd),
    .phy_rx_dv(phy_rx_dv),
    .phy_rx_er(phy_rx_er),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_en(phy_tx_en),
    .phy_col(phy_col),
    .phy_crs(phy_crs),
    .phy_reset_n(phy_reset_n),
    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),    
    /*
    * ADS127L18
    */
    .fsync(gpio_jb1),
    .dclk(gpio_jb7),
    .dout7(gpio_jb2),
    .dout6(gpio_jb8),
    .dout5(gpio_jb3),
    .dout4(gpio_jb9),
    .dout3(gpio_jb4),
    .dout2(gpio_jb10),
    .dout1(gpio_jc10),
    .dout0(gpio_jc4),
    
    .data_ready_out(gpio_jc3) //2-"GND"
);

endmodule

`resetall
