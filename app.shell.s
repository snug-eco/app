jsr main
brk


use lib.sys.s
use lib.mem.s
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
    lit 100
    jsr sys/heap/alloc
    dup
    str "[PANIC] shell error: args file does not exist."
    jsr string/print
    jsr string/newline
    brk


lab main
    ;line buffer
    lit 128
    jsr sys/heap/alloc
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
    jsr sys/file/check
    not
    jcn args-not-exist-error


    ldv _buffer
    jsr sys/file/seek
    jsr sys/file/open
    stv _file


lab loop
    ; reset args iterator
    ldv _file
    stv _iter

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
    lit 32 ;space
    jsr string/token
    dup
    stv _exec
    ; check exec is valid
    lda
    lit 0 
    equ
    jcn loop ;if not, restart

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
        dup
        inc
        stv _iter
    lit 1 ; arg present
    jsr sys/disk/write

    ; length prefix
    ldv _iter
        dup
        inc
        stv _iter
    ldv _argument
    jsr string/len
    jsr sys/disk/write

lab arg-write-loop
    ;check
    ldv _argument    
    lda
    lit 0
    equ
    jcn args-loop

    ; write into file and inc both
    ldv _iter
        dup
        inc
        stv _iter
    ldv _argument
        dup
        inc
        stv _argument
    lda
    jsr sys/disk/write
    
    jmp arg-write-loop


lab args-done
    ;BUG MAYBE????
    ;pop ;token walker

    ; write args file terminator
    ldv _iter
    lit 0
    jsr sys/disk/write

    ; render exec file
    ldv _exec
    jsr string/len
    lit 5 ; +1 termi +4 name
    add
    jsr sys/heap/alloc
    stv _exec_name
    
    ;write prefix
    ldv _exec_name
    str "bin."

    ;write name
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
    jsr sys/file/check
    not
    jcn exec-not-found

    ; launch process
    ldv _exec_name
    jsr sys/file/seek
    jsr sys/proc/launch
    stv _pid

    ;clean up
    ldv _exec_name
    jsr sys/heap/free

lab idle-loop
    jsr sys/yield

    ; check process running
    ldv _pid
    jsr sys/proc/check
    not
    jcn loop

    ; check term in avail
    jsr sys/io/recv-ready
    not
    jcn idle-loop

    ; monitor term in
    inp
    lit 3 ;^C
    equ
    jcn kill

    jmp idle-loop

lab kill
    ldv _pid
    jsr sys/proc/kill
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
    jsr sys/heap/free
    jmp loop





    
    




