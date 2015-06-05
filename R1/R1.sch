v 20110115 2
C 40000 40000 0 0 0 title-B.sym
C 48200 43000 1 0 0 W65C02.sym
{
T 48208 48693 5 10 0 0 0 0 1
device=W65C02
T 48208 47893 5 10 0 0 0 0 1
footprint=DIP40
T 49108 42993 5 10 1 1 0 0 1
refdes=U1
}
C 40300 50300 1 180 1 connector2-1.sym
{
T 40500 49300 5 10 0 0 180 6 1
device=CONNECTOR_2
T 40300 49500 5 10 1 1 180 6 1
refdes=SUPPLY
T 40600 50100 5 10 0 1 0 0 1
footprint=JUMPER2
}
C 43200 42300 1 0 0 ATmega32DIP.sym
{
T 43208 47993 5 10 0 0 0 0 1
device=ATmega32DIP
T 43208 47193 5 10 0 0 0 0 1
footprint=DIP40
T 44108 42293 5 10 1 1 0 0 1
refdes=U2
}
C 50000 49500 1 90 0 led-3.sym
{
T 49350 50450 5 10 0 0 90 0 1
device=LED
T 50050 49850 5 10 1 1 0 0 1
refdes=D2
T 49800 50000 5 10 0 1 0 0 1
footprint=LED 118
}
C 40500 45000 1 90 0 diode-1.sym
{
T 39900 45400 5 10 0 0 90 0 1
device=DIODE
T 40400 45100 5 10 1 1 0 0 1
refdes=D1
T 40300 45400 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 49900 48600 1 90 0 resistor-2.sym
{
T 49550 49000 5 10 0 0 90 0 1
device=RESISTOR
T 50000 49100 5 10 1 1 0 0 1
refdes=R2
T 49900 48600 5 10 0 1 0 0 1
footprint=AXIAL_LAY 300
}
C 49700 48300 1 0 0 gnd-1.sym
C 45000 40200 1 0 0 gnd-1.sym
N 44900 40700 45000 40700 4
N 45100 40600 45100 40500 4
N 45000 40700 45100 40600 4
C 42100 49300 1 0 0 gnd-1.sym
N 42000 49800 42100 49800 4
N 42200 49700 42200 49600 4
N 42100 49800 42200 49700 4
C 40900 43900 1 90 0 capacitor-1.sym
{
T 40200 44100 5 10 0 0 90 0 1
device=CAPACITOR
T 40800 44000 5 10 1 1 0 0 1
refdes=C1
T 40000 44100 5 10 0 0 90 0 1
symversion=0.1
T 40700 44400 5 10 0 1 0 0 1
footprint=CAP_SMALL-200
}
C 41200 45000 1 90 0 resistor-2.sym
{
T 40850 45400 5 10 0 0 90 0 1
device=RESISTOR
T 41300 45500 5 10 1 1 0 0 1
refdes=R1
T 41300 45300 5 10 1 1 0 0 1
value=3k3
T 41200 45000 5 10 0 1 0 0 1
footprint=AXIAL_LAY 300
}
C 40600 43600 1 0 0 gnd-1.sym
C 40100 45900 1 0 0 vcc-1.sym
C 40900 45900 1 0 0 vcc-1.sym
N 44900 41000 45100 41000 4
{
T 45200 41000 4 8 1 1 0 1 1
netname=RX0
}
N 44900 41300 45100 41300 4
{
T 45200 41300 4 8 1 1 0 1 1
netname=TX0
}
N 41100 45000 41100 44900 4
N 40300 45000 40300 44900 4
N 40300 44900 41300 44900 4
{
T 41400 44900 4 8 1 1 0 1 1
netname=\_RESET\_
}
N 40700 44800 40700 44900 4
N 50200 45600 51200 45600 4
{
T 50300 45600 4 8 1 1 0 0 1
netname=D1
}
N 50200 45400 51200 45400 4
{
T 50300 45400 4 8 1 1 0 0 1
netname=D2
}
N 50200 45200 51200 45200 4
{
T 50300 45200 4 8 1 1 0 0 1
netname=D3
}
N 50200 45000 51200 45000 4
{
T 50300 45000 4 8 1 1 0 0 1
netname=D4
}
N 50200 44800 51200 44800 4
{
T 50300 44800 4 8 1 1 0 0 1
netname=D5
}
N 50200 44600 51200 44600 4
{
T 50300 44600 4 8 1 1 0 0 1
netname=D6
}
N 50200 44400 51200 44400 4
{
T 50300 44400 4 8 1 1 0 0 1
netname=D7
}
N 50200 45800 51200 45800 4
{
T 50300 45800 4 8 1 1 0 0 1
netname=D0
}
C 47700 47100 1 0 0 nc-left-1.sym
{
T 47700 47500 5 10 0 0 0 0 1
value=NoConnection
T 47700 47900 5 10 0 0 0 0 1
device=DRC_Directive
}
C 50200 46900 1 0 0 nc-right-1.sym
{
T 50300 47400 5 10 0 0 0 0 1
value=NoConnection
T 50300 47600 5 10 0 0 0 0 1
device=DRC_Directive
}
C 50200 46100 1 0 0 nc-right-1.sym
{
T 50300 46600 5 10 0 0 0 0 1
value=NoConnection
T 50300 46800 5 10 0 0 0 0 1
device=DRC_Directive
}
C 47700 46700 1 0 0 nc-left-1.sym
{
T 47700 47100 5 10 0 0 0 0 1
value=NoConnection
T 47700 47500 5 10 0 0 0 0 1
device=DRC_Directive
}
C 47700 45900 1 0 0 nc-left-1.sym
{
T 47700 46300 5 10 0 0 0 0 1
value=NoConnection
T 47700 46700 5 10 0 0 0 0 1
device=DRC_Directive
}
N 50200 46000 50400 46000 4
{
T 50500 46000 4 8 1 1 0 1 1
netname=RWB
}
N 50200 46600 51300 46600 4
{
T 51100 46500 4 8 1 1 0 1 1
netname=PHI2
}
C 50800 47200 1 0 0 vdd-1.sym
N 50200 46800 50900 46800 4
N 51000 46900 51000 47200 4
N 51000 46900 50900 46800 4
N 50200 47200 50400 47200 4
{
T 50500 47200 4 8 1 1 0 1 1
netname=RESB
}
C 46200 47300 1 90 0 resistor-2.sym
{
T 45850 47700 5 10 0 0 90 0 1
device=RESISTOR
T 46300 47800 5 10 1 1 0 0 1
refdes=R3
T 46300 47600 5 10 1 1 0 0 1
value=3k3
T 46200 47300 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 45900 48200 1 0 0 vdd-1.sym
N 46100 47300 46100 46300 4
N 46200 46200 48200 46200 4
N 46200 46200 46100 46300 4
C 46900 47300 1 90 0 resistor-2.sym
{
T 46550 47700 5 10 0 0 90 0 1
device=RESISTOR
T 47000 47800 5 10 1 1 0 0 1
refdes=R4
T 47000 47600 5 10 1 1 0 0 1
value=3k3
T 46900 47300 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 46600 48200 1 0 0 vdd-1.sym
N 46800 47300 46800 46500 4
N 46900 46400 48200 46400 4
N 46900 46400 46800 46500 4
C 47600 47300 1 90 0 resistor-2.sym
{
T 47250 47700 5 10 0 0 90 0 1
device=RESISTOR
T 47700 47800 5 10 1 1 0 0 1
refdes=R5
T 47700 47600 5 10 1 1 0 0 1
value=3k3
T 47600 47300 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 47300 48200 1 0 0 vdd-1.sym
N 47500 47300 47500 47100 4
N 47600 47000 48200 47000 4
N 47600 47000 47500 47100 4
N 48000 46600 48200 46600 4
{
T 47900 46600 4 8 1 1 0 7 1
netname=IRQB
}
N 47800 45600 48200 45600 4
{
T 47900 45600 4 8 1 1 0 0 1
netname=A0
}
N 47800 45600 47700 45500 4
U 47700 45500 47600 45400 10 0
U 47600 45400 47600 42600 10 0
U 50600 42500 47100 42500 10 0
U 47500 42500 47600 42600 10 0
U 50700 42600 50700 44000 10 0
U 50600 42500 50700 42600 10 0
N 47800 45400 48200 45400 4
{
T 47900 45400 4 8 1 1 0 0 1
netname=A1
}
N 47800 45400 47700 45300 4
U 47700 45300 47600 45200 10 0
N 47800 45200 48200 45200 4
{
T 47900 45200 4 8 1 1 0 0 1
netname=A2
}
N 47800 45200 47700 45100 4
U 47700 45100 47600 45000 10 0
N 47800 45000 48200 45000 4
{
T 47900 45000 4 8 1 1 0 0 1
netname=A3
}
N 47800 45000 47700 44900 4
U 47700 44900 47600 44800 10 0
N 47800 44800 48200 44800 4
{
T 47900 44800 4 8 1 1 0 0 1
netname=A4
}
N 47800 44800 47700 44700 4
U 47700 44700 47600 44600 10 0
N 47800 44600 48200 44600 4
{
T 47900 44600 4 8 1 1 0 0 1
netname=A5
}
N 47800 44600 47700 44500 4
U 47700 44500 47600 44400 10 0
N 47800 44400 48200 44400 4
{
T 47900 44400 4 8 1 1 0 0 1
netname=A6
}
N 47800 44400 47700 44300 4
U 47700 44300 47600 44200 10 0
N 47800 44200 48200 44200 4
{
T 47900 44200 4 8 1 1 0 0 1
netname=A7
}
N 47800 44200 47700 44100 4
U 47700 44100 47600 44000 10 0
N 47800 44000 48200 44000 4
{
T 47900 44000 4 8 1 1 0 0 1
netname=A8
}
N 47800 44000 47700 43900 4
U 47700 43900 47600 43800 10 0
N 47800 43800 48200 43800 4
{
T 47900 43800 4 8 1 1 0 0 1
netname=A9
}
N 47800 43800 47700 43700 4
U 47700 43700 47600 43600 10 0
N 47800 43600 48200 43600 4
{
T 47900 43600 4 8 1 1 0 0 1
netname=A10
}
N 47800 43600 47700 43500 4
U 47700 43500 47600 43400 10 0
N 47800 43400 48200 43400 4
{
T 47900 43400 4 8 1 1 0 0 1
netname=A11
}
N 47800 43400 47700 43300 4
U 47700 43300 47600 43200 10 0
N 50500 44200 50200 44200 4
{
T 50500 44200 4 8 1 1 0 6 1
netname=A15
}
N 50500 44200 50600 44100 4
U 50600 44100 50700 44000 10 0
N 50500 44000 50200 44000 4
{
T 50500 44000 4 8 1 1 0 6 1
netname=A14
}
N 50500 44000 50600 43900 4
U 50600 43900 50700 43800 10 0
N 50500 43800 50200 43800 4
{
T 50500 43800 4 8 1 1 0 6 1
netname=A13
}
N 50500 43800 50600 43700 4
U 50600 43700 50700 43600 10 0
N 50500 43600 50200 43600 4
{
T 50500 43600 4 8 1 1 0 6 1
netname=A12
}
N 50500 43600 50600 43500 4
U 50600 43500 50700 43400 10 0
T 47800 49500 9 10 1 0 0 0 4
BE should be LOW
and PHI2 HIGH
when AVR is being
programmed
N 43000 43700 43200 43700 4
{
T 42900 43700 4 8 1 1 0 7 1
netname=TX0
}
N 43000 43900 43200 43900 4
{
T 42900 43900 4 8 1 1 0 7 1
netname=RX0
}
C 49000 47900 1 90 0 capacitor-1.sym
{
T 48300 48100 5 10 0 0 90 0 1
device=CAPACITOR
T 48900 48500 5 10 1 1 0 0 1
refdes=C5
T 48100 48100 5 10 0 0 90 0 1
symversion=0.1
T 48900 48100 5 10 1 1 0 0 1
value=100n
T 49000 47900 5 10 0 1 0 0 1
footprint=CAP_SMALL-100
}
C 48600 48800 1 0 0 vdd-1.sym
C 48700 47600 1 0 0 gnd-1.sym
C 39200 49100 1 0 0 vcc-1.sym
N 38200 48900 39300 48900 4
N 39400 49000 39400 49100 4
C 38300 47200 1 0 0 gnd-1.sym
N 38200 47700 38300 47700 4
N 38300 47700 38400 47600 4
N 38400 47600 38400 47500 4
N 38400 49200 38200 49200 4
{
T 38500 49200 4 8 1 1 0 1 1
netname=ISP_MISO
}
N 38400 48000 38200 48000 4
{
T 38500 48000 4 8 1 1 0 1 1
netname=\_RESET\_
}
N 38400 48600 38200 48600 4
{
T 38500 48600 4 8 1 1 0 1 1
netname=ISP_SCK
}
N 38400 48300 38200 48300 4
{
T 38500 48300 4 8 1 1 0 1 1
netname=ISP_MOSI
}
N 39400 49000 39300 48900 4
C 36500 47500 1 0 0 connector6-1.sym
{
T 38300 49300 5 10 0 0 0 0 1
device=CONNECTOR_6
T 36600 47300 5 10 1 1 0 0 1
refdes=ISP
T 36800 47900 5 10 0 1 0 6 1
footprint=HEADER6_2
T 36800 48800 5 10 0 1 0 0 1
footprint=HEADER6_2
}
N 43000 44900 43200 44900 4
{
T 42900 44900 4 8 1 1 0 7 1
netname=\_RESET\_
}
U 46500 41800 51300 41800 10 0
T 53900 40400 9 10 1 0 0 0 1
1
T 50100 40700 9 10 1 0 0 0 1
6502 SBC
N 43000 45500 43200 45500 4
{
T 42900 45500 4 8 1 1 0 7 1
netname=MSTR_MOSI
}
N 43000 45300 43200 45300 4
{
T 42900 45300 4 8 1 1 0 7 1
netname=MSTR_MISO
}
N 43000 45100 43200 45100 4
{
T 42900 45100 4 8 1 1 0 7 1
netname=MSTR_SCK
}
N 45200 46300 45800 46300 4
{
T 45300 46300 4 8 1 1 0 0 1
netname=A1
}
N 45200 46100 45800 46100 4
{
T 45300 46100 4 8 1 1 0 0 1
netname=A2
}
N 45200 45900 45800 45900 4
{
T 45300 45900 4 8 1 1 0 0 1
netname=A3
}
N 45200 45700 45800 45700 4
{
T 45300 45700 4 8 1 1 0 0 1
netname=A4
}
N 45200 45500 45800 45500 4
{
T 45300 45500 4 8 1 1 0 0 1
netname=A5
}
N 45200 45300 45800 45300 4
{
T 45300 45300 4 8 1 1 0 0 1
netname=A6
}
N 45200 45100 45800 45100 4
{
T 45300 45100 4 8 1 1 0 0 1
netname=A7
}
N 45200 46500 45800 46500 4
{
T 45300 46500 4 8 1 1 0 0 1
netname=A0
}
C 45200 44800 1 0 0 nc-right-1.sym
{
T 45300 45300 5 10 0 0 0 0 1
value=NoConnection
T 45300 45500 5 10 0 0 0 0 1
device=DRC_Directive
}
N 46200 44300 45200 44300 4
{
T 45500 44300 4 8 1 1 0 6 1
netname=D7
}
N 46200 44300 46300 44200 4
U 46300 44200 46400 44100 10 0
N 46200 44100 45200 44100 4
{
T 45500 44100 4 8 1 1 0 6 1
netname=D6
}
N 46200 44100 46300 44000 4
U 46300 44000 46400 43900 10 0
N 46200 43900 45200 43900 4
{
T 45500 43900 4 8 1 1 0 6 1
netname=D5
}
N 46200 43900 46300 43800 4
U 46300 43800 46400 43700 10 0
N 46200 43700 45200 43700 4
{
T 45500 43700 4 8 1 1 0 6 1
netname=D4
}
N 46200 43700 46300 43600 4
U 46300 43600 46400 43500 10 0
N 46200 43500 45200 43500 4
{
T 45500 43500 4 8 1 1 0 6 1
netname=D3
}
N 46200 43500 46300 43400 4
U 46300 43400 46400 43300 10 0
N 46200 43300 45200 43300 4
{
T 45500 43300 4 8 1 1 0 6 1
netname=D2
}
N 46200 43300 46300 43200 4
U 46300 43200 46400 43100 10 0
N 46200 43100 45200 43100 4
{
T 45500 43100 4 8 1 1 0 6 1
netname=D1
}
N 46200 43100 46300 43000 4
U 46300 43000 46400 42900 10 0
N 46200 42900 45200 42900 4
{
T 45500 42900 4 8 1 1 0 6 1
netname=D0
}
N 46200 42900 46300 42800 4
U 46300 42800 46400 42700 10 0
U 46400 41900 46400 44100 10 0
C 44900 47700 1 90 0 capacitor-1.sym
{
T 44200 47900 5 10 0 0 90 0 1
device=CAPACITOR
T 44800 48300 5 10 1 1 0 0 1
refdes=C21
T 44000 47900 5 10 0 0 90 0 1
symversion=0.1
T 44800 47900 5 10 1 1 0 0 1
value=100n
T 44900 47700 5 10 0 1 0 0 1
footprint=CAP_SMALL-100
}
C 44600 47400 1 0 0 gnd-1.sym
C 44500 48600 1 0 0 vcc-1.sym
N 43000 46100 43200 46100 4
{
T 42900 46100 4 8 1 1 0 7 1
netname=PHI2
}
N 43000 45900 43200 45900 4
{
T 42900 45900 4 8 1 1 0 7 1
netname=RWB
}
N 45200 42700 45400 42700 4
{
T 45500 42700 4 8 1 1 0 1 1
netname=A15
}
N 50400 46400 50200 46400 4
{
T 50500 46400 4 8 1 1 0 1 1
netname=\_RESET\_
}
U 45900 45200 46000 45100 10 0
U 45900 45400 46000 45300 10 0
U 45900 45600 46000 45500 10 0
U 45900 45800 46000 45700 10 0
U 45900 46000 46000 45900 10 0
U 45900 46200 46000 46100 10 0
U 45900 46400 46000 46300 10 0
U 45900 45000 46000 44900 10 0
U 46000 47000 46000 44700 10 0
N 45900 45200 45800 45300 4
N 45900 45400 45800 45500 4
N 45900 45600 45800 45700 4
N 45900 45800 45800 45900 4
N 45900 46000 45800 46100 4
N 45900 46200 45800 46300 4
N 45900 46400 45800 46500 4
N 45900 45000 45800 45100 4
U 46000 44700 46100 44600 10 0
U 46100 44600 46900 44600 10 0
U 47000 44500 47000 42600 10 0
U 46900 44600 47000 44500 10 0
U 47000 42600 47100 42500 10 0
U 45900 47100 42100 47100 10 0
U 45900 47100 46000 47000 10 0
U 42100 47100 42000 47000 10 0
U 42000 47000 42000 42900 10 0
U 46400 41900 46500 41800 10 0
N 51300 44500 51200 44600 4
U 51400 41900 51400 45600 10 0
U 51300 44500 51400 44400 10 0
N 51300 44700 51200 44800 4
U 51300 44700 51400 44600 10 0
N 51300 44900 51200 45000 4
U 51300 44900 51400 44800 10 0
N 51300 45100 51200 45200 4
U 51300 45100 51400 45000 10 0
N 51300 45300 51200 45400 4
U 51300 45300 51400 45200 10 0
N 51300 45500 51200 45600 4
U 51300 45500 51400 45400 10 0
N 51300 45700 51200 45800 4
U 51300 45700 51400 45600 10 0
N 51300 44300 51200 44400 4
U 51300 44300 51400 44200 10 0
U 51300 41800 51400 41900 10 0
C 40700 42200 1 0 0 crystal-1.sym
{
T 40900 42700 5 10 0 0 0 0 1
device=CRYSTAL
T 41050 42500 5 10 1 1 0 3 1
refdes=X2
T 40900 42900 5 10 0 0 0 0 1
symversion=0.1
T 41050 42100 5 10 1 1 0 5 1
value=20M
T 41100 42300 5 10 0 1 0 0 1
footprint=FLANGED_CRYSTAL-1
T 41000 42200 5 10 0 1 0 0 1
footprint=FLANGED_CRYSTAL-1
}
C 41400 42100 1 270 0 capacitor-1.sym
{
T 42100 41900 5 10 0 0 270 0 1
device=CAPACITOR
T 41700 41300 5 10 1 1 0 0 1
refdes=C23
T 42300 41900 5 10 0 0 270 0 1
symversion=0.1
T 41700 41100 5 10 1 1 0 0 1
value=15p
T 41400 42100 5 10 0 1 0 0 1
footprint=CAP_SMALL-200
}
C 41500 40800 1 0 0 gnd-1.sym
N 41600 41200 41600 41100 4
N 41400 42300 41600 42300 4
N 41600 42100 41600 42900 4
{
T 41600 43000 4 8 1 1 0 3 1
netname=XT01
}
C 40400 40800 1 0 0 gnd-1.sym
N 40500 41200 40500 41100 4
N 40500 42100 40500 42900 4
{
T 40500 43000 4 8 1 1 0 3 1
netname=XT02
}
C 40300 42100 1 270 0 capacitor-1.sym
{
T 40600 41300 5 10 1 1 0 0 1
refdes=C22
T 41000 41900 5 10 0 0 270 0 1
device=CAPACITOR
T 41200 41900 5 10 0 0 270 0 1
symversion=0.1
T 40600 41100 5 10 1 1 0 0 1
value=15p
T 40300 42100 5 10 0 1 0 0 1
footprint=CAP_SMALL-200
}
N 40700 42300 40500 42300 4
N 43000 44300 43200 44300 4
{
T 42900 44300 4 8 1 1 0 7 1
netname=XT02
}
N 43000 44100 43200 44100 4
{
T 42900 44100 4 8 1 1 0 7 1
netname=XT01
}
N 42200 43500 43200 43500 4
{
T 42800 43500 4 8 1 1 0 0 1
netname=A10
}
N 42200 43300 43200 43300 4
{
T 42800 43300 4 8 1 1 0 0 1
netname=A11
}
N 58300 49100 58500 49100 4
{
T 58200 49100 4 8 1 1 0 7 1
netname=IRQB
}
N 58300 46900 58500 46900 4
{
T 58200 46900 4 8 1 1 0 7 1
netname=SYS_SCK
}
N 58300 47300 58500 47300 4
{
T 58200 47300 4 8 1 1 0 7 1
netname=SYS_MOSI
}
N 58300 47100 58500 47100 4
{
T 58200 47100 4 8 1 1 0 7 1
netname=SYS_MISO
}
N 58300 46700 58500 46700 4
{
T 58200 46700 4 8 1 1 0 7 1
netname=Vcc
}
N 58400 46500 58500 46500 4
N 58400 46500 58300 46400 4
N 58300 47500 58500 47500 4
{
T 58200 47500 4 8 1 1 0 7 1
netname=\_SS0\_
}
N 58300 47700 58500 47700 4
{
T 58200 47700 4 8 1 1 0 7 1
netname=\_SS1\_
}
N 58300 47900 58500 47900 4
{
T 58200 47900 4 8 1 1 0 7 1
netname=\_SS2\_
}
N 58300 48100 58500 48100 4
{
T 58200 48100 4 8 1 1 0 7 1
netname=\_SS3\_
}
N 58300 48300 58500 48300 4
{
T 58200 48300 4 8 1 1 0 7 1
netname=\_SS4\_
}
N 58300 48500 58500 48500 4
{
T 58200 48500 4 8 1 1 0 7 1
netname=\_SS5\_
}
C 43200 41800 1 180 1 connector4-1.sym
{
T 45000 40900 5 10 0 0 180 6 1
device=CONNECTOR_4
T 43200 40400 5 10 1 1 180 6 1
refdes=SERIAL0
T 43700 40800 5 10 0 1 0 0 1
footprint=JUMPER4
}
C 44900 41800 1 0 0 vcc-1.sym
N 44900 41600 45000 41600 4
N 45100 41700 45100 41800 4
N 45100 41700 45000 41600 4
C 42900 49900 1 0 0 diode-1.sym
{
T 43300 50500 5 10 0 0 0 0 1
device=DIODE
T 43200 50400 5 10 1 1 0 0 1
refdes=D3
T 43300 50100 5 10 0 1 0 0 1
footprint=AXIAL_LAY 300
}
C 42000 50000 1 0 0 fuse-2.sym
{
T 42200 50550 5 10 0 0 0 0 1
device=FUSE
T 42300 50300 5 10 1 1 0 0 1
refdes=F1
T 42200 50750 5 10 0 0 0 0 1
symversion=0.1
T 42600 50100 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 44100 49100 1 90 0 zener-1.sym
{
T 43500 49500 5 10 0 0 90 0 1
device=ZENER_DIODE
T 44100 49500 5 10 1 1 0 0 1
refdes=D4
T 44000 49600 5 10 0 1 0 0 1
footprint=AXIAL_LAY 300
}
C 44500 50300 1 0 0 vdd-1.sym
C 44000 50300 1 0 0 vcc-1.sym
N 44200 50300 44200 50200 4
N 44600 50100 43800 50100 4
N 44200 50200 44100 50100 4
N 44700 50300 44700 50200 4
N 44700 50200 44600 50100 4
C 43800 48800 1 0 0 gnd-1.sym
N 43900 50000 43900 50100 4
T 45700 40600 9 10 1 0 0 0 4
TX and RX are from this board's
perspective, so TX should be
labelled TX< on the LHS of the
board because it's DRIVEN
C 51500 47400 1 90 0 resistor-2.sym
{
T 51150 47800 5 10 0 0 90 0 1
device=RESISTOR
T 51600 47900 5 10 1 1 0 0 1
refdes=R6
T 51600 47700 5 10 1 1 0 0 1
value=33k
T 51500 47400 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 51200 48300 1 0 0 vdd-1.sym
N 51400 46700 51400 47400 4
N 51400 46700 51300 46600 4
N 42200 43500 42100 43600 4
U 42100 43600 42000 43700 10 0
N 42200 43300 42100 43400 4
U 42100 43400 42000 43500 10 0
T 51600 40100 9 10 1 0 0 0 1
1
T 50100 40100 9 10 1 0 0 0 1
1
T 53900 40100 9 10 1 0 0 0 1
Neil Matai
N 43000 45700 43200 45700 4
{
T 42900 45700 4 8 1 1 0 7 1
netname=\_SSA\_
}
C 53000 45100 1 0 0 ATtiny2313.sym
{
T 55650 49300 5 10 1 1 0 6 1
refdes=U3
T 53300 49650 5 10 0 0 0 0 1
device=ATtiny2313
T 53300 49850 5 10 0 0 0 0 1
footprint=DIP20
}
N 55900 47300 56100 47300 4
{
T 56200 47300 4 8 1 1 0 1 1
netname=\_SSA\_
}
N 55900 48100 56100 48100 4
{
T 56200 48100 4 8 1 1 0 1 1
netname=SLV_MISO
}
N 55900 47700 56100 47700 4
{
T 56200 47700 4 8 1 1 0 1 1
netname=SLV_MOSI
}
N 55900 48500 56100 48500 4
{
T 56200 48500 4 8 1 1 0 1 1
netname=SLV_SCK
}
N 52800 48500 53000 48500 4
{
T 52700 48500 4 8 1 1 0 7 1
netname=RX1
}
N 52800 48100 53000 48100 4
{
T 52700 48100 4 8 1 1 0 7 1
netname=TX1
}
T 51400 50100 9 10 1 0 0 0 3
TX&RX 0 is for access to
the supervising AVR.
TX&RX 1 are for the 6502
C 52400 43500 1 0 0 crystal-1.sym
{
T 52600 44000 5 10 0 0 0 0 1
device=CRYSTAL
T 52750 43800 5 10 1 1 0 3 1
refdes=X3
T 52600 44200 5 10 0 0 0 0 1
symversion=0.1
T 52750 43400 5 10 1 1 0 5 1
value=18M432
T 52800 43600 5 10 0 1 0 0 1
footprint=FLANGED_CRYSTAL-1
T 52700 43500 5 10 0 1 0 0 1
footprint=FLANGED_CRYSTAL-1
}
C 53100 43400 1 270 0 capacitor-1.sym
{
T 53800 43200 5 10 0 0 270 0 1
device=CAPACITOR
T 53400 42600 5 10 1 1 0 0 1
refdes=C33
T 54000 43200 5 10 0 0 270 0 1
symversion=0.1
T 53400 42400 5 10 1 1 0 0 1
value=15p
T 53100 43400 5 10 0 1 0 0 1
footprint=CAP_SMALL-200
}
C 53200 42100 1 0 0 gnd-1.sym
N 53300 42500 53300 42400 4
N 53100 43600 53300 43600 4
N 53300 43400 53300 44200 4
{
T 53300 44300 4 8 1 1 0 3 1
netname=XT11
}
C 52100 42100 1 0 0 gnd-1.sym
N 52200 42500 52200 42400 4
N 52200 43400 52200 44200 4
{
T 52200 44300 4 8 1 1 0 3 1
netname=XT12
}
C 52000 43400 1 270 0 capacitor-1.sym
{
T 52300 42600 5 10 1 1 0 0 1
refdes=C32
T 52700 43200 5 10 0 0 270 0 1
device=CAPACITOR
T 52900 43200 5 10 0 0 270 0 1
symversion=0.1
T 52300 42400 5 10 1 1 0 0 1
value=15p
T 52000 43400 5 10 0 1 0 0 1
footprint=CAP_SMALL-200
}
N 52400 43600 52200 43600 4
N 52800 47700 53000 47700 4
{
T 52700 47700 4 8 1 1 0 7 1
netname=XT12
}
N 52800 47300 53000 47300 4
{
T 52700 47300 4 8 1 1 0 7 1
netname=XT11
}
T 54800 50000 9 10 1 0 0 0 4
The ATtiny2313 must
be removed prior to
reprogramming the
ATmega1284
N 52800 48900 53000 48900 4
{
T 52700 48900 4 8 1 1 0 7 1
netname=\_RESET\_
}
N 52800 46500 53000 46500 4
{
T 52700 46500 4 8 1 1 0 7 1
netname=IRQB
}
N 52800 46900 53000 46900 4
{
T 52700 46900 4 8 1 1 0 7 1
netname=RESB
}
N 55900 45300 56100 45300 4
{
T 56200 45300 4 8 1 1 0 1 1
netname=\_SS6\_
}
N 55900 45700 56100 45700 4
{
T 56200 45700 4 8 1 1 0 1 1
netname=\_SS0\_
}
N 55900 46100 56100 46100 4
{
T 56200 46100 4 8 1 1 0 1 1
netname=\_SS1\_
}
N 55900 46900 56100 46900 4
{
T 56200 46900 4 8 1 1 0 1 1
netname=\_SS3\_
}
N 55900 46500 56100 46500 4
{
T 56200 46500 4 8 1 1 0 1 1
netname=\_SS2\_
}
N 52800 46100 53000 46100 4
{
T 52700 46100 4 8 1 1 0 7 1
netname=\_SS4\_
}
N 52800 45700 53000 45700 4
{
T 52700 45700 4 8 1 1 0 7 1
netname=\_SS5\_
}
C 55800 42700 1 90 0 capacitor-1.sym
{
T 55100 42900 5 10 0 0 90 0 1
device=CAPACITOR
T 55700 43300 5 10 1 1 0 0 1
refdes=C31
T 54900 42900 5 10 0 0 90 0 1
symversion=0.1
T 55700 42900 5 10 1 1 0 0 1
value=100n
T 55800 42700 5 10 0 1 0 0 1
footprint=CAP_SMALL-100
}
C 55500 42400 1 0 0 gnd-1.sym
C 55400 43600 1 0 0 vcc-1.sym
N 58300 48700 58500 48700 4
{
T 58200 48700 4 8 1 1 0 7 1
netname=\_SS6\_
}
N 42200 43100 43200 43100 4
{
T 42800 43100 4 8 1 1 0 0 1
netname=A12
}
N 42200 42900 43200 42900 4
{
T 42800 42900 4 8 1 1 0 0 1
netname=A13
}
N 42200 43100 42100 43200 4
N 42200 42900 42100 43000 4
U 42100 43000 42000 43100 10 0
U 42100 43200 42000 43300 10 0
N 42200 42700 43200 42700 4
{
T 42800 42700 4 8 1 1 0 0 1
netname=A14
}
N 42200 46500 43200 46500 4
{
T 42800 46500 4 8 1 1 0 0 1
netname=A8
}
N 42200 42700 42100 42800 4
N 42200 46500 42100 46600 4
U 42100 46600 42000 46700 10 0
U 42100 42800 42000 42900 10 0
N 42200 46300 43200 46300 4
{
T 42800 46300 4 8 1 1 0 0 1
netname=A9
}
N 42200 46300 42100 46400 4
U 42100 46400 42000 46500 10 0
C 50600 47500 1 90 0 resistor-2.sym
{
T 50250 47900 5 10 0 0 90 0 1
device=RESISTOR
T 50700 48000 5 10 1 1 0 0 1
refdes=R7
T 50700 47800 5 10 1 1 0 0 1
value=33k
T 50600 47500 5 10 0 1 0 0 1
footprint=AXIAL_LAY 200
}
C 50300 48400 1 0 0 vdd-1.sym
N 50500 47300 50400 47200 4
N 50500 47300 50500 47500 4
C 37600 47800 1 270 0 tiny-jumper-3.sym
{
T 38750 46300 5 10 0 0 270 0 1
footprint=JUMPER3
T 39200 46297 5 10 0 0 270 0 1
device=JUMPER3
T 38578 45775 5 6 1 1 0 2 1
refdes=JM1
}
N 38500 45600 38500 45700 4
{
T 38500 45500 4 8 1 1 180 3 1
netname=ISP_SCK
}
N 38500 46300 38500 46400 4
{
T 38500 46500 4 8 1 1 180 5 1
netname=SYS_SCK
}
N 38300 46000 38200 46000 4
{
T 38100 46000 4 8 1 1 180 1 1
netname=MSTR_SCK
}
C 37600 46300 1 270 0 tiny-jumper-3.sym
{
T 38750 44800 5 10 0 0 270 0 1
footprint=JUMPER3
T 39200 44797 5 10 0 0 270 0 1
device=JUMPER3
T 38578 44275 5 6 1 1 0 2 1
refdes=JM2
}
N 38500 44100 38500 44200 4
{
T 38500 44000 4 8 1 1 180 3 1
netname=ISP_MISO
}
N 38500 44800 38500 44900 4
{
T 38500 45000 4 8 1 1 180 5 1
netname=SYS_MISO
}
N 38300 44500 38200 44500 4
{
T 38100 44500 4 8 1 1 180 1 1
netname=MSTR_MISO
}
C 37600 44800 1 270 0 tiny-jumper-3.sym
{
T 38750 43300 5 10 0 0 270 0 1
footprint=JUMPER3
T 39200 43297 5 10 0 0 270 0 1
device=JUMPER3
T 38578 42775 5 6 1 1 0 2 1
refdes=JM3
}
N 38500 42600 38500 42700 4
{
T 38500 42500 4 8 1 1 180 3 1
netname=ISP_MOSI
}
N 38500 43300 38500 43400 4
{
T 38500 43500 4 8 1 1 180 5 1
netname=SYS_MOSI
}
N 38300 43000 38200 43000 4
{
T 38100 43000 4 8 1 1 180 1 1
netname=MSTR_MOSI
}
C 53100 51400 1 0 0 gnd-1.sym
N 53000 51900 53100 51900 4
N 53200 51800 53200 51700 4
N 53100 51900 53200 51800 4
N 53000 52200 53200 52200 4
{
T 53300 52200 4 8 1 1 0 1 1
netname=RX1
}
N 53000 52500 53200 52500 4
{
T 53300 52500 4 8 1 1 0 1 1
netname=TX1
}
C 51300 53000 1 180 1 connector4-1.sym
{
T 53100 52100 5 10 0 0 180 6 1
device=CONNECTOR_4
T 51300 51600 5 10 1 1 180 6 1
refdes=SERIAL1
T 51800 52000 5 10 0 1 0 0 1
footprint=JUMPER4
}
C 53000 53000 1 0 0 vcc-1.sym
N 53000 52800 53100 52800 4
N 53200 52900 53200 53000 4
N 53200 52900 53100 52800 4
C 57900 55600 1 270 0 tiny-jumper-3.sym
{
T 59050 54100 5 10 0 0 270 0 1
footprint=JUMPER3
T 59500 54097 5 10 0 0 270 0 1
device=JUMPER3
T 58878 53575 5 6 1 1 0 2 1
refdes=JS1
}
N 58800 53400 58800 53500 4
{
T 58800 53300 4 8 1 1 180 3 1
netname=ISP_SCK
}
N 58800 54100 58800 54200 4
{
T 58800 54300 4 8 1 1 180 5 1
netname=SYS_SCK
}
N 58600 53800 58500 53800 4
{
T 58400 53800 4 8 1 1 180 1 1
netname=SLV_SCK
}
C 57900 54100 1 270 0 tiny-jumper-3.sym
{
T 59050 52600 5 10 0 0 270 0 1
footprint=JUMPER3
T 59500 52597 5 10 0 0 270 0 1
device=JUMPER3
T 58878 52075 5 6 1 1 0 2 1
refdes=JS2
}
N 58800 51900 58800 52000 4
{
T 58800 51800 4 8 1 1 180 3 1
netname=ISP_MISO
}
N 58800 52600 58800 52700 4
{
T 58800 52800 4 8 1 1 180 5 1
netname=SYS_MISO
}
N 58600 52300 58500 52300 4
{
T 58400 52300 4 8 1 1 180 1 1
netname=SLV_MISO
}
C 57900 52600 1 270 0 tiny-jumper-3.sym
{
T 59050 51100 5 10 0 0 270 0 1
footprint=JUMPER3
T 59500 51097 5 10 0 0 270 0 1
device=JUMPER3
T 58878 50575 5 6 1 1 0 2 1
refdes=JS3
}
N 58800 50400 58800 50500 4
{
T 58800 50300 4 8 1 1 180 3 1
netname=ISP_MOSI
}
N 58800 51100 58800 51200 4
{
T 58800 51300 4 8 1 1 180 5 1
netname=SYS_MOSI
}
N 58600 50800 58500 50800 4
{
T 58400 50800 4 8 1 1 180 1 1
netname=SLV_MOSI
}
C 49600 50400 1 0 0 vcc-1.sym
C 58500 46200 1 0 0 connector14-3.sym
{
T 58495 49758 5 10 0 0 0 0 1
device=14-way connector
T 58595 46358 5 10 1 1 0 2 1
refdes=SPI
T 58495 49558 5 10 0 0 0 0 1
footprint=HEADER14_2
}
C 58200 46000 1 0 0 gnd-1.sym
N 58300 46400 58300 46300 4
