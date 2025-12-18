package user

import (
	"context"
	"log/slog"
	"sync"

	"github.com/clin211/miniblog-v4/internal/apiserver/pkg/conversion"
	"github.com/clin211/miniblog-v4/internal/pkg/contextx"
	"github.com/clin211/miniblog-v4/internal/pkg/known"
	"github.com/clin211/miniblog-v4/pkg/store/where"
	"golang.org/x/sync/errgroup"

	v1 "github.com/clin211/miniblog-v4/pkg/api/apiserver/v1"
)

// List 实现 UserBiz 接口中的 List 方法.
func (b *userBiz) List(ctx context.Context, rq *v1.ListUserRequest) (*v1.ListUserResponse, error) {
	whr := where.P(int(rq.GetOffset()), int(rq.GetLimit()))
	if contextx.Username(ctx) != known.AdminUsername {
		whr.T(ctx)
	}

	count, userList, err := b.store.User().List(ctx, whr)
	if err != nil {
		return nil, err
	}

	var m sync.Map
	eg, ctx := errgroup.WithContext(ctx)

	// 设置最大并发数量为常量 MaxConcurrency
	eg.SetLimit(known.MaxErrGroupConcurrency)

	// 使用 goroutine 提高接口性能
	for _, user := range userList {
		eg.Go(func() error {
			select {
			case <-ctx.Done():
				return nil
			default:
				// 这里可以加入耗时的逻辑
				/*
					count, _, err := b.store.Posts().List(ctx, where.T(ctx))
					if err != nil {
						return err
					}
				*/

				userv1 := conversion.UserModelToUserV1(user)
				// userv1.PostCount = count
				m.Store(user.ID, userv1)

				return nil
			}
		})
	}

	if err := eg.Wait(); err != nil {
		slog.ErrorContext(ctx, "Failed to wait all function calls returned", "error", err)
		return nil, err
	}

	users := make([]*v1.User, 0, len(userList))
	for _, item := range userList {
		user, _ := m.Load(item.ID)
		users = append(users, user.(*v1.User))
	}

	slog.InfoContext(ctx, "Get users from backend storage", "count", len(users))

	return &v1.ListUserResponse{TotalCount: count, Users: users}, nil
}