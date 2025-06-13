package steve

import (
	"context"
	"encoding/json"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"github.com/jackc/pgx/v5"
)

const channelName = "job_inserted"

type Client struct {
	sub pubsub.Subscription
}

func (c *Client) Start(notifier pubsub.Notifier) error {
	if c.sub != nil {
		return errors.New("already started")
	}
	c.sub = notifier.Listen(channelName)
	select {
	case <-c.sub.EstablishedC():
	default:
	}

	//TOOD: deserialize existing jobs

	go c.run()

	return nil
}

func (c *Client) run() {
	for {
		select {
		case <-c.sub.NotificationC():
			// TODO: Do something
		}
	}
}

func (c *Client) InsertJob(ctx context.Context, tx pgx.Tx, args JobArgs) error {
	return c.InsertJobs(ctx, tx, []JobArgs{args})
}

func (c *Client) InsertJobs(ctx context.Context, tx pgx.Tx, args []JobArgs) error {
	params := make([]insertJobParams, 0, len(args))
	for i, a := range args {
		encodedArgs, err := json.Marshal(a)
		if err != nil {
			return err
		}

		params[i] = insertJobParams{
			Kind:        a.Kind(),
			EncodedArgs: encodedArgs,
		}
	}
	_, err := insertJobs(ctx, tx, params)
	return err
}
