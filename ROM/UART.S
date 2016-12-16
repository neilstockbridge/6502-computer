
.export UART_getc
.export UART_putc

UART_BASE =   $e108
UART_STATUS = UART_BASE
UART_SEND =   UART_BASE+1
UART_RECV =   UART_BASE+1


; Reads a character from the serial port.
;
; @return   C   Clear if no data was available or Set if a character was read
; @return   A   The character read ( if data was available)
;
; @preserves  X Y
;
UART_getc:
  lda UART_STATUS ; Determine if any data has been received or not
  clc
  and #%00000001  ; 0:No data received
  beq :+          ; Branch if no data is available
  lda UART_RECV
  sec
: rts


; Sends a character via the UART.
;
; @param  A  The character to send
;
; @preserves  A X Y C
;
UART_putc:
  pha
: lda UART_STATUS   ; Wait until the transmit buffer is ready
  and #%00010000    ; 0:Busy
  beq :-
  pla
  sta UART_SEND
  rts

