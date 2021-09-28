'02 OUTUBRO 2016    Bascom V2.0.8.1  (81% FLASH)
$regfile = "m328pdef.dat"
$crystal = 16000000

$hwstack = 42
$swstack = 20
$framesize = 50



'LCD Byte1 <=> mantém-se 328P PortD
Ddrd = &HFF
Config Portd = Output
Portd = &HFF

'LCD Byte2 <=> (0..5)lsb
'Ddrb = &B111111
Ddrb = &HFF
Config Portb = Output
Portb = &HFF

'LCD Byte2 + CRTL <=> Byte2(0..1)msb + CTRL(2..4)
'Ddrc = &B011111
Ddrc = &B011111
Config Portc = Output
Portc = &B111111

'The prescaler divides the internal clock by 2,4,8,16,32,64 or 128
Config Adc = Single , Prescaler = 16 , Reference = Internal 'Keyboard
Enable Adc

Dim Send_b As Byte
Dim Send_c As Byte
Dim Send_c1 As Byte
Dim Send_c2 As Byte
Dim Crt As Byte



Const Paper = 99                                            'cor fora da moldura
Const Back = 41                                             'cor dentro da moldura
Const Info_back = 0                                         'cor de fundo da informação
Const Text_back = 80

Dim Cnt As Integer

Dim Byte_ As Byte
Dim Integer_ As Integer

Dim Sw As Byte

Dim X As Integer
Dim Y As Integer
Dim X2 As Byte
Dim Y2 As Byte

Dim B1 As Byte
Dim B2 As Byte
Dim B_crt As Byte

Dim K As Byte
Dim Kb(2) As Byte

'Peças
Dim Sprite(16) As Byte                                      'peça escolhida
Dim Sprite_tmp(16) As Byte                                  'auxilia na rotação
Dim Sprite_ok(16) As Byte                                   'grava a última peça boa
Dim Id As Byte                                              'ID da peça a tratar
Dim Id_next As Byte
Dim Cor As Byte                                             'manupulação de cores

'Matriz
Dim Colide As Byte                                          'detecta colisões
Dim Matrix(230) As Byte                                     'quadro virtual 10x20 (+ 10 * 20)
Dim Matrix_sector(40) As Byte                               'testa movimentos e colisões antes de passar para ok
Dim Matrix_sector_ok(40) As Byte                            'backup para visualizar e gravar no final
Dim Fx_sprite(12) As Byte                                   'efeito 3D nas peças
Dim Ok_sector_x As Byte                                     'memória da última boa posição
Dim Ok_sector_y As Byte                                     ' //

'Matrix = 12 x (10 x 20)
'Sector = 10 x 4
'Sprite = 4 x 4

Dim Mx As Integer                                           'posição X do matrix ou sector
Dim My As Integer                                           'posição Y do matrix ou sector
Dim Mz As Integer                                           'posição em array do matrix ou sector

Dim Go_x As Integer                                         'memória X da posição boa
Dim Go_y As Byte                                            'memória Y da posição boa

Dim Rep As Byte
Dim Free As Byte
Dim Delay_ As Integer
Dim Moviment As Byte

Dim Level As Byte
Dim Level_inc As Byte
Dim Point As Long
Dim Point_calc As Long
Dim Long_ As Long

Dim Analog As Integer

Declare Sub Header
Declare Sub Header_y(byval B1_start As Byte , Byval B1_end As Byte , Byval B2_start As Byte , Byval B2_end As Byte )
Declare Sub Ending
Declare Sub Background_screen
Declare Sub Get_sprite(byval Spr As Byte)
Declare Sub Rotate_sprite(byval Id1 As Byte)
Declare Sub Print_matrix_line(byval Array_ As Byte , Byval Line_n As Byte)
Declare Sub Clock
Declare Sub Get_matrix_sector(byval Line_ As Byte)
Declare Sub Sprite_to_sector_colide
Declare Sub Show_matrix_lines(byval Y_pos As Byte)
Declare Sub Copy_ok_to_matrix
Declare Sub Check_lines

Declare Sub Show_logo
Declare Sub Game_over
Declare Sub Show_next
Declare Sub Text(byval Char_pos As Byte , Byval Cor_back As Byte)
Declare Sub Space_(byval Esp_x As Byte , Byval Esp_y As Byte)

Declare Sub Info(byval Numeros As Integer)
Declare Sub Ranking



'Matrix
'0123456789
'XXXXXXXXXX 0
'XXXXXXXXXX 1
'XXXXXXXXXX 2
'XXXXXXXXXX 3
'XXXXXXXXXX 4
'XXXXXXXXXX 5
'XXXXXXXXXX 6
'XXXXXXXXXX 7
'XXXXXXXXXX 8
'XXXXXXXXXX 9
'XXXXXXXXXX 10
'XXXXXXXXXX 11
'XXXXXXXXXX 12
'XXXXXXXXXX 13
'XXXXXXXXXX 14
'XXXXXXXXXX 15
'XXXXXXXXXX 16
'XXXXXXXXXX 17
'XXXXXXXXXX 18
'XXXXXXXXXX 19

'RGB RRRBBGGG
'X=0..131(x2=352) Y=0..176

  'Apaga toda a matriz
For K = 1 To 200
    Matrix(k) = Back
Next K
    'Coloca uma fila virtual em baixo e sobram duas a 0
For K = 201 To 210
    Matrix(k) = 88
Next K

    'Grava a sequência de cor FX em FX_sprite
Restore Fx_sprite_table
For K = 1 To 12
    Read Byte_
    Fx_sprite(k) = Byte_
Next K


Call Show_logo
Portc.5 = 0
While Analog = 0
    Analog = Getadc(5)
    Id_next = Rnd(7)
Wend


Call Background_screen


'----------------------------MAIN-------------------------------
Do

   '0..6
    Id = Id_next                                             'copia next para a peça presente
    Id_next = Rnd(7)                                         'gera aleatório da peça next
    Call Get_sprite(id_next)                                 'coloca a peça next em array
    Call Show_next                                           'apresenta a peça next
    Call Get_sprite(id)                                      'coloca a peça presente em array


   'posição horizontal a colocar a peça
    Go_x = 4

'Moviment:
'0 = livre
'1 = rotação
'2 = peça para baixo
'3,4 = deslocação lateral

'pára no 18
    For Go_y = 0 To 20

        Delay_ = Level * 3
        If Delay_ > 20 Then Delay_ = 20
        Delay_ = 20 - Delay_

        Moviment = 2                                           'visualiza na 1ª posição
        For Rep = 0 To 21                                      'repete 22 x para captura de comando

        'tecla1 = 76 => 5 rodar
        'tecla4 = 63 => 4 baixo
        'tecla5 = 48 => 3 esquerda
        'tecla6 = 31 => 2 direita
        'tecla3 = 15 => 1 cair

            Portc.5 = 0
            Analog = Getadc(5)
            Analog = Analog + 12                               'compensação para a divisão
            Analog = Analog / 16

        'verifica se o teclado foi solto
            If Free = 1 Then
                Free = 0                                        'a tecla só faz um comando até ser largada
                Select Case Analog
            '1 Up, 2 Down, 4 Left, 8 Right
            'rotate
                    Case 5:
                        Call Rotate_sprite(id)
                        Moviment = 1
            'peça para baixo
                    Case 4:
                        Rep = 21                                   'exit for
                        Delay_ = 0                                 'sem tempo de espera para novo y
                        Free = 1
                        Moviment = 2
            'mover para esquerda
                    Case 3:
                        Go_x = Go_x - 1
                        Moviment = 3
            'mover para direita
                    Case 2
                        Go_x = Go_x + 1
                        Moviment = 4
            'cai a peça
                    Case 1
                        If Rep > 0 Then
                            Do
                                Ok_sector_y = Go_y
                                Call Get_matrix_sector(go_y)        'copia secção de matrix para matrix_sector
                                Call Sprite_to_sector_colide        'coloca a peça no sector e vê se há colisões
                                Call Print_matrix_line(9 , Ok_sector_y)       'apaga o rasto
                                If Colide = 0 Then Ok_sector_y = Go_y
                                Incr Go_y
                            Loop Until Colide <> 0

                            Go_y = Go_y - 2
                            Delay_ = 0
                            Rep = 21
                            Moviment = 2
                        End If
                End Select
            End If
            If Analog = 0 Then Free = 1

         'verifica se há colisões, verifica no inicio para game-over !!!
            If Moviment <> 0 Then
                Call Get_matrix_sector(go_y)                   'copia secção de matrix para matrix_sector
                Call Sprite_to_sector_colide                   'coloca a peça no sector e vê se há colisões
                Call Print_matrix_line(9 , Ok_sector_y)        'apaga o rasto

             'colide
                If Colide <> 0 Then
                    For Cnt = 1 To 40
                        Matrix_sector(cnt) = Matrix_sector_ok(cnt)       'restauro do sector
                    Next Cnt

                    Select Case Moviment
                        Case 1:
                'rotação
                            For Cnt = 1 To 16
                                Sprite(cnt) = Sprite_ok(cnt)         'restauro do sprite
                            Next Cnt
                        Case 2:
                'peça para baixo
                            Call Copy_ok_to_matrix

                            If Go_y = 0 And Go_x = 4 Then
                                Call Game_over
                            End If

                            Delay_ = 0
                            Rep = 21
                            Go_y = 20
                        Case 3:
                'peça para a esquerda
                            Go_x = Go_x + 1
                        Case 4
                'peça para a direita
                            Go_x = Go_x - 1
                    End Select

             'não colide
                Else
                    Ok_sector_x = Go_x
                    Ok_sector_y = Go_y
                    For Cnt = 1 To 40
                        Matrix_sector_ok(cnt) = Matrix_sector(cnt)       'copia o sector para o bom
                    Next Cnt
                End If

                Call Show_matrix_lines(ok_sector_y)
            End If
         'fim da verificação


            Moviment = 0
            Waitms Delay_
            Byte_ = Rnd(2)                                     'melhora o nº aleatório para a peça


        Next Rep

    Next Go_y

    Call Check_lines                                            'verifica se alguma linha está feita

Loop

