library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_control is
     generic(
          C_block_size : integer := 32
     );
     port(
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
end entity;

architecture Behavioral of rsa_control is

component exponentiation 
	port(
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


-------------------------------------------------------------------------------
-- Internal signal declaration
-------------------------------------------------------------------------------
signal valid_in_1 :



begin
-------------------------------------------------------------------------------
-- Port mapping to exponentiation modules (rsa modules)
-------------------------------------------------------------------------------
module_1 : exponentiation port map (
	valid_in => valid_in_1,
	ready_in => ready_in_1,
	message => message_1,
	key => key_1,
	ready_out => ready_out_1,
	valid_out => valid_out_1,
	result => result_1,
	modulus => modulus_1,
	clk => clk_1,
     reset_n => reset_n_1,
);

module_2 : exponentiation port map (
	valid_in => valid_in_2,
	ready_in => ready_in_2,
	message => message_2,
	key => key_2,
	ready_out => ready_out_2,
	valid_out => valid_out_2,
	result => result_2,
	modulus => modulus_2,
	clk => clk_2,
     reset_n => reset_n_2,
);

module_3 : exponentiation port map (
	valid_in => valid_in_3,
	ready_in => ready_in_3,
	message => message_3,
	key => key_3,
	ready_out => ready_out_3,
	valid_out => valid_out_3,
	result => result_3,
	modulus => modulus_3,
	clk => clk_3,
     reset_n => reset_n_3,
);



end architecture;