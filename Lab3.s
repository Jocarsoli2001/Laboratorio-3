; Archivo: Lab 3
; Dispositivo: PIC16F887
; Autor: José Santizo 
; Compilador: pic-as (v2.32), MPLAB X v5.50
    
; Programa: Contador por medio de Timer 0
; Hardware: LEDs en el puerto A
    
; Creado: 10 de Agosto, 2021
; Última modificación: 10 de agosto de 2021

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
;Variables a utilizar
PSECT udata_bank0	    ; common memory
    CONT_SMALL: DS 1	    ; 1 byte
    CONT_BIG:	DS 1	    
    VAR:	DS 1	    ;Variable utilizada en suma de puertos
    PORT:	DS 1
    VAR2:	DS 1
    PORT1:	DS 1
    PORT2:	DS 1
    VAL_PORTC:	DS 1
    CERO:	DS 1
    
PSECT resVect, class=CODE, abs, delta=2
 ;------------vector reset-----------------
 ORG 00h		    ; posición 0000h para el reset
 resetVec:
    PAGESEL MAIN
    goto MAIN

 PSECT CODE, DELTA=2, ABS
 ORG 100H		    ;Posición para el codigo
 
 TABLA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F
    
 ;-----------Configuración----------------
 MAIN:
    CALL	CONFIG_IO
    CALL	CONFIG_RELOJ
    CALL	CONFIG_TMR0
    BANKSEL	PORTA
    BANKSEL	PORTC
    BANKSEL	PORTD
    CLRF	PORTD
    BANKSEL	PORTE
    
 LOOP:
    BTFSC	PORTB, 0
    CALL	INC_PORT    ;Llamar a la subrutina que incrementa a PORTC
    BTFSC	PORTB, 1
    CALL	DEC_PORT    ;Llamar a la subrutina que decrementa a PORTC 
    CALL	CONT_TMR0
    CALL	ESTADO_CONTSEC
    CALL	DISPLAY_TABLA
    CALL	MASCARA_CONT2
    CALL	DELAY_BIG
    GOTO	LOOP
 
 ;-----------SUBRUTINAS------------------
 CONT_TMR0:
    BTFSS	T0IF
    GOTO	$-1
    CALL	REINICIAR_TMR0
    INCF	PORT2
    MOVF	PORT2, W
    ANDLW	15
    MOVWF	PORTA
    RETURN
 
 DISPLAY_TABLA:
    MOVF	PORT, W
    CALL	TABLA
    MOVWF	PORTC
    RETURN
    
 MASCARA_CONT2:
    MOVF	PORTA, W
    MOVWF	VAR
    MOVLW	00001010B
    SUBWF	VAR,   0
    MOVWF	VAR2
    BTFSC	VAR2,  0
    INCF	PORT1
    MOVF	PORT1, 0
    ANDLW	15
    MOVWF	PORTD
    RETURN
   
 ESTADO_CONTSEC:
    MOVF	PORT, 0
    SUBWF	PORTD, 0
    MOVWF	CERO
    BTFSC	CERO, 0
    CALL	LED_IGUALDAD
    RETURN
    
 LED_IGUALDAD:
    CALL	LED_ENCENDIDA
    RETURN
   
 LED_ENCENDIDA:
    CLRF	PORT1
    BSF		PORTE, 0
    RETURN
    
 INC_PORT:
    BTFSC	PORTB, 0    ;Chequear si RB2 está presionado
    GOTO	$-1	    ;Regresar a chequear si RB2 está presionado por si no lo está
    INCF	PORT	    ;Incrementar en 1 el valor del puerto C
    RETURN
  
 DEC_PORT:
    BTFSC	PORTB, 1    ;Chequear si RB3 está presionado
    GOTO	$-1	    ;Regresar a chequear si RB3 está presionado por si no lo está
    DECF	PORT	    ;Decrementar en 1 el valor del puerto C
    RETURN   
    
 CONFIG_TMR0:
    BANKSEL	TRISA
    BCF		T0CS	    ;Reloj interno
    BCF		PSA	    ;PRESCALER
    BSF		PS2 
    BSF		PS1
    BCF		PS0	    ;Prescaler = 110
    BANKSEL	PORTA
    CALL	REINICIAR_TMR0
    RETURN
    
 REINICIAR_TMR0:
    MOVLW	232
    MOVWF	TMR0
    BCF		T0IF
    RETURN
 
 CONFIG_RELOJ:
    BANKSEL	OSCCON
    BCF		IRCF2	    ;IRCF = 010 = 250 kHz
    BCF		IRCF1
    BCF		IRCF0
    BSF		SCS	    ;Reloj interno
    RETURN
 
 CONFIG_IO:
    BANKSEL	ANSEL	    ;Selección de banco 11
    CLRF	ANSEL
    CLRF	ANSELH
    
    BANKSEL	TRISA	    ;Selección de banco 01
    CLRF	TRISA
    CLRF	TRISC	    ;Salida del display de 7 segmentos 
    
    BANKSEL	PORTA	    ;Selección de banco 00
    CLRF	TRISA
    
    BSF		TRISB,  0   ;Asignar los pines 0 Y 1 del portB
    BSF		TRISB,  1
    
    BSF		STATUS, 5   ;BANCO 01
    BCF		STATUS, 6
    CLRF	TRISD	    ;PORT D COMO SALIDA
    
    BSF		STATUS, 5   ;BANCO 01
    BCF		STATUS, 6
    CLRF	TRISE	    ;PORT E COMO SALIDA
    
    BCF		STATUS, 5   ;BANCO 00
    BCF		STATUS, 6
    CLRF	PORTA
    CLRF	PORTC
    CLRF	PORTD
    CLRF	PORTE	    ;Limpiar el puerto E
    RETURN
    
 DELAY_BIG:
    MOVLW   116		    ;Valor inicial del contador
    MOVWF   CONT_BIG+1
    CALL    DELAY_SMALL	    ;Rutina de delay
    DECFSZ  CONT_BIG+1, 1   ;Decrementar el contador
    GOTO    $-2		    ;Ejecutar 2 lineas atrás
    RETURN
    
 DELAY_SMALL:
    MOVLW   5		    ;Valor inicial del contador
    MOVWF   CONT_SMALL	    
    DECFSZ  CONT_SMALL, 1   ;Decrementar el contador
    GOTO    $-1		    ;Ejecutar linea anterior
    RETURN

    
END
    