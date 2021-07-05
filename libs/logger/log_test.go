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
	"github.com/tprasadtp/dotfiles/libs/libtest"
	"github.com/tprasadtp/pkg/apollo"
)

type loggerTestTable struct {
	name   string
	shell  string
	level  int
	format string
	output string
	color  bool
}

func generateTestTable() []loggerTestTable {
	var testCases []loggerTestTable
	for _, shell := range libtest.SupportedShells() {
		for _, format := range []string{"pretty", "full", "long", "fallback"} {
			for _, output := range []string{"stderr", "stdout", "default"} {
				for _, color := range []bool{true, false} {
					for _, level := range []int{0, 10, 20, 30, 35, 40, 50} {
						name := fmt.Sprintf("%s-format-%s-color-%t-output-%s-level-%d", shell, format, color, output, level)
						tc := loggerTestTable{
							name:   name,
							shell:  shell,
							format: format,
							output: output,
							level:  level,
							color:  color,
						}
						testCases = append(testCases, tc)
					}
				}
			}
		}
	}
	return testCases
}

func TestVersionFormats(t *testing.T) {
	libtest.AssertCommandAvailable(t, "faketime")
	libtest.AssertShellsAvailable(t)

	// disable colored diff
	g := apollo.New(t, apollo.WithDiffEngine(apollo.ClassicDiff))

	testCases := generateTestTable()
	t.Logf("Total test cases: %d", len(testCases))
	for _, tc := range testCases {
		// rebind tc into this lexical scope
		// for usage with t.Parallel()
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			cmd := exec.Command("faketime", "-f", "2000-01-01 00:00:00", tc.shell, "demo.sh")
			cmd.Env = append(os.Environ(),
				"TZ=UTC",
				fmt.Sprintf("LOG_FMT=%s", tc.format),
				fmt.Sprintf("LOG_LVL=%s", strconv.Itoa(tc.level)),
			)

			switch strings.ToLower(tc.output) {
			case "stdout":
				cmd.Env = append(cmd.Env, "LOG_TO_STDOUT=true")
			case "stderr", "default":
				cmd.Env = append(cmd.Env, "LOG_TO_STDOUT=false")
			default:
			}

			var goldenFilePrefix string
			var fmtGoldenName string
			switch tc.format {
			case "pretty", "default":
				fmtGoldenName = "pretty"
			case "full", "long":
				fmtGoldenName = "full"
			default:
				fmtGoldenName = "fallback"
			}

			// color specific golden files
			if tc.color {
				cmd.Env = append(cmd.Env, "CLICOLOR_FORCE=true")
				goldenFilePrefix = fmt.Sprintf("%s-%s-%d", fmtGoldenName, "colored", tc.level)

			} else {
				cmd.Env = append(cmd.Env, "CLICOLOR_FORCE=0", "NO_COLOR=1")
				goldenFilePrefix = fmt.Sprintf("%s-%s-%d", fmtGoldenName, "nocolor", tc.level)
			}

			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf

			err := cmd.Run()
			assert.Nil(t, err)
			assert.Equal(t, 0, cmd.ProcessState.ExitCode())

			switch tc.output {
			case "stderr":
				assert.Empty(t, stdoutBuf.String())
				g.Assert(t, goldenFilePrefix, stderrBuf.Bytes())
			case "stdout":
				assert.Empty(t, stderrBuf.String())
				g.Assert(t, goldenFilePrefix, stdoutBuf.Bytes())
			default:
				assert.Empty(t, stdoutBuf.String())
				g.Assert(t, goldenFilePrefix, stderrBuf.Bytes())
			}
		})
	}
}