'++++++++++++++++++++++++++++++++++++++++
'-------------------------------Info---------------------------------
Sub Info(byval Numeros As Integer)

    '21 + SCORE:_ (49) + num. = 132
    Call Header_y(200 , 200 , 17 , 23)

    'espaço = 77
    B2 = Text_back
    Call Space_(77 , 7)

    'texto numero = 5X7=35
    Cnt = 10000
    While Cnt > 0
        Integer_ = Numeros / Cnt
        Mx = Integer_ Mod 10
        Restore Numbers
        For My = 1 To Mx
            For Mz = 0 To 4
                Read Cor
            Next Mz
        Next My
        Call Text(1 , Text_back)
        Cnt = Cnt / 10
    Wend

    B2 = Text_back
    Call Space_(20 , 7)

    Call Ending

End Sub


'---------------------------------------------------------------------
'---------------------------------------------------------------------
'---------------------------------------------------------------------
'copiar secção de Matrix para Matrix_sector
'gravar Sprite em Matrix_sector e verificar se colide

'se colide então:
'- colocar ok_sector em Matrix
'- exibir matrix_sector

'se não colide:
'- gravar posição de Sprite em ok_sector
'- exibir matrix_sector

'---------------------------------------------------------------------
'------------------------------Show_next------------------------------
'---------------------------------------------------------------------
Sub Show_next

    Call Header_y(200 , 200 , 52 , 71)                      '1 = space to info
    'Secção
    'XY= 132 x 20

    'espaço até ao next = 70*20
    B2 = Paper
    Call Space_(80 , 20)

    For X = 0 To 39
        For Y = 0 To 19

            X2 = X / 10
            X2 = X2 + 1
            Y2 = Y / 10
            Y2 = Y2 * 4
            Mz = X2 + Y2
            If Sprite(mz) <> Back Then
                B2 = Sprite(mz) + 1                             'aumenta o brilho +1
            Else
                B2 = Paper
            End If
            Call Clock
        Next Y
    Next X

    'espaço após o sprite  next = 12*20
    B2 = Paper
    Call Space_(12 , 20)

    Call Ending

'---------------------------------------------------------------------
'-------------------------------Score---------------------------------

    '21 + SCORE:_ (49) + num. = 132
    Call Header_y(200 , 200 , 7 , 13)

    'espaço = 21
    B2 = Text_back
    Call Space_(21 , 7)

    'texto SCORE: 8X7  = 56
    Restore Score
    Call Text(8 , Text_back)

    'texto numero = 6X7=42
    Point_calc = 100000
    While Point_calc > 0
        Long_ = Point / Point_calc
        Mx = Long_ Mod 10
        Restore Numbers
        For My = 1 To Mx
            For Mz = 0 To 4
                Read Cor
            Next Mz
        Next My
        Call Text(1 , Text_back)
        Point_calc = Point_calc / 10
    Wend

    B2 = Text_back
    Call Space_(13 , 7)

    Call Ending

'---------------------------------------------------------------------
'-------------------------------Level---------------------------------

    Call Header_y(200 , 200 , 58 , 64)

    'espaço
    B2 = Paper
    Call Space_(31 , 7)

    'texto numero = 2X7=14
    Cnt = 10
    While Cnt > 0
        Integer_ = Level / Cnt
        Mx = Integer_ Mod 10
        Restore Numbers
        For My = 1 To Mx
            For Mz = 0 To 4
                Read Cor
            Next Mz
        Next My
        Call Text(1 , Paper)
        Cnt = Cnt / 10
    Wend

    'B2 = Paper
    'Call Space_(87 , 7)

    Call Ending

End Sub

'---------------------------------------------------------------------
'-------------------------------Text----------------------------------
'---------------------------------------------------------------------

Sub Text(byval Char_pos As Byte , Byval Cor_back As Byte)
    'Largura total = 132 // 7 pixeis por caractere
    For X2 = 1 To Char_pos                                  'fonte 5x7
        For X = 1 To 5
            Read K
            Byte_ = 1
            For Y = 0 To 6
                B2 = K And Byte_
                If B2 <> 0 Then
                    B2 = 255
                Else
                    B2 = Cor_back
                End If
                Call Clock
                Byte_ = Byte_ * 2
            Next Y
        Next X
        B2 = Cor_back
        For Y = 1 To 14
            Call Clock                                      '2 pixeis entre caracteres
        Next Y
    Next X2
End Sub

'---------------------------------------------------------------------
'------------------------------Text_space-----------------------------
'---------------------------------------------------------------------

Sub Space_(byval Esp_x As Byte , Byval Esp_y As Byte)
    For X = 1 To Esp_x
        For Y = 1 To Esp_y
            Call Clock
        Next Y
    Next X
End Sub

'---------------------------------------------------------------------
'------------------------------Game_over------------------------------
'---------------------------------------------------------------------

Sub Game_over
    For Rep = 1 To 200
        Byte_ = Matrix(rep)
        If Byte_ <> Back Then Matrix(rep) = &H50            'cinza
    Next Rep

    For Rep = 0 To 19
        Call Print_matrix_line(9 , Rep)
        Waitms 100
    Next Rep

    Waitms 500
    Call Ranking
   'The End
    Do
    Loop
End Sub

'---------------------------------------------------------------------
'------------------------------Check_lines----------------------------
'---------------------------------------------------------------------

