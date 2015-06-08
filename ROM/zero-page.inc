
; Zero page locations

  ; Idea: Use a "stack" for temporary ZP values and pointers.  The "SP" would
  ; be retrieved and used either as X for m[ZP+X] addressing or to self-modify
  ; code.  The "SP" is then decremented so that nested callers also get space.
  ; A bit like a stack frame for local variables but in ZP

  map_ptr         = $02
  brk_sp          = $05
  dump_ptr        = $22   ; A cursor for dumping routines
  lines_to_dump   = $fd   ; A counter of the number of lines remaining to dump
  printfu_y_safe  = $fb
  dump_regs_mask  = $fb
  printfu_flags   = $fc
  cmdline_stream  = $24
  mnemonic_stream = $24   ; OK to reuse cmdline_stream
  tmp0 = $fb
  tmp1 = $fc
  tmp2 = $fd
  tmp3 = $fe
  tmp_ptr0 = $00

