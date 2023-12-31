CLS       equ $0D6B ; https://skoolkid.github.io/rom/asm/0D6B.html
BORDCR    equ $5C48 ; https://skoolkid.github.io/rom/asm/5C48.html
ATTR_P    equ $5C8D ; https://skoolkid.github.io/rom/asm/5C8D.html

; Clear the screen
XOR A
LD (ATTR_P), A
LD (BORDCR), A
OUT ($FE), A
CALL CLS

; Load the image
LD DE, ($5CF4)   ; restore the FDD head position
LD BC, $0F05     ; load 15 sectors of compressed image
LD HL, $9C40     ; destination address (40000)
CALL $3D13       ;
CALL $9C40       ; decompress the image

; Load the data
LD DE, ($5CF4)   ; restore the FDD head position
LD HL, $6F18     ; destination address (28440)
LD BC, $8D05     ; load 141 sectors of data
CALL $3D13

LD HL, $FC08
LD DE, $FFF0
LD BC, $8CF1
LDDR

; Clear the screen again
XOR A
LD (ATTR_P), A
CALL CLS

; Apparently, the default stack pointer isn't good enough
LD SP, $FFEF
JP $C14B
