package model

import (
	"github.com/clin211/miniblog-v4/pkg/authn"
	"github.com/clin211/miniblog-v4/pkg/rid"
	"github.com/clin211/miniblog-v4/pkg/store/registry"
	"gorm.io/gorm"
)

// BeforeCreate encrypts the plaintext password before creating a database record.
func (m *UserM) BeforeCreate(tx *gorm.DB) error {
	// Encrypt the user password.
	var err error
	m.Password, err = authn.Encrypt(m.Password)
	if err != nil {
		return err
	}

	return nil
}

// AfterCreate generates a userID after creating a database record.
func (m *UserM) AfterCreate(tx *gorm.DB) error {
	m.UserID = rid.NewResourceID("user").New(uint64(m.ID))

	return tx.Save(m).Error
}

func init() {
	registry.Register(&UserM{})
}
