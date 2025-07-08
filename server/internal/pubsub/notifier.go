package pubsub

import (
	"context"
	"errors"
	"slices"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
)

const waitTimeout = 30 * time.Second
const opTimeout = 10 * time.Second

type Notifier interface {
	Listen(channel string) Subscription
}

type notifier struct {
	mu                        sync.RWMutex
	log                       zerolog.Logger
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

var n Notifier

func Initialize(ctx context.Context, pool *pgxpool.Pool, log zerolog.Logger) error {
	listener, err := newListener(ctx, pool)
	if err != nil {
		return err
	}

	notifier := notifier{
		mu:                        sync.RWMutex{},
		log:                       log.With().Str("mod", "notifier").Logger(),
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
					notifier.log.Fatal().Msg("connection closed. Exiting")
				}
				notifier.log.Warn().Err(err).Msg("error in notifier.waitOnce")
			}
			if notification != nil {
				notifier.notifyListeners(notification)
			}
		}
	}()

	n = &notifier
	return nil
}

func Get() Notifier {
	return n
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
				n.log.Warn().Err(err).Str("channel", u.channelName).Uint8("op", u.op).Msg("error completing op")
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
			n.log.Warn().Str("channel", notification.Channel).Msg("dropped notification")
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
