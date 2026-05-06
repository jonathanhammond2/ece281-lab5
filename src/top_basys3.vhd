--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        sw_op   :   in std_logic_vector(2 downto 0);
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- clock divider reset
        
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
--signal declarations

    --twos comp signals
    signal w_sign : std_logic_vector(3 downto 0);
    signal w_hund : std_logic_vector(3 downto 0);
    signal w_tens : std_logic_vector(3 downto 0);
    signal w_ones : std_logic_vector(3 downto 0);
    
--    signal mux_result : std_logic_vector(7 downto 0);
    
    --FSM output
    signal o_cycle : std_logic_vector(3 downto 0);
    
    signal w_slow_clk : std_logic;
--    signal reset      : std_logic;
--    signal reset_clk  : std_logic;
    signal button_db  : std_logic;
   
    
    signal w_regA, w_regB : std_logic_vector(7 downto 0); -- register outputs
    signal w_alu_result   : std_logic_vector(7 downto 0); 
    signal w_mux_result   : std_logic_vector(7 downto 0); -- Input to twos_comp
    signal w_sign_bit     : std_logic; -- 1-bit sign from twos_comp
    signal w_data         : std_logic_vector(3 downto 0);
    signal w_sel          : std_logic_vector(3 downto 0);
    
    signal seg_from_decoder    : std_logic_vector(6 downto 0);
        
--components
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component controller_fsm is
        port ( 
            i_reset : in STD_LOGIC;
            i_adv : in STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
            );
    end component controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 25000000	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    

    component ALU is
        port ( 
           i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;
    
    
    component button_debounce is
        port(	
            clk: in  STD_LOGIC;
            reset : in  STD_LOGIC;
            button: in STD_LOGIC;
            action: out STD_LOGIC);
    end component button_debounce;
	
	
begin

    -- Register A: Captures when o_cycle(1) is high (Store 1)
    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                w_regA <= (others => '0');
            elsif o_cycle(1) = '1' then
                w_regA <= sw;
            end if;
        end if;
    end process;
    
    -- Register B: Captures when o_cycle(2) is high (Store 2)
    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                w_regB <= (others => '0');
            elsif o_cycle(2) = '1' then
                w_regB <= sw;
            end if;
        end if;
    end process;
    
    


	-- PORT MAPS ----------------------------------------
	
	clk_div : clock_divider
	    generic map (
        k_DIV => 100000  -- NEW value for this instantiation
    )
	port map (
	   i_clk => clk,
	   i_reset => btnL,
	   o_clk => w_slow_clk
	);
	
	
	debounce : button_debounce
        port map (
            clk => clk,
            reset => btnU,
            button => btnC,
            action => button_db
        );
	
    controller : controller_fsm
    port map (
        i_reset    => btnU,
        i_adv      => button_db,
        o_cycle    => o_cycle
    );
    
    tdm : TDM4
    port map (
        i_clk  => w_slow_clk,     
        i_reset => btnU,
        
        i_D0 => w_ones,     
        i_D1 => w_tens,         
        i_D2 => w_hund,    
        i_D3 => w_sign,         
        
        o_data => w_data,
        o_sel  => w_sel
    );
    
    decoder : sevenseg_decoder
    port map (
        i_Hex  => w_data,
        o_seg_n => seg_from_decoder
    );
    
        -- ALU Instantiation
    alu_inst : ALU
        port map (
            i_A      => w_regA,
            i_B      => w_regB,
            i_op     => sw_op,
            o_result => w_alu_result,
            o_flags  => led(15 downto 12) -- Connecting flags to LEDs as per diagram
        );
    
    -- Twos Complement / Binary to Decimal Converter
    converter : twos_comp
        port map (
            i_bin  => w_mux_result,
            o_sign => w_sign_bit,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );
    

	
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	    
    -- Convert 1-bit sign to a 4-bit 'placeholder' for the TDM
-- If negative, we pass a unique hex value (like "1111") to trigger the minus sign
    w_sign <= "1111" when w_sign_bit = '1' else "0000";
    
    --Override the decoder if we are displaying the sign digit and the number is negative.
    seg <= "1111110" when (w_sel = "0111" and w_sign_bit = '1') else seg_from_decoder;

    
    
      an <= "1111" when o_cycle(0) = '1' else                  -- Master Blank: Turn all off in state 0
      "1111" when (w_sel = "0111" and w_sign_bit = '0') else -- Sign Blank: Turn off leftmost digit if positive
      w_sel;                                             -- Otherwise: Let TDM control which digit is on

   
    
    -- Connect FSM state to LEDs 3-0 for debugging
    led(3 downto 0) <= o_cycle;
    
    -- Internal mapping for reset
--    reset <= btnU;


--MUX between twos comp and ALU

    w_mux_result <= w_regA when o_cycle(1) = '1' else w_regB when o_cycle(2) = '1' else w_alu_result;

	
	
end top_basys3_arch;
