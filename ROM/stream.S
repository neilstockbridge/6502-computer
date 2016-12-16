;
; A "stream" is just a 16-bit pointer in ZP to a stream of bytes that are
; accessed sequentially such as a text string.
;

.import inc_zp_ptr

.export read_from_stream
.export write_to_stream


; Reads a byte from the address indicated by the ZP pointer and then advances
; the pointer.
;
; @param      X   The address in ZP of the pointer
; @return     A   The next byte from the stream
; @destroys   A
;
read_from_stream:
  lda ($00,x)
  jmp inc_zp_ptr


; Writes a byte to the address indicated by the ZP pointer and then advances
; the pointer.
;
; @param      X   The address in ZP of the pointer
; @param      A   The data to write to the stream
;
write_to_stream:
  sta ($00,x)
  jmp inc_zp_ptr  ; Use the `rts` in inc_zp_ptr

