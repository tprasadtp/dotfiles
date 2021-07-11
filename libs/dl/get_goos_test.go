package dl

import (
	"bytes"
	"fmt"
	"os/exec"
	"runtime"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func Test__libdl_GOOS(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		os     string
		expect string
		code   int
	}{
		{os: "Linux", expect: "linux", code: 0},
		{os: "Darwin", expect: "darwin", code: 0},
		{os: "FreeBSD", expect: "freebsd", code: 0},
		{os: "MINGW32_NT-6.2", expect: "windows", code: 0},
		{os: "MINGW64_NT-6.2", expect: "windows", code: 0},
		{expect: runtime.GOOS, code: 0},
		{os: "FOO-BAR", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			var tcOS string
			if tc.os == "" || strings.ToLower(tc.os) == "default" {
				tcOS = "Default"
			} else {
				tcOS = tc.os
			}
			t.Run(fmt.Sprintf("%s-%s", shell, tcOS), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_GOOS %s", tc.os))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				err := cmd.Run()
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				assert.Equal(t, tc.expect, stdoutBuf.String())
				assert.Empty(t, stderrBuf.String())

				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}
