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

func generateMD5TestTable() []hashTestTable {
	var testCases []hashTestTable
	for _, shell := range libtest.SupportedShells() {
		for _, hasherOverride := range []string{"auto", "md5sum", "none"} {
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
						expectedHash:   "f25eb2f56cad9ff59dff0e9dd2b64251",
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

func Test__libdl_hash_md5(t *testing.T) {
	t.Parallel()
	testCases := generateMD5TestTable()
	t.Logf("MD5 Total test cases: %d", len(testCases))
	for _, tc := range testCases {
		t.Run(fmt.Sprintf("%s=%d", tc.name, tc.returnCode), func(t *testing.T) {
			t.Parallel()

			var cmd *exec.Cmd
			if tc.hasherOverride == "none" {
				cmd = exec.Command(tc.shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_md5 %s", tc.targetFile))
			} else {
				cmd = exec.Command(tc.shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_md5 %s %s", tc.targetFile, tc.hasherOverride))
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
