package user

import (
	"context"
	"log/slog"

	"github.com/clin211/miniblog-v4/pkg/token"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/clin211/miniblog-v4/internal/pkg/contextx"
	"github.com/clin211/miniblog-v4/internal/pkg/errno"
	v1 "github.com/clin211/miniblog-v4/pkg/api/apiserver/v1"
)

// RefreshToken 用于刷新用户的身份验证令牌.
// 当用户的令牌即将过期时，可以调用此方法生成一个新的令牌.
func (b *userBiz) RefreshToken(ctx context.Context, rq *v1.RefreshTokenRequest) (*v1.RefreshTokenResponse, error) {
	tokenStr, expireAt, err := token.Sign(contextx.UserID(ctx))
	if err != nil {
		slog.ErrorContext(ctx, "Failed to sign token", "error", err)
		return nil, errno.ErrSignToken
	}

	return &v1.RefreshTokenResponse{Token: tokenStr, ExpireAt: timestamppb.New(expireAt)}, nil
}