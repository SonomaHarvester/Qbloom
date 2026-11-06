package logic

import "testing"

func TestCounterContract(t *testing.T) {
	if got := Greeting(); got != "Hello, world!" {
		t.Fatalf("greeting = %q", got)
	}
	c := new(Counter)
	if got := c.Count(); got != 0 {
		t.Fatalf("initial count = %d", got)
	}
	if got := c.Increment(); got != 1 {
		t.Fatalf("first increment = %d", got)
	}
	if got := c.Increment(); got != 2 {
		t.Fatalf("second increment = %d", got)
	}
	if got := c.Reset(); got != 0 {
		t.Fatalf("reset = %d", got)
	}
}