Sub Check_lines
    Dim Search As Byte
    Dim Sx As Byte
    Dim Sy As Byte

    Dim Lines_made As Byte
    Dim Level_multi As Integer

    'Linha / Pontos (multiplica pelo nivel+1):  Nintendo rules
    '1L = 40P
    '2L = 100P
    '3L = 300P
    '4L = 1200P
    '40 *(n + 1) ' 100 *(n + 1) ' 300 *(n + 1) '1200 *(n + 1)

    Lines_made = 0
    Do
        K = 0
        For Sy = 19 To 1 Step -1
            My = Sy * 10

            Search = 0

            For Sx = 1 To 10
                Mz = My + Sx
                If Matrix(mz) <> Back Then Search = Search + 1
            Next Sx


        ''''''''''Pontua
            If Search = 10 Then                                 'apaga linha
                For Cnt = Sy To 1 Step -1
                    My = Cnt * 10
                    For Mx = 1 To 10
                        Mz = My + Mx
                        Byte_ = Mz - 10
                        Matrix(mz) = Matrix(byte_)
                    Next Mx
                Next Cnt
                For Sx = 1 To 20
                    Call Print_matrix_line(9 , Sx)
                Next Sx
                K = 1

                Incr Level_inc                                  'somatório de linhas para mudar de nível
                If Level_inc = 10 Then                          'linhas por nível
                    If Level < 21 Then Incr Level
                    Level_inc = 0
                End If

                Incr Lines_made
            End If
        Next Sy
    Loop Until K = 0                                        'podem ficar linhas por remover

    '40 *(n + 1) ' 100 *(n + 1) ' 300 *(n + 1) '1200 *(n + 1)
    'Adição das linhas sob nível à pontuação
    If Point < 1000000 And Lines_made > 0 Then              'limite permitido
        Level_multi = Level + 1
        Select Case Lines_made
            Case 1:
                Level_multi = Level_multi * 40
                Point = Point + Level_multi
            Case 2:
                Level_multi = Level_multi * 100
                Point = Point + Level_multi
            Case 3:
                Level_multi = Level_multi * 300
                Point = Point + Level_multi
            Case 4:
                Level_multi = Level_multi * 1200
                Point = Point + Level_multi
        End Select

    End If


End Sub

'---------------------------------------------------------------------
'----------------------------Copy_ok_to_matrix------------------------
'---------------------------------------------------------------------

Sub Copy_ok_to_matrix

    My = Ok_sector_y * 10

    For Cnt = 1 To 40
        Mz = My + Cnt
        Matrix(mz) = Matrix_sector_ok(cnt)
    Next Cnt

End Sub

'---------------------------------------------------------------------
'-------------------------Show_matrix_lines---------------------------
'---------------------------------------------------------------------

Sub Show_matrix_lines(byval Y_pos As Byte)
    Dim See_y As Byte
    Dim See_lines As Byte

    For See_y = 0 To 3
        See_lines = See_y + Y_pos
        If See_lines < 21 Then
            Call Print_matrix_line(see_y , See_lines)
        End If
    Next
End Sub

'---------------------------------------------------------------------
'--------------------Sprite_to_sector_colide--------------------------
'------------grava o sprite no sector / verifica colisões-------------

Sub Sprite_to_sector_colide

    Colide = 0

     'verificação se a deslocação lateral e rotação está dentro dos limites (fica confuso verificar mais à frente)
    Colide = 0
    For Y = 0 To 3
        For X = 1 To 4
        'posição do sprite
            My = Y * 4
            Mz = My + X
            Cor = Sprite(mz)

        'posição de Matrix_sector
            My = Y * 10
            Mx = Go_x + X
            Mz = My + Mx

            If Cor <> Back Then                                 'cor encontrada
                If Mx < 1 Or Mx > 10 Then                        'fora dos limites
                    Colide = 1
                    Exit Sub
                End If
                If Matrix_sector(mz) <> Back Then                'vai sobrepor cor
                    Colide = 1
                    Exit Sub
                Else
                    Matrix_sector(mz) = Cor
                End If
            End If

        Next X
    Next Y

End Sub

'---------------------------------------------------------------------
'------------------------Get_matrix_sector----------------------------
'---------------------------------------------------------------------

Sub Get_matrix_sector(byval Line_ As Byte)
    Dim Sector As Byte
    Sector = Line_ * 10

    For Y = 0 To 3
        For X = 1 To 10
            My = Y * 10
            Byte_ = My + X
            Mx = Sector + Byte_
            Matrix_sector(byte_) = Matrix(mx)
        Next X
    Next Y

End Sub

'---------------------------------------------------------------------
'-----------------------Rotate_sprite---------------------------------
'---------------------------------------------------------------------

Sub Rotate_sprite(byval Id1 As Byte)
    Dim Orig As Byte
    Dim Dest As Byte

    Colide = 0

    'Quadrado não roda
    If Id1 = 3 Then Exit Sub

    'Limpar destino & backup de Sprite
    For X = 1 To 16
        Sprite_tmp(x) = Back
        Sprite_ok(x) = Sprite(x)
    Next X

    'Pau
    If Id1 = 0 Then
        X2 = 3
        Y2 = 3
    Else
        X2 = 2
        Y2 = 2
    End If

     '0..2    pau=0..3
    For Y = 0 To Y2
        For X = 0 To X2
            If Id = 0 Then
               'Pau, S, Z: só duas posições
                Dest = X * 4
                Dest = Dest + Y
                Dest = Dest + 1
            Else
                Dest = X2 - X
                Dest = Dest * 4
                Dest = Dest + Y
                Dest = Dest + 1
            End If
            Orig = Y * 4
            Orig = Orig + X
            Orig = Orig + 1
            Sprite_tmp(dest) = Sprite(orig)
        Next X
    Next Y

    For X = 1 To 16
        Sprite(x) = Sprite_tmp(x)
    Next X
End Sub

'---------------------------------------------------------------------
'----------------------------Clock------------------------------------
'---------------------------------------------------------------------

Sub Clock

        'Regist + Clock
    Send_c = B2
    Send_b = B2 And &B111111

        'Shift Send_c , Right , 6 Demora mais tempo desta forma
    Sw = 0
    Sw.0 = Send_c.6
    Sw.1 = Send_c.7

    Send_c1 = &B11000 Or Sw
    Send_c2 = &B11100 Or Sw

    Portd = B1
    Portb = Send_b
    Portc = Send_c1
    Portd = B1
    Portb = Send_b
    Portc = Send_c2
    Portd = B1
    Portb = Send_b
    Portc = Send_c1
    Portd = B1
    Portb = Send_b
    Portc = Send_c2
End Sub

'---------------------------------------------------------------------
'-----------------------Print_matrix_line-----------------------------
'---------------------------------------------------------------------

Sub Print_matrix_line(byval Array_ As Byte , Byval Line_n As Byte)
    Dim Cor_x As Byte
    Dim Cor_y As Byte
    Dim Cor_xy As Byte

    Dim X_fx As Byte
    Dim Y_fx As Byte

    Dim Byte_1_start As Byte
    Dim Byte_2_start As Byte
    Dim Byte_1_end As Byte
    Dim Byte_2_end As Byte

       'Secção


         'quadro superior
    If Line_n < 6 Then
        Byte_1_start = 200
        Integer_ = Line_n * 12
        Byte_2_start = Integer_ + 104
         'quadro inferior
    Else
        Byte_2_start = 200
        Integer_ = Line_n - 6
        Integer_ = Integer_ * 12
        If Integer_ > 163 Then Integer_ = 200
        Byte_1_start = Integer_
    End If

    Byte_1_end = Byte_1_start + 11
    Byte_2_end = Byte_2_start + 11

    Call Header_y(byte_1_start , Byte_1_end , Byte_2_start , Byte_2_end)



        '5 back, 1 white, 4x12 black, "4x12 sprite", 2x12 black, 1 wite, 5 black

    B1 = Paper
    B2 = Paper
    For Byte_ = 1 To 60
        Call Clock
    Next Byte_


    B1 = 255
    B2 = 255
    For X = 1 To 12
        Call Clock
    Next X


    For X = 0 To 9
        If Array_ <> 9 Then                             '9 = apagar rasto
            My = Array_ * 10
            Mz = My + X
            Mz = Mz + 1
            Cor = Matrix_sector_ok(mz)
        Else
            My = Line_n * 10
            Mz = My + X
            Mz = Mz + 1
            Cor = Matrix(mz)
        End If

        For Y_fx = 1 To 12
            Cor_y = Fx_sprite(y_fx)
            For X_fx = 1 To 12
                If Cor = Back Then
                    B1 = Back
                    B2 = Back
                Else
                    Cor_x = Cor + Fx_sprite(x_fx)
                    Cor_xy = Cor_x + Cor_y
                    B1 = Cor_xy
                    B2 = Cor_xy
                End If
                Call Clock
            Next X_fx
        Next Y_fx

    Next X

    B1 = 255
    B2 = 255
    For X = 1 To 12
        Call Clock
    Next X

    B1 = Paper
    B2 = Paper
    For X = 1 To 60
        Call Clock
    Next X

    Call Ending
End Sub

'---------------------------------------------------------------------
'-------------------------Background_screen---------------------------
'---------------------------------------------------------------------

           'Next = Y= 42 to 62
           '80=paper; 50=sprite; 12=random
           'Texto  largura total = 132
Sub Background_screen
    Call Header

    For X = 0 To 131
        For Y = 0 To 175
            B1 = Paper
            B2 = Paper
            For K = 1 To 2
           'Paper
                Kb(k) = Paper

           'Paper
                If Y < 104 Then
                    Integer_ = Y + X
                    Integer_ = Integer_ And 7
                    If Integer_ = 1 Then Kb(k) = Paper -1
                    Integer_ = Y - X
                    Integer_ = Integer_ And 7
                    If Integer_ = 1 Then Kb(k) = Paper -1

              'Blocos Para Escrita
                    If Y > 4 And Y < 16 Then Kb(k) = Text_back    'box texto score
                    If Y > 29 And Y < 41 Then Kb(k) = Text_back   'box texto level / next
                End If

           'Moldura H or V
                If X > 4 And X < 127 Then
                    If Y = 103 Or Y = 344 Then
                        Kb(k) = 255
                    End If
                End If
                If X = 5 Or X = 126 Then
                    If Y > 103 And Y < 344 Then
                        Kb(k) = 255
                    End If
                End If

           'Fundo do jogo
                If X > 5 And X < 126 Then
                    If Y > 104 And Y < 343 Then
                        Kb(k) = Back
                    End If
                End If

                Y = Y + 176
            Next K
            Y = Y - 352

            B1 = Kb(2)
            B2 = Kb(1)
       'Regist + Clock
            Call Clock
        Next Y
    Next X

    Call Ending
'---------------------------------------------------------------------
'-------------------------------Texto---------------------------------
'---------------------------------------------------------------------
'-------------------------------Texto---------------------------------
    '21 + LEVEL & NEXT (91) + 20 = 132
    Call Header_y(200 , 200 , 32 , 38)
    B2 = Text_back
    Call Space_(21 , 7)
    Restore Level_next
    Call Text(13 , Text_back)                               '91 = nº de caracteres
    B2 = Text_back
    Call Space_(20 , 7)
    Call Ending

End Sub

'---------------------------------------------------------------------
'-------------------------------Show_logo-----------------------------
'---------------------------------------------------------------------

Sub Show_logo
    Call Header
    Restore Logo
    For X = 0 To 131
        For Y = 0 To 175

            If Y < 71 Or Y > 170 Then
                B2 = 0
                B1 = 0
                Call Clock
            Else
                Read Cor
                B2 = Cor
                B1 = 0
                Call Clock
            End If

        Next Y
    Next X

    Call Ending
End Sub

'---------------------------------------------------------------------
'---------------------------Get_sprite--------------------------------
'---------------------------------------------------------------------

Sub Get_sprite(byval Spr As Byte)
    Local Flash As Word
    Spr = Spr * 16
    Restore Sprites

    For Mx = 0 To Spr
        Read Cor
    Next Mx

    For Mx = 1 To 16
        If Cor = 0 Then Cor = Back
        Sprite(mx) = Cor
        Read Cor
    Next Mx
End Sub

'---------------------------------------------------------------------
'----------------------------Header-----------------------------------
'---------------------------------------------------------------------

Sub Header
    Restore Head

    For Byte_ = 0 To 103

        Read B1
        Read B2
        Read B_crt

        Send_b = B2 And &B111111
        'Shift B2 , Right , 6
        Sw = 0
        Sw.0 = B2.6
        Sw.1 = B2.7

        Crt = B_crt And &B11100
        Send_c = Crt Or Sw
        Portd = B1
        Portb = Send_b
        Portc = Send_c
    Next Byte_
End Sub

'---------------------------------------------------------------------
'----------------------------Header_y---------------------------------
'---------------------------------------------------------------------

Sub Header_y(byval B1_start As Byte , Byval B1_end As Byte , Byval B2_start As Byte , Byval B2_end As Byte )


    Restore Head
    For Cnt = 0 To 103
        Read B1
        Read B2
        Read B_crt

        'Começo da escrita
        If Cnt = 94 Then
            B1 = B1_start
            B2 = B2_start
        End If

        'Final da escrita
        If Cnt = 96 Then
            B1 = B1_end
            B2 = B2_end
        End If

        Send_b = B2 And &B111111
        'Shift B2 , Right , 6
        Sw = 0
        Sw.0 = B2.6
        Sw.1 = B2.7

        Crt = B_crt And &B11100
        Send_c = Crt Or Sw
        Portd = B1
        Portb = Send_b
        Portc = Send_c
    Next Cnt


End Sub

'---------------------------------------------------------------------
'----------------------------Ending-----------------------------------
'---------------------------------------------------------------------

Sub Ending
    Restore Foot
    For Cnt = 0 To 9
        Read B1
        Read B2
        Read B_crt

        Send_b = B2 And &B111111
        'Shift B2 , Right , 6
        Sw = 0
        Sw.0 = B2.6
        Sw.1 = B2.7

        Crt = B_crt And &B11100
        Send_c = Crt Or Sw
        Portd = B1
        Portb = Send_b
        Portc = Send_c
    Next Cnt
End Sub

'---------------------------------------------------------------------
'----------------------------Ranking----------------------------------
'---------------------------------------------------------------------

Sub Ranking
    Dim Position As Byte
    Dim Scores(5) As Long
    Dim Regist As Byte
    Dim Reg_pos As Byte
    Dim Offset_pos As Byte
    Dim Value As Long
    Dim Result As Long
    Dim Y_start As Byte
    Dim Y_end As Byte
    Dim Order As Byte
    Dim Find As Byte
    Dim Eep As Byte

   'Lê 5 lugares da eeprom e regista em Scores(n)
    For Position = 0 To 4
        Value = 0
        For Offset_pos = 0 To 3
            Reg_pos = Position * 4
            Reg_pos = Reg_pos + Offset_pos
            Readeeprom Regist , Reg_pos
            Shift Value , Left , 8
            Value = Value + Regist
        Next Offset_pos
        Scores(position + 1) = Value
    Next Position


   'Verifica se a pontuação dá lugar no pódio

    For Position = 1 To 5
        Value = Scores(position)
      'Se posição for encontrada, entra no pódio
        If Point > Value Then
            Position = Position + 1
            For Reg_pos = 5 To Position Step -1
                Order = Reg_pos - 1
                Scores(reg_pos) = Scores(order)
            Next Reg_pos
            Position = Position - 1
            Scores(position) = Point

            Reg_pos = 0
         'Grava EEPROM
            For Eep = 1 To 5
                Value = Scores(eep)

                Result = &HFF000000 And Value
                Shift Result , Right , 24
                Regist = Result
                Writeeeprom Regist , Reg_pos
                Incr Reg_pos

                Result = &HFF0000 And Value
                Shift Result , Right , 16
                Regist = Result
                Writeeeprom Regist , Reg_pos
                Incr Reg_pos

                Result = &HFF00 And Value
                Shift Result , Right , 8
                Regist = Result
                Writeeeprom Regist , Reg_pos
                Incr Reg_pos

                Result = &HFF And Value
                Regist = Result
                Writeeeprom Regist , Reg_pos
                Incr Reg_pos
            Next Eep

            Exit For
        End If
    Next Position


   'Apresenta todas as 5 posições
    For Position = 1 To 5

        Value = Scores(position)
        If Value = Point Then
            Find = &HE0
        Else
            Find = Back
        End If

        Y_start = Position * 12
        Y_start = Y_start + 100
        Y_end = Y_start + 6
        Call Header_y(200 , 200 , Y_start , Y_end)

      'entrada esquerda
        B1 = Paper
        B2 = Paper
        Call Space_(5 , 7)
        B1 = 255
        B2 = 255
        Call Space_(1 , 7)
        B1 = Back
        B2 = Back
        Call Space_(29 , 7)
        B1 = Find
        B2 = Find
        Call Space_(2 , 7)


      'Nº da posição
        Restore Numbers
        For My = 1 To Position
            For Mz = 0 To 4
                Read Cor
            Next Mz
        Next My
        Call Text(1 , Find)
        Call Space_(1 , 7)
        Restore Hifen
        Call Text(1 , Find)
        Call Space_(1 , 7)

      'Pódio
        Point_calc = 100000
        While Point_calc > 0
            Long_ = Value / Point_calc
            Mx = Long_ Mod 10
            Restore Numbers
            For My = 1 To Mx
                For Mz = 0 To 4
                    Read Cor
                Next Mz
            Next My

            Call Text(1 , Find)

            Point_calc = Point_calc / 10
        Wend

      'saída direita
        B1 = Back
        B2 = Back
        Call Space_(31 , 7)
        B1 = 255
        B2 = 255
        Call Space_(1 , 7)
        B1 = Paper
        B2 = Paper
        Call Space_(5 , 7)

        Call Ending
    Next Position

End Sub

'---------------------------------------------------------------------
'------------------Default values for podium------------------------
$eeprom

Data &H00 , &H00 , &HC3 , &HCB                              '50123
Data &H00 , &H00 , &H9C , &HBB                              '40123
Data &H00 , &H00 , &H75 , &HAB                              '30123
Data &H00 , &H00 , &H4E , &H9B                              '20123
Data &H00 , &H00 , &H27 , &H8B                              '10123

$data

End

'Header 104x3Bytes (nova versão com inversão de escrita)
Head:
    Data &H00 , &H00 , &H1E , &H00 , &H00 , &H1F , &H00 , &H00 , &H17 , &H7F , &H7F , &H11 , &H7F , &H7F , &H17 , &H73 , &H73 , &H11 , &H73 , &H73 , &H17 , &H7F , &H7F , &H11 , &H7F , &H7F
    Data &H17 , &H77 , &H77 , &H11 , &H77 , &H77 , &H17 , &H77 , &H77 , &H1F , &H77 , &H77 , &H17 , &H2C , &H2C , &H11 , &H2C , &H2C , &H17 , &H2C , &H2C , &H1F , &HF9 , &HF9 , &H11 , &HF9
    Data &HF9 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &HC0 , &HC0 , &H11 , &HC0 , &HC0 , &H17 , &H40 , &H40 , &H11 , &H40 , &H40 , &H17
    Data &H40 , &H40 , &H1F , &H40 , &H40 , &H17 , &H06 , &H0A , &H11 , &H2E , &H22 , &H17 , &H18 , &H18 , &H11 , &H18 , &H18 , &H17 , &H00 , &H38 , &H11 , &H00 , &H38 , &H17 , &H02 , &H02
    Data &H11 , &H02 , &H02 , &H17 , &H02 , &H01 , &H11 , &H02 , &H01 , &H17 , &H02 , &H01 , &H1F , &H24 , &H24 , &H11 , &H24 , &H24 , &H17 , &H33 , &H33 , &H11 , &H33 , &H33 , &H17 , &H20
    Data &H20 , &H11 , &H20 , &H20 , &H17 , &H01 , &H01 , &H11 , &H01 , &H01 , &H17 , &H01 , &H01 , &H1F , &H22 , &H22 , &H11 , &H22 , &H22 , &H17 , &H22 , &H22 , &H11 , &H22 , &H22 , &H17
    Data &H36 , &H36 , &H11 , &H36 , &H36 , &H17 , &H20 , &H20 , &H11 , &H20 , &H20 , &H17 , &H2A , &H2A , &H11 , &H2A , &H2A , &H17 , &H2A , &H2A , &H1F , &HA9 , &HA9 , &H11 , &HA9 , &HA9
    Data &H17 , &H26 , &H26 , &H11 , &H26 , &H26 , &H17 , &H00 , &H10 , &H11 , &H00 , &H10 , &H17 , &H00 , &H10 , &H1F , &H00 , &H10 , &H17 , &H10 , &H10 , &H11 , &H10 , &H10 , &H17 , &H10
    Data &H10 , &H1F , &H10 , &H10 , &H17 , &H33 , &H31 , &H11 , &H33 , &H31 , &H17 , &H34 , &H34 , &H11 , &H34 , &H34 , &H17 , &H34 , &H34 , &H1F , &H13 , &H13 , &H11 , &H13 , &H13 , &H17
    Data &H30 , &H30 , &H11 , &H30 , &H30 , &H17 , &H12 , &H12 , &H11 , &H12 , &H12 , &H17 , &H28 , &H28 , &H11 , &H28 , &H28 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &H32 , &H32
    Data &H11 , &H32 , &H32 , &H17 , &H02 , &H02 , &H11 , &H02 , &H02 , &H17 , &H02 , &H02 , &H1F , &H42 , &H42 , &H11 , &H42 , &H42 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &HAF
    Data &HAF , &H11 , &HAF , &HAF , &H17 , &H43 , &H43 , &H11 , &H43 , &H43 , &H17 , &H00 , &H00 , &H11 , &H00 , &H00 , &H17 , &H83 , &H83 , &H11 , &H83 , &H83 , &H17 , &H83 , &H83 , &H1F


'End 10x3Bytes
Foot:
    Data &H2C , &H24 , &H19 , &H1F , &HBF , &H1F , &H1F , &HBF , &H17 , &H1F , &HBF , &H11 , &H51 , &H51 , &H17
    Data &H51 , &H51 , &H11 , &H53 , &H53 , &H17 , &H53 , &H53 , &H11 , &H00 , &H00 , &H17 , &H00 , &H00 , &H1F

'       0        1          2         3        4          5         6
'  ..........  .....#..  #......  ##....  ..#.....  ##.....  ....##
'  ####  ###..  ###..  ##....  ###..  .....##  ##....

'Sprites = 7 peças x 16 bytes
Sprites:
    Data &H00 , &H00 , &H00 , &H00 , &H5B , &H5B , &H5B , &H5B , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00
    Data &H00 , &H00 , &HE2 , &H00 , &HE2 , &HE2 , &HE2 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00
    Data &H51 , &H00 , &H00 , &H00 , &H51 , &H51 , &H51 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00
    Data &HC3 , &HC3 , &H00 , &H00 , &HC3 , &HC3 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00
    Data &H00 , &HD9 , &H00 , &H00 , &HD9 , &HD9 , &HD9 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00
    Data &HC8 , &HC8 , &H00 , &H00 , &H00 , &HC8 , &HC8 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00
    Data &H00 , &H6B , &H6B , &H00 , &H6B , &H6B , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00

'Efeito 3D nas peças
Fx_sprite_table:
    Data 0 , 0 , 0 , 1 , 1 , 1 , 1 , 1 , 1 , 2 , 2 , 2

'/// Fonte ///
Level_next:
'_level:
    Data &H7F , &H40 , &H40 , &H40 , &H40                       'L
    Data &H7F , &H49 , &H49 , &H49 , &H41                       'E
    Data &H1F , &H20 , &H40 , &H20 , &H1F                       'V
    Data &H7F , &H49 , &H49 , &H49 , &H41                       'E
    Data &H7F , &H40 , &H40 , &H40 , &H40                       'L
'_space:
    Data &H00 , &H00 , &H00 , &H00 , &H00                       'space
    Data &H00 , &H00 , &H00 , &H00 , &H00                       'space
    Data &H00 , &H00 , &H00 , &H00 , &H00                       'space
    Data &H00 , &H00 , &H00 , &H00 , &H00                       'space
'next
    Data &H7F , &H04 , &H08 , &H10 , &H7F                       'N
    Data &H7F , &H49 , &H49 , &H49 , &H41                       'E
    Data &H63 , &H14 , &H08 , &H14 , &H63                       'X
    Data &H01 , &H01 , &H7F , &H01 , &H01                       'T

Score:
    Data &H46 , &H49 , &H49 , &H49 , &H31                       'S
    Data &H38 , &H44 , &H44 , &H44 , &H20                       'c
    Data &H38 , &H44 , &H44 , &H44 , &H38                       'o
    Data &H7C , &H08 , &H04 , &H04 , &H08                       'r
    Data &H38 , &H54 , &H54 , &H54 , &H18                       'e
    Data &H00 , &H00 , &H00 , &H00 , &H00                       'space
    Data &H00 , &H36 , &H36 , &H00 , &H00                       ':
    Data &H00 , &H00 , &H00 , &H00 , &H00                       'space

Numbers:
    Data &H3E , &H51 , &H49 , &H45 , &H3E                       '0
    Data &H00 , &H42 , &H7F , &H40 , &H00                       '1
    Data &H42 , &H61 , &H51 , &H49 , &H46                       '2
    Data &H21 , &H41 , &H45 , &H4B , &H31                       '3
    Data &H18 , &H14 , &H12 , &H7F , &H10                       '4
    Data &H27 , &H45 , &H45 , &H45 , &H39                       '5
    Data &H3C , &H4A , &H49 , &H49 , &H30                       '6
    Data &H01 , &H71 , &H09 , &H05 , &H03                       '7
    Data &H36 , &H49 , &H49 , &H49 , &H36                       '8
    Data &H06 , &H49 , &H49 , &H29 , &H1E                       '9

Hifen:
    Data &H08 , &H08 , &H08 , &H08 , &H08                       '-


    $include "logo.bas"