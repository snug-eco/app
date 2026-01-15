jsr main
brk

use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s
use lib.line.s


var _filename
var _file
var _addr
var _tbuf
var _ptr
var _char
var _index
var _mnem

; table are constructed during exploration pass
; and map a 32-bit hash of the identifier to
; its program/memory address. two quad words per entry:
;  p + 0 -> hash
;  p + 1 -> address
var _tabl_lab ;label table
var _tabl_var ;var table

; tabel[index * 2]
var _tabl_lab_index
var _tabl_var_index

lab main
    ; read file name argument
    jsr args/get
    stv _filename

    ; check present
    ldv _filename
    not
    jcn no-file-error

    ; init exploration address
    lit 0
    stv _addr

    ; init token buffer
    lit 80
    jsr sys/heap/alloc
    stv _tbuf

    ; mnemonic
    lit 10 
    jsr sys/heap/alloc
    stv _mnem

    ;tables
    lit 400 ;200 entries
    jsr sys/heap/alloc
    stv _tabl_lab
    lit 200 ;100 entries
    jsr sys/heap/alloc
    stv _tabl_var

    ;explore file
    ldv _filename
    jsr explore

    brk



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
    jsr sys/disk/read
    jsr is-space
    not
    jcn token/not-space
        ldv _file
        inc
        stv _file
    jmp token

lab token/not-space
    ; setup write ptr
    ldv _tbuf
    stv _ptr

    ldv _file
    jsr sys/disk/read
    stv _char



    ; terminator
    ldv _char
    lit 0
    equ
    jcn token/eof

    ; comment
    ldv _char
    lit 59
    equ
    jcn token/comment

    ; string
    ldv _char
    lit 34
    equ
    jcn token/string

    ; default
lab token/default
    ldv _file
        dup
        inc
        stv _file
    jsr sys/disk/read
    dup
    jsr is-space
    jcn token/default-done
    ldv _ptr
        dup
        inc
        stv _ptr
    sta

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
    inc ;preinc
        dup
        stv _file
    jsr sys/disk/read
    lit 10
    neq
    jcn token/comment

    jmp token ;restart

lab token/string
    ldv _file
    inc
        dup
        stv _file
    jsr sys/disk/read
    dup
    lit 34
    equ
    jcn token/string-done
    ldv _ptr
        dup
        inc
        stv _ptr 
    sta

    jmp token/string

lab token/string-done
    pop

    ;skip quote
    ldv _file
    inc
    stv _file

    jmp token/finalize 

lab token/finalize
    ; write terminator
    lit 0
    ldv _ptr
    sta

    ; succies
    lit 1
    ret



; --
; compute hash of token
var _hash
lab hash
    lit 0
    stv _hash
    lit 0
    stv _index

lab hash/loop
    ldv _tbuf
    ldv _index
        dup
        inc
        stv _index
    add
    lda

    ;check termi
    dup
    not
    jcn hash/done

    ; hash = hash * 31 + char
    ldv _hash
    lit 5
    shl
    ldv _hash
    add
    add
    stv _hash

    jmp hash/loop

lab hash/done
    pop
    ret


    





; ( path-str* -- )
lab explore
    stv _filename

    ; check file
    ldv _filename
    jsr sys/file/check
    not
    jcn file-not-exist-error

    ;open file
    ldv _filename
    jsr sys/file/seek
    jsr sys/file/open
    stv _file

lab explore/loop
    jsr token

    ldv _mnem str "brk" jsr explore/match jcn explore/zero
    ldv _mnem str "inc" jsr explore/match jcn explore/zero
    ldv _mnem str "pop" jsr explore/match jcn explore/zero
    ldv _mnem str "swp" jsr explore/match jcn explore/zero
    ldv _mnem str "dup" jsr explore/match jcn explore/zero
    ldv _mnem str "lit" jsr explore/match jcn explore/one

    ldv _mnem str "equ" jsr explore/match jcn explore/zero
    ldv _mnem str "neq" jsr explore/match jcn explore/zero
    ldv _mnem str "gth" jsr explore/match jcn explore/zero
    ldv _mnem str "lth" jsr explore/match jcn explore/zero

    ldv _mnem str "jmp" jsr explore/match jcn explore/jump
    ldv _mnem str "jcn" jsr explore/match jcn explore/jump
    ldv _mnem str "jsr" jsr explore/match jcn explore/jump
    ldv _mnem str "ret" jsr explore/match jcn explore/zero

    ldv _mnem str "ldv" jsr explore/match jcn explore/one
    ldv _mnem str "stv" jsr explore/match jcn explore/one
    ldv _mnem str "lda" jsr explore/match jcn explore/zero
    ldv _mnem str "sta" jsr explore/match jcn explore/zero

    ldv _mnem str "inp" jsr explore/match jcn explore/zero
    ldv _mnem str "out" jsr explore/match jcn explore/zero

    ldv _mnem str "add" jsr explore/match jcn explore/zero
    ldv _mnem str "sub" jsr explore/match jcn explore/zero
    ldv _mnem str "mul" jsr explore/match jcn explore/zero
    ldv _mnem str "div" jsr explore/match jcn explore/zero
    ldv _mnem str "and" jsr explore/match jcn explore/zero
    ldv _mnem str "aor" jsr explore/match jcn explore/zero
    ldv _mnem str "xor" jsr explore/match jcn explore/zero
    ldv _mnem str "shl" jsr explore/match jcn explore/zero
    ldv _mnem str "shr" jsr explore/match jcn explore/zero
    ldv _mnem str "inv" jsr explore/match jcn explore/zero
    ldv _mnem str "not" jsr explore/match jcn explore/zero

    ldv _mnem str "dbg" jsr explore/match jcn explore/zero

    ldv _mnem str "str" jsr explore/match jcn explore/str
    ldv _mnem str "lab" jsr explore/match jcn explore/lab
    ldv _mnem str "var" jsr explore/match jcn explore/var
    ldv _mnem str "use" jsr explore/match jcn explore/use

    ldv _tbuf
    lda
    lit 115 ; lowercase s (for system instruction)
    equ
    jcn explore/one

    jmp explore/loop

lab explore/zero
    ldv _addr
    inc ; instruction
    stv _addr
    jmp explore/loop
lab explore/one
    jsr token ;skip attribute token
    ldv _addr
    lit 2
    add ; instruction and attribute
    stv _addr
    jmp explore/loop
lab explore/jump
    jsr token ;skip content token
    ldv _addr
    lit 3
    add ; instruction and two-byte execution pointer 
    stv _addr
    jmp explore/loop

lab explore/str
    ldv _tbuf
    jsr string/len
    lit 2 ;+1 instruction +1 terminator
    add
    ldv _addr
    add
    stv _addr
    jmp explore/loop

lab explore/use
    ldv _file ;save file pointer into outer file
        ldv _tbuf
        jsr explore
    stv _file ;restore file pointer
    jmp explore/loop

lab explore/lab
    


    



; match mnemonic again token
lab explore/match
    ldv _mnem
    ldv _tbuf
    jsr string/cmp
    ret




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
    









