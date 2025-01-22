.model small
.stack 100h
.data

zinute1 db "Iveskite dvejetaini skaiciu: $"  ; Pranešimas vartotojui, kad įvestų dvejetainį skaičių
enteris db 10, 13, "$"                       ; Eilutės pabaigos simboliai (nauja eilutė)
bufferis db 255 dup ('$')                    ; Buferis, kuriame talpinsime vartotojo įvestą skaičių

.code

pradzia:
    mov ax, @data        ; @data grąžina duomenų segmento (.data) pradžios adresą, tą adresą pakrauname į AX registrą
    mov ds, ax           ; DS (Data Segment) nustatome į duomenų segmento pradžią, kad galėtume pasiekti .data sekcijos kintamuosius

    mov ah, 9            ; AH registrą nustatome į 9, kuris nurodo DOS funkciją „spausdinti eilutę“ (Print String)
    lea dx, zinute1      ; Su lea į DX registrą užpildome su zinute1 efektyviu adresu, galėtume daryti ir su MOV jeigu pridėtume offset
    int 21h              ; Iškviečiame DOS interrupt (INT 21h) su AH = 9, kad būtų atspausdinta eilutė, kurios adresas yra DX

    mov ah, 0Ah          ; AH registrą nustatome į 0Ah, kad nurodytume DOS naudoti funkciją „Buffered Input“
    lea dx, bufferis     ; DX registrą užpildome buferio pradžios adresu
    int 21h              ; Iškviečiame DOS interrupt (INT 21h) su AH = 0Ah, kad į buferį būtų nuskaityta vartotojo įvestis

    ; new line'as
    mov ah, 9
    lea dx, enteris
    int 21h

    ; CX registras dažnai naudojamas kaip skaitliukas cikluose, tačiau tai nėra „nutylėjimas“ (t.y., procesorius automatiškai jo nenaudoja ciklams be mūsų nurodymo). Mes patys nustatome, kad CX bus naudojamas kaip skaitliukas, kai rašome ciklus. Kai kurios instrukcijos, tokios kaip LOOP ir REP, implicitai naudoja CX registrą kaip skaitliuką.
    ; SI (Source Index) ir DI (Destination Index) registrai yra specializuoti indeksiniai registrai, skirti atminties adresavimui ir dažnai naudojami kartu su tam tikromis operacijomis, pvz., MOVSB (kopijuoti baitą), STOSB (įrašyti baitą), LODSB (krauti baitą į registrą), ir SCASB (palyginti baitą). Šios instrukcijos implicitai naudoja SI ir DI registrus, todėl jų nereikia tiesiogiai nurodyti.
    
    mov cx, 0  ; Inicijuojame CX į 0, jis laikys konvertuotą dešimtainę reikšmę
    mov si, 2  ; Nustatome SI į 2, kad praleistume pirmus du buferio baitus, kurie nėra vartotojo įvesties dalis

ciklas:

    mov al, [bufferis + si]  ; Į al padedam simbolį iš bufferis
    cmp al, 13      ; Patikriname, ar pasiekėme įvesties pabaigą, nuskaitėme 'Enter' klavišą, kurio ASCII kodas 13
    je skaiciavimas ; Jei al reikšmė lygi 13 (Enter), šokame į skaiciavimas

    
    cmp al, '0'     ; Patikriname, ar įvestas simbolis yra tinkamas dvejetainis skaičius ('0' arba '1')
    je binary_zero  ; Jei simbolis yra '0', šokame į binary_zero
    cmp al, '1'
    je binary_one   ; Jei simbolis yra '1', šokame į binary_one

binary_zero:
    shl cx, 1       ;  CX = CX * 2 (bitų poslinkis į kairę)
    inc si          ;  Didiname buferio indeksą (SI) vienetu
    jmp ciklas      ;  Grįžtame į ciklą apdoroti kitą simbolį

binary_one:
    shl cx, 1  ; CX = CX * 2 (bitų poslinkis į kairę)
    add cx, 1  ; Pridedame vienetą nuskaitytą vienetą prie CX registro
    inc si     ; Didiname buferio indeksą (SI) vienetu
    jmp ciklas ; Grįžtame į ciklą apdoroti kitą simbolį

skaiciavimas:
    call print_decimal ; print_decimal Kvietimas procedūrai, kuris CX konvertuos į ASCII ir jį atspausdins
    jmp pabaiga

; Konvertuojame rezultatą iš CX (dešimtainė reikšmė) į ASCII ir atspausdiname
print_decimal proc
    mov ax, cx  ; Perkeliame dvejetainį skaičių iš CX į AX tolimesniam apdorojimui
    xor dx, dx  ; Nuliname DX, kad išvengtume konfliktų dalybos metu
    mov bx, 10  ; Nustatome bx (daliklį) į 10 (dešimtainio bazę)

    
    cmp ax, 0
    jne print_loop ; Jei AX nelygus nuliui, pereiname prie skaitmenų spausdinimo ciklo
    
    mov dl, '0'     ; DL registrui priskiriame '0' ASCII reikšmę
    mov ah, 02h     ; DOS funkcija 02h (Print Character) atspausdina ASCII reikšmę esančia DL segmente
    int 21h
    ret             ; Atspausdinę nulį, grįžtame iš procedūros, 

print_loop:
    xor cx, cx  ; Nuliname CX, jis laikys skaitmenų kiekį išvedimui

convert_digit:
    xor dx, dx      ; Nuliname DX prieš dalinant
    div bx          ; AX = AX / 10, DX = dalybos liekana (skaitmuo)
    push dx         ; Liekaną (skaitmenį) dedame į steką
    inc cx          ; Didiname skaitmenų skaičių CX registre
    cmp ax, 0       ; Patikriname, ar liko skaitmenų
    jne convert_digit  ; Jeigu jau neliko einame prie print_digits, jeigu liko kartojame veiksmą

print_digits:
    pop dx      ; Nuo stack'o viršaus paėmame mūsų su push pagalba padėtą reikšmę
    add dl, '0' ; Konvertuojame skaitmenį į ASCII pridėdami ASCII reikšmę '0' (48)
    mov ah, 02h
    int 21h
    loop print_digits ; Loop mažina cx vienetu ir kartoja kol CX tampa 0

    ret
print_decimal endp

pabaiga:
    ; End program
    mov ah, 4Ch
    int 21h

end pradzia