library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_exponentiation is
	generic (
		-- set clk frequency here
		f_clk : integer := 100_000_000;
		T_clk : time := (1 sec / f_clk) -- possible point of failure
	);
end tb_exponentiation;

architecture Behavioral of tb_exponentiation is

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
		message 	: in STD_LOGIC_VECTOR( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR( C_block_size-1 downto 0 );

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

signal clk 		: std_logic := '0';
signal reset_n 	: std_logic := '0';		-- 

signal valid_in	: std_logic := '0';		-- edit
signal ready_in	: std_logic := '0';		-- check if correct

signal msgin_data	: std_logic_vector(C_block_size-1 downto 0) := (others => '0');
signal msgout_data 	: std_logic_vector(C_block_size-1 downto 0);

signal key_e 		: std_logic_vector(C_block_size-1 downto 0) := (others => '0');
signal key_n 		: std_logic_vector(C_block_size-1 downto 0) := (others => '0');

--ouput controll
signal ready_out	: std_logic '0'; 		-- edit
signal valid_out	: std_logic '0'; 		-- check if correct 

begin

-------------------------------------------------------------------------------
-- Initiate clk
-------------------------------------------------------------------------------
clk <= not clk after T_clk;



key_e <= "00101101";        -- To small change
key_n <= "10001101";        -- To small change

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

msg_test : process (all) is
begin
    wait for 45 ns;
    wait for 60 ns;
    wait;
end process;
end Behavioral;


-- 10 - 20 key sett

-- ascii 

-- rdy bits correct
-- 