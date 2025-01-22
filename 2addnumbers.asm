.model small
.stack 100h
skBufDydis EQU 40
.data
    ;Duomenu failu pavadinimai
    duom1 db "duom1.txt", 0
    duom2 db "duom2.txt", 0
    rez db "rez.txt", 0

    skBuf db skBufDydis dup (?) ; Buferis duom1 simboliams laikyti
    skBuf2 db skBufDydis dup (?) ; Buferis duom2 simboliams laikyti

    ; db - rezervuoja 1 baitą
    ; dw - rezervuoja word (2 baitus)
    
    dFile dw ? ; Pirmo failo handle
    dFile2 dw ? ; Antro failo handle
    rFile dw ? ; Rezultato handle

    len1 dw ? ; Nuskaitytų baitų kiekis
    len2 dw ?
    newLength dw ? ; Naujo skaičiaus ilgis
    tempByte db ? ; Laikinas baitas simboliui įrašyti į rez
.code

pradzia:
    mov ax, @data ; Nustatome duomenų segmentą
    mov ds, ax

    ; Atidarome duom1 ir duom2 skaitymui, rez rašymui
    mov ah, 3Dh
    mov al, 00 ; Atidarome read-only režimu
    mov dx, offset duom1 ; Nurodome duom1 adreso pradžią
    int 21h
    mov dFile, ax ; dFile kintamajam priskiriame failo rankeną

    mov ah, 3Dh
    mov al, 00
    mov dx, offset duom2
    int 21h
    mov dFile2, ax

    mov ah, 3Ch
    mov cx, 0
    mov dx, offset rez
    int 21h
    mov rFile, ax ; rFile kintamajam priskiriame rezultato failo rankeną

    ; Nuskaitome simbolius į buferius iš duom1 ir duom2 failų
    mov bx, dFile
    mov ah, 3Fh
    mov cx, skBufDydis ; Skaitysime tiek baitų, kiek nurodyta skBufDydis
    mov dx, offset skBuf ; Nurodome duomenų buferį skBuf
    int 21h ; Nuskaitome duom1.txt į buferį skBuf
    mov len1, ax ; Kiek baitų nuskaityta, saugome len1

    mov bx, dFile2
    mov ah, 3Fh
    mov cx, skBufDydis
    mov dx, offset skBuf2
    int 21h
    mov len2, ax ; Kiek baitų nuskaityta, saugome len2

    mov cl, 0 ; Įrašome pradinę 'carry' reikšmę
    mov newLength, 0 ; Nustatome naujo skaičiaus ilgį į 0

skaitombaita:
    dec len1 ; Mažiname len1 ir len2, kad gauti paskutini skaitmeni
    dec len2
    
    mov si, len1 ; dedame len1 į si ir len2 į bx, nes [Skbuf + len1] neleidžiamas
    mov bx, len2

    mov dl, [skBuf + si]  ; Paskutinis duom1.txt baitas
    mov al, [skBuf2 + bx] ; Paskutinis duom2.txt baitas

; Patikriname, ar baitas yra skaitmuo [0; 9], jei ne - keičiame į '0'
check:
    cmp dl, '0'
    JL setDlZero
    cmp dl, '9'
    JG setDlZero

    cmp al, '0'
    JL setAlZero
    cmp al, '9'
    JG setAlZero

    JMP sudedam

setDlZero:
    mov dl, '0'
    JMP check

setAlZero:
    mov al, '0'

sudedam:
    ; Skaitmenis konvertuojame iš ASCII į jų skaitines reikšmes
    sub dl, '0'
    sub al, '0'

    ; Sudedame skaitmenis, pridedame 'carry' reikšmę
    add dl, al
    add dl, cl
    xor cl, cl ; Nustatome 'carry' į 0

    ; Jei suma neviršija 9, galime tęsti
    cmp dl, 10
    JL padedameskaiciu

    ; Jei viršija 9, mažiname sumą ir nustatome 'carry'
    sub dl, 10
    add cl, 1

padedameskaiciu:
    ; Konvertuojame į ASCII ir dedame į steką, didiname newLength
    add dl, '0'
    push dx
    inc newLength

    ; Jei liko nuskaitomų simbolių, tęsiame skaitymą
    cmp len1, 0
    JG skaitombaita

    cmp len2, 0
    JG skaitombaita

    ;Tikrinam ar liko carry, po visu simboliu apdorojimo
    cmp cl, 1
    JE skaitombaita

; Jei gautame skaičiuje yra nereikalingų nulinių reikšmių priekyje, jas pašaliname
popZero:
    CMP newLength, 0 ; Jei skaičiaus ilgis yra nulis, baigiame programą
    JE exit_program

    dec newLength ; Mažiname skaičiaus ilgį
    pop dx ; Paimame iš steko viršaus
    cmp dx, '0' ; Jei pirmi skaitmenys - nuliai, juos pašaliname, kartojame cikla
    JE popZero

    inc newLength ; Jei skaičius nebuvo nulinis, atstatome ilgį
    push dx ; Dedame skaičių atgal į steką

print:
    CMP newLength, 0
    JE exit_program

    pop dx ; Paimame skaitmenį iš steko
    mov tempByte, dl ; Laikinai įrašome skaitmenį

    ; Įrašome simbolį į rez.txt failą
    mov bx, rFile      ; Rezultato failo rankena
    mov ah, 40h        ; DOS rašymo funkcija
    mov cx, 1          ; Rašome vieną baitą
    mov dx, offset tempByte  ; DX nurodo į baito adresą
    int 21h            ; Įrašome baitą į rez.txt

    DEC newLength
    JMP print

exit_program:
    ; Uždaryti duom1.txt, duom2.txt, rez.txt
    mov ah, 3Eh        ; DOS funkcija 3Eh - uždaryti failą
    mov bx, dFile      ; duom1.txt rankena
    int 21h            ; Uždaryti failą

    mov ah, 3Eh
    mov bx, dFile2
    int 21h

    mov ah, 3Eh
    mov bx, rFile
    int 21h

    mov ax, 4C00h      ; DOS funkcija 4Ch - užbaigti programą
    int 21h            ; Užbaigti
END pradzia
