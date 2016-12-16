;
; 16-bit pointers in Zero Page.
;
; Referenced by X, only 8-bit need be passed to methods rather than a 16-bit
; pointer in both A and X thus freeing A for another parameter.  Tidy when the
; pointer can be modified by the method or the method changes the pointer in
; order to return the new pointer to the caller or the method would need
; storage for such a pointer anyway.
;

.export inc_zp_ptr
.export advance_zp_ptr
.export adjust_zp_ptr

.import add_u8_to_u16
.import add_s8_to_u16


; Advances a pointer to the next byte.
;
; @param      X     The address in ZP of the pointer
; @destroys   None
;
inc_zp_ptr:
  inc $00,x
  bne :+
  inc $01,x
  ; Could save a byte at the cost of performance by using adjust_zp_ptr
: rts


advance_zp_ptr = add_u8_to_u16


adjust_zp_ptr = add_s8_to_u16

