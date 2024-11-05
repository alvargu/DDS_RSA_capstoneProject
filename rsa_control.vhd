library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_control is
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