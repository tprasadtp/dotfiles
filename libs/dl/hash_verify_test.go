package dl

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func Test__libdl_verify_hash_sha256(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name      string
		file      string
		code      int
		hash      string
		errString string
	}{
		{
			name: "existing-file-raw-hash-match",
			file: "testdata/checksum.txt",
			hash: "c7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177",
		},
		{
			name: "existing-file-checksum-file-match",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA256SUMS.txt",
		},
		// Checksums failure
		{
			name: "existing-file-raw-hash-err-on-mismatch",
			file: "testdata/checksum.txt",
			hash: "c7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556178",
			code: 80,
		},
		{
			name: "existing-file-checksum-err-on-mismatch",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA256SUMS.mismatch.txt",
			code: 80,
		},
		// Target is missing
		{
			name: "non-existing-target-err-checksum-raw",
			file: "testdata/no-such-file.txt",
			hash: "c7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177",
			code: 31,
		},
		{
			name: "non-existing-target-err-checksum-file",
			file: "testdata/no-such-file.txt",
			hash: "testdata/SHA256SUMS.txt",
			code: 31,
		},
		// Invalid checksum
		{
			name: "existing-file-raw-hash-invalid-checksum",
			file: "testdata/checksums.txt",
			hash: "z7ff397df263ecbf0af7b717affa95c6a19fd784dbd20a210190cd5402556177",
			code: 31,
		},
		{
			name: "existing-file-checksum-file-invalid-checksum",
			file: "testdata/checksums.txt",
			hash: "testdata/SHA256SUMS.invalid.txt",
			code: 31,
		},
		// Target missing from checksums file
		{
			name:      "existing-file-err-on-missing-from-hashes-file",
			file:      "testdata/checksum.txt",
			hash:      "testdata/SHA256SUMS.missing.txt",
			errString: "failed to find hash corresponding to",
			code:      35,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_verify_hash ./%s %s", tc.file, tc.hash))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_TO_STDERR=true", "LOG_LVL=0")
				err := cmd.Run()

				if tc.code == 0 {
					assert.Nil(t, err)
					assert.Equal(t, 0, cmd.ProcessState.ExitCode())
					assert.Empty(t, stdoutBuf.String())
				} else {
					assert.NotNil(t, err)
					assert.Contains(t, strings.ToLower(stderrBuf.String()), tc.errString)
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
					assert.Empty(t, stdoutBuf.String())
				}
			})
		}
	}
}
