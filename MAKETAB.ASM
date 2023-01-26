                .286

                INCLUDE RECDISK.MAC


                .MODEL  SMALL
                .CODE

                EXTRN   WorkingDRV  :BYTE
                EXTRN   FreeMemSegm :WORD
                EXTRN   ExecuteFile :WORD
                EXTRN   GarbageColl :NEAR
                EXTRN   MissingFile :NEAR

                EXTRN   TabPointer     :WORD
                EXTRN   DataTransArea  :DWORD
                EXTRN   ExeComSysBin   :BYTE
                EXTRN   WildName       :BYTE
                EXTRN   WildNameLen    :ABS
                EXTRN   SpecialMark    :BYTE
                EXTRN   RecordALL      :BYTE
                EXTRN   FileNameLEN    :ABS
                EXTRN   RecordFileA    :BYTE

                ASSUME  ds:_TEXT

                PUBLIC  MakeTABLE

MakeTABLE       PROC    NEAR
                pusha

                push    es
                IntDOS  2Fh     ; Get DTA (ES:BX)
                mov     WORD PTR DataTransArea, bx
                mov     WORD PTR DataTransArea[2], es

                mov     es, FreeMemSegm
                xor     di, di
                mov     bx, di
                mov     ExecuteFile, di
                mov     cx, 18
                lea     si, SpecialMark
                rep     movsb
                mov     TabPointer, di
                pop     es

                mov     al, WorkingDRV
                mov     ah, ':'
                sub     sp, 08
                mov     bp, sp
                mov     [bp], ax
                mov     WORD PTR [bp][2], '\' + '*' * 100h
                mov     WORD PTR [bp][4], '.' + '*' * 100h
                mov     WORD PTR [bp][6], bx
                mov     ax, 0308h
                push    ax
                push    bx
                call    BuildFileTable
                add     sp, 12

                call    GarbageColl

                popa
                ret
MakeTABLE       ENDP


BuildFileTable  PROC    NEAR

ParentPointer   EQU     <WORD PTR [bp+4]>
DirLen          EQU     <WORD PTR [bp+6]>
DirPointer      EQU     8
                push    bp
                mov     bp, sp
CurLevelPtr     EQU     <WORD PTR [bp-2]>
CurLevelDir     EQU     <WORD PTR [bp-4]>
Counter         EQU     <WORD PTR [bp-6]>
                sub     sp, 6

                xor     ax, ax
                mov     Counter, ax
                mov     CurLevelDir, ax

                lea     dx, [bp][DirPointer]
                mov     cx, 27h
                push    ds
                mov     ax, ss
                mov     ds, ax
                IntDOS  4Eh
                pop     ds
NextFile:       jnc     FileManag
                jmp     NoFile

FileManag:      les     di, DataTransArea

                cmp     BYTE PTR RecordALL, 0
                jnz     FoundALL

                add     di, 30
                mov     dx, di
                mov     cx, 13
                mov     al, 0
        repnz   scasb
                sub     cx, 13
                neg     cx
                lea     si, ExeComSysBin
                mov     di, dx
                mov     al, '.'
        repnz   scasb
                jnz     NotFound
                mov     dx, di

FindNext:       mov     cx,4
        repz    cmpsb
                jz      Found
                add     si, cx
                mov     di, dx
                cmp     BYTE PTR [si], 0
                jnz     FindNext

NotFound:       IntDOS  4Fh
                jmp     NextFile

FoundALL:       mov     si, OFFSET RecordFileA
                add     di, 30
                mov     cx, FileNameLEN
        repz    cmpsb
                jz      NotFound

Found:          push    es

                mov     di, WORD PTR DataTransArea
                add     di, 30
                mov     al, 0
                mov     cx, 13
        repnz   scasb
        rep     stosb

                mov     di, TabPointer
                mov     ax, es
                mov     es, FreeMemSegm
                push    ds
                mov     ds, ax
                mov     si, 26
                add     si, WORD PTR DataTransArea
                mov     cx, 13 + 4
                mov     al, 00000001B
                stosb
        rep     movsb
                pop     ds
                mov     TabPointer, di
                pop     es
                inc     ExecuteFile
                inc     Counter
                jmp     NotFound

NoFile:         mov     ax, TabPointer
                mov     CurLevelPtr, ax
                lea     dx, [bp][DirPointer]
                mov     cx, 37h
                push    ds
                mov     ax, ss
                mov     ds, ax
                IntDOS  4Eh
                pop     ds
NextDir:        jc      NoDirectory

                les     di, DataTransArea

                mov     al, es:[di][21]
                and     al, 10h
                jnz     FounDir
NotFounDir:     IntDOS  4Fh
                jmp     NextDir

FounDir:        cmp     BYTE PTR es:[di][30], '.'
                jz      NotFounDir

                add     di, 30
                mov     al, 0
                mov     cx, 13
        repnz   scasb
        rep     stosb

                push    es
                mov     dx, FreeMemSegm
                mov     di, TabPointer
                mov     ax, es
                push    ds
                mov     ds, ax
                mov     es, dx
                mov     si, 30
                add     si, WORD PTR DataTransArea
                mov     bx, di
                mov     cx, 13
                mov     al, 00000010B
                stosb
                add     di, 4
        rep     movsb
                pop     ds
                mov     TabPointer, di
                pop     es
                inc     CurLevelDir
                inc     Counter
                jmp     NotFounDir

NoDirectory:    mov     es, FreeMemSegm
                mov     di, ParentPointer
                mov     ax, Counter
                mov     es:[di][1], ax
                cmp     CurLevelDir, 0
                jnz     Recursive
                jmp     EndRecFile

Recursive:      mov     es, FreeMemSegm
                mov     di, CurLevelPtr
                mov     ax, TabPointer
                mov     es:[di][3], ax
                add     di, 5
                mov     al, 0
                mov     cx, -1
        repnz   scasb
                not     cx
                dec     cx
                mov     dx, cx
                mov     bx, DirLen
                add     cl, bh
                mov     ax, cx
                inc     ax
                add     cl, 5
                shr     cx, 1
                adc     cl, 0
                shl     cx, 1
                sub     sp, cx
                mov     di, sp
                mov     ch, al
                push    cx
                mov     ax, CurLevelPtr
                push    ax
                add     ax, 18
                mov     CurLevelPtr, ax

                push    es
                mov     ax, ss
                mov     es, ax
                mov     cx, bx
                shr     cx, 8
                mov     si, DirPointer
StoreHIS:       mov     al, [bp][si]
                inc     si
                stosb
                loop    StoreHIS
                pop     ax
                push    ax
                mov     si, CurLevelPtr
                add     si, (5 - 18)
                push    ds
                mov     ds, ax
                mov     cx, dx
        rep     movsb
                pop     ds
                mov     cx, WildNameLen
                lea     si, WildName
        rep     movsb
                pop     es

                call    BuildFileTable

                lahf

                pop     bx
                pop     bx
                xor     bh, bh
                add     sp, bx

                sahf
                jnc     DirOK

                dec     Counter
                mov     es, FreeMemSegm
                mov     di, CurLevelPtr
                mov     BYTE PTR es:[di][-18], -1

DirOK:          dec     CurLevelDir
                jz      EndRecFile
                jmp     Recursive

EndRecFile:     cmp     Counter, 1
                mov     sp, bp
                pop     bp
                ret
BuildFileTable  ENDP
                END
