.INCLUDE	"2313def.inc"

.DEF	Step=r20
.DEF	FreqIndex=r21
.DEF	FreqDelay=r22
.DEF	SSREG=r23

.CSEG

.ORG	0
	rjmp	Reset

.ORG	OVF0addr
	in	SSREG,SREG
	dec	FreqDelay
	out	SREG,SSREG
	reti

Reset:
	ldi	r30,$DF
        out	SPL,r30
	; настройка направлени€ работы линий порта B
	ldi	r30,$08
	out	DDRB,r30
	; режим работы таймера 0 с максимальным предварительным делением
	; здесь же разрешаем прерывани€
	ldi	r30,$05
	out	TCCR0,r30
	ldi	r30,$02
	out	TIMSK,r30
	sei
	; режим работы таймера 1 на переключение внешнего вывода,
	; выбор коэффициента предварительного делени€ тактовой частоты 1:1
	; и автоматический сброс таймера при совпадении
        ldi	r30,$40
        out	TCCR1A,r30
        ldi	r30,$09
        out	TCCR1B,r30
	; установка номера шага на начало
	clr	Step



ReadNote:	; чтение длительности и номера одной ноты
	ldi	r31,High(2*ProgramTab)	; FreqIndex = Lo ProgramTab[Step]
	ldi	r30,Low(2*ProgramTab)	; FreqDelay = Hi ProgramTab[Step]
	mov	r0,Step                 ; Step++
	lsl	r0
	add	r30,r0
	inc	Step
	lpm
	mov	FreqIndex,r0
	inc	r30
	lpm
	sbrc	r0,7
	rjmp	SleepReset		; если старший бит установлен, то
	mov	FreqDelay,r0            ; это означает что мелоди€ закончилась

		
SetFreq:        ; настройка таймера 1 на вывод частоты текущей ноты
	ldi	r31,High(2*SoundTab)	; OCR1A = SoundTab[FreqIndex]
	ldi	r30,Low(2*SoundTab)
	lsl	FreqIndex
        add	r30,FreqIndex
        lpm

;      out	OCR1AL,r0	; «акоментареный блок заменен блоком ниже
;      inc	r30		; ошибку нашел и исправил
;      lpm			; —ергей –оманец. ¬ильнюс, Ћитва.
;      out	OCR1AH,r0

       mov	r16,r0
       inc	r30
       lpm
       out	OCR1AH,r0
       out	OCR1AL,r16



Wait:	tst	FreqDelay	; ќжидаем заданное врем€ пока проигрываетс€
	brne	Wait		; текуща€ нота
	rjmp	ReadNote

SleepReset:
        ldi	r30,$3F		; подготовка к переходу в режим Power Down
        out	MCUCR,r30
	sleep			; отключение микроконтроллера
	rjmp	Reset		; эта команда в данной версии программы не 
				; должна исполн€тс€ никогда

.ORG	$100
SoundTab:
; “аблица констант соответствующим нотам.
; ∆елательно выровн€ть таблицу по границе 256 байт, чтобы упростить программу
; отказавшись от операций с 16 битными словами.
.DW 11364,10292,9322,8443,7647,6926,6273    ; 440 √ц - нота "л€"
.DW 5682,5146,4661,4222,3824,3463,3137      ; втора€ октава
.DW 2841,2573,2330,2111,1912,1732,1568      ; треть€ октава
; при необходимости таблицу можно продолжить.


ProgramTab:
; “аблица последовательности нот,
; формат таблицы: байт длительности/кода операции, байт номера частоты.
; ¬ этом примере записано проигрывание гаммы.
.DW	$1001, $1002, $1003, $1004, $1005, $1006, $1007
.DW	$1008, $1009, $100A, $100B, $100C, $100D, $100E
.DW	$200D, $200B, $2009, $2007, $2005, $2003, $2001
.DW	$8000


.EXIT

