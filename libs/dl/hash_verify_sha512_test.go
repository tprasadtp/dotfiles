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

func Test__libdl_verify_sha512(t *testing.T) {
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
			hash: "948da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64",
		},
		{
			name: "existing-file-checksum-file-match",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.txt",
		},
		// Checksums failure
		{
			name: "existing-file-raw-hash-err-on-mismatch",
			file: "testdata/checksum.txt",
			hash: "948da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e65",
			code: 80,
		},
		{
			name: "existing-file-checksum-err-on-mismatch",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.mismatch.txt",
			code: 80,
		},
		// Target is missing
		{
			name: "non-existing-target-err-checksum-raw",
			file: "testdata/no-such-file.txt",
			hash: "948da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64",
			code: 31,
		},
		{
			name: "non-existing-target-err-checksum-file",
			file: "testdata/no-such-file.txt",
			hash: "testdata/SHA512SUMS.txt",
			code: 31,
		},
		// Invalid checksum
		{
			name: "existing-file-raw-hash-invalid-looks-for-file",
			file: "testdata/checksum.txt",
			hash: "z48da6c339b8a2edd280ac2a6b1bcf9b181338b8ce92542f6cfad47f63684cf9d58aa72079bcd4f8c6db4ab83643fcd6c4a11e60ccca2ccfec643875528c4e64",
			code: 32,
		},
		{
			name: "existing-file-checksum-file-invalid-checksum",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.invalid.txt",
			code: 35,
		},
		// Target missing from checksums file
		{
			name:      "existing-file-err-on-missing-from-hashes-file",
			file:      "testdata/checksum.txt",
			hash:      "testdata/SHA512SUMS.missing.txt",
			errString: "failed to find sha512 hash corresponding to",
			code:      35,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			for _, hashTypeInput := range []string{"sha512", "sha-512", "SHA512", "SHA-512"} {
				t.Run(fmt.Sprintf("%s-%s-%s=%d", shell, tc.name, hashTypeInput, tc.code), func(t *testing.T) {
					cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_verify %s %s %s", tc.file, tc.hash, hashTypeInput))
					libtest.PrintCmdDebug(t, cmd)
					var stdoutBuf, stderrBuf bytes.Buffer
					cmd.Stdout = &stdoutBuf
					cmd.Stderr = &stderrBuf
					cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_TO_STDERR=true", "LOG_LVL=0")
					err := cmd.Run()
					assert.Empty(t, stdoutBuf.String())
					if tc.code == 0 {
						assert.Nil(t, err)
					} else {
						assert.NotNil(t, err)
						assert.Contains(t, strings.ToLower(stderrBuf.String()), tc.errString)
					}
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				})
			}
		}
	}
}
