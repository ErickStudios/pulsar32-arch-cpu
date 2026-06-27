org32

vectors: Dword start        ; vector de arranque

start:
    dbgAc64                 ; configurar el 64 (skip solo para debug)
    org64                   ; decirle al asm que esta en Pulsar64
    
    slcinm       00h        ; seleccionar el inm a editar
    rstinm                  ; resetear el inm que se esta editando
    ld64        STACK_TOP   ; cargar direccion del stack
    linm        sp, 00h     ; cargar el inm que se edito

    rstinm                  ; resetear el inm que se esta editando
    ld16        0DEADh      ; valor a cargar
    linm        r0, 00h     ; cargar

    slcinm       01h        ; seleccionar el inm a editar
    rstinm                  ; resetear el inm que se esta editando
    ld16        00A0h      ; valor a cargar

    sub         sp, sp, 8   ; restar
    mwr64       sp, r0      ; poner en el stack
    
    ifm64       02h, sp     ; obtener del el puntero al stack
    add         sp, sp, 8   ; añadir

    linm        r0, 02h     ; obtener inmediato

Align           128
STACK_TOP: