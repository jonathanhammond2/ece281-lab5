----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

--signal for calculations
signal w_res : signed(8 downto 0);

begin
    process(i_A, i_B, i_op)
    begin 
        case i_op is
            when "000" => --addiiton
                w_res <= signed(i_A) + signed(i_B);
            when "001" => --subtraction
                 w_res <= signed(i_A) - signed(i_B);
            when "010" => --bitwise AND
                 w_res <= signed(i_A and i_B);
            when "011" => --bitwise OR
                 w_res <= signed(i_A or i_B);
            when others => --default
                 w_res <= (others => '0');
        end case;
    end process;
    
    o_result <= std_logic_vector(w_res);
    
    --flag logic:
    
    o_flags(3) <= std_logic(w_res(7)); --negative flag is MSB of result
    
    o_flags(2) <= '1' when (w_res = 0) else '0';
    
    o_flags(1) <= w_res(8);
    
    o_flags(0) <= (i_A(7) xnor i_B(7)) and (i_A(7) xor w_res(7));


    

end Behavioral;
