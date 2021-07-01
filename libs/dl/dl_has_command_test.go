package dl

import (
	"bytes"
	"fmt"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func TestHasCommand(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		command string
		code    int
	}{
		{command: "ls", code: 0},
		{command: "non-existing-command", code: 1},
		{command: "", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {

		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.command), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_command %s", tc.command))
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
}
