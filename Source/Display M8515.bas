'7 AGOSTO 2016
'Este programa é apenas para visualisar os comandos de acesso ao display (versão simplificada)

'Resumo aqui o seu controle:
'Head - Deve sempre ser iniciado com com esta sequência
'           Ao se enviar a sequência, cada valor é enviado à respectiva porta, nomeados B1, B2 e B_crt sucessivamente
'           Dentro destes dados, existem alguns que podem ser modificados para outros fins, descrito mais adiante
'           O display está dividiso tem duas secções, B1 e B2, ou esquerda e direita
'           B1 e B2 são escritos em simultâneo ou individualmente
'Foot -  Sequência a ser enviada no final de cada escrita, seja escrita parcial ou ecrân completo

'Desconheço por completo o protocolo usado no inicio e no fim, foi por tentativa que alterei cada valor para encontrar resultados.


$regfile = "m8515.dat"
$crystal = 8000000

$hwstack = 32                                               ' default use 32 for the hardware stack
$swstack = 10                                               ' default use 10 for the SW stack
$framesize = 40                                             ' default use 40 for the frame space


'LCD Byte1
Ddrd = &HFF
Config Portd = Output
Portd = &H00

'LCD Byte2
Ddrc = &HFF
Config Portc = Output
Portc = &H00

'LCD CTRL
Ddrb = &HFF
Config Portb = Output
Portb = &H00

Dim Cnt As Integer
Dim X , Y As Integer

Dim B1 , B2 , B_crt As Byte

Declare Sub Header
Declare Sub Ending

Call Header
'2 X(132 X 176)
'Fill RED RRRBBGGG =111 00 000
For X = 0 To 131
    For Y = 0 To 175
        B1 = &B11100000
        B2 = &B11100000

        'Regist + Clock
        Portd = B1
        Portc = B2
        Portb = 25

        Portd = B1
        Portc = B2
        Portb = 31

        Portd = B1
        Portc = B2
        Portb = 25

        Portd = B1
        Portc = B2
        Portb = 31
    Next Y
Next X

Call Ending

Do
Loop

'---------------------------------------------------------------------
'----------------------------Header---------------------------------
Sub Header
'Quadro 1 = DB8..DB15
'Quadro 2 = DB0..DB7

'Operações sugestivas a serem implementadas antes do envio de uma imagem
'Estas operações também podem ser realisadas alterando directamente os valores de "DATA Head"
'Quando se quer escrever apenas num quadro, o inicio aqui declarado deve ser igual ao fnal (fora do limite)
    Restore Head
    'Apagar os casos não usados:
    For Cnt = 0 To 103
        Read B1
        Read B2
        Read B_crt

        Select Case Cnt
            Case 29 :
            'Inversão de escrita (esquerda para direita)
                B1 = 46
                B2 = 34
                'B1=22 & B2=26 = cores invertidas
                'B1=46 & B2=34 X invertido (usado neste exemplo)
                'B1=30 & B2=18 = cores e X invertido
            Case 85:
            'Contraste (valor de 0..3)
                B2 = 0
            Case 94:
             'Começo da escrita  (200 para escrever apenas num quadro)
                B1 = 0
                B2 = 0
            Case 96:
             'Final da escrita        (200 para escrever apenas num quadro)
                B1 = 175
                B2 = 175

            'Resumo de todas as alterações com resultados:
            '28, 29 res bad
            '32, 33, 34, 35,  só em cima, baixo com risco
            '36, 37 / 84, 85, 86, 87 ambos com risco
            '59, 60 blank
            '61, 62 cima estranho em branco
            '71, 72 troca de quadros cores com problemas
            '85 contraste
            '93, 94 risco na separação
            '94 largura de cada quadro em baixo
            '96 largura de cada quadro em cima
            '99 / 100 escreve no último Y
            '102 risco na separação
            '103 apaga e bloqueia
        End Select
        Portd = B1
        Portc = B2
        Portb = B_crt
    Next Cnt
End Sub
'---------------------------------------------------------------------
'----------------------------Ending----------------------------------
Sub Ending
    Restore Foot
    For Cnt = 0 To 9
        Read B1
        Read B2
        Read B_crt
        Portd = B1
        Portc = B2
        Portb = B_crt
    Next Cnt
End Sub

