package dl

import (
	"bytes"
	"fmt"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func Test_libdl_has_command(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name    string
		command string
		code    int
	}{
		{name: "ls", command: "ls", code: 0},
		{name: "non-existing-command", command: "non-existing-command", code: 1},
		{name: "empty-quote", command: `""`, code: 1},
		{name: "empty", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.command), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_command %s", tc.command))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				err := cmd.Run()

				assert.Empty(t, stdoutBuf.String())
				assert.Empty(t, stderrBuf.String())
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())

				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}
