; $0000–$07FF -> Internal RAM (2 KB)
; $2000–$2007 -> NES PPU registers
; $4000–$4017 -> NES APU and I/O registers
; $6000-$7FFF -> PRG RAM
; $8000-$BFFF -> First 16 KB of ROM.
; $C000-$FFFF -> Last 16 KB of ROM

; PPU Resgisters
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007
PPUSCROLL = $2005
OAMADDR   = $2003
OAMDMA    = $4014

; NES Colors
BLUE     = $01
PURPLE   = $14
LIGHT_PURPLE = $24
ORANGE   = $27
PINK     = $25 
GREEN    = $2a
SKY_BLUE = $2c
RED      = $16
BLACK    = $0F
SKY_BLUE_LIGHT  = $3c

;Palettes -> PPU memory from $3f00 to $3f20
PPU_BG_PALETTE_0 = $3F00 ; 4 colors in each palette. First one is universal background in all of them.
PPU_BG_PALETTE_1 = $3F04
PPU_BG_PALETTE_2 = $3F08
PPU_BG_PALETTE_3 = $3F0C
PPU_FG_PALETTE_0 = $3f10
PPU_FG_PALETTE_1 = $3f14
PPU_FG_PALETTE_2 = $3f18
PPU_FG_PALETTE_3 = $3f1c

; PPU Tilemaps
PPU_SCREEN_1_MAP=$2000 ; 960 tiles of 1 byte + 64 bytes attribute table
PPU_SCREEN_1_ATTR=$23C0 ; 64 bytes attribute table
PPU_SCREEN_2_MAP=$2400
PPU_SCREEN_2_ATTR=$27C0
PPU_SCREEN_3_MAP=$2800
PPU_SCREEN_3_ATTR=$2BC0
PPU_SCREEN_4_MAP=$2C00
PPU_SCREEN_4_ATTR=$2FC0

; Gamepad ports
PORT1 = $4016
PORT2 = $4017

; Gamepad Buttons
BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000

; Variables
gamepad1 = $01
gamepad2 = $02
scrollx  = $03
scrolly  = $04
oambuffer = $0200


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

.asc "CODE"
_main:
.(
  ; Reset latch PPUADDR
  LDX PPUSTATUS
  ; Set PPU high address $3F00 to store next value
  LDX #>PPU_BG_PALETTE_0
  STX PPUADDR
  ; Set PPU low address $3F00 to store next value
  LDX #$00
  STX PPUADDR
  
  ; Send paleta
  paleta: 
  .byt $21,$03,$14,$28, $21,$21,$21,$21, $21,$21,$21,$21 ,$21,$21,$21,$21,
  .byt $21,$16,$28,$0f, $21,$21,$21,$21, $21,$21,$21,$21 ,$21,$21,$21,$21,
  LDX #0
  loop_paletas
    LDA paleta,X
    STA PPUDATA
    INX
    CPX #32
  BNE loop_paletas
  
  
  
  ; Set PPU address to nametable 1
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_1_MAP
  STX PPUADDR
  LDX #<PPU_SCREEN_1_MAP
  STX PPUADDR
  ; Store first of 960 tiles
  LDA #1
  STA PPUDATA
  LDA #2
  STA PPUDATA
  LDA #3
  STA PPUDATA
  LDA #4
  STA PPUDATA
  ; Second tile row at 
  LDX PPUSTATUS
  LDX #$20
  STX PPUADDR
  LDX #$20
  STX PPUADDR
  LDA #5
  STA PPUDATA
  LDA #6
  STA PPUDATA
  LDA #6
  STA PPUDATA
  LDA #7
  STA PPUDATA
  
  LDX PPUSTATUS
  LDX #$20
  STX PPUADDR
  LDX #$40
  STX PPUADDR
  LDA #8
  STA PPUDATA
  LDA #9
  STA PPUDATA
  LDA #10
  STA PPUDATA
  LDA #11
  STA PPUDATA
    
  ; Set PPU address to attribute map 1
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_1_ATTR
  STX PPUADDR
  LDX #<PPU_SCREEN_1_ATTR
  STX PPUADDR
  ; Store palettes indexes
  LDX #$0
  STX PPUDATA
  
  ; Set scroll
  LDA #0
  STA scrollx
  LDA #248
  STA scrolly
  
  ; write sprite data
  LDX #0
  loop3:
  LDA sprites,X
  STA $0200,X
  INX
  CPX #32
  BNE loop3
  
  
  ; wait for vblank
  vblankwait:       
  BIT PPUSTATUS
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
  STA PPUCTRL
  
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
  STA PPUMASK
  
forever:
  JMP forever
.)
; -- end main method --


