library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_input_handler is
     generic(
          C_block_size : integer := 256;
          C_status_size : integer := 32;
          C_msg_id_size : integer := 4;
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
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

          -----------------------------------------------------------------------------
		-- Output handler communication
		-----------------------------------------------------------------------------
          h_core_id : out std_logic_vector(C_msg_id_size-1 downto 0);
          -- Indicates boundary of last packet
		il_msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Core interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		il_msgin_valid             : out std_logic_vector(C_CORE_CNT-1 downto 0);
		-- Slave ready to accept a new message
		il_msgin_ready             :  in std_logic_vector(C_CORE_CNT-1 downto 0);
		-- Message that will be sent out of the rsa_msgin module
		il_msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                  :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                    :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          -- Description...
		input_handler_rsa_status : out std_logic_vector((C_status_size/2)-1 downto 0)
     );
end entity;

architecture rtl of rsa_input_handler is
     ---------------------------------------------------------------------
     -- Output handler signals
     ---------------------------------------------------------------------
     signal core_id: std_logic_vector(C_msg_id_size-1 downto 0); --output
     signal core_id_recieved: std_logic; -- input
     signal core_id_sent: std_logic; -- output

     ---------------------------------------------------------------------
     -- Core handling signals
     ---------------------------------------------------------------------
     signal msgin_ready_sel: std_logic_vector(C_CORE_CNT-1 downto 0); -- input
     signal msgin_cs: std_logic_vector(C_CORE_CNT-1 downto 0); -- output

     -- h_core_id : out std_logic_vector(C_msg_id_size-1 downto 0)
     -- actual signal of architecture
     signal h_core_id_temp: std_logic_vector(C_id_size-1 downto 0);

begin


p_ID_output_handler : process (all) 
begin
     h_core_id <= std_logic_vector(h_core_id_temp);
end process;

end architecture;
