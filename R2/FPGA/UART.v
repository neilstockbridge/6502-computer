/*

Register file:

Status:
  indicator: data received (and is waiting)
  indicator: transmit buffer is available for writing or not
Data:
  write to write to transmit buffer
  read to read from receive buffer

TODO:
- Will definitely want the ability to interrupt when data is received
- framing error: RXD was low when a STOP bit was expected
- overflow: When the next frame was received before the data from the previous frame was read (will need indicator to note that RX data register has been read or not)
- Interrupt for TX data buffer idle?  Would allow a TX buffer in the 6502 to be flushed without blocking
- Switches to enable or disable interrupts
- Don't plan to support different frame formats or parity

tx_data_ready:  1 indicates that tx_data may be written to without corrupting
                an existing transmission.  0 indicates that a transmission is
                in progress
*/


module UART (
  input             clk,
  input             phi2,
  input             enabled,
  //input [1:0]   register_select,
  input             register_select,
  input             rwb,
  input [7:0]       data_bus_r,
  output reg [7:0]  data_bus_w,
  input             rxd_line,
  output            txd_line
);
  `include "globals.v"

  localparam  MEGAHERTZ = 1000 * 1000;

  // Constructs a frame given the data to transmit.  Saves writing this
  // assignment in three separate places.
  //
  function [10:0] framed;
    input [7:0] data;
    // One START bit, LOW.  8 data bits and two STOP bits, HIGH.  LSB on RHS
    framed = {2'b11, data, 1'b0};
  endfunction

  reg [7:0]   tx_data = 8'h41;
  // tx_data_ready could just be assign tx_state == IDLE but then what if the
  // buffer has been loaded `tx_data` written to but the transmission not yet
  // begun?
  reg         tx_data_ready = 1'b1;

  parameter  CLK_RATE = 12 * MEGAHERTZ;
  parameter  BAUD_RATE = 9600;

  // For baud rates lower than 9600, check that `tx_countdown` has enough bits
  // to store CLK_DIVISOR.
  // When `clk` is 12 MHz, dividing by 1250 yields exactly 9600 bps
  parameter  CLK_DIVISOR = CLK_RATE / BAUD_RATE;

  // The countdown in `clk` cycles to the next bit at BAUD_RATE
  reg [11:0]  tx_countdown = CLK_DIVISOR;

  // The frame currently being transmitted.  If this is changed during a
  // transmission then it will screw up the transmission but that's OK because
  // the driver should *not* do that.
  reg [10:0]  frame = framed (8'h00);
  // The bit position in `frame` that is being driven on txd_line right now.
  // This is initialized to `10` because `txd_line` is quiescent HIGH and `10`
  // drives the STOP bit, which is HIGH.
  reg [3:0]   frame_bit_id = 10;
  localparam  TX_STATE_IDLE =          0;
  localparam  TX_STATE_TRANSMITTING =  1;
  localparam  TX_STATE_COMPLETE =      2;
  reg [1:0]   tx_state = TX_STATE_IDLE;

  assign  txd_line = frame [frame_bit_id];

  always @ (posedge clk) begin

    case (tx_state)

      // If the transmitter is not currently transmitting a frame..
      TX_STATE_IDLE: begin
        // If a request to send a frame has been received..
        if (tx_data_ready == 1'b0) begin
          frame <= framed (tx_data);
          frame_bit_id <= 0;
          tx_countdown <= CLK_DIVISOR;
          tx_state <= TX_STATE_TRANSMITTING;
        end
      end

      TX_STATE_TRANSMITTING: begin
        tx_countdown <= tx_countdown - 1;

        // `txd_line` has been driven for a whole bit period when `tx_countdown`
        // reaches zero.  `frame_bit_id` therefore indicates the bit position
        // within frame that has *been* transmitted.
        if (tx_countdown == 0) begin
          if (frame_bit_id != 10) begin
            frame_bit_id <= frame_bit_id + 1;
            tx_countdown <= CLK_DIVISOR;

          end else begin
            tx_state <= TX_STATE_COMPLETE;
          end
        end
      end // TX_STATE_TRANSMITTING

      // This extra state is only here so that "always @ phi2" can reset
      // tx_data_ready after a transmission is complete without continually
      // resetting it while tx_state is IDLE and potentially resetting it
      // immediately after it was set 0 by a write to tx_data.
      TX_STATE_COMPLETE: begin
        if (tx_data_ready == 1) tx_state <= TX_STATE_IDLE;
      end

    endcase // tx_state

  end // posedge clk


  reg [11:0]  rx_countdown = CLK_DIVISOR;

  localparam  EXPECTING_START_BIT = 0;
  localparam  EXPECTING_DATA_BIT =  1;
  localparam  EXPECTING_STOP_BIT =  2;
  reg [1:0]  rx_state = EXPECTING_START_BIT;
  reg [7:0]  rx_data;
  reg [2:0]  bit_cursor;
  reg        frame_error;
  reg        data_overrun;
  reg        rx_data_valid;
  reg        acknowledge = LOW;
  reg        last_acknowledge = LOW;

  always @ (posedge clk) begin

    if (acknowledge != last_acknowledge) begin
      frame_error <= LOW;
      data_overrun <= LOW;
      rx_data_valid <= LOW;
      last_acknowledge <= acknowledge;
    end

    // Always count down even if `rx_countdown` hasn't been reset, which means
    // that it will contain junk but it is ignored.
    rx_countdown = rx_countdown - 1;

    case (rx_state)

      EXPECTING_START_BIT: begin
        // RXD is quiescent HIGH, so a START bit is indicated by LOW
        if (rxd_line == LOW) begin
          // `rxd_line` was not yet LOW the last time it was checked
          // (1 / CLK_RATE seconds ago), so the start bit began between 0 and 1
          // / CLK_RATE seconds ago.  Ignore the start bit now, but subsequent
          // bits should be sampled as close to half-way through a BAUD_RATE
          // cycle as possible, hence:
          bit_cursor <= 0;
          rx_state <= EXPECTING_DATA_BIT;
          rx_countdown <= (CLK_DIVISOR / 2) + CLK_DIVISOR;
        end
      end

      EXPECTING_DATA_BIT: begin

        if (rx_countdown == 0) begin

          rx_data [bit_cursor] = rxd_line;
          if (rx_data_valid)  data_overrun <= HIGH;
          bit_cursor = bit_cursor + 1;
          if (bit_cursor == 0)  rx_state = EXPECTING_STOP_BIT;
          rx_countdown <= CLK_DIVISOR;
        end
      end

      EXPECTING_STOP_BIT: begin

        if (rx_countdown == 0) begin

          // The STOP bit should be the quiescent state, which is HIGH
          if (rxd_line == HIGH) begin
            rx_data_valid <= HIGH;

          end else begin
            frame_error <= HIGH;
          end
          // The receiver is now ready to receive the next frame
          rx_state <= EXPECTING_START_BIT;
        end
      end
    endcase
  end


  wire [7:0]  status_register = {3'b0, tx_data_ready, 1'b0, data_overrun, frame_error, rx_data_valid};

  // The 6502 computes and changes A* and RWB when PHI2 is LOW, so when PHI2
  // rises, bus devices should respond.
  // The address decoder is slow enough that if it were to wait for a RISING
  // edge of `phi2` to enable this device then `if (enabled)` below would fall
  // right through

  // Maybe when 6502 is writing, should wait for falling PHI2 for D* lines to
  // settle, but when 6502 is reading, should drive D* when PHI2 rises
  always @ (posedge phi2) begin
    if (enabled && rwb == RWB_READ) begin
      case (register_select)
        0: begin  // Status register
            data_bus_w = status_register;
            acknowledge = ! acknowledge;  // "=" otherwise acknowledge is cleared before status_register is read!
          end
        1: begin  // Data register
            data_bus_w <= rx_data;
          end
      endcase
    end
  end
  always @ (negedge phi2) begin
    //data_bus = 8'bz;
    if (enabled && rwb == RWB_WRITE) begin
      case (register_select)
        0: ;/*case (rwb) // Status register
            RWB_READ: begin
                //data_bus_w = status_register;
                //acknowledge = ! acknowledge;  // "=" otherwise acknowledge is cleared before status_register is read!
              end
            RWB_WRITE:  ;//data_bus_w <= 0; // TODO: Set baud rate, etc.
          endcase */
        1: //case (rwb) // Data register
            //RWB_READ:   ;//data_bus_w <= rx_data;
            //RWB_WRITE: if (phi2 == LOW) begin
            begin
                //data_bus_w <= 0; // Supposed to avoid latch but I can't see any difference in the blifs
                tx_data = data_bus_r;
                tx_data_ready = 1'b0;
              end
          //endcase
      endcase
    end
    //end else begin
      // No idea if it is necessary to wrap this in !enable or not but don't
      // want tx_data_ready assigned 1 and 0 at the same time
      if (tx_state == TX_STATE_COMPLETE) tx_data_ready <= 1'b1;
    //end
  end

endmodule

