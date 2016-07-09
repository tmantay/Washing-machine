--MÁQUINA DE LAVAR V 3.0

-- botões, switches and keys

--  =========================
--				MÁQUINA
--  =========================


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY maquina IS
PORT (
	-------------- ENTRADAS
		Reset : IN STD_LOGIC;
		CLOCK_50: IN  STD_LOGIC;
		--SENSORES

		--BOTÕES
			KEY: IN  STD_LOGIC_VECTOR(3 downto 0);
			SW : IN STD_LOGIC_VECTOR(15 downto 0);
				
				--SWITCH - sensores					BOTÕES - entrada
				--SW(0) <= sen_porta_aberta;		KEY(0) <= ENTER
				--SW(1) <= sen_agua_max;			KEY(1) <= TROCA
				--SW(2) <= sen_agua_min;			KEY(2) <= CANCELA
				--SW(3) <= sen_tampa;				KEY(3) <= RESET
			
	-------------- SAÍDAS
			--ATUADORES
			motor_lig, motor_dir, trancar_porta, sai_agua, ent_agua: OUT STD_LOGIC:= '0';
			--LEDS
			LEDG:	OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			LEDR: OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
	 );
END maquina;


ARCHITECTURE bc OF maquina IS

TYPE state_type IS (S1,S2,S3,S4,S5,S6,S7,S8,S8A,S8B,S8C,S8D,S9,S10);

TYPE programa_lavagem IS (NORMAL, SUJA);
SIGNAL sen_tampa, sen_porta_aberta, sen_agua_min, sen_agua_max : STD_LOGIC := '0';
SIGNAL b_enter, b_troca, b_cancel, b_reset : STD_LOGIC:= '0';
SIGNAL state: state_type;
SIGNAL programa,prog_select: programa_lavagem;
SIGNAL sin_motor_lig, sin_motor_dir, sin_trancar_porta, sin_sai_agua, sin_ent_agua: STD_LOGIC:= '0';
SIGNAL prog_sel,op: STD_LOGIC_VECTOR(1 downto 0);
SIGNAL entra: STD_LOGIC;
SIGNAL t_molho, t_lava, t_centrif, temp1,temp2,cont1,cont2: INTEGER RANGE 0 TO 18000:= 0; -- 5 horas MAX
SIGNAL count_meio_seg:  integer range 0 to 24999999 	:= 24999999; 	--1/2 de segundo  F=50MHz
SIGNAL count_seg:  integer range 0 to 49999999 	:= 49999999 ; 			--1 segundo 		F=50MHz
					
BEGIN
	

--############################
--# LÓGICA DE PROXIMO ESTADO #
--############################

