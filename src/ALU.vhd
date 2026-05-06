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
signal w_res : signed(7 downto 0);


begin
    process(i_A, i_B, i_op)
    variable v_res : unsigned(8 downto 0);
    variable v_A, v_B : unsigned(8 downto 0);
    
    begin 
        v_A := unsigned('0' & i_A);
        v_B := unsigned('0' & i_B);
        
    
        case i_op is
            when "000" => --addiiton
                v_res := v_A + v_B;
            when "001" => --subtraction
                 v_res := v_A + unsigned(not ('0' & i_B)) + 1;
            when "010" => --bitwise AND
                 v_res := '0' & (unsigned(i_A) and unsigned(i_B));
            when "011" => --bitwise OR
                 v_res := '0' & (unsigned(i_A) or unsigned(i_B));
            when others => --default
                v_res := (others => '0');
        end case;
        o_result <= std_logic_vector(v_res(7 downto 0));
        o_flags(3) <= v_res(7); --N
        if v_res(7 downto 0) = x"00" then o_flags(2) <= '1';
        else o_flags(2) <= '0';
        end if;
        
        if i_op = "000" or i_op = "001" then
            o_flags(1) <= v_res(8);
        else
            o_flags(1) <= '0';
        end if;

        -- V: Overflow flag (Signed math error)
        if i_op = "000" then -- Addition Overflow
            o_flags(0) <= (i_A(7) xnor i_B(7)) and (i_A(7) xor v_res(7));
        elsif i_op = "001" then -- Subtraction Overflow
            o_flags(0) <= (i_A(7) xor i_B(7)) and (i_A(7) xor v_res(7));
        else
            o_flags(0) <= '0';
        end if;

    end process;
    
--    o_result <= std_logic_vector(w_res(7 downto 0));
    
    --flag logic:
    
--    o_flags(3) <= std_logic(w_res(7)); --negative flag is MSB of result N
    
--    o_flags(2) <= '1' when (w_res = 0) else '0'; --Z
    
--    o_flags(1) <= '1' when unsigned(i_A) + unsigned(i_B) > 255 else '0'; --C
    
--    o_flags(0) <= (i_A(7) xnor i_B(7)) and (i_A(7) xor w_res(7)); --V


    

end Behavioral;
