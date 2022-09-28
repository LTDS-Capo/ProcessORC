create_clock -period 20 [get_ports {PLL_refclk}]

derive_pll_clocks
derive_clock_uncertainty