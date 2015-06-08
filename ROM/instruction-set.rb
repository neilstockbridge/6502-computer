#!/usr/bin/env ruby
#
# Contains and parses a representation of the W65C02 instruction set that is
# easy to input from the data sheet and outputs it in JSON.
#

# from data-sheet                   fromDS  bytes cycles  C (for addr. may be used as index to M[] again dep on instr)
addressing_modes = <<".".split("\n")
absolute                            a       2     4m      i2 << 8 | i1
absolute-indexed-indirect           (a,x)   2     5       M[ ( i2 << 8 | i1 ) + X ]
absolute-indexed-with-X             a,x     2     4pm     ( i2 << 8 | i1 ) + X
absolute-indexed-with-Y             a,y     2     4p      ( i2 << 8 | i1 ) + Y
absolute-indirect                   (a)     2     4m      M[ i2 << 8 | i1 ]
accumulator                         A       0     2       A
immediate                           #       1     2       i1
implied                             i       0     2       -
program-counter-relative            r       1     2b      i1
stack                               s       0     3..7
zero-page                           zp      1     3m      i1
zero-page-indexed-indirect          (zp,x)  1     6       M[ i1 + X ]
zero-page-indexed-with-X            zp,x    1     4m      i1 + X
zero-page-indexed-with-Y            zp,y    1     4       i1 + Y
zero-page-indirect                  (zp)    1     5       M[ i1 ]
zero-page-indirect-indexed-with-Y   (zp),y  1     5       M[ i1 ] + Y
.
# b: +1 cycle if branch is taken
# m: +2 cycles for read-modify-write instructions
# p: +1 cycle if page boundary is crossed when forming address

opcodes = <<".".split("\n").reject {|line| "----------" == line }
brk #
ora (zp,x)
-
-
tsb zp
ora zp
asl zp
rmb0 zp
php s
ora #
asl A
-
tsb a
ora a
asl a
bbr0 r
----------
bpl r
ora (zp),y
ora (zp)
-
trb zp
ora zp,x
asl zp,x
rmb1 zp
clc i
ora a,y
inc A
-
trb a
ora a,x
asl a,x
bbr1 r
----------
jsr a
and (zp,x)
-
-
bit zp
and zp
rol zp
rmb2 zp
plp s
and #
rol A
-
bit a
and a
rol a
bbr2 r
----------
bmi r
and (zp),y
and (zp)
-
bit zp,x
and zp,x
rol zp,x
rmb3 zp
sec i
and a,y
dec A
-
bit a,x
and a,x
rol a,x
bbr3 r
----------
rti s
eor zp,x
-
-
-
eor zp
lsr zp
rmb4 zp
pha s
eor #
lsr A
-
jmp a
eor a
lsr a
bbr4 r
----------
bvc r
eor (zp),y
eor (zp)
-
-
eor zp,x
lsr zp,x
rmb5 zp
cli i
eor a,y
phy s
-
-
eor a,x
lsr a,x
bbr5 r
----------
rts s
adc (zp,x)
-
-
stz zp
adc zp
ror zp
rmb6 zp
pla s
adc #
ror A
-
jmp (a)
adc a
ror a
bbr6 r
----------
bvs r
adc (zp),y
adc (zp)
-
stz zp,x
adc zp,x
adc zp,x
rmb7 zp
sei i
adc a,y
ply s
-
jmp (a,x)
adc a,x
ror a,x
bbr7 r
----------
bra r
sta (zp,x)
-
-
sty zp
sta zp
stx zp
smb0 zp
dey i
bit #
txa i
-
sty a
sta a
stx a
bbs0 r
----------
bcc r
sta (zp),y
sta (zp)
-
sty zp,x
sta zp,x
stx zp,y
smb1 zp
tya i
sta a,y
txs i
-
stz a
sta a,x
stz a,x
bbs1 r
----------
ldy #
lda (zp,x)
ldx #
-
ldy zp
lda zp
ldx zp
smb2 zp
tay i
lda #
tax i
-
ldy a
lda a
ldx a
bbs2 r
----------
bcs r
lda (zp),y
lda (zp)
-
ldy zp,x
lda zp,x
ldx zp,y
smb3 zp
clv i
lda a,y
tsx i
-
ldy a,x
lda a,x
ldx a,x
bbs3 r
----------
cpy #
cmp (zp,x)
-
-
cpy zp
cmp zp
dec zp
smb4 zp
iny i
cmp #
dex i
wai i
cpy a
cmp a
dec a
bbs4 r
----------
bne r
cmp (zp),y
cmp (zp)
-
-
cmp zp,x
dec zp,x
smb5 zp
cld i
cmp a,y
phx s
stp i
-
cmp a,x
dec a,x
bbs5 r
----------
cpx #
sbc (zp,x)
-
-
cpx zp
sbc zp
inc zp
smb6 zp
inx i
sbc #
nop i
-
cpx a
sbc a
inc a
bbs6 r
----------
beq r
sbc (zp),y
sbc (zp)
-
-
sbc zp,x
inc zp,x
smb7 zp
sed i
sbc a,y
plx s
-
-
sbc a,x
inc a,x
bbs7 r
.

