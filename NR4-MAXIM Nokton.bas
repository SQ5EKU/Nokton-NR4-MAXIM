' Nadajnik Nokton NR4 MAXIM (TX160n) v5.4
' http://sq5eku.blogspot.com/2015/04/nokton-nr4-maxim.html
'
$regfile = "m16def.dat"
'$crystal = 14745600                                         ' 14.7456 MHz
$crystal = 8000000

Dim A1 As Word
Dim A3 As Word
Dim N2 As Word
Dim N3 As Word
Dim Mb_ref As Word                                         
    Mb_sw_ref Alias Mb_ref.15                              
    Mb_c_ref Alias Mb_ref.0                                
Dim Mb_swallow As Byte                                     
    Mb_c_prog Alias Mb_swallow.0                           
Dim Mb_prog As Word                                        
Dim Mb_n As Word                                           
Dim Mb_n_h As Byte
Dim Mb_n_l As Byte
Dim Tmp As Bit                                             

Declare Sub Lmx_tx
Declare Sub Le_pulse

Config Pina.0 = Input                                       ' ADC VCC-12V nadajnika
Config Pina.1 = Input                                       ' wejscie IN2
Config Pina.2 = Input                                       ' wejscie IN3
Config Pina.3 = Input                                       ' wejscie IN4
Config Pina.4 = Input                                       ' wejscie IN5
Config Pina.5 = Input                                       ' wejscie IN6
Config Pina.6 = Input                                       ' wejscie IN7
Config Pina.7 = Input                                       ' wejscie IN8

Config Pinb.0 = Input                                       ' wejscie IN1
Config Pinb.1 = Input                                       ' info o mocy wyjsciowej TX 0=ON , 1=OFF
Config Portb.2 = Output                                     ' LED czerwona (D3)
Config Pinb.3 = Input                                       ' wejscie IN9
Config Pinb.4 = Input                                       ' wejscie IN10
Config Portb.5 = Output                                     ' CLK LMX1501A
Config Portb.6 = Output                                     ' DATA LMX1501A
Config Pinb.7 = Input                                       ' wejscie SAB

Config Portc.1 = Output                                     ' 8V VCC 2 x TL064 (modulacja) 0=ON , 1=OFF
Config Pinc.2 = Input                                       ' wejscie AC-16V
Config Pinc.3 = Input
Config Portc.4 = Output                                     ' LED zielona (D4)
Config Portc.5 = Output                                     ' "syrena do 100mA"
Config Portc.7 = Output                                     ' do ukladu ladowania AKU

Config Portd.1 = Output
Config Portd.2 = Output                                     ' Zalaczanie drivera TX
Config Portd.3 = Output
Config Portd.4 = Output
Config Portd.5 = Output                                     ' zasilanie VCO 0=ON , 1=OFF
Config Pind.6 = Input                                       ' Lock Detect PLL
Config Portd.7 = Output                                     ' LE LMX1501A

Lmx_clk Alias Portb.5                                       ' CLK LMX1501A
Lmx_data Alias Portb.6                                      ' DATA LMX1501A
Lmx_le Alias Portd.7                                        ' LE LMX1501A
Tx_drv Alias Portd.2                                        ' Zalaczanie drivera TX
Ptt_test Alias Pinc.3                                       ' SW "TEST" na PCB
Led_red Alias Portb.2                                       ' LED D3 (czerwona)
Led_gren Alias Portc.4                                      ' LED D4 (zielona)
Lmx_lock Alias Pind.6                                       ' Lock Detect PLL
Tx_vco Alias Portd.5                                        ' Zalaczanie VCO TX
Pwr_0 Alias Portd.4                                         ' poziom mocy
Pwr_1 Alias Portd.3                                         ' poziom mocy
8v_mod Alias Portc.1                                        ' zasilanie 8V 2 x TL062
12v_adc Alias Pina.0                                        ' wejscie pomiarowe napiecia zasilania nadajnika (12V)
Pwr_ctrl Alias Pinb.1                                       ' obecnosc mocy na wyjsciu nadajnika

Lmx_le = 0
Lmx_clk = 0
Lmx_data = 0
Tx_drv = 1
Tx_vco = 1
Led_red = 1
Led_gren = 1
Ptt_test = 1
Lmx_lock = 1
Pwr_0 = 0
Pwr_1 = 0
8v_mod = 1

Mb_ref = 1040 * 2                                          
Mb_prog = 11584                                            
'Mb_prog = 13611                                            

Mb_c_ref = 1                                               
Mb_c_prog = 0                                              


Config Watchdog = 256
Start Watchdog


'-------------------------------------------------------------  glowna petla

Do

If Tmp = 0 Then
 If Ptt_test = 0 Then                                       ' jesli PTT wlaczone idz dalej
  Tx_vco = 0                                                ' wlacz zasilanie VCO
  8v_mod = 0                                                ' wlacz zasilanie 8V 2 x TL062
  Gosub Lmx_tx
  Waitms 20                                                 ' odczekaj 20ms na synchro PLL
   If Lmx_lock = 0 Then
    Tx_drv = 0                                              ' wlacz zasilanie drivera TX
    Led_red = 0                                             ' wlacz czerwona LED D3
    Tmp = 1
   Else
    Tx_vco = 1
    Tmp = 1
   End If
 End If
End If

If Tmp = 1 Then
 If Ptt_test = 1 Then
  Tx_drv = 1                                                ' wylacz zasilanie VCO i PLL
  Tx_vco = 1                                                ' wylacz zasilanie wzmaniaczy w.cz
  Led_red = 1                                               ' wylacz czerwona LED D3
  8v_mod = 1
  Tmp = 0
 End If
End If


Reset Watchdog
Loop
End

'-------------------------------------------------------------  koniec glownej petli programu


Lmx_tx:
'
N2 = Mb_prog / 64
A1 = Mb_prog Mod 64
N3 = Mb_prog / 128
A3 = Mb_prog Mod 128
  If A3 < N3 Then
 Mb_n = N3
 Mb_swallow = A3 * 2
 Mb_sw_ref = 0
  Else
 Mb_n = N2
 Mb_swallow = A1 * 2
 Mb_sw_ref = 1
  End If

Shiftout Lmx_data , Lmx_clk , Mb_ref , 0                   

Gosub Le_pulse

Mb_n_h = High(mb_n)
Mb_n_l = Low(mb_n)
Shiftout Lmx_data , Lmx_clk , Mb_n_h , 0 , 3               
Shiftout Lmx_data , Lmx_clk , Mb_n_l , 0                   
Shiftout Lmx_data , Lmx_clk , Mb_swallow , 0               

Gosub Le_pulse

Return

Le_pulse:
 nop
 Set Lmx_le
 nop
 Reset Lmx_le
Return
