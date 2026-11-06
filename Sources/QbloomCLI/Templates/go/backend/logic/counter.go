package logic

import "sync"

// Counter owns the QML-visible state. The C++ facade only relays updates.
type Counter struct {
	mu    sync.Mutex
	count int
}

func Greeting() string { return "Hello, world!" }

func (c *Counter) Count() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.count
}

func (c *Counter) Increment() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.count++
	return c.count
}

func (c *Counter) Reset() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.count = 0
	return c.count
}
