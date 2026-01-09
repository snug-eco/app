jsr main
brk


use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s


lab main
lab loop
    ; grab next argument
    jsr args/get

    ; check null ptr
    dup
    not
    jcn done

    ; print
    dup
    jsr string/print
    lit 32
    out

    ; clean up
    jsr sys/heap/free

    jmp loop

lab done
    pop
    jsr string/newline
    ret

