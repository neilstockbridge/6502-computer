
reset_handler:
main:
  jmp main


irq_handler:
nmi_handler:
  rti


.segment "VECTORS"
  .word nmi_handler, reset_handler, irq_handler

