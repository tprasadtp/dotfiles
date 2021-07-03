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

func Test__libdl_is_sha256hash(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		code int
		hash string
	}{
		{name: "valid", hash: "c7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177"},
		{name: "invalid", hash: "z7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177", code: 1},
		{name: "empty-quote", hash: `""`, code: 1},
		{name: "filename", hash: "testdata/SHA256SUMS.txt", code: 1},
		{name: "none", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {

			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_is_sha256hash %s", tc.hash))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_TO_STDERR=true")

				err := cmd.Run()
				if tc.code == 0 {
					assert.Nil(t, err)
					assert.Equal(t, 0, cmd.ProcessState.ExitCode())
					assert.Empty(t, stderrBuf.String())
					assert.Empty(t, stdoutBuf.String())
				} else {
					assert.NotNil(t, err)
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
					assert.Empty(t, stdoutBuf.String())
				}
			})
		}
	}
}

func Test__libdl_is_sha512hash(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		code int
		hash string
	}{
		{name: "valid", hash: "948da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64"},
		{name: "invalid", hash: "z48da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64", code: 1},
		{name: "filename", hash: "testdata/SHA256SUMS.txt", code: 1},
		{name: "empty-quote", hash: `""`, code: 1},
		{name: "none", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_is_sha512hash %s", tc.hash))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_TO_STDERR=true")

				err := cmd.Run()
				if tc.code == 0 {
					assert.Nil(t, err)
					assert.Equal(t, 0, cmd.ProcessState.ExitCode())
					assert.Empty(t, stderrBuf.String())
					assert.Empty(t, stdoutBuf.String())
				} else {
					assert.NotNil(t, err)
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
					assert.Empty(t, stdoutBuf.String())
				}
			})
		}
	}
}