_update:
.(
  ; Player 1 up
  LDA gamepad1
  AND #BTN_UP
  BEQ next
  DEC $0200
  DEC $0204
  DEC $0208
  DEC $020C
  next:
  ; Player 1 down
  LDA gamepad1
  AND #BTN_DOWN
  BEQ next2
  INC $0200
  INC $0204
  INC $0208
  INC $020C
  next2:
  
  ; Player 2 up
  LDA gamepad2
  AND #BTN_UP
  BEQ next3
  DEC $0210
  DEC $0214
  DEC $0218
  DEC $021C
  next3:
  ; Player 2 down
  LDA gamepad2
  AND #BTN_DOWN
  BEQ next4
  INC $0210
  INC $0214
  INC $0218
  INC $021C
  next4:
  
  RTS
.)

sprites:
; y tile attr x
.byt 50,1,0,8
.byt 58,2,0,8
.byt 66,3,0,8
.byt 74,4,0,8

.byt 50,1,0,240
.byt 58,2,0,240
.byt 66,3,0,240
.byt 74,4,0,240

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
  STX PPUCTRL
  ; Disable graphics
  STX PPUMASK
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
  LDA #<oambuffer
  STA OAMADDR
  LDA #>oambuffer
  STA OAMDMA

  ; Set Background scroll
  LDA scrollx
  STA PPUSCROLL
  LDA scrolly
  STA PPUSCROLL

  ; Latch controllers
  LDA #$01
  STA PORT1
  LDA #$00
  STA PORT1  
  ; Read controller 1
  LDA #%00000001
  STA gamepad1
  loop:
  LDA PORT1
  LSR
  ROL gamepad1
  BCC loop  
  ; Read controller 2
  LDA #%00000001
  STA gamepad2
  loop2:
  LDA PORT2
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
; Tile 1
.byt $00,$00,$03,$03,$07,$0F,$17,$27,$00,$00,$00,$01,$01,$07,$0F,$1F ; 1
.byt $1F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$00,$1F,$7F,$FF,$FF,$FF,$FF,$FF ; 2
.byt $F8,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$00,$F8,$FE,$FF,$FF,$FF,$FF,$FF ; 3
.byt $00,$00,$C0,$C0,$E0,$F0,$E8,$E4,$00,$00,$00,$80,$80,$E0,$F0,$F8 ; 4
.byt $73,$F3,$F3,$F3,$F9,$F9,$F9,$F9,$3F,$7F,$7F,$7F,$7F,$7F,$7F,$7F ; 5
.byt $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 6
.byt $CE,$CF,$CF,$CF,$9F,$9F,$9F,$9F,$FC,$FE,$FE,$FE,$FE,$FE,$FE,$FE ; 7
.byt $FC,$FC,$FC,$FC,$FE,$FE,$FE,$FE,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F ; 8
.byt $FF,$FF,$FF,$FF,$7F,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 9
.byt $FF,$FF,$FF,$FF,$FE,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 10
.byt $3F,$3F,$3F,$3F,$7F,$7F,$7F,$7F,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE ; 11
.byt $FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F ; 12
.byt $7F,$7F,$3F,$3F,$3F,$3F,$3F,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 13
.byt $FE,$FE,$FC,$FC,$FC,$FC,$FC,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 14
.byt $7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE ; 15

; Unused tiles
.dsb $1000-*, $00

;=== 4K SPRITE CHR (TILES) (256 tiles of 16 bytes) ===
*=$0000

; Tile 0, all with color zero
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
; Tile 1
.byt $18,$7E,$FF,$93,$A5,$C9,$93,$A5,$18,$66,$81,$FF,$FF,$FF,$FF,$FF
.byt $C9,$93,$A5,$C9,$93,$A5,$C9,$93,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byt $A5,$C9,$93,$A5,$C9,$93,$A5,$C9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byt $93,$A5,$C9,$93,$A5,$FF,$7E,$18,$FF,$FF,$FF,$FF,$FF,$81,$66,$18


; Unused tiles
.dsb $1000-*, $00
