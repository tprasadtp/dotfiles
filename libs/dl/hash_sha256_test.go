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

func Test__libdl_hash_sha256_WithHasherOverride(t *testing.T) {
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
			hash: "c7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177",
		},
		{
			name: "non-existant-file",
			file: "testdata/no-such-file.txt",
			code: 31,
		},
		{
			name: "empty",
			file: `""`,
			code: 12,
		},
		{
			name: "no-file-with-override-should-look-for-file",
			code: 31,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tcHashHandler := range []string{"auto", "sha256sum"} {
			for _, tc := range tests {

				t.Run(fmt.Sprintf("%s-%s-%s", shell, tcHashHandler, tc.name), func(t *testing.T) {
					cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha256 %s %s", tc.file, tcHashHandler))
					libtest.DebugPrintCmd(t, cmd)
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

func Test__libdl_hash_sha256_WithAutoDetectHasher(t *testing.T) {
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
			name: "none",
			code: 12,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {

			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha256 %s", tc.file))
				libtest.DebugPrintCmd(t, cmd)
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
