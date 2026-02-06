jsr main
brk

use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s
use lib.line.s


var _filename
var _buildname
var _file
var _build
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

; table[index * 2]
var _tabl_lab_index
var _tabl_var_index

lab main
    ; read file name argument
    jsr args/get
    stv _filename

    jsr args/get
    stv _buildname

    ; check present
    ldv _filename
    not
    jcn no-file-error
    ldv _buildname
    not
    jcn no-build-error

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

    lit 0
    stv _tabl_lab_index
    lit 0
    stv _tabl_var_index

    ldv _filename
    dup
        jsr explore

    ; delete build file if exists
    ldv _buildname
    jsr sys/file/check
    not
    jcn skip-delete-build
        ldv _buildname
        jsr sys/file/seek
        jsr sys/file/delete
    lab skip-delete-build

    ; generate new
    ldv _buildname
    ldv _addr
    jsr sys/file/create
    jsr sys/file/open
    stv _build

    jsr assemble

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
    not
    jcn explore/done

    ldv _tbuf
    jsr string/print
    jsr string/newline

    ldv _mnem str "brk" jsr match jcn explore/zero
    ldv _mnem str "inc" jsr match jcn explore/zero
    ldv _mnem str "pop" jsr match jcn explore/zero
    ldv _mnem str "swp" jsr match jcn explore/zero
    ldv _mnem str "dup" jsr match jcn explore/zero
    ldv _mnem str "lit" jsr match jcn explore/one

    ldv _mnem str "equ" jsr match jcn explore/zero
    ldv _mnem str "neq" jsr match jcn explore/zero
    ldv _mnem str "gth" jsr match jcn explore/zero
    ldv _mnem str "lth" jsr match jcn explore/zero

    ldv _mnem str "jmp" jsr match jcn explore/jump
    ldv _mnem str "jcn" jsr match jcn explore/jump
    ldv _mnem str "jsr" jsr match jcn explore/jump
    ldv _mnem str "ret" jsr match jcn explore/zero

    ldv _mnem str "ldv" jsr match jcn explore/one
    ldv _mnem str "stv" jsr match jcn explore/one
    ldv _mnem str "lda" jsr match jcn explore/zero
    ldv _mnem str "sta" jsr match jcn explore/zero

    ldv _mnem str "inp" jsr match jcn explore/zero
    ldv _mnem str "out" jsr match jcn explore/zero

    ldv _mnem str "add" jsr match jcn explore/zero
    ldv _mnem str "sub" jsr match jcn explore/zero
    ldv _mnem str "mul" jsr match jcn explore/zero
    ldv _mnem str "div" jsr match jcn explore/zero
    ldv _mnem str "and" jsr match jcn explore/zero
    ldv _mnem str "aor" jsr match jcn explore/zero
    ldv _mnem str "xor" jsr match jcn explore/zero
    ldv _mnem str "shl" jsr match jcn explore/zero
    ldv _mnem str "shr" jsr match jcn explore/zero
    ldv _mnem str "inv" jsr match jcn explore/zero
    ldv _mnem str "not" jsr match jcn explore/zero

    ldv _mnem str "dbg" jsr match jcn explore/zero

    ldv _mnem str "str" jsr match jcn explore/str
    ldv _mnem str "lab" jsr match jcn explore/lab
    ldv _mnem str "var" jsr match jcn explore/var
    ldv _mnem str "use" jsr match jcn explore/use

    ldv _tbuf
    lda
    lit 115 ; lowercase s (for system instruction)
    equ
    jcn explore/zero

    jmp explore/loop

lab explore/zero
    ldv _addr
    inc ; instruction
    stv _addr
    jmp explore/loop
lab explore/one
    jsr token pop ;skip attribute token
    ldv _addr
    lit 2
    add ; instruction and attribute
    stv _addr
    jmp explore/loop
lab explore/jump
    jsr token pop ;skip content token
    ldv _addr
    lit 3
    add ; instruction and two-byte execution pointer 
    stv _addr
    jmp explore/loop

lab explore/str
    jsr token pop ; skip iden
    ldv _tbuf
    jsr string/len
    lit 2 ;+1 instruction +1 terminator
    add
    ldv _addr
    add
    stv _addr
    jmp explore/loop

lab explore/use
    jsr token pop ; skip iden
    ldv _file ;save file pointer into outer file
    dup dbg
        ldv _tbuf
        jsr explore
    dup dbg
    stv _file ;restore file pointer
    jmp explore/loop

