/*

An address decoder can be thought of as a black box in to which address lines
go and which will enable *exactly one* bus device at any one time.

The 6502 can drive the address bus with random values when PHI2 is low, so no
bus device should be selected when phi2 is 0.  Actually, because the address
decoder is slower than an internal bus device's "always @ (posedge phi2) if
(enabled)" test, devices should be enabled when PHI2 is low but not triggered
(/OE, /WE, etc.) until PHI2 rises.

When PHI2 is low, the 6502 does some thinking and makes changes to its A* and
RWB lines, which are held stable while PHI2 is HIGH, which is when peripherals
should do their thing.

*/

module AddressDecoder (
  input         phi2,
  input [15:0]  address_bus,
  /*
  output        ce0,
  output        ce1
  */
  /*
  output reg    ce0,
  output reg    ce1
  */
  output [MAX_BUS_DEVICE_ID : 0]              enable_lines,
  output reg [(BUS_DEVICE_ID_WIDTH - 1) : 0]  active_bus_device_id
);

  `include "globals.v"

  assign  enable_lines[CLOCK_SCALER_ID] =   active_bus_device_id == CLOCK_SCALER_ID;
  assign  enable_lines[CYCLE_COUNTER_ID] =  active_bus_device_id == CYCLE_COUNTER_ID;
  assign  enable_lines[UART_ID] =           active_bus_device_id == UART_ID;
  assign  enable_lines[SPI_ID] =            active_bus_device_id == SPI_ID;
  assign  enable_lines[SRAM_ID] = (phi2 == 1) & (active_bus_device_id == SRAM_ID);

  // Even if this is slow, it will change active_bus_device_id while phi2 is
  // LOW so that the chip enable signal can be asserted quickly by the
  // combinatorial logic when phi2 rises (to avoid the situation where an
  // internal bus device with "always @ posedge phi2; if (enabled)" thinks it's
  // disabled because it checks its enable line so quickly after phi2 rises).
  always @* begin
    casex (address_bus)
      16'b1110_0001_0000_000x: active_bus_device_id <= CLOCK_SCALER_ID;   // $e100..e101
      16'b1110_0001_0000_01xx: active_bus_device_id <= CYCLE_COUNTER_ID;  // $e104..e107
      16'b1110_0001_0000_100x: active_bus_device_id <= UART_ID;           // $e108..e109
      16'b1110_0001_0001_00xx: active_bus_device_id <= SPI_ID;            // $e110..e113
      //16'b1111_1111_1111_00xx: active_bus_device_id <= SPI_ID;            // $fff0..fff3
      default:  active_bus_device_id <= SRAM_ID;
    endcase
  end

  /*
  assign  ce0 = (phi2 == 1) & (active_bus_device_id == 0);
  assign  ce1 = active_bus_device_id == 1;
  */

  /*
  assign ce0 = phi2 == 1 & address_bus[7] == 0;
  assign ce1 = phi2 == 1 & address_bus[7] == 1;
  */
  /*
  always @* begin
    // Disabled because I think there's enough of a delay here that "posedge
    // phi2 if (enable)" make an erroneous decision because it's faster
    //if (phi2 == 0) begin
    //  ce0 <= 0;
    //  ce1 <= 0;
    //end else begin
      casex (address_bus)
        16'h00fx: begin
            ce0 = 0;
            ce1 = 1;
          end
        default: begin
            ce1 = 0;
            ce0 = 1;
          end
      endcase
    //end
  end
  */
endmodule

