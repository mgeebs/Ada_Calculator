with Ada.Text_IO, Ada.Float_Text_IO, Unbound_Stack;
use Ada.Text_IO, Ada.Float_Text_IO;

-- procedure Float_Calc_Hedrick
procedure Float_Calc_Hedrick is

	package Unbound_Character_Stack is new Unbound_Stack(Character);
	package Unbound_Float_Stack is new Unbound_Stack(Float);
	use Unbound_Character_Stack, Unbound_Float_Stack;
	
	Buffer : String(1..1000);
	Last : Natural;
	Index : Integer := 1;
	Result : Float;
	Expect_Operand : Boolean := true;
	Paren_Count : Integer := 0; --count parenthesis to check for balance
	Expression_Error : exception;
	Parens_Allowed : Boolean := true; --true if a parenthesis is legal (not right after an operand)
	-- function Evaluate return Float
	-- Evaluates the floating point expression in Buffer and returns the result. An
	-- Expression_Error is raised if the expression has an error;
    function Evaluate return Float is
	    Operator_Stack : Unbound_Character_Stack.Stack;
	    Operand_Stack : Unbound_Float_Stack.Stack;
		Result : Float;
		
		-- function Precedence(Operator : Character) return Integer
		-- Returns the precedence of Operator. Raises Exception_Error if
		-- Operator is not a known operator.
		--     '+' | '-' => 0
		--     '*' | '/' => 1
		function Precedence(Operator : Character) return Integer is
		begin
		    case Operator is
		    	when '+' | '-' =>
		    		return 0;
		    	when '*' | '/' =>
		    		return 1;
		    	when others =>
		    		raise Expression_Error;
		    end case;
		end Precedence;

		-- procedure Apply
		-- Applies the top operator on the Operator_Stack to its right and left
		-- operands on the Operand Stack.
		procedure Apply is
		    Operator : Character;
			Left, Right : Float;
		begin -- Apply
		    Pop(Right, Operand_Stack);		--pop the right operand
		    Pop(Left, Operand_Stack);		--Pop the left operand
		    Pop(Operator, Operator_Stack);	--pop the operator

		    case Operator is
		    	when '+' =>	Push(Left + Right, Operand_Stack);--add
		    	when '-' =>	Push(Left - Right, Operand_Stack);--subtract
		    	when '*' => Push(Left * Right, Operand_Stack);--multiply
		    	when '/' => Push(Left / Right, Operand_Stack);--divide
		    	when others => raise Expression_Error;--this shouldn't be able to happen
		    end case;
		end Apply;

    	begin -- Evaluate
	    -- Process the expression left to right once character at a time.
	    while Index <= Last loop 
		    case Buffer(Index) is
		    	when ')' =>		--recursive base case, end of paren enclosure
			        --Apply;
		    		Index := Index + 1;
		    		Expect_Operand := false;		--expecting an operator after this
		    		Paren_Count := Paren_Count - 1;	--decrement the parens when a right paren comes
		    		while not Is_Empty(Operator_Stack) loop
						Apply;
					end loop;

		    		Pop(Result, Operand_Stack);
		    		Parens_Allowed := false;
					return Result;
				when '(' =>		--going to make a recrusive call
					if not Parens_Allowed then
						raise Expression_Error;
					end if;
					Paren_Count := Paren_Count + 1;	--add a paren when a left paren is encountered
					Expect_Operand := true;			--expecting an operand after the parenthesis
					Index := Index + 1;			
					Result := Evaluate;				--recursive calls to evaluate
					Push(Result, Operand_Stack);	--push the result
			    when '0'..'9' =>
				    -- The character starts an operand. Extract it and push it
					-- on the Operand Stack.
			        if not Expect_Operand then
				        raise Expression_Error;
				    end if;
			        declare
			            Value : Float := 0.0;			--whole portion
			            Fractional_Value : Float := 0.0;--decimal portion
			            Exponent : Integer := 1;		--Exponent for Sci notation
				    begin
				        while Index <= Last and then
						    Buffer(Index) in '0'..'9' loop
						    --Float() to change the initial integer to floating point
					        Value := Value*10.0+Float(Character'Pos(Buffer(Index))-Character'Pos('0'));
						    Index := Index + 1;
					    end loop;
					    --check for a decimal and add up the fractional portion
					    if Buffer(Index) = '.' then
					    	Index := Index + 1;
					    	Expect_Operand := true;
					    	--similar to enclosing loop to get decimal portion
					    	while Index <= Last and then
					    	Buffer(Index) in '0'..'9' loop
					    		Fractional_Value := Fractional_Value+Float(Character'Pos(Buffer(index))-Character'Pos('0'))/10.0**Exponent;
					    		Exponent := Exponent + 1;
					    		Index := Index + 1;
					    	end loop;

					    end if;

					    Push(Value + Fractional_Value, Operand_Stack); --the entire value is on the stack now
					    Expect_Operand := false;	--should not see an operand right now
					    Parens_Allowed := false;	--should not see a parenthesis right now
				    end;
			    when '+' | '-' | '*' | '/' =>
				    -- The character is an operator. Apply any pending operators
					-- (on the Operator_Stack) whose precedence is greater than
					-- or equal to this operator. Then, push the operator on the
					-- Operator_Stack.
			        while not Is_Empty(Operator_Stack) --only apply if the stack has operators
			        and then Precedence(Buffer(Index)) <= Precedence(Top(Operator_Stack)) loop
			        	Apply;
			        end loop;
			        Push(Buffer(Index), Operator_Stack); --push the operator to the stack
			        Expect_Operand := true; --we know to expect an operand next
			        Parens_Allowed := true; --can have parens after an operator
			        Index := Index + 1;		--increment the index

			    when ' ' =>  	-- The character is a space. Ignore it
			    	Index := Index + 1;
				   
			    when others =>
				    -- The character is something unexpected. Raise
					-- Expression_Error.
				    raise Expression_Error;
			end case;
		end loop;
		-- We are at the end of the expression. Apply all of the pending
		-- operators. The operand stack must have exactly one value, which is
		-- returned.

		while not Is_Empty(Operator_Stack) loop
			Apply;
		end loop;

		Pop(Result, Operand_Stack);
		return Result;
		
	exception
		when Unbound_Character_Stack.Underflow |
		     Unbound_Float_Stack.Underflow =>
		    raise Expression_Error;
	end Evaluate;
	
begin -- Calculator
	Put_Line("Calculator by Michael Hedrick, CSCI3415");
	Put_Line("Type an expression containing only +,-,*,/,(, and )");
	Put_Line("Or pipe input from a file via command line");
    -- Process all of the expression in standard input.
    while not End_of_File loop
	    -- Read the next expression, evaluate it, and print the result.
	    begin
	        Get_Line(Buffer, Last);
			Put_Line(Buffer(1..Last));
		    Index := 1;
			Expect_Operand := True;
			Parens_Allowed := true;
			Paren_Count := 0;
            Result := Evaluate;
            if Paren_Count /= 0 then
            	raise Expression_Error;
            end if;
	        Put(Result,0);
		    New_Line;
		exception
		    when Expression_Error => Put_Line("EXPRESSION ERROR");
			when others => Put_Line("ERROR");
		end;
	end loop;
end Float_Calc_Hedrick;
