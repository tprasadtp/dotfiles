package dl

import (
	"bytes"
	"fmt"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func Test__libdl_GOARM(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		arch   string
		expect string
		code   int
	}{
		{arch: "armv7l", expect: "7"},
		{arch: "armv6", expect: "6"},
		{arch: "armv5", expect: "5"},
		{arch: "armv8l", expect: "7"},
		{arch: "armv8b", expect: "7"},
		{arch: "aarch64"},
		{arch: "arm64"},
		{arch: "x86_64"},
		{arch: "i686"},
		{arch: "x86"},
		{arch: "FOO-BAR", code: 11},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			tc := tc
			t.Run(fmt.Sprintf("%s-%s", shell, tc.arch), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_GOARM %s", tc.arch))
				libtest.DebugPrintCmd(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				err := cmd.Run()
				assert.Equal(t, tc.expect, stdoutBuf.String())
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
