
; Zero page locations

  ; Idea: Use a "stack" for temporary ZP values and pointers.  The "SP" would
  ; be retrieved and used either as X for m[ZP+X] addressing or to self-modify
  ; code.  The "SP" is then decremented so that nested callers also get space.
  ; A bit like a stack frame for local variables but in ZP

  zp_sp           = $02   ; Zero-Page Stack Pointer
  map_ptr         = $03
  brk_sp          = $05
  dump_ptr        = $22   ; A cursor for dumping routines
  lines_to_dump   = $10   ; A counter of the number of lines remaining to dump
  printfu_y_safe  = $11
  dump_regs_mask  = $11
  printfu_flags   = $12
  cmdline_stream  = $24
  mnemonic_stream = $24   ; OK to reuse cmdline_stream
  tmp_ptr0 = $00

