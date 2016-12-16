/*

# PLAN

  - For first 6502 test (free run):
    - PHI2 is controlled by Monitor AVR (via GO)
    - RESB (could be controlled via Monitor rather than convoluted "strobe low and FPGA ensures low for X PHI2")
    - No need for RDY while the Monitor controls PHI2
    - Danger: IF the 6502 were to drive RWB LOW then it would drive the data bus yet the Monitor might still be driving it
      - Maybe seed the RAM with NOP?

    - Latest code on FPGA then AVR
    - r  to hold RESB low
    - F  to fill RAM with NOP
    - 00E, ffE, eaE  to check that RAM has NOPs
    - C  to toggle clock
    - r  to release RESB
    - C  to toggle clock
    - z  to disconnect in emergency
  / Test BE
  / Test 64K of RAM
  / re-map FPGA for the new bus adapter
  / test all lines with the monitor AVR
  / Check that data bus lines are high-Z at FPGA when RWB is 0
  / Have the AVR drive the address bus lines to test address decoder
  / Implement the memory-mapped UART
  / Maybe implement multiple bus devices with a mux?  Each device has data_bus_out and the mux selects
  / Test out the SRAM, with TAH all wired to GND

*/


module top (
  input   clk,        // The external clock (12 MHz)
  output  indicator7,
  output  indicator6,
  output  indicator5,
  output  indicator4,
  output  indicator3,
  output  indicator2,
  output  indicator1,
  output  indicator0,
  inout   resb,
  output  phi2,
  input   stop,
  input   go,
  output  rdy,
  output  ta16,
  output  ta15,
  output  ta14,
  output  ta13,
  output  ta12,
  output  ta11,
  output  ta10,
  output  ta9,
  output  ta8,
  input   a15,
  input   a14,
  input   a13,
  input   a12,
  input   a11,
  input   a10,
  input   a9,
  input   a8,
  input   a7,
  input   a6,
  input   a5,
  input   a4,
  input   a3,
  input   a2,
  input   a1,
  input   a0,
  output  ce0,
  input   rwb,
  /*
  input   d7,
  input   d6,
  input   d5,
  input   d4,
  input   d3,
  input   d2,
  input   d1,
  input   d0,
  */
  inout   d7,
  inout   d6,
  inout   d5,
  inout   d4,
  inout   d3,
  inout   d2,
  inout   d1,
  inout   d0,
  output  irqb,
  input   rxd_line,
  output  txd_line,
  output  sck_line,
  input   miso_line,
  output  mosi_line,
  output  ss0_line
);
  `include "globals.v"

  wire [7:0]    indicators;
  wire [8:0]    sram_address_bus_hi;
  wire [15:0]   address_bus;
  wire [7:0]    data_bus_r;
  wire [7:0]    data_bus_w;

  reg [29:0]  counter;

  assign {indicator7, indicator6, indicator5, indicator4, indicator3, indicator2, indicator1, indicator0} = indicators;

  assign sram_address_bus_hi = {ta16, ta15, ta14, ta13, ta12, ta11, ta10, ta9, ta8};
  assign address_bus = {a15, a14, a13, a12, a11, a10, a9, a8, a7, a6, a5, a4, a3, a2, a1, a0};

  assign  ce0 = ! chip_enable_lines [SRAM_ID];

  //assign data_bus_r = {d7, d6, d5, d4, d3, d2, d1, d0};

  // Direct RAM mapping (no translation, only lower 64K available):
  //assign ta16 = 0;
  //assign sram_address_bus_hi[7:0] = address_bus[15:8];
  //assign sram_address_bus_hi = 0;
  assign {ta16, ta15, ta14, ta13, ta12, ta11, ta10, ta9, ta8} = {1'b0, a15, a14, a13, a12, a11, a10, a9, a8};
  //assign  indicators = address_bus[15:8];
  //assign  indicators = data_bus_r;
  //assign  indicators = address_bus[7:0];
  //assign  indicators = 0;

  //always
  //begin
    //{indicator7, indicator6, indicator5, indicator4, indicator3, indicator2, indicator1, indicator0} <= counter [29:22];
    //{indicator7, indicator6, indicator5, indicator4, indicator3, indicator2} <= 6'b0;
    /*
    phi2 = 0;
    rdy <= 0;
    sync <= 0;
    irqb <= 0;
    */
    //d0 <= 1'bz;
    //rwb <= 0;
  //end
  //assign {resb, rdy, irqb} = 0;
  //assign resb = 1;
  assign irqb = 1;
  assign rdy = stop; // STOP: Allow the Monitor AVR to control RDY for testing
  //assign sram_enable = phi2 == 1;
  //assign txd_line = 1;

  // The AVR controls PHI2 via GO for testing but only when STOP is 0,
  // otherwise `phi2` is driven by clock_scaler.  FIXME: This can glitch (make
  // half-cycles shorter than intended) when STOP changes.
  reg [1:0]   dstop = 0;  // Delayed STOP, which only changes when `clk` rises
  // dstop2 is between half a cycle and a full cycle of `clk` delayed, so at
  // least half of a 12 MHz cycle, which is out of spec at 3V3 but better than
  // the potential spike glitch we would have had before
  assign  phi2 = dstop[1] == 0 ? go : iphi2;
  //assign  phi2 = go;
  // `posedge clk` might happen too shortly after `stop` changes or it might
  // happen up to one cycle of `clk` afterwards.  Either way, `dstop[1]`
  // doesn't take the value until a cycle of `clk` after that, so it is delayed
  // by between 1 and 2 cycles of `clk`
  always @ (posedge clk) begin
    dstop <= {dstop[0], stop};
  end
  //assign  indicators = {phi2, iphi2, go, 1'b0, dstop, 1'b0, stop};

  // The indicators show what's on the data bus
  //assign {indicator3, indicator2, indicator1, indicator0} = data_bus_w;

  //assign  indicator7 = phi2;
  //assign  indicator6 = sram_enable;
  //assign  indicator5 = uart_enable;
  //assign  indicator4 = rwb;


  // phi2d rises slighty after phi2 rises because UART checks whether it's
  // enabled so quickly that it thinks that it is diabled because the address
  // decoder hasn't had time to change its enable signal.
  //reg  phi2d = 0; // delayed

  //assign {indicator7, indicator6, indicator5, indicator4, indicator3, indicator2, indicator1, indicator0} = counter [29:22];
  //assign {indicator7, indicator6, indicator5, indicator4, indicator3, indicator2, indicator1, indicator0} = sram_address_bus_hi[7:0];

  /* To test all lines between FPGA and Monitor AVR:
  reg         go = 0;
  reg [26:0]  shifter = 1;
  assign  {resb, stop, a15, a14, a13, a12, a11, a10, a9, a8, a7, a6, a5, a4, a3, a2, a1, a0, rwb, d7, d6, d5, d4, d3, d2, d1, d0} = shifter;
  reg  ck = 0;
  */

  always @ (posedge clk) begin
    counter <= counter + 1;
    //phi2d <= phi2;
    /* To test all lines:
    if (counter [23] != ck) begin
      go = ~go;
      shifter = shifter << 1;
      if (shifter == 0) shifter = 1;
    end
    ck = counter [23];
    */
  end

  // Quandary: Should devices be defined as free-standing Verilog and the have
  // bus devices attached to them, or should the Verilog to behave as a bus
  // device be part of the device module?

  reg  ckout;
  wire  iphi2;
  ClockScaler  clock_scaler (
    .input_clock      (clk),
    //.output_clock     (ckout),
    //.output_clock     (phi2),
    .output_clock     (iphi2),
    .phi2     (phi2),
    .enabled          (chip_enable_lines [CLOCK_SCALER_ID]),
    .register_select  (address_bus [0]),
    .rwb              (rwb),
    .data_bus_r       (data_bus_r),
    .data_bus_w       (data_buses [7 + 8 * CLOCK_SCALER_ID : 8 * CLOCK_SCALER_ID])
  );

  UART  uart (
    .clk              (clk),
    .phi2             (phi2),
    .enabled          (chip_enable_lines [UART_ID]),
    .register_select  (address_bus [0]),
    .rwb              (rwb),
    .data_bus_r       (data_bus_r),
    .data_bus_w       (data_buses [7 + 8 * UART_ID : 8 * UART_ID]),
    .rxd_line         (rxd_line),
    .txd_line         (txd_line)
  );
  defparam uart.BAUD_RATE = 9600;

  wire [7 : 0]  spi_slave_select_lines;
  wire          spi_irq_line;
  assign  ss0_line = spi_slave_select_lines [0];
  SPI  spi (
    .reset            (~ resb_sense),
    .clk              (clk),
    .phi2             (phi2),
    .enabled          (chip_enable_lines [SPI_ID]),
    .register_select  (address_bus [1 : 0]),
    .rwb              (rwb),
    .data_bus_r       (data_bus_r),
    .data_bus_w       (data_buses [7 + 8 * SPI_ID : 8 * SPI_ID]),
    .select_lines     (spi_slave_select_lines),
    .sck_line         (sck_line),
    .miso_line        (miso_line),
    .mosi_line        (mosi_line),
    .irq_line         (spi_irq_line)
  );


  CycleCounter  cycle_counter (
    .clk              (phi2),
    .phi2             (phi2),
    .enabled          (chip_enable_lines [CYCLE_COUNTER_ID]),
    .register_select  (address_bus [1 : 0]),
    .rwb              (rwb),
    .data_bus_r       (data_bus_r),
    .indicators       (indicators),
    .data_bus_w       (data_buses [7 + 8 * CYCLE_COUNTER_ID : 8 * CYCLE_COUNTER_ID])
  );

  wire [(BUS_DEVICE_ID_WIDTH - 1) : 0]  active_bus_device_id;
  wire [MAX_BUS_DEVICE_ID : 0]          chip_enable_lines;

  AddressDecoder  address_decoder (
    .phi2                   (phi2),
    .address_bus            (address_bus),
    .enable_lines           (chip_enable_lines),
    .active_bus_device_id   (active_bus_device_id)
  );

  wire [(8 * INTERNAL_BUS_DEVICES - 1) : 0]   data_buses;

  Mux8  data_bus_mux (
    .in       (data_buses),
    .select   (active_bus_device_id),
    .out      (data_bus_w)
  );

  // Whether the active bus device (enabled by the address decoder) is internal
  // to the FPGA or not, which determines whether the FPGA should drive the
  // data bus lines or tri-state them.
  wire  active_bus_device_is_internal = active_bus_device_id == CLOCK_SCALER_ID |
                                        active_bus_device_id == CYCLE_COUNTER_ID |
                                        active_bus_device_id == UART_ID |
                                        active_bus_device_id == SPI_ID;
  // `sddb`: Should drive data bus
  wire  sddb = active_bus_device_is_internal  &&  rwb == RWB_READ;
  // When `sddb` is LOW, data bus pins should be high-Z and data_bus_r is
  // sensed.  When `sddb` is HIGH, data_bus_w is driven by the active
  // (internal) bus device, which drives the data bus pins.  data_bus_r still
  // follows the data bus.

  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d0_io (.PACKAGE_PIN(d0), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[0]), .D_IN_0(data_bus_r[0]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d1_io (.PACKAGE_PIN(d1), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[1]), .D_IN_0(data_bus_r[1]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d2_io (.PACKAGE_PIN(d2), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[2]), .D_IN_0(data_bus_r[2]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d3_io (.PACKAGE_PIN(d3), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[3]), .D_IN_0(data_bus_r[3]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d4_io (.PACKAGE_PIN(d4), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[4]), .D_IN_0(data_bus_r[4]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d5_io (.PACKAGE_PIN(d5), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[5]), .D_IN_0(data_bus_r[5]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d6_io (.PACKAGE_PIN(d6), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[6]), .D_IN_0(data_bus_r[6]));
  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 0)) d7_io (.PACKAGE_PIN(d7), .OUTPUT_ENABLE(sddb), .D_OUT_0(data_bus_w[7]), .D_IN_0(data_bus_r[7]));

  wire  resb_sense;
  wire  should_release_resb;

  ResetControl  reset_control (
    //.indicators   (indicators),
    .phi2         (phi2),
    .resb_strobe  (resb_sense),
    .resb         (should_release_resb)
  );

  SB_IO #(.PIN_TYPE(6'b 1010_01), .PULLUP(1'b 1)) resb_io (
    .PACKAGE_PIN    (resb),           // Tri-statable pin
    .OUTPUT_ENABLE  (!should_release_resb),  // When this is 1, PACKAGE_PIN is driven by D_OUT_0.  0: D_IN_0 senses the pin
    .D_OUT_0        (LOW),
    .D_IN_0         (resb_sense)
  );

endmodule

