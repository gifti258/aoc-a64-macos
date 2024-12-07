#include <sys/syscall.h>

.global _main
.align 2

.set STDIN, 0
.set STDOUT, 1
.set CELL, 8

.macro adrl reg, label
  adrp \reg, \label@page
  add \reg, \reg, \label@pageoff
.endm

.macro syscall number
  mov x16, \number
  svc 0x80
.endm

.macro quit
  mov x0, 0
  syscall SYS_exit
.endm

.macro write_stdout
  mov x0, STDOUT
  syscall SYS_write
.endm

.data
NL:
  .ascii "\n"

.macro nl
  adrl x1, NL
  mov x2, 1
  write_stdout
.endm

.data
SP:
  .ascii " "

.macro sp
  adrl x1, SP
  mov x2, 1
  write_stdout
.endm

.bss
T0:
  .skip CELL
T1:
  .skip CELL

.macro save_time reg
  mrs \reg, cntpct_el0
.endm

.macro store_time symbol
  save_time x0
  adrl x1, \symbol
  str x0, [x1]
.endm

.macro start_timer
  store_time T0
.endm

.data
NANOS:
  .ascii "nanos: "

.macro stop_timer
  store_time T1

  adrl x1, NANOS
  mov x2, 7
  write_stdout

  adrl x1, T0
  ldr x0, [x1]
  adrl x1, T1
  ldr x2, [x1]
  sub x0, x2, x0
  print_u64 x0
.endm

.bss
NUMBER:
  .skip 20

_write_u64_number .req x0
_write_u64_buffer .req x1
_write_u64_len .req x2
_write_u64_ten .req x3
_write_u64_quot .req x4
_write_u64_rem .req x5
_write_u64_rem_w .req w5

.macro write_u64 reg
  mov _write_u64_number, \reg
  adrl _write_u64_buffer, (NUMBER + 20)
  mov _write_u64_len, 0
  mov _write_u64_ten, 10
_write_u64_loop_\@:
  sdiv _write_u64_quot, _write_u64_number, _write_u64_ten
  msub _write_u64_rem, _write_u64_ten, _write_u64_quot, _write_u64_number
  add _write_u64_rem, _write_u64_rem, '0'
  sub _write_u64_buffer, _write_u64_buffer, 1
  strb _write_u64_rem_w, [_write_u64_buffer]
  add _write_u64_len, _write_u64_len, 1
  mov _write_u64_number, _write_u64_quot
  cbnz _write_u64_quot, _write_u64_loop_\@
  mov x1, _write_u64_buffer
  mov x2, _write_u64_len
  write_stdout
.endm

.macro print_u64 reg
  write_u64 \reg
  nl
.endm
