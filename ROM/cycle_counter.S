
.export reset_cycle_counter
.export show_cycle_count

.import phex8
.import write_eol


CYCLE_COUNTER_BASE = $e104
CYCLE_COUNTER_LO = CYCLE_COUNTER_BASE + 0
CYCLE_COUNTER_HI = CYCLE_COUNTER_BASE + 1


reset_cycle_counter:
  lda #0
  sta CYCLE_COUNTER_LO  ; Reset to 0
  rts


show_cycle_count:
  lda CYCLE_COUNTER_LO
  pha
  lda CYCLE_COUNTER_HI
  jsr phex8
  pla
  jsr phex8
  jsr write_eol
  rts