PROCESS (CLOCK_50, b_reset)
BEGIN

				LEDG(0) <= sin_motor_dir;
				LEDG(1) <= sin_motor_lig;
				LEDG(2) <= sin_sai_agua;
				LEDG(3) <= sin_ent_agua;
		
				sen_porta_aberta <= SW(0);	
				sen_agua_max <= SW(1);			
				sen_agua_min <= SW(2);			
				sen_tampa <= SW(3);
				
				LEDR(0) <= sen_porta_aberta;
				LEDR(1) <= sen_agua_max;
				LEDR(2) <= sen_agua_min;
				LEDR(3) <= sen_tampa;

				b_enter <= KEY(0);			
				b_troca <= KEY(1);			
				b_cancel <= KEY(2);
				b_reset <= KEY(3);
			
	IF(b_reset = '0') THEN
		state <= S1 ;		--RESET
		
	ELSIF (CLOCK_50'EVENT AND CLOCK_50 = '1') THEN
	
		CASE state IS
		
			WHEN S1 =>		--INICIA
						programa <= NORMAL;
						t_molho	<= 1;
						t_lava	<= 6; 		--6s
						t_centrif<= 3; 		--6s
						LEDR(17) <= '1';
						temp1 <= 0;
						
					IF(temp1 < 250000000 ) THEN			--executa até atingir o tempo de molho
								temp1 <= temp1 + 1;
					END IF;
					
--					IF(KEY(0) = '0') THEN
--							state <= S2;
--					ELSE 
--					state <= S3;
--					END IF;

--						IF(sen_agua_min = '1') THEN
--							state <= S2;				
--						END IF;	
--						IF(sen_agua_min = '0' AND sen_porta_aberta = '0') THEN
--							state <= S3;
--						END IF;	

			WHEN S2 =>		--ESVAZIAR MÁQUINA
			
						temp1 <= 0;
						LEDR(17) <= '0';
						LEDR(16) <= '1';
						
							IF(temp1 < 250000000 ) THEN			--executa até atingir o tempo de molho
								temp1 <= temp1 + 1;
							END IF;
					
						IF(KEY(0) = '0') THEN
							IF(sen_agua_min = '0') THEN
							state <= S2;			
							ELSE
							state <= S3;	
							END IF;
						END IF;							
						
			WHEN S3 =>		--ESCOLHE PROGRAMA OU EXECUTA
			
						--MOSTRA: variavel programa 
			
--						IF(KEY(0) = '1') THEN	--ENTER PRESSIONADO
--							b_enter <= '1';
--						END IF;
--						
--						IF(KEY(1) = '1')	THEN	--TROCA PRESSIONADO
--							b_troca <= '1';
--						END IF;
						LEDR(16) <= '0';
						LEDR(15) <= '1';
						
						IF(KEY(0)= '0') THEN 	--EXECUTA
							state <= S5;
						END IF;
						
						IF(KEY(1)= '0') THEN 	--SEM ÁGUA
							state <= S4;
						END IF;	
			
			WHEN S4 =>		-- -> SUJA
			
						LEDR(15) <= '0';
						LEDR(14) <= '1';
						programa <= SUJA;
						t_molho	<= 10;		--10s
						t_lava	<= 10; 		--10s
						t_centrif<= 5;			--5s
						state <= S5;
			WHEN S5 => 		--EXECUTAR
			
						LEDR(14) <= '0';
						LEDR(13) <= '1';
						
						IF(b_enter = '0') THEN 	--EXECUTA
							state <= S6;
						END IF;

			
			WHEN S6 =>		-- ENCHER
		
						LEDR(13) <= '0';
						LEDR(12) <= '1';
						IF(b_enter= '1') THEN 	--EXECUTA
							IF(sen_agua_max = '0') THEN
							state <= S9;
							ELSE state <= S10;
							END IF;
							state <= S7;
						END IF;
			
			
			WHEN S7 =>		-- MOLHO
		
						LEDR(12) <= '0';
						LEDR(11) <= '1';
						temp2 <= 0;
						temp1 <= 0;
						
						
						IF(temp1 < t_molho ) THEN			--executa até atingir o tempo de molho
							IF(temp2 < count_seg) THEN			--1 segundo
								temp2 <= temp2 + 1;
							END IF;
						temp1 <= temp1 + 1;	
						END IF;
						temp1 <= 0;
						state <= S8;
			
			
			WHEN S8 => 		--LAVAR
			
						LEDR(11) <= '0';
						LEDR(10) <= '1';
						
						IF (temp1 < t_lava) THEN	--esse estado controla o tempo total de lavagem
						state <= S8A;					--chama a outra FSM que faz 2 ciclos = 2 segundos
						temp1 <= temp1 + 2;
						ELSE state <= S9;				--pula para o próximo ciclo
						END IF;
				
     --MÁQUINA DE ESTADOS DA LAVAGEM

				WHEN S8A =>	--LAVAR > Liga motor - direçao 0
			
						LEDR(10) <= '0';
						LEDR(9) <= '1';
						temp2 <= 0;
						IF(temp2 < count_meio_seg) THEN			--1/2 segundo
							temp2 <= temp2 + 1;
						ELSE 
						LEDG(5) <= '1';
						state <= S8B;
						END IF;
			
				
				WHEN S8B =>	--LAVAR > Desliga motor 
				
						temp2 <= 0;
						IF(temp2 < count_meio_seg) THEN			--1/2 segundo
								temp2 <= temp2 + 1;
						ELSE 
							LEDG(5) <= '0';
							state <= S8C;
						END IF;
		
				
				WHEN S8C =>	--LAVAR > Liga motor -  direçao 1
				
						temp2 <= 0;
						IF(temp2 < count_meio_seg) THEN			--1/2 segundo
							temp2 <= temp2 + 1;
						ELSE state <= S8D;
						END IF;
			
				
				WHEN S8D =>	--LAVAR > Desligar motor
				
						temp2 <= 0;
						IF(temp2 < count_meio_seg) THEN			--1/2 segundo
							temp2 <= temp2 + 1;
						ELSE 
						LEDG(5) <= '1';
						state <= S8;					--volta para o a FSM principal
						END IF;
						
				-- FIM DA FSM MÁQUINA DE ESTADOS DA LAVAGEM
	
				
			WHEN S9 => 		--ESVAZIAR
						IF(sen_agua_min = '1') THEN
						state <= S9;
						ELSE state <= S10;
						END IF;
				
						
			WHEN S10 =>		--CENTRIFUGAR
						temp1 <= 0;
						IF(temp1 < t_centrif ) THEN
								temp2 <= 0;
							IF(temp2 < count_seg) THEN			--1 segundo
								temp2 <= temp2 + 1;
						END IF;
						temp1 <= temp1 + 1;	
						END IF;
			
		END CASE;			--FIM DO CASE state

	END IF; 				--FIM DO IF CLK_50
	
	--FIM DA LÓGICA DE PROXIMO ESTADO
END PROCESS;


--###########################
--#	LÓGICA DE SAÍDA       #
--###########################

--PROCESS (state)
--BEGIN
--
--	CASE state IS
--		WHEN S1 =>		--INICIAR
--				motor_lig <= '0';
--				sin_motor_lig <= '0';
--
--		WHEN S2	=>		--ESVAZIAR
--				sai_agua <= '1';
--				sin_sai_agua <= '1';
--	
--		WHEN S3 =>		--PROGRAMAÇAO
--				sai_agua <= '0';
--				sin_sai_agua <= '0';
--				
--		WHEN S4 =>		--SUJA
--		
--				
--		WHEN S5 =>
--		
--		
--		WHEN S6 =>		--ENCHER
--					ent_agua <= '1';
--					sin_ent_agua <= '1';
--					
--		WHEN S7 =>		--MOLHO
--				
--	
--		WHEN S8 =>		--LAVAR	
--		
--
--			--     MÁQUINA DE ESTADOS DA LAVAGEM
--			
--			WHEN S8A =>						--LIGA MOTOR
--					motor_dir <= '0';		--DIREÇÃO: 0
--					motor_lig <= '1'; 
--					sin_motor_dir <= '0';		
--					sin_motor_lig <= '1';
--		
--			WHEN S8B =>						--DESLIGA MOTOR
--					motor_lig <= '0'; 
--					sin_motor_lig <= '0';
--					
--			WHEN S8C =>						--LIGA MOTOR
--					motor_dir <= '1';		----DIREÇÃO: 1
--					motor_lig <= '1';
--					sin_motor_dir <= '1';		
--					sin_motor_lig <= '1';
--					
--			WHEN S8D =>						--DESLIGA MOTOR
--					motor_lig <= '0';
--					sin_motor_lig <= '0';
--					
--				-- FIM
--					
--		WHEN S9 =>		--ESVAZIAR
--				sai_agua <= '1';
--				sin_sai_agua <= '1';
--				
--		WHEN S10 =>		--CENTRIFUGAR
--				motor_dir <= '1';
--				motor_lig <= '1';
--				sai_agua  <= '1'; 
--				sin_motor_dir <= '1';
--				sin_motor_lig <= '1';
--				sin_sai_agua  <= '1'; 
--				
--		END CASE;
--			
--	END PROCESS;
	--FIM DA LÓGICA DE SAÍDA
END bc;