lab explore/lab
    jsr token pop ; skip iden
    ;compute identifier hash
    jsr hash
    
    ; p+0 <- hash
    ldv _hash
        ldv _tabl_lab_index
            dup
            inc
            stv _tabl_lab_index
        ldv _tabl_lab
        add
    sta

    ; p+1 <- address
    ldv _addr
        ldv _tabl_lab_index
            dup
            inc
            stv _tabl_lab_index
        ldv _tabl_lab
        add
    sta

    ldv _hash
    dbg
    ldv _tbuf
    jsr string/print
    jsr string/newline


    jmp explore/loop

lab explore/var
    jsr token pop ; skip iden
    ;compute identifier hash
    jsr hash
    
    ; p+0 <- hash
    ldv _hash
        ldv _tabl_var_index
            dup
            inc
            stv _tabl_var_index
        ldv _tabl_var
        add
    sta

    ; p+1 <- address
    ldv _tabl_var_index
        ldv _tabl_var_index
            dup
            inc
            stv _tabl_var_index
        ldv _tabl_var
        add
    sta

    jmp explore/loop

lab explore/done 
    ret



; match mnemonic again token
lab match
    ldv _mnem
    ldv _tbuf
    jsr string/cmp
    ret


; (_hash) -- addr
lab lookup-label
    lit 0
    stv _index

    lit 0 ;stack magic :3
lab lookup-label/loop
    pop
    ldv _index
        dup
        inc
        inc
        stv _index
    ldv _tabl_lab
    add

    ; check hash
    dup
        lda
        ldv _hash
        neq
        jcn lookup-label/loop

    ;found
    inc ;address ^= _p + 1
    lda
    ret

; (_hash) -- var
lab lookup-var
    lit 0
    stv _index

    lit 0 ;stack magic :3
lab lookup-var/loop
    pop
    ldv _index
        dup
        inc
        inc
        stv _index
    ldv _tabl_var
    add

    ; check hash
    dup
        lda
        ldv _hash
        neq
        jcn lookup-var/loop

    ;found
    inc ;address ^= _p + 1
    lda
    ret


; byte --
lab fput
    ldv _build
        dup
        inc
        stv _build
    swp
    jsr sys/disk/write
    ret

lab fjump
    jsr token
    jsr hash
    jsr lookup-label
    dup 
        jsr fput ;low byte
    lit 8
    shr
        jsr fput ;high byte
    ret

; ( path-str* -- )
lab assemble

    ;open file (file already checked during exploration)
    jsr sys/file/seek
    jsr sys/file/open
    stv _file

lab assemble/loop
    jsr token
    not
    jcn assemble/done

    ldv _tbuf
    jsr string/print
    jsr string/newline

    ldv _mnem str "brk" jsr match jcn assemble/brk
    ldv _mnem str "inc" jsr match jcn assemble/inc
    ldv _mnem str "pop" jsr match jcn assemble/pop
    ldv _mnem str "swp" jsr match jcn assemble/swp
    ldv _mnem str "dup" jsr match jcn assemble/dup
    ldv _mnem str "lit" jsr match jcn assemble/lit

    ldv _mnem str "equ" jsr match jcn assemble/equ
    ldv _mnem str "neq" jsr match jcn assemble/neq
    ldv _mnem str "gth" jsr match jcn assemble/gth
    ldv _mnem str "lth" jsr match jcn assemble/lth

    ldv _mnem str "jmp" jsr match jcn assemble/jmp
    ldv _mnem str "jcn" jsr match jcn assemble/jcn
    ldv _mnem str "jsr" jsr match jcn assemble/jsr
    ldv _mnem str "ret" jsr match jcn assemble/ret

    ldv _mnem str "ldv" jsr match jcn assemble/ldv
    ldv _mnem str "stv" jsr match jcn assemble/stv
    ldv _mnem str "lda" jsr match jcn assemble/lda
    ldv _mnem str "sta" jsr match jcn assemble/sta

    ldv _mnem str "inp" jsr match jcn assemble/inp
    ldv _mnem str "out" jsr match jcn assemble/out

    ldv _mnem str "add" jsr match jcn assemble/add
    ldv _mnem str "sub" jsr match jcn assemble/sub
    ldv _mnem str "mul" jsr match jcn assemble/mul
    ldv _mnem str "div" jsr match jcn assemble/div
    ldv _mnem str "and" jsr match jcn assemble/and
    ldv _mnem str "aor" jsr match jcn assemble/aor
    ldv _mnem str "xor" jsr match jcn assemble/xor
    ldv _mnem str "shl" jsr match jcn assemble/shl
    ldv _mnem str "shr" jsr match jcn assemble/shr
    ldv _mnem str "inv" jsr match jcn assemble/inv
    ldv _mnem str "not" jsr match jcn assemble/not

    ldv _mnem str "dbg" jsr match jcn assemble/dbg

    ldv _mnem str "str" jsr match jcn assemble/str
    ldv _mnem str "lab" jsr match jcn assemble/lab
    ldv _mnem str "var" jsr match jcn assemble/var
    ldv _mnem str "use" jsr match jcn assemble/use

    ldv _tbuf
    lda
    lit 115 ; lowercase s (for system instruction)
    equ
    jcn assemble/system

    jmp assemble/loop
    

