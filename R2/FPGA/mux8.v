
module Mux8 (
  //input [7:0]  in [0:(width-1)];
  //input [7:0]   in [0:3],
  input [(8 * width) - 1 : 0]   in,
  //input [ceil(log2(width))-1:0]       select,
  input [1:0]       select,
  output reg [7:0]  out
);
  parameter  width = 4;

  //integer  i;

  always @ (select or in) begin
    /* Synthesises with Yosys but iverilog doesn't like it so can't test it:
    for (i = 0;  i < width;  i = i + 1) begin
      if (i == select) begin
        //b = i << 3;
        //out = in [(7+b):(b)];
        out = in [(7 + (i << 3)) : (i << 3)];
      end
    end
    */
    case (select)
      0: out <= in [7 + (0 << 3) : 0 << 3];
      1: out <= in [7 + (1 << 3) : 1 << 3];
      2: out <= in [7 + (2 << 3) : 2 << 3];
      3: out <= in [7 + (3 << 3) : 3 << 3];
    endcase
  end

endmodule

