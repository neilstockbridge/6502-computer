
.export SPI_select
.export SPI_exchange
.export SPI_release

;SPI_TRACE = 1
;SPI_DISABLED = 1

.import show_A


SPI_BASE =          $e110
SPI_DATA =          SPI_BASE
SPI_STATUS_CTRL =   SPI_BASE+1
SPI_CLOCK =         SPI_BASE+2
SPI_SLAVE_SELECT =  SPI_BASE+3


; Selects the SPI slave by bringing its /CS line LOW.
;
; @destroys  A
;
SPI_select:
  lda #$fe                ; Select SPI device #0
write_slave_select_register:
  sta SPI_SLAVE_SELECT
  rts


; Exchanges 8 bits with the selected SPI slave.
;
; @param    A   The value to transmit to the slave
; @return   A   The value received from the slave
;
SPI_exchange:

    .ifndef SPI_DISABLED
  pha
    .endif

    .ifdef SPI_TRACE
  .data
  @sent_msg: .byt "S>", 0
  .code
  bit @sent_msg
  jsr show_A
    .endif

    .ifndef SPI_DISABLED
  ; Wait until BSY is 0
  lda #$20
: bit SPI_STATUS_CTRL
  bne :-

  ; Send the data to the slave and receive data in exchange
  pla
  sta SPI_DATA

  ; Wait for the exchange to complete (TC is 1)
  lda #$80
: bit SPI_STATUS_CTRL
  beq :-
    .endif ; SPI_DISABLED

  ; Load the received data (acknowledges TC too)
  lda SPI_DATA

    .ifdef SPI_TRACE
  .data
  @received_msg: .byt " <", 0
  .code
  bit @received_msg
  jsr show_A
    .endif

  rts


; Releases the SPI slave by driving its /CS line HIGH.
;
; @destroys   A
;
SPI_release:
  lda #$ff                ; Release SPI device #0
  bra write_slave_select_register