End
'---------------------------------------------------------------------
'----------------------------DATA-----------------------------------
'---------------------------------------------------------------------

Head:                                                       'B1, B2, B_crt, B1, B2, B_crt...
    Data &H00 , &H00 , &H1E , &H00 , &H00 , &H1F , &H00 , &H00 , &H17 , &H7F , &H7F , &H11 , &H7F , &H7F , &H17 , &H73 , &H73 , &H11 , &H73 , &H73 , &H17 , &H7F , &H7F , &H11 , &H7F , &H7F
    Data &H17 , &H77 , &H77 , &H11 , &H77 , &H77 , &H17 , &H77 , &H77 , &H1F , &H77 , &H77 , &H17 , &H2C , &H2C , &H11 , &H2C , &H2C , &H17 , &H2C , &H2C , &H1F , &HF9 , &HF9 , &H11 , &HF9
    Data &HF9 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &HC0 , &HC0 , &H11 , &HC0 , &HC0 , &H17 , &H40 , &H40 , &H11 , &H40 , &H40 , &H17
    Data &H40 , &H40 , &H1F , &H40 , &H40 , &H17 , &H06 , &H0A , &H11 , &H06 , &H0A , &H17 , &H18 , &H18 , &H11 , &H18 , &H18 , &H17 , &H00 , &H38 , &H11 , &H00 , &H38 , &H17 , &H02 , &H02
    Data &H11 , &H02 , &H02 , &H17 , &H02 , &H01 , &H11 , &H02 , &H01 , &H17 , &H02 , &H01 , &H1F , &H24 , &H24 , &H11 , &H24 , &H24 , &H17 , &H33 , &H33 , &H11 , &H33 , &H33 , &H17 , &H20
    Data &H20 , &H11 , &H20 , &H20 , &H17 , &H01 , &H01 , &H11 , &H01 , &H01 , &H17 , &H01 , &H01 , &H1F , &H22 , &H22 , &H11 , &H22 , &H22 , &H17 , &H22 , &H22 , &H11 , &H22 , &H22 , &H17
    Data &H36 , &H36 , &H11 , &H36 , &H36 , &H17 , &H20 , &H20 , &H11 , &H20 , &H20 , &H17 , &H2A , &H2A , &H11 , &H2A , &H2A , &H17 , &H2A , &H2A , &H1F , &HA9 , &HA9 , &H11 , &HA9 , &HA9
    Data &H17 , &H26 , &H26 , &H11 , &H26 , &H26 , &H17 , &H00 , &H10 , &H11 , &H00 , &H10 , &H17 , &H00 , &H10 , &H1F , &H00 , &H10 , &H17 , &H10 , &H10 , &H11 , &H10 , &H10 , &H17 , &H10
    Data &H10 , &H1F , &H10 , &H10 , &H17 , &H33 , &H31 , &H11 , &H33 , &H31 , &H17 , &H34 , &H34 , &H11 , &H34 , &H34 , &H17 , &H34 , &H34 , &H1F , &H13 , &H13 , &H11 , &H13 , &H13 , &H17
    Data &H30 , &H30 , &H11 , &H30 , &H30 , &H17 , &H12 , &H12 , &H11 , &H12 , &H12 , &H17 , &H28 , &H28 , &H11 , &H28 , &H28 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &H32 , &H32
    Data &H11 , &H32 , &H32 , &H17 , &H02 , &H02 , &H11 , &H02 , &H02 , &H17 , &H02 , &H02 , &H1F , &H42 , &H42 , &H11 , &H42 , &H42 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &HAF
    Data &HAF , &H11 , &HAF , &HAF , &H17 , &H43 , &H43 , &H11 , &H43 , &H43 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &H83 , &H83 , &H11 , &H83 , &H83 , &H17 , &H83 , &H83 , &H1F



Foot:                                                       'B1, B2, B_crt, B1, B2, B_crt...
    Data &H2C , &H24 , &H19 , &H1F , &HBF , &H1F , &H1F , &HBF , &H17 , &H1F , &HBF , &H11 , &H51 , &H51 , &H17
    Data &H51 , &H51 , &H11 , &H53 , &H53 , &H17 , &H53 , &H53 , &H11 , &H00 , &H00 , &H17 , &H00 , &H00 , &H1F