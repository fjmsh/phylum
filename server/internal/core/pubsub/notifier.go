package pubsub

import (
	"context"
	"errors"
	"os"
	"slices"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
)

const waitTimeout = 30 * time.Second
const opTimeout = 10 * time.Second

type Notifier interface {
	Listen(channel string) Subscription
}

type notifier struct {
	mu                        sync.RWMutex
	listener                  *listener
	subscriptions             map[string][]*subscription
	pendingOps                []pendingOp
	cancelWaitForNotification context.CancelFunc
}

type pendingOp struct {
	op          pendingOpType
	channelName string
	callback    func()
}

type pendingOpType = uint8

const (
	pendingOpTypeListen   = iota
	pendingOpTypeUnlisten = iota
)

func Start(pool *pgxpool.Pool, ctx context.Context) (Notifier, error) {
	listener, err := newListener(pool, ctx)
	if err != nil {
		return nil, err
	}

	notifier := notifier{
		mu:                        sync.RWMutex{},
		listener:                  listener,
		subscriptions:             make(map[string][]*subscription),
		pendingOps:                []pendingOp{},
		cancelWaitForNotification: context.CancelFunc(func() {}),
	}

	go func() {
		for {
			notifier.processPendingOps(ctx)
			notification, err := notifier.waitOnce(ctx)
			if err != nil {
				if err.Error() == "conn closed" {
					logrus.Error("PGX Connection Closed. Exiting")
					os.Exit(1)
				}
				logrus.Error(err)
			}
			if notification != nil {
				notifier.notifyListeners(notification)
			}
		}
	}()

	return &notifier, nil
}

func (n *notifier) Listen(channel string) Subscription {
	n.mu.Lock()
	defer n.mu.Unlock()

	existingSubs := n.subscriptions[channel]

	sub := &subscription{
		channelName: channel,
		listenChan:  make(chan string, 2),
		notifier:    n,
	}
	n.subscriptions[channel] = append(existingSubs, sub)

	if len(existingSubs) > 0 {
		sub.establishedChan = existingSubs[0].establishedChan
		return sub
	}

	ch := make(chan struct{})
	sub.establishedChan = ch
	op := pendingOp{pendingOpTypeListen, channel, func() { close(ch) }}
	n.pendingOps = append(n.pendingOps, op)
	n.cancelWaitForNotification()

	return sub
}

// this needs to pull channelChange instances from the channelChange channel
// in order to perform LISTEN/UNLISTEN operations on the notifier.
func (n *notifier) processPendingOps(ctx context.Context) {
	n.mu.Lock()
	defer n.mu.Unlock()

	for _, u := range n.pendingOps {
		func() {
			ctx, cancel := context.WithTimeout(ctx, opTimeout)
			defer cancel()

			var err error
			switch u.op {
			case pendingOpTypeListen:
				err = n.listener.listen(ctx, u.channelName)
			case pendingOpTypeUnlisten:
				err = n.listener.unlisten(ctx, u.channelName)
			}

			if err != nil {
				logrus.Warnf("error completing op %v on channel %s: %s", u.op, u.channelName, err.Error())
			}
			u.callback()
		}()
	}
	n.pendingOps = nil
}

// waitOnce blocks until either 1) a notification is received and
// distributed to all topic listeners, 2) the timeout is hit, or 3) an external
// caller calls l.waitForNotificationCancel.
func (n *notifier) waitOnce(ctx context.Context) (*pgconn.Notification, error) {
	ctx, cancel := context.WithTimeout(ctx, waitTimeout)
	defer cancel()

	n.mu.Lock()
	n.cancelWaitForNotification = cancel
	n.mu.Unlock()

	notification, err := n.listener.waitForNotification(ctx)
	if err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			return nil, nil
		}

		return nil, err
	}
	return notification, nil
}

func (n *notifier) notifyListeners(notification *pgconn.Notification) {
	n.mu.RLock()
	defer n.mu.RUnlock()

	for _, sub := range n.subscriptions[notification.Channel] {
		select {
		case sub.listenChan <- notification.Payload:
		default:
			logrus.Warn("dropped notification due to full buffer", "payload", notification.Payload)
		}
	}
}

func (n *notifier) unsubscribe(sub *subscription) error {
	n.mu.Lock()
	defer n.mu.Unlock()

	n.subscriptions[sub.channelName] = slices.DeleteFunc(n.subscriptions[sub.channelName], func(s *subscription) bool {
		return s == sub
	})

	if len(n.subscriptions[sub.channelName]) == 0 {
		n.pendingOps = append(n.pendingOps, pendingOp{pendingOpTypeUnlisten, sub.channelName, func() {}})
		n.cancelWaitForNotification()
		delete(n.subscriptions, sub.channelName)
	}

	return nil
}