lab assemble/brk lit 0 jsr fput jmp assemble/loop    
lab assemble/inc lit 1 jsr fput jmp assemble/loop    
lab assemble/pop lit 2 jsr fput jmp assemble/loop    
lab assemble/swp lit 3 jsr fput jmp assemble/loop    
lab assemble/dup lit 4 jsr fput jmp assemble/loop    
lab assemble/lit 
    lit 5 jsr fput 

    jsr token
    ldv _tbuf
    jsr string/to-int
    jsr fput
    jmp assemble/loop    


lab assemble/equ lit 6 jsr fput jmp assemble/loop    
lab assemble/neq lit 7 jsr fput jmp assemble/loop    
lab assemble/gth lit 8 jsr fput jmp assemble/loop    
lab assemble/lth lit 9 jsr fput jmp assemble/loop    

lab assemble/jmp lit 10 jsr fput jsr fjump jmp assemble/loop
lab assemble/jcn lit 11 jsr fput jsr fjump jmp assemble/loop
lab assemble/jsr lit 12 jsr fput jsr fjump jmp assemble/loop
lab assemble/ret lit 13 jsr fput jmp assemble/loop
 
lab assemble/ldv lit 14 jsr fput  jsr token jsr hash jsr lookup-var jsr fput jmp assemble/loop
lab assemble/stv lit 15 jsr fput  jsr token jsr hash jsr lookup-var jsr fput jmp assemble/loop

lab assemble/lda lit 16 jsr fput jmp assemble/loop
lab assemble/sta lit 17 jsr fput jmp assemble/loop

lab assemble/inp lit 18 jsr fput jmp assemble/loop
lab assemble/out lit 19 jsr fput jmp assemble/loop

lab assemble/add lit 20 jsr fput jmp assemble/loop
lab assemble/sub lit 21 jsr fput jmp assemble/loop
lab assemble/mul lit 22 jsr fput jmp assemble/loop
lab assemble/div lit 23 jsr fput jmp assemble/loop

lab assemble/and lit 24 jsr fput jmp assemble/loop
lab assemble/aor lit 25 jsr fput jmp assemble/loop
lab assemble/xor lit 26 jsr fput jmp assemble/loop
lab assemble/shl lit 27 jsr fput jmp assemble/loop
lab assemble/shr lit 28 jsr fput jmp assemble/loop
lab assemble/inv lit 29 jsr fput jmp assemble/loop
lab assemble/not lit 30 jsr fput jmp assemble/loop

lab assemble/str
    lit 31 jsr fput
    jsr token
    ldv _tbuf
    stv _index

lab assemble/str/loop
    ldv _index
        dup
        inc
        stv _index
    lda

    dup
        jsr fput

    jcn assemble/str/loop
    jmp assemble/loop

lab assemble/dbg
    lit 32
    jsr fput
    jmp assemble/loop

lab assemble/lab jsr token jmp assemble/loop
lab assemble/var jsr token jmp assemble/loop

lab assemble/system
        ldv _tbuf
        inc
        lda
        lit 48
        sub
    lit 10
    mul
        ldv _tbuf
        inc
        inc
        lda
        lit 48
        sub
    add
    lit 128
    aor
    jsr fput
    jmp assemble/loop

lab assemble/use
    jsr token pop ; skip iden
    ldv _file ;save file pointer into outer file
        ldv _tbuf
        jsr assemble
    stv _file ;restore file pointer
    jmp assemble/loop

lab assemble/done 
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
    
lab no-build-error
    lit _tbuf
    str "assembler error: no build name provided"
    lit _tbuf
    jsr string/print
    jsr string/newline
    brk









