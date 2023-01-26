		.286

		INCLUDE RECDISK.MAC

		.MODEL	SMALL
		.CODE

		EXTRN	RecordFile  :BYTE
		EXTRN	FreeMemSegm :WORD
		EXTRN	TabPointer  :WORD
		EXTRN	MakeTABLE   :NEAR
		EXTRN	TabCOMPARE  :NEAR
		EXTRN	Stream	    :WORD
		EXTRN	recBOOT     :NEAR
		EXTRN	cmpBOOT     :NEAR

		ASSUME	ds:_TEXT

		PUBLIC	RecFILE, CmpFILE

RecFILE 	PROC	NEAR

		mov	BYTE PTR RECorCMP, 1

		lea	dx, RecordFile
		mov	cx, 27h
		mov	ah, 4Eh
		int	21h
		jc	NoFileFound

		lea	dx, RecordFile
		mov	cx, 20h
		mov	ax, 4301h
		int	21h

NoFileFound:	lea	dx, RecordFile
		mov	cx, 20h
		IntDOS	3Ch
		lea	dx, CannotCREATE
		jc	ErrorOUT

		call	MakeTABLE

		mov	cx, HeaderLEN
		lea	dx, RecHEADER
		mov	Stream, ax
		mov	bx, ax
		IntDOS	40h

		lea	dx, CannotWRITE
		jc	ErrorOUT

		call	recBOOT

		jc	ErrorOUT

		lea	dx, RecFileMsg
		IntDOS	09h

		mov	cx, TabPointer
		xor	dx, dx
		push	ds
		mov	ax, FreeMemSegm
		mov	ds, ax
		IntDOS	40h
		pop	ds
		lea	dx, CannotWRITE
		jc	ErrorOUT

		IntDOS	3Eh
		lea	dx, ok_msg
		IntDOS	09h
		call	CompareNum

		lea	dx, RecordFile

		mov	cx, RecordFileATTR

		mov	ax, 4301h
		int	21h

		ret

ErrorOUT:	IntDOS	09h
		ret

RecFILE 	ENDP


CmpFILE 	PROC	NEAR

		mov	BYTE PTR RECorCMP, 0

		mov	WORD PTR CmpErrFileNum, 0
		lea	dx, RecordFile
;		mov	cx, 27h
		IntDOS	3D20h
		lea	dx, CannotOPEN
		jnc	CompareOK
		jmp	ErrorCMP2
CompareOK:	mov	Stream, ax
		mov	bx, ax
		mov	ax, FreeMemSegm

		push	ds
		mov	cx, ExtHeadLEN
		mov	ds, ax
		xor	dx, dx
		IntDOS	3Fh
		lea	dx, CannotREAD
		mov	ax, ds:[ExeFileOff]
		mov	cx, ds
		pop	ds
		jc	ErrorCMP

		push	es
		push	cx
		mov	es, cx
		xor	di, di
		mov	si, OFFSET RecHEADER
		lea	dx, NotMatchMSG
		mov	cx, ExeFileOff - AddDataSize
		repz	cmpsb
		jnz	MatchErr
		push	ds
		push	es
		push	si
		push	di

		push	es
		push	ds
		pop	es
		pop	ds
		xchg	si, di
		mov	cx, AddDataSize
		rep	movsb
;
		mov	si, RecBootOff
		mov	di, OFFSET RecordBOOT
		movsb
;
		pop	di
		pop	si
		pop	es
		pop	ds
MatchErr:	pop	cx
		pop	es
		jnz	ErrorCMP2

		call	cmpBOOT
		jc	ErrorCMP

		push	cx
		push	ax
		lea	dx, CmpFileMsg
		IntDOS	09h
		pop	ax
		pop	dx

		push	ds
		mov	ds, dx
		push	ax

		mov	cx, 0FFFFh
		xor	dx, dx
		IntDOS	3Fh
		pop	dx
		pop	ds
		mov	ExecuteFile, dx
		lea	dx, CannotREAD
		jc	ErrorCMP
		mov	TabPointer, ax

		IntDOS	3Eh

		call	TabCOMPARE

		lea	dx, CmpError
		jc	ErrorCMP
		lea	dx, ok_msg

ErrorCMP:	IntDOS	09h
		call	CompareNum
		ret

ErrorCMP2:	IntDOS	09h
		ret

CmpFILE 	ENDP

CompareNum	PROC	NEAR
		pusha

		lea	dx, ComFileNum
		cmp	BYTE PTR RECorCMP, 0
		jz	PrtCmNmsg
		lea	dx, RecFileNum
PrtCmNmsg:	IntDOS	09h

		lea	si, Digital
		mov	ax, ExecuteFile
		mov	bx, 10
Div_10: 	xor	dx, dx
		div	bx
		add	dl, '0'
		dec	si
		mov	[si], dl
		and	ax, ax
		jnz	Div_10

		mov	dx, si
		IntDOS	09h

		popa
		ret
CompareNum	ENDP

		PUBLIC	ExecuteFile, CmpErrFileNum, RecordALL, RecordBOOT

RecHEADER	DB	'RECDisk ', VERSION, 1Ah
RecordALL	DB	0
AddDataSize	EQU	$ - RecordALL
ExeFileOff	EQU	$ - RecHEADER
ExecuteFile	DW	?
HeaderLEN	EQU	$ - RecHEADER

RecBootOff	EQU	$ - RecHEADER
RecordBOOT	DB	0

ExtHeadLEN	EQU	$ - RecHEADER

CannotOPEN	DB	'The RECDisk data file not found !!', 13, 10, '$'
CannotREAD	DB	'Reading error !!', 13, 10, '$'
CannotCREATE	DB	'Cannot create RECDisk data file', 13, 10, '$'
CannotWRITE	DB	'Writting error !!', 13, 10, '$'
ComFileNum	DB	13, 10, 'Total comparing System and Excutable files : $'
RecFileNum	DB	13, 10, 'Total System and Excutable files recorded : $'
RECorCMP	DB	6 DUP (0)
Digital 	DB	'.', 13, 10, '$'
RecFileMsg	DB	'Recording System and Excutable files ... $'
CmpFileMsg	DB	'Comparing System and Excutable files ... $'
ok_msg		DB	'ok.'
CmpError	DB	13, 10, '$'
CmpErrFileNum	DW	?
NotMatchMSG	DB	'The format of RECDisk data file mismatch !!', 13, 10, '$'
		END
