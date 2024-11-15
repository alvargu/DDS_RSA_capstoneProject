library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_input_handler is
     generic(
          C_block_size : integer := 256;
          C_CORE_CNT : integer := 15
     );
     port(
        -----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : inout std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : inout std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  inout std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  inout std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		--msgout_valid            : inout std_logic;
		-- Slave ready to accept a new message
		--msgout_ready            :  inout std_logic;
		-- Message that will be sent out of the rsa_msgin module
		--msgout_data             : inout std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		--msgout_last             : inout std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
		--rsa_status              : inout std_logic_vector(31 downto 0)
     );
end entity;

architecture rtl of rsa_input_handler is
     


begin



end architecture;
