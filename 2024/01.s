#include "../include.s"

.set LINES, 1000
.set DIGITS, 5
.set SPACES, 3
.set LEFT_BYTES, (DIGITS + SPACES)
.set RIGHT_BYTES, (DIGITS + 1)
.set BUFFER_SIZE, (DIGITS * 2 + SPACES + 1) * LINES
.set ARRAY_SIZE, CELL * LINES

.bss
BUFFER:
  .skip BUFFER_SIZE
LEFT:
  .skip ARRAY_SIZE
RIGHT:
  .skip ARRAY_SIZE

left .req x19
right .req x20
buffer .req x21

line .req x22
number .req x23
i .req x24
digit .req x25
digit_w .req w25
ten .req x26

start .req x21
end .req x22
root .req x23
a_end .req x24
a_0 .req x25
left_child .req x24
right_child .req x25
a_left_child .req x26
a_right_child .req x27
a_root .req x27

lnum .req x21
rnum .req x23
diff .req x21
abs .req x23
sum .req x24

li .req x22
ri .req x25
n .req x26
prev .req x27

.macro parse_number array, bytes
  mov number, 0
  mov i, 0
1:
  ldrb digit_w, [buffer, i]
  sub digit, digit, '0'
  madd number, number, ten, digit
  add i, i, 1
  cmp i, DIGITS
  bne 1b
  str number, [\array, line, lsl 3]
  add buffer, buffer, \bytes
.endm

.macro sort array
  mov start, (LINES / 2)
  mov end, LINES
1:
  cmp end, 1
  beq 6f
  cbz start, 2f
  sub start, start, 1
  b 3f
2:
  sub end, end, 1
  ldr a_end, [\array, end, lsl 3]
  ldr a_0, [\array]
  str a_end, [\array]
  str a_0, [\array, end, lsl 3]
3:
  mov root, start
4:
  lsl left_child, root, 1
  add left_child, left_child, 1
  cmp left_child, end
  bge 1b
  add right_child, left_child, 1
  cmp right_child, end
  ldr a_left_child, [\array, left_child, lsl 3]
  ldr a_right_child, [\array, right_child, lsl 3]
  ccmp a_left_child, a_right_child, 0, lt
  bge 5f
  add left_child, left_child, 1
  ldr a_left_child, [\array, left_child, lsl 3]
5:
  ldr a_root, [\array, root, lsl 3]
  cmp a_root, a_left_child
  bge 1b
  str a_left_child, [\array, root, lsl 3]
  str a_root, [\array, left_child, lsl 3]
  mov root, left_child
  b 4b
6:
.endm

.text
_main:
  mov x0, STDIN
  adrl x1, BUFFER
  mov x2, BUFFER_SIZE
  syscall SYS_read

  start_timer

  adrl buffer, BUFFER
  adrl left, LEFT
  adrl right, RIGHT
  mov line, 0
  mov ten, 10
parse_line:
  parse_number left, LEFT_BYTES
  parse_number right, RIGHT_BYTES
  add line, line, 1
  cmp line, LINES
  bne parse_line

  sort left
  sort right

  mov line, LINES
  mov sum, 0
next_pair:
  sub line, line, 1
  ldr lnum, [left, line, lsl 3]
  ldr rnum, [right, line, lsl 3]
  sub diff, lnum, rnum
  eor abs, diff, diff, asr 63
  sub abs, abs, diff, asr 63
  add sum, sum, abs
  cbnz line, next_pair

  stop_timer

  print_u64 sum

  start_timer

  mov li, 0
  mov ri, 0
  mov prev, 0
  ldr rnum, [right]
  mov sum, 0
next_left:
  ldr lnum, [left, li, lsl 3]
  cmp prev, lnum
  beq accumulate
  mov prev, lnum
  mov n, 0
next_right:
  cmp lnum, rnum
  blt accumulate
  bgt find_left
  add n, n, 1
find_left:
  add ri, ri, 1
  ldr rnum, [right, ri, lsl 3]
  b next_right
accumulate:
  madd sum, n, lnum, sum
  add li, li, 1
  cmp li, LINES
  bne next_left

  stop_timer

  print_u64 sum

  quit
