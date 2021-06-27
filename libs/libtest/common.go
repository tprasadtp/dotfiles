package libtest

import (
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

func AssertShells(t *testing.T) {
	_, zshErr := exec.LookPath("zsh")
	assert.Nil(t, zshErr)

	_, bashErr := exec.LookPath("bash")
	assert.Nil(t, bashErr)

	_, alpineShellErr := exec.LookPath("ash")
	assert.Nil(t, alpineShellErr)
}
