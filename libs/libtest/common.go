package libtest

import (
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func AssertCommandAvailable(t *testing.T, cmd string) {
	_, err := exec.LookPath(cmd)
	assert.Nil(t, err)
}

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

func PrintCmdDebug(t *testing.T, cmd *exec.Cmd) {
	if os.Getenv("DEBUG") == "1" {
		t.Log(cmd.String())
	}
}
