jsr main
brk


use lib.quad.s
use lib.mem.s
use lib.heap.s
use lib.string.s
use lib.line.s

var _buffer
var _file
var _iter
var _exec
var _argument
var _exec_name
var _pid


lab args-not-exist-error
    lit 0
    str "[PANIC] shell error: args file does not exist."
    lit 0
    jsr string/print
    jsr string/newline
    brk


lab main
    ;line buffer
    lit 128
    jsr heap/new
    stv _buffer

    ; print startup message
    ldv _buffer
    str "--- Snug Shell ---"

    ldv _buffer
    jsr string/print
    jsr string/newline

    ; open args file
    ldv _buffer 
    str "args"
    
    ldv _buffer
    s04
    lit 0
    equ
    jcn args-not-exist-error

    lit 4
    jsr heap/new
    stv _file

    ldv _file
    ldv _buffer
    s05 ;seek file

    ldv _file
    s06 ;open file iterator

    lit 4
    jsr heap/new
    stv _iter


lab loop
    ; reset args iterator
    ldv _iter
    ldv _file
    lit 4
    jsr mem/cpy

    ; prompt
    lit 62
    out
    lit 32
    out

    ; user interact 
    ldv _buffer
    lit 128
    jsr line

    ; parse exec
    ldv _buffer
    lit 32
    jsr string/token
    dup
    stv _exec
    lda
    lit 0 
    equ
    jcn loop

lab args-loop
    ; tokenize next arg and bounds check
    lit 32
    jsr string/token
    dup
    stv _argument
    lda
    lit 0
    equ
    jcn args-done

    ;flag
    ldv _iter
    lit 1
    s03 ;disk write
    ldv _iter
    jsr quad/inc

    ; length prefix
    ldv _iter
    ldv _argument
    jsr string/len
    s03 ;disk write
    ldv _iter
    jsr quad/inc

lab arg-write-loop
    ;check
    ldv _argument    
    lda
    lit 0
    equ
    jcn args-loop

    ldv _iter
    ldv _argument
    lda
    s03 ;disk write
    
    ldv _iter
    jsr quad/inc

    ldv _argument
    inc
    stv _argument
    jmp arg-write-loop


lab args-done
    pop ;token walker

    ; write args file terminator
    ldv _iter
    lit 0
    s03 ;disk write

    ; render exec file
    ldv _exec
    jsr string/len
    jsr heap/new
    stv _exec_name
    
    ldv _exec_name
    str "bin."

    ldv _exec_name
    lit 4
    add
    ldv _exec
    ldv _exec
    jsr string/len
    inc ;termi
    jsr mem/cpy

    ; check exec file exists
    ldv _exec_name
    s04
    lit 0
    equ
    jcn exec-not-found

    ; launch process
    lit 4
    jsr heap/new

    dup
    ldv _exec_name
    s05 ;file seek

    dup
    s11 ;process launch
    stv _pid

    ;clean up
    jsr heap/void
    ldv _exec_name
    jsr heap/void

lab idle-loop
    s00 ;yield

    ; check process running
    ldv _pid
    s13 ;process active?
    lit 0
    equ
    jcn loop

    ; check term in avail
    s14
    lit 0
    equ
    jcn idle-loop

    ; monitor term in
    inp
    lit 3 ;^C
    equ
    jcn kill

    jmp idle-loop

lab kill
    ldv _pid
    s12
    jmp idle-loop


lab exec-not-found
    ldv _buffer
    str "shell error: no such file "
    ldv _buffer
    jsr string/print

    ldv _exec_name
    jsr string/print
    jsr string/newline

    ldv _exec_name
    jsr heap/void
    jmp loop





    
    




