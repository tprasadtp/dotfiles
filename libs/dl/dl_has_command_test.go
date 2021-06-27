//go:build linux
// +build linux

package dl

import (
	"bytes"
	"fmt"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHasCommand(t *testing.T) {
	t.Parallel()

	_, zshErr := exec.LookPath("zsh")
	assert.Nil(t, zshErr)

	_, bashErr := exec.LookPath("bash")
	assert.Nil(t, bashErr)

	_, alpineShellErr := exec.LookPath("ash")
	assert.Nil(t, alpineShellErr)

	tests := []struct {
		shell   string
		command string
		code    int
	}{
		{shell: "bash", command: "ls", code: 0},
		{shell: "bash", command: "non-existing-command", code: 1},
		{shell: "bash", command: "", code: 1},

		{shell: "sh", command: "ls", code: 0},
		{shell: "sh", command: "non-existing-command", code: 1},
		{shell: "sh", command: "", code: 1},

		{shell: "zsh", command: "ls", code: 0},
		{shell: "zsh", command: "non-existing-command", code: 1},
		{shell: "zsh", command: "", code: 1},

		{shell: "ash", command: "ls", code: 0},
		{shell: "ash", command: "non-existing-command", code: 1},
		{shell: "ash", command: "", code: 1},
	}
	for _, tc := range tests {
		t.Run(fmt.Sprintf("%s-%s", tc.shell, tc.command), func(t *testing.T) {
			cmd := exec.Command(tc.shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_command %s", tc.command))
			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf
			err := cmd.Run()
			if tc.code == 0 {
				assert.Nil(t, err)
				assert.Equal(t, 0, cmd.ProcessState.ExitCode())
			} else {
				assert.NotNil(t, err)
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
			}
			assert.Empty(t, stdoutBuf.String())
			assert.Empty(t, stderrBuf.String())
		})
	}
}
