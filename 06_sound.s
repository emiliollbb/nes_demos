gamepad1 = $01
gamepad2 = $02

; === EMULATORS HEADER (16 byte) (https://www.nesdev.org/wiki/INES) ===
*=$0000
.asc "NES"
.byt $1a                      ; Magic string that always begins an iNES header
.byt $02                      ; Number of 16KB PRG-ROM banks
.byt $01                      ; Number of 8KB CHR-ROM banks
.byt %00000001                ; Vertical mirroring (Screens left, right), no save RAM, no mapper
.byt %00000000                ; No special-case flags set, no mapper
.byt $00                      ; No PRG-RAM present
.byt $00                      ; NTSC format
.byt $00,$00,$00,$00,$00,$00  ; Unused padding


; === 32K PRG ROM (https://www.nesdev.org/wiki/NROM) ===
*=$8000

_main:
.(
  ; Reset latch PPUADDR
  LDX $2002
  ; Set PPU high address $3F00 to store next value
  LDX #$3F
  STX $2006
  ; Set PPU low address $3F00 to store next value
  LDX #$00
  STX $2006
  
  ; Send paleta
  paleta: 
  .byt $21,$03,$14,$28, $21,$21,$21,$21, $21,$21,$21,$21 ,$21,$21,$21,$21,
  .byt $21,$16,$28,$0f, $21,$21,$21,$21, $21,$21,$21,$21 ,$21,$21,$21,$21,
  LDX #0
  loop_paletas
    LDA paleta,X
    STA $2007
    INX
    CPX #32
  BNE loop_paletas

  ; wait for vblank
  vblankwait:       
  BIT $2002
  BPL vblankwait
  
; Configurar PPUCTRL
;  0 1 Base nametable address (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
;  2   VRAM address increment per CPU read/write of PPUDATA (0= add 1, going across; 1= add 32, going down)
;  3   Sprite pattern table address for 8x8 sprites (0= $0000; 1= $1000; ignored in 8x16 mode)
;  4   Background pattern table address (0= $0000; 1= $1000)
;  5   Sprite size (0= 8x8 pixels; 1= 8x16 pixels – see PPU OAM#Byte 1)
;  6   PPU master/slave select (0= read backdrop from EXT pins; 1= output color on EXT pins)
;  7   Vblank NMI enable (0= off, 1= on)
  LDA #%10001000
  STA $2005
  
; Configurar PPUMASK
;  0  Greyscale mode enable (0 normal color, 1 greyscale)
;  1  Left edge (8px) background enable (0 hide, 1 show)
;  2  Left edge (8px) foreground enable (0 hide, 1 show)
;  3  Background enable
;  4  Foreground enable
;  5  Emphasize red
;  6  Emphasize green
;  7  Emphasize blue
  LDA #%00011110
  STA $2001
  
  ; Enable square channel 1
  LDA #%00000001
  STA $4015
  
  LDA #%10111111 ; Duty 50% Volume F
  STA $4000
  
  ; 0C9 do#
  LDA #$C9
  STA $4002
  LDA #0
  STA $4003
  
forever:
  JMP forever
.)
; -- end main method --

_update:
.(
  RTS
.)

_reset_handler:
.(
  ; Disable interrupts
  SEI
  ; Disable decimal mode
  CLD
  ; Disable audio IRQs
  LDX #$40
  STX $4017
  ; Initialize stack
  LDX #$FF
  TXS
  ; Disable NMI frame trigger bit 7 controls whether or not the PPU will trigger an NMI every frame
  LDX #$0
  STX $2000
  ; Disable graphics
  STX $2001
  ; Turn off DMC IRQs
  STX $4010
  ; Wait for the PPU to fully boot up
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait
vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP _main
.)

_irq_handler:
  RTI

_nmi_handler:
.(
  PHA

  ; Copy OAM cache
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014

  ; Latch controllers
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016  
  ; Read controller 1
  LDA #%00000001
  STA gamepad1
  loop:
  LDA $4016
  LSR
  ROL gamepad1
  BCC loop  
  ; Read controller 2
  LDA #%00000001
  STA gamepad2
  loop2:
  LDA $4017
  LSR
  ROL gamepad2
  BCC loop2
  
  jsr _update

  PLA
  RTI
.)

; === VECTORS ===
.dsb $fffa-*, $ff
.word _nmi_handler ; NMI
.word _reset_handler ; RESET
.word _irq_handler ; IRQ


;=== 4K BACKGROUND CHR (TILES) (256 tiles of 16 bytes) ===
*=$0000

; Tile 0, all with color zero
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


; Unused tiles
.dsb $1000-*, $00

;=== 4K SPRITE CHR (TILES) (256 tiles of 16 bytes) ===
*=$0000

; Tile 0, all with color zero
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,



; Unused tiles
.dsb $1000-*, $00
