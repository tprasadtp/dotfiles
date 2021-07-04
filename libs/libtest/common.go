package libtest

import (
	"os/exec"
	"strings"
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

func UnameM() string {
	cmd := exec.Command("uname", "-m")
	out, err := cmd.CombinedOutput()
	if err == nil {
		return strings.Replace(strings.Replace(string(out), "\n", "", -1), "\r", "", -1)
	} else {
		return ""
	}
}

func UnameS() string {
	cmd := exec.Command("uname", "-s")
	out, err := cmd.CombinedOutput()
	if err == nil {
		return strings.Replace(strings.Replace(string(out), "\n", "", -1), "\r", "", -1)
	} else {
		return ""
	}
}
