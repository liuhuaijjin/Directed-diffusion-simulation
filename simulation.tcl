# ===================================================================
# Define options
# ===================================================================
set opt(chan)			Channel/WirelessChannel
set opt(prop)			Propagation/TwoRayGround
set opt(netif)			Phy/WirelessPhy
set opt(mac)			Mac/802_11
set opt(ifq)			Queue/DropTail/PriQueue
set opt(ll)				LL
set opt(ant)        	Antenna/OmniAntenna
set opt(filters)    	GradientFilter  ;# old name for twophasepull filter
set opt(x)				560				;# X dimension of the topography
set opt(y)				560				;# Y dimension of the topography
set opt(cp)				"./network"		;# need to write new generate function
set opt(ifqlen)			50				;# max packet in ifq
set opt(nn)				49				;# number of nodes
set opt(stop)			50.0			;# simulation time
set opt(tr)				"output.tr"		;# trace file
set opt(nam)            "diffusion.nam" ;# nam file
set opt(energymodel)    EnergyModel     ;#set opt(energymodel)    
set opt(initialenergy)  1000.0          ;# Initial energy in Joules
set opt(txpower)		0.660
set opt(rxpower)		0.350
set opt(idlepower)		0.035
set opt(adhocRouting)   Directed_Diffusion
set opt(prestop)		50.0
# ===================================================================
LL set mindelay_		50us
LL set delay_			30us
LL set bandwidth_		0	;# not used

Queue/DropTail/PriQueue set Prefer_Routing_Protocols    1

# unity gain, omni-directional antennas
# set up the antennas to be centered in the node and 1.5 meters above it
Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 1.5
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0

# Initialize the SharedMedia interface with parameters to make
# it work like the 914MHz Lucent WaveLAN DSSS radio interface
Phy/WirelessPhy set CPThresh_ 10.0
Phy/WirelessPhy set CSThresh_ 1.559e-11
Phy/WirelessPhy set RXThresh_ 3.652e-10
Phy/WirelessPhy set Rb_ 2*1e6
Phy/WirelessPhy set Pt_ 0.2818
Phy/WirelessPhy set freq_ 914e+6 
Phy/WirelessPhy set L_ 1.0

# ====================================================================
# Main Program
# ====================================================================

#
# Initialize Global Variables
#

set ns_ [new Simulator]
set topo	[new Topography]
$topo load_flatgrid $opt(x) $opt(y)
set tracefd	[open $opt(tr) w]
$ns_ trace-all $tracefd
set nf [open $opt(nam) w]
$ns_ namtrace-all-wireless $nf $opt(x) $opt(y)
set god_ [create-god $opt(nn)]

#global node setting
$ns_ node-config -adhocRouting $opt(adhocRouting) \
		 -llType $opt(ll) \
		 -macType $opt(mac) \
		 -ifqType $opt(ifq) \
		 -ifqLen $opt(ifqlen) \
		 -antType $opt(ant) \
		 -propType $opt(prop) \
		 -phyType $opt(netif) \
		 -channelType $opt(chan) \
		 -topoInstance $topo \
         	-diffusionFilter $opt(filters) \
		 -agentTrace ON \
         	-routerTrace ON \
         	-macTrace ON \
         -stopTime $opt(prestop) \
         -energyModel $opt(energymodel) \
         	-idlePower $opt(idlepower) \
         	-rxPower $opt(rxpower) \
         	-txPower $opt(txpower) \
         	-initialEnergy $opt(initialenergy)

# $ns_ use-newtrace

#network topology generation

for {set i 0} {$i < $opt(nn) } {incr i} {
	set node_($i) [$ns_ node $i]	
	$node_($i) random-motion 0
	$node_($i) set X_ [expr ($i%7)*80+40]
	$node_($i) set Y_ [expr ($i/7)*80+40]
	$node_($i) set Z_ 0 		;# disable random motion
	$god_ new_node $node_($i)
}

#load connection pattern for senders
puts "Loading connection pattern..."
source $opt(cp)

#receiver setup
set snk_(0) [new Application/DiffApp/PingReceiver/TPP]
$ns_ attach-diffapp $node_(24) $snk_(0)
$ns_ at 1.1 "$snk_(0) subscribe"

# Define node initial position in nam
for {set i 0} {$i < $opt(nn)} {incr i} {

    # 20 defines the node size in nam, must adjust it according to your scenario
    # The function must be called after mobility model is defined
    
    $ns_ initial_node_pos $node_($i) 20
}

#
# Tell nodes when the simulation ends
#
for {set i 0} {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).000000001 "$node_($i) reset";
}
$ns_ at $opt(stop).000000001 "$ns_ nam-end-wireless $opt(stop)"
$ns_ at $opt(stop).000000001 "puts \"NS EXITING...\" ; $ns_ halt"

puts $tracefd "Directed Diffusion:"
puts "Starting Simulation..."
$ns_ run