mode_id_by_label = {}

puts <<"."
; Table of addressing modes.  Each byte is simply the number of operand bytes
; for an instruction that uses the mode
@ADDRESSING_MODES:
.
print "  .byt "
addressing_modes.each_with_index do |line, mode_id| line.chomp!
  description, label, bytes, cycle, in_C = line.split(/  +/)
  mode_id_by_label[ label] = mode_id
  print "#{ bytes }"
  print ", " unless "(zp),y" == label # "(zp),y" being the last
end
puts


mnemonics = []           # A list of mnemonics ( strings)
opcode_mnemonic_ids = [] # Lookup table from OpCode to index in the "mnemonics" table
opcode_mode_ids = []     # Lookup table from OpCode to index in the "addressing_modes" table

opcodes.each_with_index do |line, opcode| line.chomp!
  mnemonic, mode_id = line.split
  mode_id ||= "i" # Pretend that missing intructions use the "implied" addressing mode
  # Rename the SMBx, RMBx, BBRx, BBSx mnemonics so they a) fit in to 3
  # characters, and b) match the Set/Clear convention of the original
  mnemonic.sub! /smb([0-7])/, 'se\1'
  mnemonic.sub! /rmb([0-7])/, 'cl\1'
  mnemonic.sub! /bbs([0-7])/, 'b\1s'
  mnemonic.sub! /bbr([0-7])/, 'b\1c'
  mnemonic.sub! "-", "---"

  mnemonics << mnemonic unless mnemonics.include? mnemonic
  opcode_mnemonic_ids << mnemonics.index( mnemonic)
  opcode_mode_ids << mode_id_by_label[ mode_id]
end

puts "; List of mnemonics"
puts "@MNEMONICS:"
mnemonics.each_with_index do |mnemonic, mnemonic_id|
  print "  .byt " if 0 == mnemonic_id & 0x7
  print "\"#{ mnemonic }\""
  last = mnemonics.count - 1 == mnemonic_id
  eol = mnemonic_id + 1 & 0x7 == 0
  print ! eol && ! last ? ", " : "\n"
end

puts "; Lookup table that maps OpCode to index in @MNEMONICS"
puts "@OPCODE_MNEMONIC_IDS:"
opcode_mnemonic_ids.each_with_index do |mnemonic_id, opcode|
  print "  .byt " if 0 == opcode & 0xf
  print "$%02x"% mnemonic_id
  print opcode + 1 & 0xf != 0 ? "," : "\n"
end

puts "; Lookup table that maps OpCode to addressing mode ID.  FIXME: Pack in to nybbles"
puts "@OPCODE_ADDRESSING_MODE_IDS:"
opcode_mode_ids.each_with_index do |mode_id, opcode|
  print "  .byt " if 0 == opcode & 0xf
  print "$%02x"% mode_id
  print opcode + 1 & 0xf != 0 ? "," : "\n"
end

