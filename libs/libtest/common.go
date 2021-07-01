package libtest

import (
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

func AssertShellsAvailable(t *testing.T) {
	for _, shell := range SupportedShells() {
		_, err := exec.LookPath(shell)
		assert.Nil(t, err)
	}
}

func SupportedShells() [4]string {
	return [4]string{"bash", "sh", "zsh", "ash"}
}
