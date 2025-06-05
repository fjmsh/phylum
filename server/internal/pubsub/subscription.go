package pubsub

import (
	"sync"

	"github.com/sirupsen/logrus"
)

type Subscription interface {
	NotificationC() <-chan string
	EstablishedC() <-chan struct{}
	Cancel()
}

type subscription struct {
	channelName string
	listenChan  chan string
	notifier    *notifier

	establishedChan chan struct{}
	unlistenOnce    sync.Once
}

func (s *subscription) NotificationC() <-chan string { return s.listenChan }

// EstablishedC is a channel that's closed after the Notifier has successfully
// established a connection to the database and started listening for updates.
//
// There's no full guarantee that the notifier will successfully establish a
// listen, so callers will usually want to `select` on it combined with a
// context done, a stop channel, and/or a timeout.
func (s *subscription) EstablishedC() <-chan struct{} { return s.establishedChan }

func (s *subscription) Cancel() {
	s.unlistenOnce.Do(func() {
		if err := s.notifier.unsubscribe(s); err != nil {
			logrus.Errorf("error cancelling subscription on %s: %s", s.channelName, err)
		}
	})
}
