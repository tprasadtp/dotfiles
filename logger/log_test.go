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

	_, err := exec.LookPath("faketime")
	assert.Nil(t, err)

	origNoColor, origNoColorSet := os.LookupEnv("NO_COLOR")
	origTZ, origTZSet := os.LookupEnv("TZ")

	origClicolor, origClicolorSet := os.LookupEnv("CLICOLOR")
	origClicolorForce, origClicolorForceSet := os.LookupEnv("CLICOLOR_FORCE")
	origTerm := os.Getenv("TERM")

	t.Cleanup(func() {
		if origNoColorSet {
			os.Setenv("NO_COLOR", origNoColor)
		} else {
			os.Unsetenv("NO_COLOR")
		}

		if origClicolorSet {
			os.Setenv("NO_COLOR", origClicolor)
		} else {
			os.Unsetenv("NO_COLOR")
		}

		if origClicolorForceSet {
			os.Setenv("NO_COLOR", origClicolorForce)
		} else {
			os.Unsetenv("NO_COLOR")
		}

		if origTZSet {
			os.Setenv("TZ", origTZ)
		} else {
			os.Unsetenv("TZ")
		}

		os.Setenv("TERM", origTerm)
	})

	// disable colored diff
	g := apollo.New(t, apollo.WithDiffEngine(apollo.ClassicDiff))
	tests := []struct {
		format string
		sdterr bool
		level  int
		color  bool
	}{
		{format: "pretty", sdterr: false, color: true, level: 0},
		{format: "pretty", sdterr: false, color: true, level: 10},
		{format: "pretty", sdterr: false, color: true, level: 20},
		{format: "pretty", sdterr: false, color: true, level: 30},
		{format: "pretty", sdterr: false, color: true, level: 35},
		{format: "pretty", sdterr: false, color: true, level: 40},
		{format: "pretty", sdterr: false, color: true, level: 50},

		{format: "pretty", sdterr: false, color: false, level: 0},
		{format: "pretty", sdterr: false, color: false, level: 10},
		{format: "pretty", sdterr: false, color: false, level: 20},
		{format: "pretty", sdterr: false, color: false, level: 30},
		{format: "pretty", sdterr: false, color: false, level: 35},
		{format: "pretty", sdterr: false, color: false, level: 40},
		{format: "pretty", sdterr: false, color: false, level: 50},

		{format: "pretty", sdterr: true, color: true, level: 0},
		{format: "pretty", sdterr: true, color: true, level: 10},
		{format: "pretty", sdterr: true, color: true, level: 20},
		{format: "pretty", sdterr: true, color: true, level: 30},
		{format: "pretty", sdterr: true, color: true, level: 35},
		{format: "pretty", sdterr: true, color: true, level: 40},
		{format: "pretty", sdterr: true, color: true, level: 50},

		{format: "pretty", sdterr: true, color: false, level: 0},
		{format: "pretty", sdterr: true, color: false, level: 10},
		{format: "pretty", sdterr: true, color: false, level: 20},
		{format: "pretty", sdterr: true, color: false, level: 30},
		{format: "pretty", sdterr: true, color: false, level: 35},
		{format: "pretty", sdterr: true, color: false, level: 40},
		{format: "pretty", sdterr: true, color: false, level: 50},

		{format: "full", sdterr: false, color: true, level: 0},
		{format: "full", sdterr: false, color: true, level: 10},
		{format: "full", sdterr: false, color: true, level: 20},
		{format: "full", sdterr: false, color: true, level: 30},
		{format: "full", sdterr: false, color: true, level: 35},
		{format: "full", sdterr: false, color: true, level: 40},
		{format: "full", sdterr: false, color: true, level: 50},

		{format: "full", sdterr: false, color: false, level: 0},
		{format: "full", sdterr: false, color: false, level: 10},
		{format: "full", sdterr: false, color: false, level: 20},
		{format: "full", sdterr: false, color: false, level: 30},
		{format: "full", sdterr: false, color: false, level: 35},
		{format: "full", sdterr: false, color: false, level: 40},
		{format: "full", sdterr: false, color: false, level: 50},

		{format: "full", sdterr: true, color: true, level: 0},
		{format: "full", sdterr: true, color: true, level: 10},
		{format: "full", sdterr: true, color: true, level: 20},
		{format: "full", sdterr: true, color: true, level: 30},
		{format: "full", sdterr: true, color: true, level: 35},
		{format: "full", sdterr: true, color: true, level: 40},
		{format: "full", sdterr: true, color: true, level: 50},

		{format: "full", sdterr: true, color: false, level: 0},
		{format: "full", sdterr: true, color: false, level: 10},
		{format: "full", sdterr: true, color: false, level: 20},
		{format: "full", sdterr: true, color: false, level: 30},
		{format: "full", sdterr: true, color: false, level: 35},
		{format: "full", sdterr: true, color: false, level: 40},
		{format: "full", sdterr: true, color: false, level: 50},
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

		t.Run(fmt.Sprintf("%s-%t", goldenFilePrefix, tc.sdterr), func(t *testing.T) {
			if tc.color {
				os.Setenv("CLICOLOR_FORCE", "true")
				os.Unsetenv("NO_COLOR")
			} else {
				os.Unsetenv("CLICOLOR_FORCE")
				os.Setenv("NO_COLOR", "1")
			}

			if tc.sdterr {
				os.Setenv("LOG_TO_STDERR", "true")
			} else {
				os.Unsetenv("LOG_TO_STDERR")
			}

			os.Setenv("LOG_FMT", tc.format)
			os.Setenv("LOG_LVL", strconv.Itoa(tc.level))

			cmd := exec.Command("faketime", "-f", "2000-01-01 00:00:00", "bash", "demo.bash")
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
