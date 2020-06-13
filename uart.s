.global uart_init
.global uart_char
.global uart_str


uart_init:
  mov  x19, x30 // push return address

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
       
  mov  x0, 150
  bl   delay // delay for 150 cycles
 
  // write 49152 to address 0x3f20 0098 (GPPUDCLK0)
  mov  x0, 0x0098
  movk x0, 0x3f20, lsl 16
  mov  w1, 49152
  str  w1, [x0]
  
  mov  x0, 150
  bl   delay // delay for 150 cycles

  // write 0 to address 0x3f20 0098 (GPPUDCLK0)
  mov  x0, 0x0098
  movk x0, 0x3f20, lsl 16
  str  wzr, [x0]

  // write 3 to address 0x3f21 5060 (AUX_MU_CTRL, enable Tx, Rx)
  mov     x0, 0x5060
  movk    x0, 0x3f21, lsl 16
  mov     w1, 3
  str     w1, [x0]

  mov  x30, x19 // pop return address
  ret     

  
uart_char: // x0: character to print

  // check value at address 0x3f21 5054 (AUX_MU_LSR, ready to print)
  mov  x1, 0x5054
  movk x1, 0x3f21, lsl 16
  ldr  w1, [x1]
  and  w1, w1, 32
  cbnz w1, .print // continue if we are ready to print

  // otherwise wait a cycle and repeat the check
  nop
  b uart_char

.print:

  // write character to address 0x3f21 5040 (AUX_MU_IO)
  mov  x1, 0x5040
  movk x1, 0x3f21, lsl 16
  str  x0, [x1]
  ret


uart_str: // x0: address of the first character of string to print
  mov  x19, x30 // push return address
  
.loop:
  mov  x20, x0  // push character address
  
  // check the character value (zero indicates end of string)
  ldr  x0, [x0]
  cbz  x0, .done // we are done printing the string

  bl   uart_char  // print the character
  add  x0, x20, 1 // increment and pop character address
  b    .loop      // repeat for next character

.done:
  mov  x30, x19  // pop return address
  ret
