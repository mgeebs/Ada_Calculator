generic
	type Item_Type is private;
package Unbound_Stack is
 	type Stack is private;
 	Underflow : exception;
 	procedure Push (Item : in Item_Type; Onto : in out Stack);
 	procedure Pop (Item : out Item_Type; From : in out Stack);
 	function Is_Empty (S : Stack) return Boolean;
 	function Top (S : Stack) return Item_Type;
private
 	type Cell;
 	type Stack is access Cell;
end Unbound_Stack;