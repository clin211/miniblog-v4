package user

import (
	"context"
	"log/slog"

	"github.com/clin211/miniblog-v4/pkg/authn"
	"github.com/clin211/miniblog-v4/pkg/store/where"

	"github.com/clin211/miniblog-v4/internal/pkg/errno"
	v1 "github.com/clin211/miniblog-v4/pkg/api/apiserver/v1"
)

// ChangePassword 实现 UserBiz 接口中的 ChangePassword 方法.
func (b *userBiz) ChangePassword(ctx context.Context, rq *v1.ChangePasswordRequest) (*v1.ChangePasswordResponse, error) {
	userM, err := b.store.User().Get(ctx, where.T(ctx))
	if err != nil {
		return nil, err
	}

	if err := authn.Compare(userM.Password, rq.GetOldPassword()); err != nil {
		slog.ErrorContext(ctx, "Failed to compare password", "error", err)
		return nil, errno.ErrPasswordInvalid
	}

	userM.Password, _ = authn.Encrypt(rq.GetNewPassword())
	if err := b.store.User().Update(ctx, userM); err != nil {
		return nil, err
	}

	return &v1.ChangePasswordResponse{}, nil
}