.section ".text.boot"

.global start

start:
  mrs  x0, mpidr_el1 // retrieve core id from special register
  and  x0, x0, 3
  cbnz x0, idle      // let all cores but the first one idle


main:
  bl   uart_init

  ldr  x0, =msg
  bl   uart_str // print msg 

idle: 
  wfe       // allow cores to run in low-power state
  b    idle // infinite loop


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


delay: // x0: number of cycles to delay for
  cbz  x0, delay_break // break if we have no more cycles to delay
  nop                  // wait a cycle
  sub  x0, x0, 1       // decrement counter
  b delay

delay_break:
  ret

  
uart_char: // x0: character to print

  // check value at address 0x3f21 5054 (AUX_MU_LSR, ready to print)
  mov  x1, 0x5054
  movk x1, 0x3f21, lsl 16
  ldr  w1, [x1]
  and  w1, w1, 32
  cbnz w1, uart_char_continue // continue if we are ready to print

  // otherwise wait a cycle and repeat the check
  nop
  b uart_char

uart_char_continue:

  // write character to address 0x3f21 5040 (AUX_MU_IO)
  mov  x1, 0x5040
  movk x1, 0x3f21, lsl 16
  str  x0, [x1]
  ret


uart_str: // x0: address of the first character of string to print
  mov  x19, x30 // push return address
  
uart_str_loop:
  mov  x20, x0  // push character address
  
  // peek the character
  ldr  x0, [x0]
  cbz  x0, uart_str_break // break if we are done printing the string

  bl   uart_char  // print the character
  add  x0, x20, 1 // increment and pop character address
  b    uart_str_loop   // repeat for next character

uart_str_break:
  mov  x30, x19  // pop return address
  ret


.data

msg:
  .asciz "Hello World from armOS!\n"
