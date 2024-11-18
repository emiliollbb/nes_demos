; Ejemplo de paletas NES
; ----------------------
; Compilar con xa -C ejemplo.s -o ejemplo.nes

; Tabla colores NES
; https://famicom.party/_app/immutable/assets/NES_color_palette_with_numbers.pvUMp0SZ.webp
AZUL           = $01
VIOLETA        = $14
VIOLETA_CLARO  = $24
NARANJA        = $27
ROSA           = $25 
VERDE          = $2a
CELESTE        = $2c
ROJO           = $16
NEGRO          = $0F
CELESTE_CLARO  = $3c
AMARILLO       = $38

; Registros PPU
PPUCTRL     = $2000
PPUMASK     = $2001
PPUSTATUS   = $2002
PPUADDR     = $2006
PPUDATA     = $2007
PPUPALETTES = $3F00


; Cabecera emuladores
*=$0000
.byte $4e, $45, $53, $1a, $02, $01, $00, $00


; Direccion de memoria de inicio de la ROM
*=$8000

main:
.(
  ; Especificamos a la PPU a que direccion de memoria vamos a enviar datos
  ; En primer lugar leemos PPUSTATUS, y a continuacion enviamos la primera 
  ; direccion de la PPU en la que queremos escribir, primero el byte mas 
  ; significativo, seguido del byte menos significativo
  LDX PPUSTATUS  
  LDX #>PPUPALETTES
  STX PPUADDR
  LDX #<PPUPALETTES
  STX PPUADDR
  
  ; En NES tenemos 8 paletas de cuatro colores cada una. Primero van 
  ; las 4 de BACKGROUND, seguidas de las 4 de SPRITES
  ; Enviamos los 4 colores de la primera paleta de fondo
  LDA #CELESTE_CLARO
  STA PPUDATA
  LDA #NEGRO
  STA PPUDATA
  LDA #ROJO
  STA PPUDATA
  LDA #AZUL
  STA PPUDATA
  
  ; Enviamos la segunda paleta de fondo. El primer color debe ser el mismo 
  ; en las 8 paletas. Sera usado como color de trnasparencia en los sprites
  LDA #CELESTE_CLARO
  STA PPUDATA
  LDA #NARANJA
  STA PPUDATA
  LDA #ROSA
  STA PPUDATA
  LDA #VERDE
  STA PPUDATA
  
  ; Enviamos la tercera paleta de fondo. Mantenemos el primer color.
  ; No es necesario informar todas las paletas si no las vamos a usar, pero en
  ; este ejemplo vamos a enviarlas todas y comprobar en el emulador que 
  ; se hayan actualizado
  LDA #CELESTE_CLARO
  STA PPUDATA
  LDA #ROJO
  STA PPUDATA
  LDA #VERDE
  STA PPUDATA
  LDA #AMARILLO
  STA PPUDATA
  
  ; Enviamos la ultima paleta de los fondos
  LDA #CELESTE_CLARO
  STA PPUDATA
  LDA #ROJO
  STA PPUDATA
  LDA #VERDE
  STA PPUDATA
  LDA #AMARILLO
  STA PPUDATA
  
  ; Ahora vamos a enviar las cuatro paletas de sprites, en este 
  ; caso vamos a usar un bucle, y vamos a enviar las cuatro iguales
  LDY #4
  bucle:
	  LDA #CELESTE_CLARO
	  STA PPUDATA
	  LDA #ROJO
	  STA PPUDATA
	  LDA #VERDE
	  STA PPUDATA
	  LDA #AMARILLO
	  STA PPUDATA
	  DEY
  BNE bucle
  
  
; Activar PPU
  LDA #$1e
  LDA #%00011110
  STA PPUMASK
forever:
  JMP forever
.asc "MAIN"
.)

; Rutina de arranque de la NES. Esta rutina la mantendremos siempre igual
init:
.(
  ; Inicializar CPU
  SEI
  CLD
  LDX #$FF
  TXS
  ; Inicializar APU
  LDX #$40
  STX $4017
  ; Inicializar PPU
  LDX #$0
  STX PPUCTRL
  STX PPUMASK
  STX $4010
  ; Esperar a que la PPU este lista
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait
vblankwait2:
  BIT $2002
  BPL vblankwait2
  ; Ir al codigo principal
  JMP main
.)

; Rutinas de interrupciones. Sin uso en este ejemplo
irq_handler:
  RTI
nmi_handler:
  RTI

; Vectores 6502. Indican la direccion de inicio del programa.
; Siempre lo vamos a dejar igual
.dsb $fffa-*, $ff
.word nmi_handler
.word init
.word irq_handler

; CHR ROM
; Espacio para guardar las losetas (tiles). Sin uso en este ejemplo
*=$0000
.dsb $2000-*, $00

