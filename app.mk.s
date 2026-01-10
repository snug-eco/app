jsr main
brk


use lib.sys.s
use lib.mem.s
use lib.string.s
use lib.args.s

var _name
var _size_int
var _size_str

lab main
    jsr args/get
    stv _name

    jsr args/get
    stv _size_str

    ; check name given
    ldv _name
    not
    jcn usage

    ; check size given
    ldv _size_str
    not
    jcn usage

    ;convert
    ldv _size_str
    jsr string/to-int
    stv _size_int


    ldv _name
    ldv _size_int
    jsr sys/file/create
    
    jsr string/from-int
    dup
    jsr string/print
    jsr string/newline
    jsr sys/heap/free

    brk


lab usage
    lit 0
    str "usage: mk filename size"
    lit 0
    jsr string/print
    jsr string/newline
    brk





