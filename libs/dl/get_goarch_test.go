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

func TestGetGOARCH(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		arch   string
		expect string
		code   int
	}{
		{arch: "x86_64", expect: "amd64"},
		{arch: "i686", expect: "386"},
		{arch: "x86", expect: "386"},
		{arch: "aarch64", expect: "arm64"},
		{arch: "armv7l", expect: "arm"},
		{arch: "armv6", expect: "arm"},
		{arch: "armv5", expect: "arm"},
		{arch: "armv8l", expect: "arm"},
		{arch: "armv8b", expect: "arm"},
		{expect: runtime.GOARCH},
		{arch: "FOO-BAR", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			var tcArch string
			if tc.arch == "" || strings.ToLower(tc.arch) == "default" {
				tcArch = "Default"
			} else {
				tcArch = tc.arch
			}
			t.Run(fmt.Sprintf("%s-%s", shell, tcArch), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_GOARCH %s", tc.arch))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				err := cmd.Run()
				if tc.code == 0 {
					assert.Nil(t, err)
					assert.Equal(t, 0, cmd.ProcessState.ExitCode())
					assert.Empty(t, stderrBuf.String())
					assert.Equal(t, tc.expect, stdoutBuf.String())
				} else {
					assert.NotNil(t, err)
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
					assert.Empty(t, stdoutBuf.String())
				}
			})
		}
	}
}

func TestGetGOARM(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		arch   string
		expect string
	}{
		{arch: "armv7l", expect: "v7"},
		{arch: "armv6", expect: "v6"},
		{arch: "armv5", expect: "v5"},
		{arch: "x86_64"},
		{arch: "i686"},
		{arch: "x86"},
		{arch: "aarch64"},
		{arch: "armv8l"},
		{arch: "armv8b"},
		{arch: "FOO-BAR"},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.arch), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_GOARM %s", tc.arch))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				err := cmd.Run()
				assert.Nil(t, err)
				assert.Equal(t, 0, cmd.ProcessState.ExitCode())
				assert.Empty(t, stderrBuf.String())
				assert.Equal(t, tc.expect, stdoutBuf.String())
			})
		}
	}
}
