/*

Controls the RESB line.

  - RESB is open collector
  - When RESB is strobed low (which may be for a very short time such as a
    switch bounce grounding RESB), this module pulls RESB low until two cycles
    of `phi2` have passed

*/

module ResetControl (
  //input [7:0]   indicators,
  input   phi2,
  input   resb_strobe,
  output  resb
);
  `include "globals.v"

  reg   strobed = 0;
  reg   strobed_last = 0;

  // The number of cycles of `phi2` before `resb` can be released
  reg [1:0]   countdown = 0;

  // When the count reaches zero, `resb` is released
  assign  resb = countdown == 0;

  //assign  indicators = {phi2, resb_strobe, strobed, strobed_last, resb, 1'b0, countdown};

  always @ (negedge resb_strobe) begin
    // NOTE: This event occurs when the FPGA pulls RESB low after detecting the strobe
    strobed <= ~strobed;
  end

  // Using `negedge` assumes that a "cycle" is PHI2 LOW *then* PHI2 HIGH, so a
  // FALLING edge denotes the end of the cycle
  always @ (negedge phi2) begin
    if (strobed != strobed_last) begin
      countdown <= 3; // `3` rather than `2` because uncertain whether a cycle of `phi2` begins on rising or falling edge
      strobed_last <= strobed;
    end else begin
      if (countdown != 0)   countdown <= countdown - 1;
    end
  end

endmodule

