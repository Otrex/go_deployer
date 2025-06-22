package utils

import (
	"bufio"
	"io"
	"sync"
)

type StreamManager struct {
	subscribers []chan string
	mu          sync.Mutex
}

func NewStreamManager() *StreamManager {
	return &StreamManager{}
}

func (s *StreamManager) Subscribe() chan string {
	ch := make(chan string, 100)
	s.mu.Lock()
	s.subscribers = append(s.subscribers, ch)
	s.mu.Unlock()
	return ch
}

func (s *StreamManager) Broadcast(msg string) {
	s.mu.Lock()
	for _, ch := range s.subscribers {
		select {
		case ch <- msg:
		default: // skip if full
		}
	}
	s.mu.Unlock()
}

func (s *StreamManager) Remove(ch chan string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for i, c := range s.subscribers {
		if c == ch {
			s.subscribers = append(s.subscribers[:i], s.subscribers[i+1:]...)
			close(c)
			break
		}
	}
}

func StreamOutput(pipe io.ReadCloser, stream *StreamManager) {
	scanner := bufio.NewScanner(pipe)
	for scanner.Scan() {
		stream.Broadcast(scanner.Text())
	}
}
