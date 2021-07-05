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

func Test__libdl_hash_sha512_WithHasherOverride(t *testing.T) {
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
			hash: "948da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64",
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
		for _, tcHashHandler := range []string{"auto", "sha512sum"} {
			for _, tc := range tests {

				t.Run(fmt.Sprintf("%s-%s-%s", shell, tcHashHandler, tc.name), func(t *testing.T) {
					cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha512 %s %s", tc.file, tcHashHandler))
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

func Test__libdl_hash_sha512_WithAutoDetectHasher(t *testing.T) {
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
			hash: "948da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64",
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
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_sha512 %s", tc.file))
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
