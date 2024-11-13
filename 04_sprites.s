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

; NES Colors
BLUE     = $01
PURPLE   = $14
LIGHT_PURPLE = $24
ORANGE   = $27
PINK     = $25 
GREEN    = $2a
SKY_BLUE = $2c
RED      = $16

;Palettes -> PPU memory from $3f00 to $3f20
PPU_BG_PALETTE_0 = $3F00 ; 4 colors in each palette. First one is universal background in all of them.
PPU_BG_PALETTE_1 = $3F04
PPU_BG_PALETTE_2 = $3F08
PPU_BG_PALETTE_3 = $3F0C

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
  ; Store palette colors at PPU
  LDA #GREEN
  STA PPUDATA
  LDA #BLUE
  STA PPUDATA
  LDA #SKY_BLUE
  STA PPUDATA
  LDA #RED
  STA PPUDATA
  
  LDA #GREEN
  STA PPUDATA
  LDA #PURPLE
  STA PPUDATA
  LDA #LIGHT_PURPLE
  STA PPUDATA
  LDA #RED
  STA PPUDATA
  
  LDA #GREEN
  STA PPUDATA
  LDA #BLUE
  STA PPUDATA
  LDA #SKY_BLUE
  STA PPUDATA
  LDA #RED
  STA PPUDATA
  
  LDA #GREEN
  STA PPUDATA
  LDA #BLUE
  STA PPUDATA
  LDA #SKY_BLUE
  STA PPUDATA
  LDA #RED
  STA PPUDATA
  
  ; Set PPU address to nametable 1
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_1_MAP
  STX PPUADDR
  LDX #<PPU_SCREEN_1_MAP
  STX PPUADDR
  ; Store 960 tiles, alternating tiles 1 and 2
  LDY #15
  loop:
  LDX #1
  JSR _draw_row
  INX
  JSR _draw_row
  DEY
  BNE loop
  
  ; Store tile 3 as first tile in map
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_1_MAP
  STX PPUADDR
  LDX #<PPU_SCREEN_1_MAP
  STX PPUADDR
  LDX #3
  STX PPUDATA
  
  
  ; Store 960 tiles again, this time for the second tilemap, alternating tiles 1 and 2
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_2_MAP
  STX PPUADDR
  LDX #<PPU_SCREEN_2_MAP
  STX PPUADDR
  LDY #15
  loop2:
  LDX #1
  JSR _draw_row
  INX
  JSR _draw_row
  DEY
  BNE loop2
  
  ; Store tile 3 as first tile in map
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_2_MAP
  STX PPUADDR
  LDX #<PPU_SCREEN_2_MAP
  STX PPUADDR
  LDX #3
  STX PPUDATA
  
  ; Set PPU address to attribute map 1
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_1_ATTR
  STX PPUADDR
  LDX #<PPU_SCREEN_1_ATTR
  STX PPUADDR
  ; Store palettes indexes
  LDY #64
  LDX #$0
  loop3:
  STX PPUDATA
  DEY
  BNE loop3
  
  ; Second palette for the whole second map
  LDX PPUSTATUS
  LDX #>PPU_SCREEN_2_ATTR
  STX PPUADDR
  LDX #<PPU_SCREEN_2_ATTR
  STX PPUADDR
  LDY #64
  LDX #%01010101
  loop4:
  STX PPUDATA
  DEY
  BNE loop4
  
  ; Set scroll
  LDA #0
  STA scrollx
  LDA #248
  STA scrolly
  
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
  LDA #%00001110
  STA PPUMASK
  
forever:
  JMP forever
.)
; -- end main method --


_update:
.(
  LDA gamepad1
  AND #BTN_UP
  BEQ next
  NOP
  next:
  
  LDA gamepad1
  AND #BTN_DOWN
  BEQ next2
  NOP
  next2:
  
  LDA gamepad1
  AND #BTN_LEFT
  BEQ next3
  NOP
  next3:
  
  LDA gamepad1
  AND #BTN_RIGHT
  BEQ next4
  NOP
  next4:
  
  RTS
.)

_draw_row:
.(
  PHA
  TYA
  PHA
  
  LDY #32
  loop:
  
  STX PPUDATA ; Tile 1
  TXA
  AND #%00000001
  TAX
  INX
  
  DEY
  BNE loop
  
  PLA
  TAY
  PLA
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
.byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,

; Tile 1
; LOW bit
.byt %11111111 ; Row 0
.byt %11111111 ; Row 1
.byt %11111111 ; Row 2
.byt %11111111 ; Row 3
.byt %11111111 ; Row 4
.byt %11111111 ; Row 5
.byt %11111111 ; Row 6
.byt %11111111 ; Row 7
; HIGH bit
.byt %00000000 ; Row 0
.byt %00000000 ; Row 1
.byt %00000000 ; Row 2
.byt %00000000 ; Row 3
.byt %00000000 ; Row 4
.byt %00000000 ; Row 5
.byt %00000000 ; Row 6
.byt %00000000 ; Row 7

; Tile 2
; LOW bit
.byt %00000000 ; Row 0
.byt %00000000 ; Row 1
.byt %00000000 ; Row 2
.byt %00000000 ; Row 3
.byt %00000000 ; Row 4
.byt %00000000 ; Row 5
.byt %00000000 ; Row 6
.byt %00000000 ; Row 7
; HIGH bit
.byt %11111111 ; Row 0
.byt %11111111 ; Row 1
.byt %11111111 ; Row 2
.byt %11111111 ; Row 3
.byt %11111111 ; Row 4
.byt %11111111 ; Row 5
.byt %11111111 ; Row 6
.byt %11111111 ; Row 7

; Tile 3
; LOW bit
.byt %11111111 ; Row 0
.byt %11111111 ; Row 1
.byt %11111111 ; Row 2
.byt %11111111 ; Row 3
.byt %11111111 ; Row 4
.byt %11111111 ; Row 5
.byt %11111111 ; Row 6
.byt %11111111 ; Row 7
; HIGH bit
.byt %11111111 ; Row 0
.byt %11111111 ; Row 1
.byt %11111111 ; Row 2
.byt %11111111 ; Row 3
.byt %11111111 ; Row 4
.byt %11111111 ; Row 5
.byt %11111111 ; Row 6
.byt %11111111 ; Row 7


; Unused tiles
.dsb $1000-*, $00

;=== 4K SPRITE CHR (TILES) (256 tiles of 16 bytes) ===
*=$0000
.asc "SPRITES CHR"
; Unused tiles
.dsb $1000-*, $00
