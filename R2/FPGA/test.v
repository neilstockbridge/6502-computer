
`timescale 1 ns / 100 ps

//`define  MUX_TEST
//`define  CLOCK_DIVIDER_TEST
//`define  ADDRESS_DECODER_TEST
//`define  UART_TEST
//`define  RESET_CONTROL_TEST
`define  SPI_TEST

module test;

  `include "globals.v"

  reg   reset;
  reg   clk;

  initial begin
    reset = 1;
    clk = 0;
    #1 reset = 0;
  end
  always #50 clk = !clk; // 50 ns is half cycle of 10 MHz clk


  `ifdef ADDRESS_DECODER_TEST
  `define BUS_DEVICE_TEST
  `elsif UART_TEST
  `define BUS_DEVICE_TEST
  `elsif RESET_CONTROL_TEST
  `define BUS_DEVICE_TEST
  `elsif SPI_TEST
  `define BUS_DEVICE_TEST
  `endif


  `ifdef BUS_DEVICE_TEST

  reg         phi2;
  reg [15:0]  address_bus;
  reg         rwb;
  reg [7:0]   data_bus_r;
  wire [7:0]  data_bus_w;

  initial phi2 = 0;

  always #500 phi2 = ~ phi2; // 500 ns is half cycle of 1 MHz

  `endif // def PHI2


  `ifdef MUX_TEST
  reg [7:0]   a;
  reg [7:0]   b;
  reg [7:0]   c;
  reg [7:0]   d;
  reg [1:0]   select;
  wire [7:0]  out;
  Mux8  mux (
    .in       ({d, c, b, a}),
    .select   (select),
    .out      (out)
  );

  initial begin
    a = 8'h00;
    b = 8'h55;
    c = 8'haa;
    d = 8'hff;
    select = 0;
    $display("\t\ttime\tselect\tout");
    $monitor("%t\t%d\t%d", $time, select, out);
    #1 select = 1;
    #1 select = 2;
    #1 select = 3;
    #50 $finish;
  end
  `endif // MUX_TEST


  `ifdef CLOCK_DIVIDER_TEST

  reg [11:0]  scaler_divisor;
  reg         set_scaler_divisor;
  wire        divided_clock;

  ClockScaler  clock_scaler (
    .divisor      (scaler_divisor),
    .set          (set_scaler_divisor),
    .input_clock  (clk),
    .output_clock (divided_clock)
  );

  `endif


  `ifdef ADDRESS_DECODER_TEST

  wire  ce0;
  wire  ce1;

  AddressDecoder  address_decoder (
    .phi2         (phi2),
    .address_bus  (address_bus),
    .ce0          (ce0),
    .ce1          (ce1)
  );

  `endif


  `ifdef UART_TEST

  reg   uart_enable;
  wire  txd_line;

  UART  uart (
    .clk              (clk),
    .phi2             (phi2),
    .enable           (uart_enable),
    .register_select  (address_bus [0]),
    .rwb              (rwb),
    .data_bus_r       (data_bus_r),
    .data_bus_w       (data_bus_w),
    .txd_line         (txd_line)
  );
  defparam uart.CLK_DIVISOR = 4;

  `endif


  initial begin
    $dumpfile("/tmp/test.vcd");
    $dumpvars(0,test);

    `ifdef CLOCK_DIVIDER_TEST
      #1 scaler_divisor = 2;
      #1 set_scaler_divisor = 1;
      #1 set_scaler_divisor = 0;
      #500 $finish;
    `endif

    `ifdef ADDRESS_DECODER_TEST
      $display("\t\ttime\tphi2\taddr\tce0\tce1");
      $monitor("%t\t%d\t%d\t%d\t%d", $time, phi2, address_bus, ce0, ce1);
      address_bus = 0;
      repeat (16) begin
        #20 address_bus = address_bus + 16;
      end
      #40 $finish;
    `endif

    `ifdef UART_TEST
      // Write to the tx_data register
      uart_enable = 1;
      address_bus = 16'h0001;
      rwb = 0;
      data_bus_r = 8'h7f;
      #1000 uart_enable = 0;
      #10000 $finish;
    `endif
  end


  `ifdef RESET_CONTROL_TEST
  reg   phi2;
  reg   resb_strobe;
  wire  resb;

  ResetControl  reset_control (
    .phi2         (phi2),
    .resb_strobe  (resb_strobe),
    .resb         (resb)
  );

  initial begin
    resb_strobe = 1;
    $display("\t\ttime\tphi2\tresb_sb\tresb");
    $monitor("%t\t%d\t%d\t%d", $time, phi2, resb_strobe, resb);
    #3000 resb_strobe = 0;
    #1 resb_strobe = 1;
    #5000 $finish;
  end
  `endif


  `ifdef SPI_TEST
  reg           chip_enable;
  wire [7 : 0]  spi_slave_select_lines;
  wire          spi_sck_line;
  reg           spi_miso_line = 0;
  wire          spi_mosi_line;
  wire          spi_irq_line;
  SPI  spi (
    .reset            (reset),
    .clk              (clk),
    .phi2             (phi2),
    .enabled          (chip_enable),
    .register_select  (address_bus [1 : 0]),
    .rwb              (rwb),
    .data_bus_r       (data_bus_r),
    .data_bus_w       (data_bus_w),
    .select_lines     (spi_slave_select_lines),
    .sck_line         (spi_sck_line),
    .miso_line        (spi_miso_line),
    .mosi_line        (spi_mosi_line),
    .irq_line         (spi_irq_line)
  );

  initial begin
    //$display("\t\ttime\tselect\tout");
    //$monitor("%t\t%d\t%d", $time, clk, phi2, chip_enable, out);

    // Slave Select lines should all be high
    rwb = RWB_WRITE;
    chip_enable = 1;
    // Set up the device
    #250 begin  // 250: While phi2 is LOW..
      // Check:
      //  cpol gets cpol_latch when phi2 falls
      address_bus = 16'h0001; // Control register
    end
    #500 data_bus_r = 8'b0100_0100; // No interrupts, No Fast Receive, No Tri-state, SCK = PHI2 divided, mode 0
    // Choose the SCK rate
    // The input clock should change as ECE becomes 0.  It's been set
    #500 address_bus = 16'h0002; // Divisor for SCK register
    #500 data_bus_r = 1; // Divisor 1 => SCK = CK / 2
    // Select the slave
    #500 address_bus = 16'h0003;
    #500 data_bus_r = 8'b1111_1110; // Assert SS0 line
    #250 spi_miso_line = 1;
    // Initiate an exchange
    #250 address_bus = 16'h0000;
    #500 data_bus_r = 8'h41;
    #500 chip_enable = 0;
    #0 spi_miso_line = 0;
    #2250 rwb = RWB_READ;
    #0 chip_enable = 1;
    #1000 $finish;
  end
  `endif

endmodule

