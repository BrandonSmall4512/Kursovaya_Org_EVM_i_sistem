-- этот файл содержит описание операционного устройства для выполнения умножения и сложения
-- он представляет собой vhdl описание схемного проекта contr_unit_BO, представленного на верхнем уровне как МУУ(файл control unit) + БО (файл BO)
-- В описании представлено entity и архитектурное тело операционного устройства
-- Операнды n разрядные

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ctrl_un_BO is
generic (n:integer);     -- n параметр, задает разрядность операндов
	port
	(
		a : in  STD_LOGIC_VECTOR (n-1 downto 0);-- первый операнд		
		b : in  STD_LOGIC_VECTOR (n-1 downto 0);-- второй операнд
		clk		 : in	std_logic; -- тактовый сигнал
		set 		 : in	std_logic; --  сигнал начальной установки
		cop		 : in	std_logic; --  код операции 1-умножение,0 - сложение

		sno		 : in	std_logic; -- сигнал начала операции
		rr 		 : buffer  STD_LOGIC_VECTOR (2*n-1 downto 0);-- результат
      priznak 	 : out  STD_LOGIC_VECTOR (1 downto 0); -- признак результата
		sko	 	 : out	std_logic -- сигнал конца операции

	);

end entity;

architecture arch of ctrl_un_BO is

	type state_type is (s0, s1, s2, s3, s4); -- определяем состояния МУУ

	signal next_state, state : state_type; -- следующее состояние, текущее состояние
	signal i : integer range 1 to n-1 ;    -- счетчик анализируемых разрядов множителя
	signal incr_i	 :std_logic;            -- разрешение инкремента i
	signal RA	:STD_LOGIC_VECTOR (2*n-1 downto 0);-- для запоминания а и в
	signal RB  	:STD_LOGIC_VECTOR (n-1 downto 0);-- для запоминания а и в

signal d  		:STD_LOGIC_VECTOR (2*n-1 downto 0);-- выход КС1
signal q  		:STD_LOGIC_VECTOR (2*n-1 downto 0);-- выход КС2
signal s  		:STD_LOGIC_VECTOR (2*n-1 downto 0);-- выход сумматора
signal pr  		:STD_LOGIC_VECTOR (1 downto 0);-- выход КС3
signal sym     :STD_LOGIC_VECTOR (2*n downto 0); -- для вычисления суммы
signal rrr  		:STD_LOGIC_VECTOR (2*n-1 downto 0);-- выход сумматора
signal x			:std_logic_vector (3 downto 1);-- логические условия
signal y	 		:std_logic_vector(12 downto 1); -- управляющие сигналы для блока операций

begin

TS: process (clk,set) -- этот процесс определяет текущее состояние МУУ
	 begin
		if set = '1' then
			state <= s0;
		elsif (rising_edge(clk)) then -- по положительному фронту переключаются состояния
			state <= next_state;			
		end if;
	 end process;
	 
NS: process (state,sno,cop,x,i) -- этот процесс определяет следующее состояние МУУ, управляющие сигналы для БО
	 begin
			case state is
				when s0=> -- переходы из s0
				 if  (sno = '1' and cop='1') then	-- если вторая операция
						next_state <= s1; y<="110101100110";
					elsif (sno = '1' and cop='0') then	-- 
						next_state <= s4; y<="110011100110";
						elsif (sno = '0' ) then	
						next_state <= s0; y<="000000000000"; 
					end if;		
						
					
				when s1=> 
				next_state <= s2;
				
				if cop='0' and x(2) = '1'  then
						y<="000001101000"; -- rr=rr +RA  													
					elsif cop='0' and x(2) = '0'  then
						y<="000000000000"; -- rr=rr+0 - пропускаем и делаем сдвиг 
					elsif  cop='1' then	-- если приращение
						y<="000101101000"; 
						
					end if;
					--end if;
					
				when s2=>
					if i = n-1 then
						next_state <= s3; y<="000001100001"; -- формируем сигнал конца операции
					elsif cop='0' then 							-- если умножение
						next_state <= s1; y<="100000000100";  -- иначе сдвиг rа, сдвиг RB
					elsif cop='1' then			-- если 2оп
					   next_state <= s3; y<="001100000000";  -- иначе запись признака в RPR
					end if;
					
				when s3 =>
						next_state <= s0; y<="000000000000";  -- иначе запись признака в RPR						
				when s4 =>
						next_state <= s1; y<="100000000000";  -- формируем сигнал конца операции
				
			end case;			
	end process;
	
	sko<='1' when (state=s3 and (i=n-1))  or state =s3 else -- формирование sko
			'0';
	incr_i<='1' when state=s2 and cop='0' and i/=n-1 else --инкремент i, когда умножение и не последний разряд множителя
			'0';
			
