package user

import (
	"context"
	"log/slog"

	"github.com/clin211/miniblog-v4/internal/apiserver/pkg/conversion"
	"github.com/clin211/miniblog-v4/internal/pkg/contextx"
	"github.com/clin211/miniblog-v4/internal/pkg/known"
	"github.com/clin211/miniblog-v4/pkg/store/where"

	v1 "github.com/clin211/miniblog-v4/pkg/api/apiserver/v1"
)

// ListWithBadPerformance 是性能较差的实现方式（已废弃）.
func (b *userBiz) ListWithBadPerformance(ctx context.Context, rq *v1.ListUserRequest) (*v1.ListUserResponse, error) {
	whr := where.P(int(rq.GetOffset()), int(rq.GetLimit()))
	if contextx.Username(ctx) != known.AdminUsername {
		whr.T(ctx)
	}

	count, userList, err := b.store.User().List(ctx, whr)
	if err != nil {
		return nil, err
	}

	users := make([]*v1.User, 0, len(userList))
	for _, user := range userList {
		/*
			count, _, err := b.store.Posts().List(ctx, where.T(ctx))
			if err != nil {
				return nil, err
			}
		*/

		userv1 := conversion.UserModelToUserV1(user)
		// userv1.PostCount = count
		users = append(users, userv1)
	}

	slog.InfoContext(ctx, "Get users from backend storage", "count", len(users))

	return &v1.ListUserResponse{TotalCount: count, Users: users}, nil
}