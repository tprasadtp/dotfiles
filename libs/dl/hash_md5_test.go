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

func Test__libdl_hash_md5(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		file string
		code int
		hash string
	}{
		{
			name: "existing-file",
			file: "testdata/checksum.txt",
			hash: "f25eb2f56cad9ff59dff0e9dd2b64251",
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
			name: "none",
			code: 12,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tcHashHandler := range []string{"", "md5sum", "rhash"} {
			for _, tc := range tests {

				if tcHashHandler == "" {
					tcHashHandler = "auto"
				}

				t.Run(fmt.Sprintf("%s-%s-%s", shell, tcHashHandler, tc.name), func(t *testing.T) {
					cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_md5 %s %s", tc.file, tcHashHandler))
					var stdoutBuf, stderrBuf bytes.Buffer
					cmd.Stdout = &stdoutBuf
					cmd.Stderr = &stderrBuf
					cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_TO_STDERR=true")

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
					}
				})
			}
		}
	}
}
