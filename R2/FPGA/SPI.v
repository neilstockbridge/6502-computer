/*

The LEADING edge refers to the first edge within a SCK cycle.  The leading edge
is a RISING edge when CPOL is 0 (idle LOW) but a FALLING edge when CPOL is 1
(idle HIGH) hence referring to the "leading" edge rather than the rising or
falling edge.

*/

module SPI (
  input             reset,
  input             clk,
  input             phi2,
  input             enabled,
  input [1:0]       register_select,
  input             rwb,
  input [7:0]       data_bus_r,
  output reg [7:0]  data_bus_w,
  output reg [7:0]  select_lines,
  output reg        sck_line,
  input             miso_line,
  output            mosi_line,
  output            irq_line
);
  `include "globals.v"

  reg [7 : 0]   data;
  reg [7 : 0]   data_latch; // Written by "posedge phi2"
  reg           tc;  // Transmission Complete  1: Exchange complete, cleared when data register is read
  reg           ier; // Interrupt enable  1: Interrupts enabled
  reg           bsy; // Busy  1: Do not write to data register
  reg           frx; // Fast Receive  1: Begin exchange when data register is read OR written, 0: Only begin when the data register is written
  reg           tmo; // Tri-state  1: MOSI high-Z  0: MOSI driven
  reg           ece; // External Clock Enable  0:PHI2  1:EXTC pin
  reg           cpol = 1; // Clock Polarity  0:Idle LOW  1:Idle HIGH
  reg           cpha; // Clock Phase  Data sampled on 0:Leading 1:Trailing edge of cycle
  wire [7 : 0]  status_register = {tc, ier, bsy, frx, tmo, ece, cpol, cpha};
  reg           cpol_latch;
  reg [7 : 0]   clock_divisor;
  reg [7 : 0]   clock_countdown;

  reg [1 : 0]   begin_exchange; // Synchronizing between `always` blocks
  reg [1 : 0]   data_consumed; // Synchronizing between `always` blocks
  wire          input_clock; // `phi2` or `clk`
  reg           miso_latch; // Remember the state of MISO at the leading edge
  reg [2 : 0]   shift_count;

  assign  input_clock = (ece == 0) ? phi2 : clk;
  assign  mosi_line = data [7]; // MSB first
  assign  irq_line = (ier == 1) && (tc == 1);

  // Clock divider
  always @ (posedge input_clock or posedge reset) begin

  if (reset == HIGH) begin

    sck_line <= 0;
    data <= 8'h00; // Don't care about data except that mosi_line is driven from it
    begin_exchange [0] <= 0;
    data_consumed [0] <= 0;
    tc <= 0;
    bsy <= 0; // Important because should not begin an exchange unbidden
    cpol <= 0;
    // Doesn't matter that `clock_countdown` is X because it's not relevant
    // until bsy is 1, at which point `clock_countdown` will be set.  Ditto
    // `shift_count`.

  end else begin // not reset

    if (cpol_latch != cpol) begin
      cpol = cpol_latch;
      sck_line = cpol;
    end

    // If an exchange has been requested
    if (begin_exchange [0] != begin_exchange [1]) begin
      begin_exchange [0] <= begin_exchange [1];
      bsy <= 1;
      data <= data_latch;
      shift_count <= 0;
      clock_countdown <= 1;
    end

    // If `data` has been read
    if (data_consumed [0] != data_consumed [1]) begin
      data_consumed [0] <= data_consumed [1];
      tc <= 0;
    end

    // Don't even count unless an exchange is in progress
    if (bsy == 1) begin
      // NOTE: This work differently than 65SPI.  65SPI divisor of 0 means /2, here it means /256
      //  `posedge input_clock` means that it will /2 before dividing by the divider
      //  Divider 1 => /2
      //  Divider 2 => /4
      //  Divider 3 => /6
      //  Divider ff => /510
      //  Divider 0 => /512
      // FIXME: log scale would be better: /2 /4 /8 /16 etc
      clock_countdown = clock_countdown - 1;
      if (clock_countdown == 0) begin
        clock_countdown <= clock_divisor;
        sck_line = ~ sck_line;
        // FIXME: Assuming mode 0 ATM
        if (sck_line == HIGH) begin // RISEN  FIXME: HIGH^H ~ (cpol ^ cpha)
          // Sample the data at the leading edge
          miso_latch <= miso_line;
        end else begin // FELL
          // Change the data at the trailing edge
          data <= {data[6 : 0], miso_latch};
          shift_count = shift_count + 1;
          if (shift_count == 0) begin
            bsy <= 0;
            tc <= 1;
          end
        end
      end
    end
  end // not reset
  end

  // Register file
  // When phi2 rises, the 6502 has set up the address lines and RWB and they
  // have stabilised.  If RWB is HIGH then the 6502 expect the data lines to
  // have stabilised reading for reading by the time phi2 falls.
  always @ (posedge phi2 or posedge reset) begin
  if (reset) begin
    data_consumed [1] <= 0;
  end else begin
    if (enabled && rwb == RWB_READ) begin
      case (register_select)
        0: begin  // Data register
            data_bus_w <= data;
            // The TC bit of the Status Register should be cleared
            data_consumed [1] <= ~ data_consumed [1];
          end
        1: data_bus_w <= status_register; // Status / Control
        2: data_bus_w <= clock_divisor; // Clock divisor
        3: data_bus_w <= select_lines; // Slave select
      endcase
    end
  end // not reset
  end
  // When phi2 rises and the 6502 is writing, D* will have stabilised by the
  // time phi2 falls, hence `negedge phi2` here.
  always @ (negedge phi2 or posedge reset) begin
  if (reset) begin
    ier <= 0;
    frx <= 0;
    tmo <= 1;
    ece <= 0;
    cpha <= 0;
    clock_divisor <= 0;
    select_lines <= -1;
    begin_exchange [1] <= 0;
  end else begin
    if (enabled && rwb == RWB_WRITE) begin
      case (register_select)
        0: begin
            data_latch <= data_bus_r;
            begin_exchange [1] <= ~ begin_exchange [1];
          end
        1: {ier, frx, tmo, ece, cpol_latch, cpha} <= {data_bus_r [6], data_bus_r [4 : 0]};
        2: clock_divisor <= data_bus_r;
        3: select_lines <= data_bus_r;
      endcase
    end
  end // not reset
  end

endmodule

