
localparam  LOW = 1'b0;
localparam  HIGH = 1'b1;
localparam  RWB_READ = HIGH;
localparam  RWB_WRITE = LOW;

localparam  BUS_DEVICE_ID_WIDTH = 3;
// The number of bus devices that are internal to the FPGA.  These devices
// should have the lowest IDs so that arrays of bus lines may be defined in
// terms of this constant and bus device IDs used to index those arrays.
localparam  INTERNAL_BUS_DEVICES = 4;

localparam  CLOCK_SCALER_ID =  0;
localparam  CYCLE_COUNTER_ID = 1;
localparam  UART_ID =          2;
localparam  SPI_ID =           3;
localparam  SRAM_ID =          4;
localparam  MAX_BUS_DEVICE_ID = SRAM_ID;

