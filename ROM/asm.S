
SERIAL_PORT = $e000


reset_handler:
main:
  lda #$2e    ; ASCII '.'
: sta SERIAL_PORT
  jmp main


irq_handler:
nmi_handler:
  rti


.segment "VECTORS"
  .word nmi_handler, reset_handler, irq_handler

