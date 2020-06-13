.section ".text.boot"

.global start


start:
  mrs  x0, mpidr_el1 // retrieve core id from special register
  and  x0, x0, 3
  cbnz x0, .idle     // let all cores but the first one idle

  bl   uart_init

  ldr  x0, =msg
  bl   uart_str // print msg 

.idle: 
  wfe        // allow cores to run in low-power state
  b    .idle // infinite loop


.data

msg:
  .asciz "Hello World from armOS!\n"
