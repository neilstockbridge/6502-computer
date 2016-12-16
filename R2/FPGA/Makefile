
PROJECT=N6502R2
PARTS= mux8.v  reset_control.v  clock_scaler.v  UART.v  SPI.v  address_decoder.v  cycle_counter.v  top.v
#PARTS= mux8.v  reset_control.v  clock_scaler.v  UART.v  SPI.v  address_decoder.v  cycle_counter.v # no top.v for test
DEVICE=8k
FOOTPRINT=ct256

# Remove top.v from `PARTS` and uncomment this to test.  Then run gtkwave on /tmp/test.vcd
#all: simulate

include ../../Verilog-Makefile

