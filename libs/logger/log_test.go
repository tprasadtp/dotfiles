//go:build linux
// +build linux

package logger_test

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/pkg/apollo"
)

func TestVersionFormats(t *testing.T) {
	t.Parallel()

	_, faketimeErr := exec.LookPath("faketime")
	assert.Nil(t, faketimeErr)

	_, zshErr := exec.LookPath("zsh")
	assert.Nil(t, zshErr)

	_, bashErr := exec.LookPath("bash")
	assert.Nil(t, bashErr)

	origNoColor, origNoColorSet := os.LookupEnv("NO_COLOR")
	origClicolorForce, origClicolorForceSet := os.LookupEnv("CLICOLOR_FORCE")

	t.Cleanup(func() {
		if origNoColorSet {
			os.Setenv("NO_COLOR", origNoColor)
		} else {
			os.Unsetenv("NO_COLOR")
		}

		if origClicolorForceSet {
			os.Setenv("CLICOLOR_FORCE", origClicolorForce)
		} else {
			os.Unsetenv("CLICOLOR_FORCE")
		}
	})

	// disable colored diff
	g := apollo.New(t, apollo.WithDiffEngine(apollo.ClassicDiff))
	tests := []struct {
		shell  string
		format string
		sdterr bool
		level  int
		color  bool
	}{
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 0},
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 10},
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 20},
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 30},
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 35},
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 40},
		{format: "pretty", shell: "bash", sdterr: false, color: true, level: 50},

		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 0},
		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 10},
		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 20},
		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 30},
		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 35},
		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 40},
		{format: "pretty", shell: "bash", sdterr: false, color: false, level: 50},

		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 0},
		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 10},
		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 20},
		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 30},
		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 35},
		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 40},
		{format: "pretty", shell: "bash", sdterr: true, color: true, level: 50},

		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 0},
		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 10},
		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 20},
		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 30},
		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 35},
		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 40},
		{format: "pretty", shell: "bash", sdterr: true, color: false, level: 50},

		{format: "full", shell: "bash", sdterr: false, color: true, level: 0},
		{format: "full", shell: "bash", sdterr: false, color: true, level: 10},
		{format: "full", shell: "bash", sdterr: false, color: true, level: 20},
		{format: "full", shell: "bash", sdterr: false, color: true, level: 30},
		{format: "full", shell: "bash", sdterr: false, color: true, level: 35},
		{format: "full", shell: "bash", sdterr: false, color: true, level: 40},
		{format: "full", shell: "bash", sdterr: false, color: true, level: 50},

		{format: "full", shell: "bash", sdterr: false, color: false, level: 0},
		{format: "full", shell: "bash", sdterr: false, color: false, level: 10},
		{format: "full", shell: "bash", sdterr: false, color: false, level: 20},
		{format: "full", shell: "bash", sdterr: false, color: false, level: 30},
		{format: "full", shell: "bash", sdterr: false, color: false, level: 35},
		{format: "full", shell: "bash", sdterr: false, color: false, level: 40},
		{format: "full", shell: "bash", sdterr: false, color: false, level: 50},

		{format: "full", shell: "bash", sdterr: true, color: true, level: 0},
		{format: "full", shell: "bash", sdterr: true, color: true, level: 10},
		{format: "full", shell: "bash", sdterr: true, color: true, level: 20},
		{format: "full", shell: "bash", sdterr: true, color: true, level: 30},
		{format: "full", shell: "bash", sdterr: true, color: true, level: 35},
		{format: "full", shell: "bash", sdterr: true, color: true, level: 40},
		{format: "full", shell: "bash", sdterr: true, color: true, level: 50},

		{format: "full", shell: "bash", sdterr: true, color: false, level: 0},
		{format: "full", shell: "bash", sdterr: true, color: false, level: 10},
		{format: "full", shell: "bash", sdterr: true, color: false, level: 20},
		{format: "full", shell: "bash", sdterr: true, color: false, level: 30},
		{format: "full", shell: "bash", sdterr: true, color: false, level: 35},
		{format: "full", shell: "bash", sdterr: true, color: false, level: 40},
		{format: "full", shell: "bash", sdterr: true, color: false, level: 50},

		// ZSH

		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 0},
		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 10},
		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 20},
		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 30},
		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 35},
		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 40},
		{format: "pretty", shell: "zsh", sdterr: false, color: true, level: 50},

		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 0},
		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 10},
		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 20},
		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 30},
		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 35},
		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 40},
		{format: "pretty", shell: "zsh", sdterr: false, color: false, level: 50},

		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 0},
		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 10},
		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 20},
		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 30},
		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 35},
		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 40},
		{format: "pretty", shell: "zsh", sdterr: true, color: true, level: 50},

		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 0},
		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 10},
		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 20},
		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 30},
		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 35},
		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 40},
		{format: "pretty", shell: "zsh", sdterr: true, color: false, level: 50},

		{format: "full", shell: "zsh", sdterr: false, color: true, level: 0},
		{format: "full", shell: "zsh", sdterr: false, color: true, level: 10},
		{format: "full", shell: "zsh", sdterr: false, color: true, level: 20},
		{format: "full", shell: "zsh", sdterr: false, color: true, level: 30},
		{format: "full", shell: "zsh", sdterr: false, color: true, level: 35},
		{format: "full", shell: "zsh", sdterr: false, color: true, level: 40},
		{format: "full", shell: "zsh", sdterr: false, color: true, level: 50},

		{format: "full", shell: "zsh", sdterr: false, color: false, level: 0},
		{format: "full", shell: "zsh", sdterr: false, color: false, level: 10},
		{format: "full", shell: "zsh", sdterr: false, color: false, level: 20},
		{format: "full", shell: "zsh", sdterr: false, color: false, level: 30},
		{format: "full", shell: "zsh", sdterr: false, color: false, level: 35},
		{format: "full", shell: "zsh", sdterr: false, color: false, level: 40},
		{format: "full", shell: "zsh", sdterr: false, color: false, level: 50},

		{format: "full", shell: "zsh", sdterr: true, color: true, level: 0},
		{format: "full", shell: "zsh", sdterr: true, color: true, level: 10},
		{format: "full", shell: "zsh", sdterr: true, color: true, level: 20},
		{format: "full", shell: "zsh", sdterr: true, color: true, level: 30},
		{format: "full", shell: "zsh", sdterr: true, color: true, level: 35},
		{format: "full", shell: "zsh", sdterr: true, color: true, level: 40},
		{format: "full", shell: "zsh", sdterr: true, color: true, level: 50},

		{format: "full", shell: "zsh", sdterr: true, color: false, level: 0},
		{format: "full", shell: "zsh", sdterr: true, color: false, level: 10},
		{format: "full", shell: "zsh", sdterr: true, color: false, level: 20},
		{format: "full", shell: "zsh", sdterr: true, color: false, level: 30},
		{format: "full", shell: "zsh", sdterr: true, color: false, level: 35},
		{format: "full", shell: "zsh", sdterr: true, color: false, level: 40},
		{format: "full", shell: "zsh", sdterr: true, color: false, level: 50},

		// SH

		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 0},
		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 10},
		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 20},
		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 30},
		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 35},
		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 40},
		{format: "pretty", shell: "sh", sdterr: false, color: true, level: 50},

		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 0},
		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 10},
		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 20},
		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 30},
		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 35},
		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 40},
		{format: "pretty", shell: "sh", sdterr: false, color: false, level: 50},

		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 0},
		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 10},
		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 20},
		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 30},
		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 35},
		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 40},
		{format: "pretty", shell: "sh", sdterr: true, color: true, level: 50},

		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 0},
		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 10},
		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 20},
		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 30},
		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 35},
		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 40},
		{format: "pretty", shell: "sh", sdterr: true, color: false, level: 50},

		{format: "full", shell: "sh", sdterr: false, color: true, level: 0},
		{format: "full", shell: "sh", sdterr: false, color: true, level: 10},
		{format: "full", shell: "sh", sdterr: false, color: true, level: 20},
		{format: "full", shell: "sh", sdterr: false, color: true, level: 30},
		{format: "full", shell: "sh", sdterr: false, color: true, level: 35},
		{format: "full", shell: "sh", sdterr: false, color: true, level: 40},
		{format: "full", shell: "sh", sdterr: false, color: true, level: 50},

		{format: "full", shell: "sh", sdterr: false, color: false, level: 0},
		{format: "full", shell: "sh", sdterr: false, color: false, level: 10},
		{format: "full", shell: "sh", sdterr: false, color: false, level: 20},
		{format: "full", shell: "sh", sdterr: false, color: false, level: 30},
		{format: "full", shell: "sh", sdterr: false, color: false, level: 35},
		{format: "full", shell: "sh", sdterr: false, color: false, level: 40},
		{format: "full", shell: "sh", sdterr: false, color: false, level: 50},

		{format: "full", shell: "sh", sdterr: true, color: true, level: 0},
		{format: "full", shell: "sh", sdterr: true, color: true, level: 10},
		{format: "full", shell: "sh", sdterr: true, color: true, level: 20},
		{format: "full", shell: "sh", sdterr: true, color: true, level: 30},
		{format: "full", shell: "sh", sdterr: true, color: true, level: 35},
		{format: "full", shell: "sh", sdterr: true, color: true, level: 40},
		{format: "full", shell: "sh", sdterr: true, color: true, level: 50},

		{format: "full", shell: "sh", sdterr: true, color: false, level: 0},
		{format: "full", shell: "sh", sdterr: true, color: false, level: 10},
		{format: "full", shell: "sh", sdterr: true, color: false, level: 20},
		{format: "full", shell: "sh", sdterr: true, color: false, level: 30},
		{format: "full", shell: "sh", sdterr: true, color: false, level: 35},
		{format: "full", shell: "sh", sdterr: true, color: false, level: 40},
		{format: "full", shell: "sh", sdterr: true, color: false, level: 50},
	}
	for _, tc := range tests {
		os.Setenv("TZ", "UTC")
		var variant []string

		variant = append(variant, tc.format)

		if tc.color {
			variant = append(variant, "colored")
		} else {
			variant = append(variant, "nocolor")
		}

		// we ignore stdout/stderr as they have same outputs
		variant = append(variant, strconv.Itoa(tc.level))
		goldenFilePrefix := strings.Join(variant, "-")

		t.Run(fmt.Sprintf("shell=%s-%s-stderr=%t", tc.shell, goldenFilePrefix, tc.sdterr), func(t *testing.T) {
			if tc.color {
				os.Setenv("CLICOLOR_FORCE", "true")
				os.Unsetenv("NO_COLOR")
			} else {
				os.Unsetenv("CLICOLOR_FORCE")
				os.Setenv("NO_COLOR", "1")
			}

			cmd := exec.Command("faketime", "-f", "2000-01-01 00:00:00", tc.shell, "demo.sh")
			cmd.Env = append(os.Environ(),
				"TZ=UTC",
				fmt.Sprintf("LOG_TO_STDERR=%s", strconv.FormatBool(tc.sdterr)),
				fmt.Sprintf("LOG_FMT=%s", tc.format),
				fmt.Sprintf("LOG_LVL=%s", strconv.Itoa(tc.level)),
			)
			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf

			// Verify command ran without any problems
			err := cmd.Run()
			assert.Nil(t, err)
			assert.Equal(t, 0, cmd.ProcessState.ExitCode())

			if tc.sdterr {
				assert.Empty(t, stdoutBuf.Bytes())
				g.Assert(t, goldenFilePrefix, stderrBuf.Bytes())
			} else {
				assert.Empty(t, stderrBuf.Bytes())
				g.Assert(t, goldenFilePrefix, stdoutBuf.Bytes())
			}
		})
	}
}
