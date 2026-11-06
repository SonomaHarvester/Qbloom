package main

/*
#include <stdint.h>
#include <stdlib.h>
*/
import "C"

import (
	"example.com/qbloom/{{TARGET}}/backend/logic"
	"sync"
	"unsafe"
)

var states = struct {
	sync.Mutex
	next  uint64
	items map[uint64]*logic.Counter
}{items: make(map[uint64]*logic.Counter)}

func state(handle C.ulonglong) *logic.Counter {
	states.Lock()
	defer states.Unlock()
	return states.items[uint64(handle)]
}

//export GoGreeting
func GoGreeting() *C.char { return C.CString(logic.Greeting()) }

//export GoFreeString
func GoFreeString(value *C.char) { C.free(unsafe.Pointer(value)) }

//export GoNewState
func GoNewState() C.ulonglong {
	states.Lock()
	defer states.Unlock()
	states.next++
	states.items[states.next] = new(logic.Counter)
	return C.ulonglong(states.next)
}

//export GoDestroyState
func GoDestroyState(handle C.ulonglong) {
	states.Lock()
	defer states.Unlock()
	delete(states.items, uint64(handle))
}

//export GoCount
func GoCount(handle C.ulonglong, output *C.int) C.int {
	if output == nil {
		return -1
	}
	c := state(handle)
	if c == nil {
		return -1
	}
	*output = C.int(c.Count())
	return 0
}

//export GoIncrement
func GoIncrement(handle C.ulonglong, output *C.int) C.int {
	if output == nil {
		return -1
	}
	c := state(handle)
	if c == nil {
		return -1
	}
	*output = C.int(c.Increment())
	return 0
}

//export GoReset
func GoReset(handle C.ulonglong, output *C.int) C.int {
	if output == nil {
		return -1
	}
	c := state(handle)
	if c == nil {
		return -1
	}
	*output = C.int(c.Reset())
	return 0
}

func main() {}
