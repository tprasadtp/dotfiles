//go:build linux
// +build linux

package logger_test

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
	"github.com/tprasadtp/pkg/apollo"
)

func TestVersionFormats(t *testing.T) {
	logLevels := []int{0, 10, 20, 30, 35, 40, 50}

	_, faketimeErr := exec.LookPath("faketime")
	assert.Nil(t, faketimeErr)

	libtest.AssertShellsAvailable(t)

	// disable colored diff
	g := apollo.New(t, apollo.WithDiffEngine(apollo.ClassicDiff))
	tests := []struct {
		format string
		stderr bool
		level  int
		color  bool
	}{
		// pretty:stdout
		{format: "pretty", stderr: false, color: true},
		{format: "pretty", stderr: false, color: false},

		// pretty:stderr
		{format: "pretty", stderr: true, color: true},
		{format: "pretty", stderr: true, color: false},

		// full:stdout
		{format: "full", stderr: false, color: true},
		{format: "full", stderr: false, color: false},

		// full:stderr
		{format: "full", stderr: true, color: true},
		{format: "full", stderr: true, color: false},

		// fallback:stdout
		{format: "fallback", stderr: false, color: true},
		{format: "fallback", stderr: false, color: false},

		// full:stderr
		{format: "fallback", stderr: true, color: true},
		{format: "fallback", stderr: true, color: false},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			for _, level := range logLevels {
				t.Run(fmt.Sprintf("%s-%s-color=%t-stderr=%t-%d", shell, tc.format, tc.color, tc.stderr, level), func(t *testing.T) {
					cmd := exec.Command("faketime", "-f", "2000-01-01 00:00:00", shell, "demo.sh")
					cmd.Env = append(os.Environ(),
						"TZ=UTC",
						fmt.Sprintf("LOG_TO_STDERR=%s", strconv.FormatBool(tc.stderr)),
						fmt.Sprintf("LOG_FMT=%s", tc.format),
						fmt.Sprintf("LOG_LVL=%s", strconv.Itoa(level)),
					)
					var goldenFilePrefix string

					if tc.color {
						cmd.Env = append(cmd.Env, "CLICOLOR_FORCE=true")
						goldenFilePrefix = fmt.Sprintf("%s-%s-%d", tc.format, "colored", level)

					} else {
						cmd.Env = append(cmd.Env, "CLICOLOR_FORCE=0", "NO_COLOR=1")
						goldenFilePrefix = fmt.Sprintf("%s-%s-%d", tc.format, "nocolor", level)

					}

					var stdoutBuf, stderrBuf bytes.Buffer
					cmd.Stdout = &stdoutBuf
					cmd.Stderr = &stderrBuf

					err := cmd.Run()
					assert.Nil(t, err)
					assert.Equal(t, 0, cmd.ProcessState.ExitCode())

					if tc.stderr {
						assert.Empty(t, stdoutBuf.String())
						g.Assert(t, goldenFilePrefix, stderrBuf.Bytes())
					} else {
						assert.Empty(t, stderrBuf.String())
						g.Assert(t, goldenFilePrefix, stdoutBuf.Bytes())
					}
				})
			}
		}
	}
}
