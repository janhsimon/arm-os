.section ".text.boot"

.global start

start:
  mrs  x0, mpidr_el1 // retrieve processor id
  and  x0, x0, 3
  cbz  x0, main      // let only the primary core run


infinite_loop: 
  wfe
  b    infinite_loop


main:
 
  // set last bit at address 0x3f21 5004 to 1 (AUX_ENABLE, uart1)
  mov  x0, 0x5004
  movk x0, 0x3f21, lsl 16
  ldr  w1, [x0]
  orr  w1, w1, 1 // force last bit to 1
  str  w1, [x0]

  // write 0 to address 0x3f21 5060 (AUX_MU_CNTL, disable Tx, Rx)
  mov  x0, 0x5060
  movk x0, 0x3f21, lsl 16
  str  wzr, [x0] // write zero register to address

  // write 3 to address 0x3f21 504c (AUX_MU_LCR, 8 bits)
  mov  x0, 0x504c
  movk x0, 0x3f21, lsl 16
  mov  w1, 3
  str  w1, [x0]

  // write 0 to address 0x3f21 5050 (AUX_MU_MCR)
  mov  x0, 0x5050
  movk x0, 0x3f21, lsl 16
  str  wzr, [x0]

  // write 0 to address 0x3f21 5044 (AUX_MU_IER)
  mov  x0, 0x5044
  movk x0, 0x3f21, lsl 16
  str  wzr, [x0]

  // write 198 to address 0x3f21 5048 (AUX_MU_IIR, disable interrupts)        
  mov  x0, 0x5048
  movk x0, 0x3f21, lsl 16
  mov  w1, 198
  str  w1, [x0]

  // write 270 to address 0x3f21 5068 (AUX_MU_BAUD, 115200 baud) 
  mov  x0, 0x5068
  movk x0, 0x3f21, lsl 16
  mov  w1, 270
  str  w1, [x0]

  // store bitmask at address 0x3f20 0004 (GPFSEL1)
  mov  x0, 0x0004
  movk x0, 0x3f20, lsl 16
  ldr  w1, [x0]
        
  // and bitmask with 0xffff ffff fffc 0fff (GPIO14, GPIO15)
  and w1, w1, 0xfffffffffffc0fff

  // or bitmask with 0x0001 2000 (ALT5)  
  mov  w0, 0x2000
  movk w0, 0x0001, lsl 16
  orr  w1, w1, w0

  // write bitmask back to address 0x3f20 0004 (GPFSEL1)
  mov  x0, 0x0004
  movk x0, 0x3f20, lsl 16
  str  w1, [x0]

  // write 0 to address 0x3f20 0094 (GPPUD, enable pins 14 and 15)
  mov  x0, 0x0094
  movk x0, 0x3f20, lsl 16
  str  wzr, [x0]
       
  mov x0, 150
  bl delay // delay for 150 cycles
 
  // write 49152 to address 0x3f20 0098 (GPPUDCLK0)
  mov  x0, 0x0098
  movk x0, 0x3f20, lsl 16
  mov  w1, 49152
  str  w1, [x0]
  
  mov x0, 150
  bl delay // delay for 150 cycles

  // write 0 to address 0x3f20 0098 (GPPUDCLK0)
  mov  x0, 0x0098
  movk x0, 0x3f20, lsl 16
  str  wzr, [x0]

  // write 3 to address 0x3f21 5060 (AUX_MU_CTRL, enable Tx, Rx)
  mov     x0, 20576
  movk    x0, 0x3f21, lsl 16
  mov     w1, 3
  str     w1, [x0]
        
  ldr  x0, =msg
  bl   uart_str      // print msg
  b    infinite_loop // and also go into infinite loop


delay: // x0: number of cycles to delay for
  nop            // wait a cycle
  sub  x0, x0, 1 // decrement counter
  cbnz x0, delay // compare and repeat if non-zero
  ret

  
uart_char: // x0: character to print
  nop // wait a cycle

  // check value at address 0x3f21 5054 (AUX_MU_LSR)
  mov  x1, 0x5054
  movk x1, 0x3f21, lsl 16
  ldr  w1, [x1]
  and  w1, w1, 32    // and the value with 32
  cbz  w1, uart_char // repeat if we can not send yet

  // write character to address 0x3f21 5040 (AUX_MU_IO)
  mov  x1, 0x5040
  movk x1, 0x3f21, lsl 16
  str  x0, [x1]
  ret


uart_str: // x0: address of string to print
  ldr  x1, [x0]          // load the character at address x0 into x1
  cbz  x1, uart_str_done // return if we are done printing the string

  // print character at address x0
  mov  x19, x30  // push return address
  mov  x20, x0   // push character address to print
  mov  x0, x1
  bl   uart_char // print the character at address x0
  mov  x0, x20   // pop first character of string to print
  mov  x30, x19  // pop return address
  
  add  x0, x0, 1 // increment the character address
  b uart_str     // repeat for this next character

uart_str_done:
  ret


.data

msg:
  .asciz "Hello World from armOS!\n"
