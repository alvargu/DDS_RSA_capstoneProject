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
	constant C_block_size : integer := 256; -- blocksize for final implementation should be 256 bits,
	constant Testing_bits : integer := 8;  -- for the sake of testing and verifying the result with python, small values of 8 bits are tested

	component exponentiation
	    port (  
            --input control
            valid_in	: in STD_LOGIC;
            ready_in	: out STD_LOGIC;
    
            --input data
            message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
            key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
    
            --output control
            ready_out	: in STD_LOGIC;
            valid_out	: out STD_LOGIC;
    
            --output data
            result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);
    
            --modulus
            modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
    
            --utility
            clk 		: in STD_LOGIC;
            reset_n 	: in STD_LOGIC
	        );
	end component;



	-----------------------------------------------------------------------------
	-- Signal declaration
	-----------------------------------------------------------------------------
	-- UUT signals
		-- utility
	signal clk 		: std_logic := '0';
	signal reset_n 	: std_logic := '1';		-- 
		-- input controll
	signal valid_in	: std_logic := '0';		-- edit
	signal ready_in	: std_logic := '0';		-- check if correct
		-- IO data
	signal message	: std_logic_vector(C_block_size-1 downto 0); --:= (others => '0');
	signal result 	: std_logic_vector(C_block_size-1 downto 0);
		-- 
	signal key 		: std_logic_vector(C_block_size-1 downto 0); --:= (others => '0');
	signal modulus 		: std_logic_vector(C_block_size-1 downto 0); --:= (others => '0');

		-- ouput controll
	signal ready_out	: std_logic := '0'; 	-- edit
	signal valid_out	: std_logic := '0'; 	-- check if correct 

begin

	-----------------------------------------------------------------------------
	-- Instantiations for unit under test
	-----------------------------------------------------------------------------
	UUT : exponentiation
	    port map 
	     (
			    valid_in => valid_in,
                ready_in => ready_in,
                message => message,
                key => key,
                ready_out => ready_out,
                valid_out => valid_out,
                result => result,
                modulus => modulus,
                clk => clk,
                reset_n => reset_n
		);

	-----------------------------------------------------------------------------
	-- purpose: control the clk-signal
	-- type   : sequential
	-- inputs : none
	-----------------------------------------------------------------------------
	
    	clk <= not clk after T_clk/2;
		

    -----------------------------------------------------------------------------
	-- Initializing key and modulus values
    -----------------------------------------------------------------------------
	p_key_set : process
  	begin
	key(C_block_size-1 downto Testing_bits) <= (others => '0');
        key(Testing_bits-1 downto 0) <= "00101101";  --45    -- To small change
	modulus(C_block_size-1 downto Testing_bits) <= (others => '0');
        modulus(Testing_bits-1 downto 0) <= "10001101";  --141      -- To small change
        wait;
	end process;

	-----------------------------------------------------------------------------
	-- External signal from rsa_msgin, signaling that the data is valid
    -----------------------------------------------------------------------------
    rsa_msgin_valid : process
    begin
        wait for 300 us;
        valid_in <= '1';
        wait for 10 ns;
        valid_in <= '0';
        wait for 3 ms;
        valid_in <= '1';
        wait for 10 ns;
        valid_in <= '0';
        wait for 3 ms;
        valid_in <= '1';
        wait for 10 ns;
        valid_in <= '0';
        wait for 3 ms;
        valid_in <= '1';
        wait for 10 ns;
        valid_in <= '0';
        wait for 3 ms;
        valid_in <= '1';
        wait for 10 ns;
        valid_in <= '0';
        wait for 3 ms;
        valid_in <= '1';
        wait;
    end process;
    
    -----------------------------------------------------------------------------
    -- External signal from rsa_msgout, signaling that it is ready to recieve the result
    -----------------------------------------------------------------------------
    
    rsa_msgout_ready : process
    begin
        wait for 3 ms;
        ready_out <= '1';
        wait for 10 ns;
        ready_out <= '0';
        wait for 3 ms;
        ready_out <= '1';
        wait for 10 ns;
        ready_out <= '0';
        wait for 3 ms;
        ready_out <= '1';
        wait for 10 ns;
        ready_out <= '0';
        wait for 3 ms;
        ready_out <= '1';
        wait for 10 ns;
        ready_out <= '0';
        wait for 3 ms;
        ready_out <= '1';
        wait for 10 ns;
        ready_out <= '0';
        wait for 3 ms;
        ready_out <= '1';
        wait;
    end process;

    -----------------------------------------------------------------------------
	-- Message stream "GROUP5" in ASCII stream of 'G' 'R' 'O' 'U' 'P' '5', one at a time
	-----------------------------------------------------------------------------
	msg_test : process
	begin
	--log(ID_LOG_HDR, "Start of simulation");
	message(C_block_size-1 downto Testing_bits) <= (others => '0');
       message(Testing_bits-1 downto 0) <= "01000111"; -- Decimal 72, or ASCII 'G'. Expected result: 2
	   wait for 3 ms;
	message(C_block_size-1 downto Testing_bits) <= (others => '0');
       message(Testing_bits-1 downto 0) <= "01010010"; -- Decimal 82, or ASCII 'R'. Expected result: 43
       wait for 3 ms;
	message(C_block_size-1 downto Testing_bits) <= (others => '0');
       message(Testing_bits-1 downto 0) <= "01001111"; -- Decimal 79, or ASCII 'O'. Expected result: 25
       wait for 3 ms;
	message(C_block_size-1 downto Testing_bits) <= (others => '0');
       message(Testing_bits-1 downto 0) <= "01010101"; -- Decimal 85, or ASCII 'U'. Expected result: 73
       wait for 3 ms;
	message(C_block_size-1 downto Testing_bits) <= (others => '0');
       message(Testing_bits-1 downto 0) <= "01010000"; -- Decimal 80, or ASCII 'P'. Expected result: 104
       wait for 3 ms;
	message(C_block_size-1 downto Testing_bits) <= (others => '0');
       message(Testing_bits-1 downto 0) <= "00110101"; -- Decimal 53, or ASCII '5'. Expected result: 8
       wait;
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
