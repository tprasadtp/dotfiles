package dl

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func generatesha1TestTable() []hashTestTable {
	var testCases []hashTestTable
	for _, shell := range libtest.SupportedShells() {
		for _, hasherOverride := range []string{"auto", "sha1sum", "shasum", "none"} {
			for _, variant := range []string{"existing-file", "non-existant-file", "empty-quotes", "empty"} {
				var tc hashTestTable
				name := fmt.Sprintf("%s-hasher-override-%s-%s", shell, hasherOverride, variant)

				switch variant {
				case "existing-file":
					tc = hashTestTable{
						name:           name,
						shell:          shell,
						hasherOverride: hasherOverride,
						targetFile:     "testdata/checksum.txt",
						expectedHash:   "b5db34c1b59b6e0c223b103ba52967dbb59c2f8b",
						returnCode:     0,
					}
				case "non-existant-file":
					tc = hashTestTable{
						name:           name,
						shell:          shell,
						hasherOverride: hasherOverride,
						targetFile:     "testdata/non-existant-file.txt",
						returnCode:     31,
					}
				case "empty-quotes":
					tc = hashTestTable{
						name:           name,
						shell:          shell,
						hasherOverride: hasherOverride,
						targetFile:     `""`,
						returnCode:     12,
					}
				case "empty":
					var rc int
					switch hasherOverride {
					case "none", `""`:
						rc = 12
					default:
						rc = 31
					}
					tc = hashTestTable{
						name:           name,
						shell:          shell,
						hasherOverride: hasherOverride,
						returnCode:     rc,
					}
				}
				// build table
				testCases = append(testCases, tc)
			}

		}
	}
	return testCases
}

func Test__libdl_hash_sha1(t *testing.T) {
	t.Parallel()
	testCases := generatesha1TestTable()
	t.Logf("SHA1 Total test cases: %d", len(testCases))
	for _, tc := range testCases {
		t.Run(fmt.Sprintf("%s=%d", tc.name, tc.returnCode), func(t *testing.T) {
			var cmd *exec.Cmd
			if tc.hasherOverride == "none" {
				cmd = exec.Command(tc.shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha1 %s", tc.targetFile))
			} else {
				cmd = exec.Command(tc.shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha1 %s %s", tc.targetFile, tc.hasherOverride))
			}

			libtest.PrintCmdDebug(t, cmd)
			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf
			cmd.Env = append(os.Environ(), "TZ=UTC")

			err := cmd.Run()
			assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())

			if tc.returnCode == 0 {
				assert.Nil(t, err)
				assert.Empty(t, stderrBuf.String())
				assert.Equal(t, tc.expectedHash, stdoutBuf.String())
			} else {
				assert.NotNil(t, err)
				assert.Empty(t, stdoutBuf.String())
			}
		})
	}
}