count_i:   process (sno, clk) -- этот процесс определяет поведение счетчика i
	
	begin
		if (sno='1') then i<=1; --устанавливаем в начальное состояние
		elsif clk'event and clk='1' then 
		  if (incr_i='1') then i<=i+1; -- инкремент счетчика
		  end if;
		 end if;
	end process;
	

       
pr_RA: process (clk) -- этот процесс описывает логику работы регистра RA сдвиговый
	begin
      if clk'event and clk='1' then -- по положительному фронту 
		 if y(12)='1' and  y(11)='1' and y(9) = '0' then -- если есть разрешение тактирования
                 RA(2*n-1 downto n) <= a; 
					  RA(n-1 downto 0) <=(others => '0');
					  
                elsif y(11)='0' and y(12)='1' then  RA <= RA(2*n-1) & RA(2*n-1 downto 1); -- циклический сдвиг 
			
                end if;
			if y(12)='1' and  y(11)='1'  and y(9)='1' then -- если есть разрешение тактирования
                 RA(2*n-1 downto n) <= (others => '0') ; 
					  RA(n-1 downto 0) <= a;		 
					end if;
				end if;
	end process pr_RA;
		
pr_RB: process(clk) -- этот процесс описывает логику работы регистра RB
    begin
        if clk'event and clk='1' then  -- по положительному фронту 
            if y(3) = '1' then -- если есть разрешение тактирования
                if y(2) = '1' then 
                    RB <= b; -- если разрешена загрузка, то прием второго операнда
                else 
                    RB <=RB(n-1) & RB(n-3 downto 0)&'0'; -- иначе сдвиг с сохранением знака
                end if;
            end if;
        end if;
    end process pr_RB;

-- КС1
with y(4) select
	d(2*n-1 downto 0)<= '0' & RA(2*n-2 downto 0)   when '1',-- передаем +А(в старшие)если y4=1
	(others=>'0') when '0'; -- ноль в остальных случаях

-- КС2 
q(2*n-1 downto n)<=RR(2*n-1 downto n) when y(9)='0' else -- RR когда умножение
			(others=>'0'); -- старшая часть 0
			
q(n-1 downto 0)<=RR(n-1 downto 0) when y(9)='0' else -- когда умножение 
			(not RB(n-1)) & RB(n-2 downto 0); -- когда приращение
			
SM: process(d,q) 
variable sym:STD_LOGIC_VECTOR (2*n downto 0); -- для вычисления суммы
begin
 
sym:=('0'&d)+('0'&q);-- сложение
	if (sym(2*n)='1')then sym(2*n) :='0'; sym :=sym;
   end if;

s <=sym(2*n-1 downto 0);
end process SM;

-- КС5 - знак результата
ZN: process(RA, RB, y, s)
    variable z: STD_LOGIC;
begin
z := RA(2*n-1) xor RB(n-1); -- автоматически считает знак
    if y(1) = '1' then        
rrr  <= z & s(2*n-2 downto 0);
else
rrr  <= s(2*n-1 downto 0);
   
    end if;
end process ZN;

--znak<=z;
		
pr_RR: process (clk) -- этот процесс описывает работу регистра результата

begin
	if clk'event and clk='1' then	-- по положительному фронту синхросигнала
		if y(8)='1' then rr<=(others=>'0');   --очистка rr
		elsif (y(7)='1') then -- если есть разрешение тактирования
			if y(6)='1' then rr<=rrr;--загрузка rr
				
				
			end if;
		end if;
	end if;
end process pr_RR;

--ниже приводится описание КС3, которая формирует признак результата
	pr<="00" when rr(n downto 0 ) = 0  else -- результат равен нулю, нет переноса
		"01" when (rr (n) = '0') and rr(n-2 downto 0 ) > 0 else -- не 0 и нет переполнения
		"10" when (rr (n) = '1') and rr(n-1 downto 0 ) = 0  else -- переполнение
		"11"  ; -- результат меньше 0
		
pr_RPR: process(clk) --этот процесс описывает работу регистра признака
begin
	if clk'event and clk='1' then -- по положительному фронту 
		if y(10)='1' then priznak<=pr; -- запоминаем признак результата
		end if;
	end if;
end process pr_RPR;	
-- ниже приводится описание логических условий
x(1)<= RB(n-1);   --знак множителя
x(2)<= RB(n-2);	--	анализируемый разряд множителя
x(3)<= '0' when RR (n downto 0)=(2**(n+1))-1 else -- признак отрицательного нуля
			'0'; -- иначе ноль	



--	s_out<=0 when state=s0 else
--			 1 when state=s1 else					
--			 3;
--	next_state_out<=0 when next_state=s0 else
--			 1 when next_state=s1 else					
--			 2 when next_state=s2 else
--			 3;

end arch;
