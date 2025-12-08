jsr main
brk

use lib.mem.s
use lib.quad.s
use lib.heap.s
use lib.string.s
use lib.args.s
use lib.line.s
use lib.disk.s


var _filename
var _file
var _addr
var _tbuf
var _ptr

lab main
    ; read file name argument
    jsr args/get
    stv _filename

    ; check present
    ldv _filename
    lit 0
    equ
    jcn no-file-error

    ; init exploration address
    lit 0
    stv _addr

    ; init token buffer
    lit 80
    jsr heap/new
    stv _tbuf

    ; debug open file
    lit 4
    jsr heap/new
    dup
    stv _file
    ldv _filename
    s05
    ldv _file
    s06

lab loop
    jsr token
    lit 1
    xor
    jcn done

    ldv _tbuf
    jsr string/print
    jsr string/newline

    jmp loop
lab done
    brk

    ;ldv _filename

    ; explore file
    ;ldv _filename
    ;jsr explore

    ;



; ( char -- is )
lab is-space
    ; space
    dup
    lit 32
    equ
    swp
    ; linefeed
    dup
    lit 10
    equ
    swp
    ; tab
    dup
    lit 9
    equ
    swp

    ; or together
    pop
    aor
    aor
    ret
    


; ( -- succ)
lab token
    ; skip white space
    ldv _file
    s02 ;disk/read
    jsr is-space
    lit 1
    xor
    jcn token/not-space
    ldv _file    
    s16 ;quad/inc
    jmp token

lab token/not-space
    ; setup write ptr
    ldv _tbuf
    stv _ptr

    ldv _file
    s02 ;disk/read

    ; terminator
    dup
    lit 0
    equ
    jcn token/eof

    ; comment
    dup
    lit 59
    equ
    jcn token/comment

    ; string
    dup
    lit 34
    equ
    jcn token/string

    ; default
lab token/default
    ldv _file
    s02 ;disk/read
    dup
    jsr is-space
    jcn token/default-done
    ldv _ptr
    sta

    ;inc
    ldv _ptr
    inc
    stv _ptr
    ldv _file
    s16

    jmp token/default
lab token/default-done
    pop
    jmp token/finalize

lab token/eof
    ; not succies
    lit 0
    ret

lab token/comment
    ldv _file
    s16 ;quad/inc

    ldv _file
    s02 ;disk/read
    lit 10
    neq
    jcn token/comment

    jmp token ;restart

lab token/string
    ldv _file
    s16 ;quad/inc

    ldv _file
    s02 ;disk/read
    dup
    lit 34
    equ
    jcn token/string-done
    ldv _ptr
    sta

    ;inc
    ldv _ptr
    inc
    stv _ptr

    jmp token/string

lab token/string-done
    pop

    ldv _file
    s16 ;quad/inc

    jmp token/finalize 

lab token/finalize
    ; write terminator
    lit 0
    ldv _ptr
    sta

    ; succies
    lit 1
    ret








; ( path-str* -- )
lab explore
    stv _filename

    ; check file
    ldv _filename
    s04
    lit 0
    equ
    jcn file-not-exist-error

    ;open file
    lit 4
    jsr heap/new
    dup
    stv _file
    ldv _filename
    s05
    ldv _file
    s06

lab explore/loop
    jsr token




lab file-not-exist-error
    lit _tbuf
    str "assembler error: no such file "
    lit _tbuf
    jsr string/print
    ldv _filename
    jsr string/print
    jsr string/newline
    brk

lab no-file-error
    lit _tbuf
    str "assembler error: no file name provided"
    lit _tbuf
    jsr string/print
    jsr string/newline
    brk
    









