jsr main
brk


use lib.mem.s
use lib.quad.s
use lib.heap.s
use lib.string.s
use lib.args.s


lab main
lab loop
    ; grab next argument
    jsr args/get

    ; check null ptr
    dup
    lit 0
    equ
    jcn done

    ; print
    dup
    jsr string/print
    lit 32
    out

    ; clean up
    jsr heap/void

    jmp loop

lab done
    pop
    jsr string/newline
    ret

