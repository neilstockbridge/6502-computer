/*

Counts PHI2 cycles and provides acces to the count (for cycle counting routines
for performance).

A 16-bit counter at 8 MHz can count up to 8.192 milliseconds.

Registers when reading:
0: Cycles 7..0
1: Cycles 15..8
Registers when writing:
0: Bit 0: 0: Reset the cycle count to zero  1: Leave the cycle count alone

*/

module CycleCounter (
  input               clk,              // The clock to count cycles of.  Typically `phi2`
  input               phi2,
  input               enabled,          // 0: Bus is ignored  1: This is the selected bus device
  input [1 : 0]       register_select,  // Register index.  Driven by low address bus
  input               rwb,              // 0: Bus master writes to this device  1: Reads from this device
  input [7 : 0]       data_bus_r,       // Data bus when listening to the bus master
  output [7 : 0]      indicators,
  output reg [7 : 0]  data_bus_w        // Data bus when providing data to the bus master
);

  `include "globals.v"

  localparam  RESET =     0;
  localparam  COUNTING =  1;
  localparam  HELD =      2;

  reg           reset_request = 0;
  reg           reset_request_prior = 0;
  reg           hold_request = 0;
  reg           hold_request_prior = 0;
  reg [1 : 0]   state = RESET;
  reg [15 : 0]  count;

  assign  indicators = {2'b0, reset_request, reset_request_prior, hold_request, hold_request_prior, state};

  always @ (negedge clk) begin

    case (state)
      RESET:    begin
                  count <= 0;
                  state <= COUNTING;
                end
      COUNTING: begin
                  count <= count + 1;
                  if (hold_request != hold_request_prior) begin
                    state <= HELD;
                    hold_request_prior <= hold_request;
                  end
                end
      HELD:     if (reset_request != reset_request_prior) begin
                  state <= RESET;
                  reset_request_prior <= reset_request;
                end
    endcase
  end

  always @ (posedge phi2) if (enabled && rwb == RWB_READ) case (register_select)
    0:  begin
          // Without this, the 6502 could read LO as $ff while HI is $03.  By
          // the time the 6502 reads HI it will be $04 leading to an erroneous
          // count of $04ff
          if (state == COUNTING)  hold_request = ~ hold_request;
          // trigger move to HELD
          data_bus_w <= count [7 : 0];
        end
    1:  data_bus_w <= count [15 : 8];
    2:  data_bus_w <= {2'b0, reset_request, reset_request_prior, hold_request, hold_request_prior, state};
    3:  data_bus_w <= 8'hff;
  endcase
  always @ (negedge phi2) if (enabled && rwb == RWB_WRITE) case (register_select)
    0:  if (data_bus_r [0] == 0)  reset_request <= ~ reset_request;
    1:  ;
    2:  ;
    3:  ;
  endcase

endmodule

