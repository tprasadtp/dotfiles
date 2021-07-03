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

func Test__libdl_hash_sha256(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		file string
		code int
		hash string
	}{
		{name: "existing-file",
			file: "testdata/checksum.txt",
			hash: "c7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177",
		},
		{
			name: "non-existant-file",
			file: "testdata/no-such-file.txt",
			code: 31,
		},
		{
			name: "empty-quotes",
			file: `""`,
			code: 12,
		},
		{
			name: "empty-quotes",
			code: 12,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tcHashHandler := range []string{"", "sha256sum", "shasum", "rhash"} {
			for _, tc := range tests {
				var tCName string
				var tcArg string
				if tc.file == "" {
					// needed to ensure multiple args are passed
					tcArg = `""`
					tCName = "no-file-specified"
				} else {
					tcArg = tc.file
					tCName = tc.file
				}

				if tcHashHandler == "" {
					tcHashHandler = "auto"
				}

				t.Run(fmt.Sprintf("%s-%s-%s", shell, tcHashHandler, tCName), func(t *testing.T) {
					cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha256 %s %s", tcArg, tcHashHandler))
					var stdoutBuf, stderrBuf bytes.Buffer
					cmd.Stdout = &stdoutBuf
					cmd.Stderr = &stderrBuf
					cmd.Env = append(os.Environ(), "TZ=UTC")

					err := cmd.Run()
					if tc.code == 0 {
						assert.Nil(t, err)
						assert.Equal(t, 0, cmd.ProcessState.ExitCode())
						assert.Empty(t, stderrBuf.String())
						assert.Equal(t, tc.hash, stdoutBuf.String())
					} else {
						assert.NotNil(t, err)
						assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
						assert.Empty(t, stdoutBuf.String())
						assert.Empty(t, stderrBuf.String())
					}
				})
			}
		}
	}
}
