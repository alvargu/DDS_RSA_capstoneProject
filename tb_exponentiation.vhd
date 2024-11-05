-- IEEE library instantiation
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- UVVM utils library instantiation
--library UVVM_util;
--context UVVM_util.UVVM_util_context;

-----------------------------------------------------------------------------
-- entity : tb_exponentiation
-- purpose: Simple test of single rsa core
-- type   : testbench
-- inputs : none
-----------------------------------------------------------------------------
entity tb_exponentiation is
end tb_exponentiation;

-----------------------------------------------------------------------------
-- Beginning of architechture
-----------------------------------------------------------------------------
architecture Behavioral of tb_exponentiation is

	-- set clk frequency here
	constant f_clk : integer := 100_000_000;
	constant T_clk : time := (1 sec / f_clk); -- possible point of failure
	constant C_block_size : integer := 32;

	component exponentiation
	    generic (
			C_block_size : integer := 32			
			-- blocksize for final implementation should be 256 bits, 
			-- but for the sake of testing with comprahencable values 32 bits are used
		);
	    port ( 
			--input controll
			valid_in	: in std_logic;
			ready_in	: out std_logic;

			--input data
			message 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
			key 		: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

			--ouput controll
			ready_out	: in std_logic;
			valid_out	: out std_logic;

			--output data
			result 	: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

			--modulus
			modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

			--utility
			clk 		: in std_logic;
			reset_n 	: in std_logic
	        );
	end component;



	-----------------------------------------------------------------------------
	-- Signal declaration
	-----------------------------------------------------------------------------
	-- UUT signals
		-- utility
	signal clk 		: std_logic := '0';
	signal reset_n 	: std_logic := '0';		-- 
		-- input controll
	signal valid_in	: std_logic := '0';		-- edit
	signal ready_in	: std_logic := '0';		-- check if correct
		-- IO data
	signal msgin_data	: std_logic_vector(C_block_size-1 downto 0) := (others => '0');
	signal msgout_data 	: std_logic_vector(C_block_size-1 downto 0);
		-- 
	signal key_e 		: std_logic_vector(C_block_size-1 downto 0) := (others => '0');
	signal key_n 		: std_logic_vector(C_block_size-1 downto 0) := (others => '0');

		-- ouput controll
	signal ready_out	: std_logic := '0'; 	-- edit
	signal valid_out	: std_logic := '0'; 	-- check if correct 

begin

	-----------------------------------------------------------------------------
	-- purpose: control the clk-signal
	-- type   : sequential
	-- inputs : none
	-----------------------------------------------------------------------------
	p_clk : process
	begin
		clk <= not clk after T_clk/2;
	end process p_clk;

	p_key_set : process
  	begin
		key_e <= ("00101101", others => '0');        -- To small change
		key_n <= ("10001101", others => '0');        -- To small change
	end process;

	-----------------------------------------------------------------------------
	-- Instantiations for unit under test
	-----------------------------------------------------------------------------
	UUT : exponentiation_test
	    port map 
	     (
			clk => clk,
	        	rst => rst,
	        	valid_in => valid_in,
		   	ready_in => ready_in,
	        	msgin_data => msgin_data,
	        	key_e => key_e,
	        	key_n => key_n,
	        	msgout_data => msgout_data
		);

	msg_test : process


	begin
		--log(ID_LOG_HDR, "Start of simulation");
	    	wait for 45 ns;

	    	--wait for 60 ns;
	    	-- assert ( ascii_display = "11000000") -- Test if recieved byte is displayed as 0
		-- 	report "msg"
		--	severity error;
	    	--wait;
	end process;
end Behavioral;


-- 10 - 20 key sett

-- ascii 

-- rdy bits correct
-- 