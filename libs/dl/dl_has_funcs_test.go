//go:build linux
// +build linux

package dl

import (
	"bytes"
	"fmt"
	"math/rand"
	"os/exec"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func TestHasAllFunctions(t *testing.T) {
	t.Parallel()
	libtest.AssertShells(t)

	tests := []struct {
		shell string
	}{
		{shell: "bash"},
		{shell: "sh"},
		{shell: "ash"},
		{shell: "ash"},
	}
	for _, tc := range tests {
		t.Run(tc.shell, func(t *testing.T) {
			cmd := exec.Command(tc.shell,
				"-c", ". ./../logger/logger.sh && . ./dl.sh && __libdl_has_depfuncs")
			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf
			err := cmd.Run()
			assert.Nil(t, err)
			assert.Equal(t, 0, cmd.ProcessState.ExitCode())
			assert.Empty(t, stderrBuf.String())
			assert.Empty(t, stdoutBuf.String())
		})
	}
}

func TestMissingFunctions(t *testing.T) {
	t.Parallel()
	libtest.AssertShells(t)
	logFuncs := []string{"log_trace", "log_debug", "log_info", "log_success", "log_warning", "log_notice", "log_error"}
	rand.Seed(time.Now().Unix())

	tests := []struct {
		shell    string
		undefine string
	}{
		{shell: "bash", undefine: logFuncs[rand.Intn(len(logFuncs))]},
		{shell: "zsh", undefine: logFuncs[rand.Intn(len(logFuncs))]},
		{shell: "sh", undefine: logFuncs[rand.Intn(len(logFuncs))]},
		{shell: "ash", undefine: logFuncs[rand.Intn(len(logFuncs))]},
	}
	for _, tc := range tests {
		t.Run(fmt.Sprintf("%s-missing-%s", tc.shell, tc.undefine), func(t *testing.T) {
			cmd := exec.Command(tc.shell,
				"-c", fmt.Sprintf(". ./../logger/logger.sh && . ./dl.sh && unset -f %s && __libdl_has_depfuncs", tc.undefine))

			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf
			err := cmd.Run()
			assert.NotNil(t, err)
			assert.NotEqual(t, 0, cmd.ProcessState.ExitCode())
			assert.Empty(t, stderrBuf.String())
			assert.Empty(t, stdoutBuf.String())
		})
	}
}
