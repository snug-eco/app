jsr main
brk


use lib.quad.s
use lib.mem.s
use lib.heap.s
use lib.string.s
use lib.args.s

var _iter
var _end
var _name


lab main
    ; quad ptrs
    lit 4
    jsr heap/new
    stv _iter

    ; file name
    jsr args/get
    stv _name

    ; check arg provided
    ldv _name
    lit 0
    equ
    jcn no-file-error

    ; check file exists
    ldv _name
    s04 ; fs_check
    lit 0
    equ
    jcn file-not-exist-error

    ; seek file
    ldv _iter
    ldv _name
    s05 ; fs_seek

    ; open iterator
    ldv _iter
    s06 ; fs_open

lab loop
    ; read char
    ldv _iter
    s02 ; sd_read

    dup
        lit 0
        equ
        jcn done

    dup
        out

    ; scan for lf 
    lit 10
    equ
    jcn linefeed

    ; inc iter
    ldv _iter
    s16 ;quad/inc

    jmp loop

lab done
    pop
    ret

lab linefeed
    ; suppliment lf with cr
    lit 13
    out

    ldv _iter
    ;jsr quad/inc
    s16 ;quad/inc
    jmp loop


lab file-not-exist-error
    lit 80
    jsr heap/new
    dup
    str "cat error: no such file "
    dup
    jsr string/print
    ldv _name
    jsr string/print
    jsr string/newline
    brk

lab no-file-error
    lit 0 
    str "cat error: no file name provided"
    lit 0
    jsr string/print
    jsr string/newline
    brk




    



