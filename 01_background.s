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

; NES Colors
BLUE    = $01
PURPLE  = $14
ORANGE  = $27

;Palettes -> PPU memory from $3f00 to $3f20
PPU_BG_PALETTE_0 = $3F00 ; 4 colors in each palette. First one is universal background in all of them.
PPU_BG_PALETTE_1 = $3F04
PPU_BG_PALETTE_2 = $3F08
PPU_BG_PALETTE_3 = $3F0C




PPU_SCREEN_1_MAP=$2000 ; 960 tiles of 1 byte + 64 bytes attribute table
PPU_SCREEN_1_ATTR=$23C0
PPU_SCREEN_2_MAP=$2400
PPU_SCREEN_2_ATTR=$27C0
PPU_SCREEN_3_MAP=$2800
PPU_SCREEN_3_ATTR=$2BC0
PPU_SCREEN_4_MAP=$2C00
PPU_SCREEN_4_ATTR=$2FC0

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
  LDX #$>>PPU_BG_PALETTE_0
  STX PPUADDR
  ; Set PPU low address $3F00 to store next value
  LDX #$00
  STX PPUADDR
  ; Store green value at PPU
  LDA #BLUE
  STA PPUDATA
  LDA #PURPLE
  STA PPUDATA
  LDA #ORANGE
  STA PPUDATA
  
  ; Set PPU address to nametable 1
  LDX PPUSTATUS
  LDX #$>>PPU_SCREEN_1_MAP
  STX PPUADDR
  LDX #$<<PPU_SCREEN_1_MAP
  STX PPUADDR
  ; Store tile numbers in tile map
  LDX #0
  STX PPUDATA ; Tile 0
  INX
  STX PPUDATA ; Tile 1
  INX
  STX PPUDATA ; Tile 2
  INX
  STX PPUDATA ; Tile 3
  
  ; Set PPU address to attribute map 1
  LDX PPUSTATUS
  LDX #$>>PPU_SCREEN_1_ATTR
  STX PPUADDR
  LDX #$<<PPU_SCREEN_1_ATTR
  STX PPUADDR
  ; Store palettes indexes
  LDX #0
  STX PPUDATA
  STX PPUDATA
  
; Configurar PPU
;  0  Greyscale mode enable (0 normal color, 1 greyscale)
;  1  Left edge (8px) background enable (0 hide, 1 show)
;  2  Left edge (8px) foreground enable (0 hide, 1 show)
;  3  Background enable
;  4  Foreground enable
;  5  Emphasize red
;  6  Emphasize green
;  7  Emphasize blue
  LDA #%00010000
  STA PPUMASK
forever:
  JMP forever
.)
; -- end main method --

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
  ; Disable NMI frame trigger (bit 7 controls whether or not the PPU will trigger an NMI every frame.)
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
  RTI

; === VECTORS ===
.dsb $fffa-*, $ff
.word _nmi_handler ; NMI
.word _reset_handler ; RESET
.word _irq_handler ; IRQ


;=== 8K CHR (TILES) (512 tiles of 16 bytes) ===
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

; Tile 3. First 4 pixel, each one of one of the palette colors
; LOW bit
.byt %01010000 ; Row 0
.byt %00000000 ; Row 1
.byt %00000000 ; Row 2
.byt %00000000 ; Row 3
.byt %00000000 ; Row 4
.byt %00000000 ; Row 5
.byt %00000000 ; Row 6
.byt %00000000 ; Row 7
; HIGH bit
.byt %00110000 ; Row 0
.byt %00000000 ; Row 1
.byt %00000000 ; Row 2
.byt %00000000 ; Row 3
.byt %00000000 ; Row 4
.byt %00000000 ; Row 5
.byt %00000000 ; Row 6
.byt %00000000 ; Row 7

; Unused tiles
.dsb $2000-*, $00


