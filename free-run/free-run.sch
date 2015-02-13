v 20110115 2
C 40000 40000 0 0 0 title-B.sym
C 43900 48100 1 90 0 resistor-2.sym
{
T 43550 48500 5 10 0 0 90 0 1
device=RESISTOR
T 44000 48600 5 10 1 1 0 0 1
refdes=R2
T 44000 48400 5 10 1 1 0 0 1
value=3k3
}
C 47500 48000 1 0 0 vdd-1.sym
C 44300 47900 1 0 0 nc-left-1.sym
{
T 44300 48300 5 10 0 0 0 0 1
value=NoConnection
T 44300 48700 5 10 0 0 0 0 1
device=DRC_Directive
}
C 46800 47700 1 0 0 nc-right-1.sym
{
T 46900 48200 5 10 0 0 0 0 1
value=NoConnection
T 46900 48400 5 10 0 0 0 0 1
device=DRC_Directive
}
N 46800 48000 47000 48000 4
{
T 47100 48000 4 8 1 1 0 1 1
netname=RESB
}
N 46800 47600 47600 47600 4
N 47700 47700 47700 48000 4
N 47600 47600 47700 47700 4
C 46800 46900 1 0 0 nc-right-1.sym
{
T 46900 47400 5 10 0 0 0 0 1
value=NoConnection
T 46900 47600 5 10 0 0 0 0 1
device=DRC_Directive
}
N 46800 47200 47900 47200 4
N 47900 47200 48000 47300 4
C 44300 47500 1 0 0 nc-left-1.sym
{
T 44300 47900 5 10 0 0 0 0 1
value=NoConnection
T 44300 48300 5 10 0 0 0 0 1
device=DRC_Directive
}
C 44300 46700 1 0 0 nc-left-1.sym
{
T 44300 47100 5 10 0 0 0 0 1
value=NoConnection
T 44300 47500 5 10 0 0 0 0 1
device=DRC_Directive
}
C 43600 49000 1 0 0 vdd-1.sym
N 43900 47800 44800 47800 4
N 43900 47800 43800 47900 4
N 43800 47900 43800 48100 4
N 44600 47400 44800 47400 4
{
T 44500 47400 4 8 1 1 0 7 1
netname=IRQB
}
N 43200 47200 44800 47200 4
N 43200 47200 43100 47300 4
N 43100 47300 43100 48100 4
C 42500 48100 1 90 0 resistor-2.sym
{
T 42150 48500 5 10 0 0 90 0 1
device=RESISTOR
T 42600 48600 5 10 1 1 0 0 1
refdes=R1
T 42600 48400 5 10 1 1 0 0 1
value=3k3
}
C 42200 49000 1 0 0 vdd-1.sym
N 42500 47000 42400 47100 4
N 42400 47100 42400 48100 4
N 42500 47000 44800 47000 4
N 46800 47400 47000 47400 4
{
T 47100 47400 4 8 1 1 0 1 1
netname=PHI2
}
N 46800 46800 47000 46800 4
{
T 47100 46800 4 8 1 1 0 1 1
netname=RWB
}
N 46800 45200 47700 45200 4
{
T 46900 45200 4 8 1 1 0 0 1
netname=D7
}
N 47700 45200 47800 45300 4
N 46800 45400 47700 45400 4
{
T 46900 45400 4 8 1 1 0 0 1
netname=D6
}
N 47700 45400 47800 45500 4
N 46800 45600 47700 45600 4
{
T 46900 45600 4 8 1 1 0 0 1
netname=D5
}
N 47700 45600 47800 45700 4
N 46800 45800 47700 45800 4
{
T 46900 45800 4 8 1 1 0 0 1
netname=D4
}
N 47700 45800 47800 45900 4
N 46800 46000 47700 46000 4
{
T 46900 46000 4 8 1 1 0 0 1
netname=D3
}
N 47700 46000 47800 46100 4
N 46800 46200 47700 46200 4
{
T 46900 46200 4 8 1 1 0 0 1
netname=D2
}
N 47700 46200 47800 46300 4
N 46800 46400 47700 46400 4
{
T 46900 46400 4 8 1 1 0 0 1
netname=D1
}
N 47700 46400 47800 46500 4
N 46800 46600 47700 46600 4
{
T 46900 46600 4 8 1 1 0 0 1
netname=D0
}
N 47700 46600 47800 46700 4
N 44400 46400 44800 46400 4
{
T 44700 46400 4 8 1 1 0 6 1
netname=A0
}
N 44300 46300 44400 46400 4
U 44300 42300 53400 42300 10 0
U 44200 42400 44300 42300 10 0
U 47500 42300 47400 42400 10 0
N 44400 46200 44800 46200 4
{
T 44700 46200 4 8 1 1 0 6 1
netname=A1
}
N 44300 46100 44400 46200 4
N 44400 46000 44800 46000 4
{
T 44700 46000 4 8 1 1 0 6 1
netname=A2
}
N 44300 45900 44400 46000 4
N 44400 45800 44800 45800 4
{
T 44700 45800 4 8 1 1 0 6 1
netname=A3
}
N 44300 45700 44400 45800 4
N 44400 45600 44800 45600 4
{
T 44700 45600 4 8 1 1 0 6 1
netname=A4
}
N 44300 45500 44400 45600 4
N 44400 45400 44800 45400 4
{
T 44700 45400 4 8 1 1 0 6 1
netname=A5
}
N 44300 45300 44400 45400 4
N 44400 45200 44800 45200 4
{
T 44700 45200 4 8 1 1 0 6 1
netname=A6
}
N 44300 45100 44400 45200 4
N 44400 45000 44800 45000 4
{
T 44700 45000 4 8 1 1 0 6 1
netname=A7
}
N 44300 44900 44400 45000 4
N 44400 44800 44800 44800 4
{
T 44700 44800 4 8 1 1 0 6 1
netname=A8
}
N 44300 44700 44400 44800 4
N 44400 44600 44800 44600 4
{
T 44700 44600 4 8 1 1 0 6 1
netname=A9
}
N 44300 44500 44400 44600 4
N 44400 44400 44800 44400 4
{
T 44700 44400 4 8 1 1 0 6 1
netname=A10
}
N 44300 44300 44400 44400 4
N 44400 44200 44800 44200 4
{
T 44700 44200 4 8 1 1 0 6 1
netname=A11
}
N 44300 44100 44400 44200 4
N 46800 45000 47200 45000 4
{
T 46900 45000 4 8 1 1 0 0 1
netname=A15
}
N 47300 44900 47200 45000 4
N 46800 44800 47200 44800 4
{
T 46900 44800 4 8 1 1 0 0 1
netname=A14
}
N 47300 44700 47200 44800 4
N 46800 44600 47200 44600 4
{
T 46900 44600 4 8 1 1 0 0 1
netname=A13
}
N 47300 44500 47200 44600 4
N 46800 44400 47200 44400 4
{
T 46900 44400 4 8 1 1 0 0 1
netname=A12
}
N 47300 44300 47200 44400 4
C 46000 48900 1 90 0 capacitor-1.sym
{
T 45300 49100 5 10 0 0 90 0 1
device=CAPACITOR
T 45900 49500 5 10 1 1 0 0 1
refdes=C1
T 45100 49100 5 10 0 0 90 0 1
symversion=0.1
T 45900 49100 5 10 1 1 0 0 1
value=100n
}
C 45600 49800 1 0 0 vdd-1.sym
C 45700 48600 1 0 0 gnd-1.sym
U 47900 47000 47900 45400 10 0
U 47900 45400 47800 45300 10 0
U 47900 45600 47800 45500 10 0
U 47900 45800 47800 45700 10 0
U 47900 46000 47800 45900 10 0
U 47900 46200 47800 46100 10 0
U 47900 46400 47800 46300 10 0
U 47900 46600 47800 46500 10 0
U 47900 46800 47800 46700 10 0
U 47400 42400 47400 44800 10 0
{
T 48000 42400 10 10 1 1 0 0 1
busname=ADDR
}
U 44200 46200 44200 42400 10 0
U 44200 44000 44300 44100 10 0
U 44200 44200 44300 44300 10 0
U 44200 44400 44300 44500 10 0
U 44200 44600 44300 44700 10 0
U 44200 45400 44300 45500 10 0
U 44200 44800 44300 44900 10 0
U 44200 45000 44300 45100 10 0
U 44200 45200 44300 45300 10 0
U 44200 46200 44300 46300 10 0
U 44200 45600 44300 45700 10 0
U 44200 45800 44300 45900 10 0
U 44200 46000 44300 46100 10 0
U 47300 44900 47400 44800 10 0
U 47300 44700 47400 44600 10 0
U 47300 44300 47400 44200 10 0
U 47300 44500 47400 44400 10 0
C 50600 42700 1 0 0 iMX-233-NANO.sym
{
T 50608 50193 5 10 0 0 0 0 1
device=iMX233_NANO
T 51408 42693 5 10 1 1 0 0 1
refdes=U2
}
N 49900 48500 49800 48600 4
C 49600 48800 1 0 0 vdd-1.sym
N 49800 48600 49800 48800 4
N 49900 48500 50600 48500 4
C 50100 48800 1 0 0 nc-left-1.sym
{
T 50100 49200 5 10 0 0 0 0 1
value=NoConnection
T 50100 49600 5 10 0 0 0 0 1
device=DRC_Directive
}
C 50100 48200 1 0 0 nc-left-1.sym
{
T 50100 48600 5 10 0 0 0 0 1
value=NoConnection
T 50100 49000 5 10 0 0 0 0 1
device=DRC_Directive
}
C 50100 48000 1 0 0 nc-left-1.sym
{
T 50100 48400 5 10 0 0 0 0 1
value=NoConnection
T 50100 48800 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 47800 1 0 0 nc-right-1.sym
{
T 52700 48300 5 10 0 0 0 0 1
value=NoConnection
T 52700 48500 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 47600 1 0 0 nc-right-1.sym
{
T 52700 48100 5 10 0 0 0 0 1
value=NoConnection
T 52700 48300 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 47400 1 0 0 nc-right-1.sym
{
T 52700 47900 5 10 0 0 0 0 1
value=NoConnection
T 52700 48100 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 47200 1 0 0 nc-right-1.sym
{
T 52700 47700 5 10 0 0 0 0 1
value=NoConnection
T 52700 47900 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 47000 1 0 0 nc-right-1.sym
{
T 52700 47500 5 10 0 0 0 0 1
value=NoConnection
T 52700 47700 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 46800 1 0 0 nc-right-1.sym
{
T 52700 47300 5 10 0 0 0 0 1
value=NoConnection
T 52700 47500 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 46600 1 0 0 nc-right-1.sym
{
T 52700 47100 5 10 0 0 0 0 1
value=NoConnection
T 52700 47300 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 46400 1 0 0 nc-right-1.sym
{
T 52700 46900 5 10 0 0 0 0 1
value=NoConnection
T 52700 47100 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 46200 1 0 0 nc-right-1.sym
{
T 52700 46700 5 10 0 0 0 0 1
value=NoConnection
T 52700 46900 5 10 0 0 0 0 1
device=DRC_Directive
}
C 52600 48400 1 0 0 nc-right-1.sym
{
T 52700 48900 5 10 0 0 0 0 1
value=NoConnection
T 52700 49100 5 10 0 0 0 0 1
device=DRC_Directive
}
C 53600 49400 1 0 0 output-1.sym
{
T 53700 49700 5 10 0 0 0 0 1
device=OUTPUT
}
C 52400 49400 1 0 0 input-1.sym
{
T 52400 49700 5 10 0 0 0 0 1
device=INPUT
}
C 49500 46600 1 0 0 resistor-2.sym
{
T 49900 46950 5 10 0 0 0 0 1
device=RESISTOR
T 49700 46700 5 8 1 1 0 1 1
refdes=R10
T 50000 46700 5 8 1 1 0 1 1
value=1K
}
N 50400 46700 50600 46700 4
N 49100 46700 49500 46700 4
{
T 49200 46700 4 8 1 1 0 0 1
netname=D0
}
C 49500 46400 1 0 0 resistor-2.sym
{
T 49900 46750 5 10 0 0 0 0 1
device=RESISTOR
T 49700 46500 5 8 1 1 0 1 1
refdes=R11
T 50000 46500 5 8 1 1 0 1 1
value=1K
}
N 50400 46500 50600 46500 4
N 49100 46500 49500 46500 4
{
T 49200 46500 4 8 1 1 0 0 1
netname=D1
}
C 49500 46200 1 0 0 resistor-2.sym
{
T 49900 46550 5 10 0 0 0 0 1
device=RESISTOR
T 49700 46300 5 8 1 1 0 1 1
refdes=R12
T 50000 46300 5 8 1 1 0 1 1
value=1K
}
N 50400 46300 50600 46300 4
N 49100 46300 49500 46300 4
{
T 49200 46300 4 8 1 1 0 0 1
netname=D2
}
C 49500 44800 1 0 0 resistor-2.sym
{
T 49900 45150 5 10 0 0 0 0 1
device=RESISTOR
T 49700 44900 5 8 1 1 0 1 1
refdes=R13
T 50000 44900 5 8 1 1 0 1 1
value=1K
}
N 50400 44900 50600 44900 4
N 49100 44900 49500 44900 4
{
T 49200 44900 4 8 1 1 0 0 1
netname=D3
}
C 49500 44600 1 0 0 resistor-2.sym
{
T 49900 44950 5 10 0 0 0 0 1
device=RESISTOR
T 49700 44700 5 8 1 1 0 1 1
refdes=R14
T 50000 44700 5 8 1 1 0 1 1
value=1K
}
N 50400 44700 50600 44700 4
N 49100 44700 49500 44700 4
{
T 49200 44700 4 8 1 1 0 0 1
netname=D4
}
C 49500 44400 1 0 0 resistor-2.sym
{
T 49900 44750 5 10 0 0 0 0 1
device=RESISTOR
T 49700 44500 5 8 1 1 0 1 1
refdes=R15
T 50000 44500 5 8 1 1 0 1 1
value=1K
}
N 50400 44500 50600 44500 4
N 49100 44500 49500 44500 4
{
T 49200 44500 4 8 1 1 0 0 1
netname=D5
}
C 49500 44200 1 0 0 resistor-2.sym
{
T 49900 44550 5 10 0 0 0 0 1
device=RESISTOR
T 49700 44300 5 8 1 1 0 1 1
refdes=R16
T 50000 44300 5 8 1 1 0 1 1
value=1K
}
N 50400 44300 50600 44300 4
N 49100 44300 49500 44300 4
{
T 49200 44300 4 8 1 1 0 0 1
netname=D6
}
C 49500 44000 1 0 0 resistor-2.sym
{
T 49900 44350 5 10 0 0 0 0 1
device=RESISTOR
T 49700 44100 5 8 1 1 0 1 1
refdes=R17
T 50000 44100 5 8 1 1 0 1 1
value=1K
}
N 50400 44100 50600 44100 4
N 49100 44100 49500 44100 4
{
T 49200 44100 4 8 1 1 0 0 1
netname=D7
}
U 49000 47000 49000 44200 10 0
U 49000 44200 49100 44100 10 0
U 49000 44400 49100 44300 10 0
U 49000 44600 49100 44500 10 0
U 49000 44800 49100 44700 10 0
U 49000 45000 49100 44900 10 0
U 49000 46400 49100 46300 10 0
U 49000 46600 49100 46500 10 0
U 49000 46800 49100 46700 10 0
U 48000 47100 47900 47000 10 0
U 48900 47100 49000 47000 10 0
U 48000 47100 48900 47100 10 0
N 53300 48400 53200 48300 4
N 53500 48200 53400 48100 4
N 53200 48300 52600 48300 4
N 53400 48100 52600 48100 4
N 53600 49500 53500 49400 4
N 53200 49500 53300 49400 4
N 53300 49400 53300 48400 4
N 53500 49400 53500 48200 4
T 51600 49300 9 10 1 0 0 0 2
DEBUG
UART
N 52600 43100 53300 43100 4
{
T 52700 43100 4 8 1 1 0 0 1
netname=A10
}
N 53400 43000 53300 43100 4
U 53400 43000 53500 42900 10 0
U 53400 42300 53500 42400 10 0
U 53500 44700 53500 42400 10 0
U 49900 42300 50000 42400 10 0
U 50000 43300 50000 42400 10 0
N 50200 43100 50600 43100 4
{
T 50500 43100 4 8 1 1 0 6 1
netname=A11
}
N 50100 43000 50200 43100 4
U 50000 42900 50100 43000 10 0
N 49600 47900 50600 47900 4
{
T 50500 47900 4 8 1 1 0 6 1
netname=A0
}
N 49600 47900 49500 48000 4
U 49500 48000 49400 48100 10 0
U 49400 47100 49400 48400 10 0
{
T 49000 48500 10 10 1 1 0 0 1
busname=ADDR
}
N 49600 47700 50600 47700 4
{
T 50500 47700 4 8 1 1 0 6 1
netname=A1
}
N 49600 47700 49500 47800 4
N 49600 47500 50600 47500 4
{
T 50500 47500 4 8 1 1 0 6 1
netname=A2
}
N 49600 47500 49500 47600 4
N 49600 47300 50600 47300 4
{
T 50500 47300 4 8 1 1 0 6 1
netname=A3
}
N 49600 47300 49500 47400 4
N 49600 47100 50600 47100 4
{
T 50500 47100 4 8 1 1 0 6 1
netname=A4
}
N 49600 47100 49500 47200 4
N 49600 46900 50600 46900 4
{
T 50500 46900 4 8 1 1 0 6 1
netname=A5
}
N 49600 46900 49500 47000 4
U 49500 47800 49400 47900 10 0
U 49500 47600 49400 47700 10 0
U 49500 47400 49400 47500 10 0
U 49500 47200 49400 47300 10 0
U 49500 47000 49400 47100 10 0
N 52600 43300 53300 43300 4
{
T 52700 43300 4 8 1 1 0 0 1
netname=A6
}
N 53400 43200 53300 43300 4
U 53400 43200 53500 43100 10 0
N 52600 43500 53300 43500 4
{
T 52700 43500 4 8 1 1 0 0 1
netname=A8
}
N 53400 43400 53300 43500 4
U 53400 43400 53500 43300 10 0
N 52600 43700 53300 43700 4
{
T 52700 43700 4 8 1 1 0 0 1
netname=A7
}
N 53400 43600 53300 43700 4
U 53400 43600 53500 43500 10 0
N 52600 43900 53300 43900 4
{
T 52700 43900 4 8 1 1 0 0 1
netname=A9
}
N 53400 43800 53300 43900 4
U 53400 43800 53500 43700 10 0
N 52600 44700 53300 44700 4
{
T 52700 44700 4 8 1 1 0 0 1
netname=A14
}
N 53400 44600 53300 44700 4
U 53400 44600 53500 44500 10 0
N 50200 43300 50600 43300 4
{
T 50500 43300 4 8 1 1 0 6 1
netname=A12
}
N 50100 43200 50200 43300 4
U 50000 43100 50100 43200 10 0
N 50200 43500 50600 43500 4
{
T 50500 43500 4 8 1 1 0 6 1
netname=A13
}
N 50100 43400 50200 43500 4
U 50000 43300 50100 43400 10 0
N 50400 43900 50600 43900 4
{
T 50300 43900 4 8 1 1 0 7 1
netname=IRQB
}
C 50100 43600 1 0 0 nc-left-1.sym
{
T 50100 44000 5 10 0 0 0 0 1
value=NoConnection
T 50100 44400 5 10 0 0 0 0 1
device=DRC_Directive
}
N 52600 44500 52800 44500 4
{
T 52900 44500 4 8 1 1 0 1 1
netname=RESB
}
N 52600 44300 52800 44300 4
{
T 52900 44300 4 8 1 1 0 1 1
netname=PHI2
}
N 52600 44900 53300 44900 4
{
T 52700 44900 4 8 1 1 0 0 1
netname=A15
}
N 53400 44800 53300 44900 4
U 53400 44800 53500 44700 10 0
N 52600 44100 52800 44100 4
{
T 52900 44100 4 8 1 1 0 1 1
netname=RWB
}
C 44800 43800 1 0 0 W65C02.sym
{
T 44808 49493 5 10 0 0 0 0 1
device=W65C02
T 44808 48693 5 10 0 0 0 0 1
footprint=DIP40
T 45708 43793 5 10 1 1 0 0 1
refdes=U1
}
C 48500 48700 1 90 0 resistor-2.sym
{
T 48150 49100 5 10 0 0 90 0 1
device=RESISTOR
T 48600 49200 5 10 1 1 0 0 1
refdes=R2
T 48600 49000 5 10 1 1 0 0 1
value=3k3
}
C 48200 49600 1 0 0 vdd-1.sym
C 48400 48500 1 270 0 switch-spst-1.sym
{
T 49100 48100 5 10 0 0 270 0 1
device=SPST
T 48600 47900 5 10 1 1 0 0 1
refdes=S1
}
C 48300 47400 1 0 0 gnd-1.sym
N 48000 48500 48100 48600 4
N 48400 48700 48400 48500 4
N 48100 48600 48400 48600 4
N 48000 48500 48000 47300 4
C 43200 48100 1 90 0 resistor-2.sym
{
T 42850 48500 5 10 0 0 90 0 1
device=RESISTOR
T 43300 48600 5 10 1 1 0 0 1
refdes=R1
T 43300 48400 5 10 1 1 0 0 1
value=3k3
}
C 42900 49000 1 0 0 vdd-1.sym
