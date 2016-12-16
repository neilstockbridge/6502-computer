
// NOTE: If the input_clock begins low and the divisor is 2 then then the
// output_clock will transition on the FALLING edge of input_clock since TWO
// half-cycles will have elapsed.
//
module ClockScaler (
  input             input_clock,
  output reg        output_clock,
  input             phi2,
  input             enabled,          // 0: Bus is ignored  1: This is the selected bus device
  input             register_select,  // Register index.  Driven by low address bus
  input             rwb,              // 0: Bus master writes to this device  1: Reads from this device
  input [7:0]       data_bus_r,       // Data bus when listening to the bus master
  // "reg" required for Icarus
  output reg [7:0]  data_bus_w        // Data bus when providing data to the bus master
  //output [7:0]  data_bus_w        // Data bus when providing data to the bus master
);
  `include "globals.v"

  parameter  WIDTH = 8 * 2; // bits wide divisor and countdown registers

  reg [7:0]               latched_lo; // So that clock frequency doesn't change until MSB is written
  reg [(WIDTH - 1) : 0]   count_down_from = 2;//2048;
  reg [(WIDTH - 1) : 0]   countdown;

  //always @ (posedge input_clock or negedge input_clock) begin
  always @ (posedge input_clock) begin
    countdown = countdown - 1;
    if (countdown == 0) begin
      output_clock = ! output_clock;
      if (output_clock == HIGH) begin
        //if(enabled)..
      end
      countdown <= count_down_from;
    end
    if (enabled) begin
      if (phi2 == LOW && rwb == RWB_READ) begin
        case (register_select)
          0: data_bus_w <= count_down_from [7:0];
          1: data_bus_w <= count_down_from [15:8];
        endcase
      end
      if (phi2 == HIGH && rwb == RWB_WRITE) begin
        case (register_select)
          0: latched_lo <= data_bus_r;
          1: count_down_from <= {data_bus_r, latched_lo};
        endcase
      end
    end
  end

endmodule

