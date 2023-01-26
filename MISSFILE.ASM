                .286

                INCLUDE RECDISK.MAC


                .MODEL  SMALL
                .CODE

                EXTRN   FreeMemSegm   :WORD
                EXTRN   CmpErrFileNum :WORD

                ASSUME  ds:_TEXT

                PUBLIC  MissingFile

MissingFile     PROC    NEAR
                push    ds
                pusha
                mov     bp, ds
                mov     ax, FreeMemSegm
                mov     ds, ax
                mov     es, ax
                xor     di, di
                call    Missing
                popa
                pop     ds
                ret
MissingFile     ENDP

Missing         PROC    NEAR
                mov     cx, [di][1]
                mov     bx, [di][3]
                and     cx, cx
                jz      noFile

FindNext:       push    cx
                test    BYTE PTR [bx], 10000000B
                jnz     SkipScan

                mov     [di][3], bx
                cmp     BYTE PTR [bx], 00000001B
                jnz     IsItDir
                or      BYTE PTR [bx], 10000000B
                xor     si, si
                lea     dx, LineFeed
                push    ds
                mov     ds, bp
                IntDOS  09h
                pop     ds
PrintName:      push    si
                add     si, 5
Printing:       lodsb
                and     al, al
                jz      EndOfPrint
                mov     dl, al
                IntDOS  02h
                jmp     Printing

EndOfPrint:     pop     si
                cmp     si, bx
                jz      PrintEOM
                mov     si, [si][3]
                mov     dl, '\'
                IntDOS  02h
                jmp     PrintName

PrintEOM:       push    ds
                mov     ds, bp
                lea     dx, MissingMSG
                IntDOS  09h
                inc     CmpErrFileNum
                pop     ds
                jmp     SHORT SkipScan

IsItDir:        push    di
                push    bx
                mov     di, bx
                call    Missing
                pop     bx
                pop     di

SkipScan:       add     bx, 18
                pop     cx
                loop    FindNext
noFile:
                ret
Missing         ENDP

MissingMSG      DB      '  file not found !$'
LineFeed        Db      13, 10, '$'
                END
