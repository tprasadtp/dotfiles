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

type gpgTestCase struct {
	name       string
	target     string
	signature  string
	keyring    string
	returnCode int
}

// func testCasesGPGVerification() []testCaseGPG {
// 	var testCases []testCaseGPG
// 	for _, shell := range libtest.SupportedShells() {
// 		for _, signatureFormat := range []string{"armored", "binary",} {
// 			for _, signsignatureType := range []string{"detached", "clearsign"} {
// 				for _, validationResult := range []string{}
// 			}

// 		}

// 	}

// }

func Test__libdl_verify_gpg_valid(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tt := []gpgTestCase{
		{
			name:      "binary-detached",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.gpg",
		},
		{
			name:      "ascii-detached",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.asc",
		},
	}

	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tt {
			t.Run(fmt.Sprintf("%s-%s=%d", shell, tc.name, tc.returnCode), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_gpg_verify %s %s", tc.target, tc.signature))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()

				assert.Nil(t, err)
				assert.Empty(t, stdoutBuf.String())
				assert.Contains(t, stderrBuf.String(), tc.signature)
				assert.Contains(t, stderrBuf.String(), "VERIFIED")
				assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			})
		}
	}
}

func Test__libdl_verify_gpg_valid_custom_keyring(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tt := []gpgTestCase{
		{
			name:      "binary-detached-binary-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.gpg",
			keyring:   "testdata/GPG-PUBKEY.gpg",
		},
		{
			name:      "ascii-detached-binary-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.asc",
			keyring:   "testdata/GPG-PUBKEY.gpg",
		},
		{
			name:      "binary-detached-ascii-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.gpg",
			keyring:   "testdata/GPG-PUBKEY.asc",
		},
		{
			name:      "ascii-detached-ascii-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.asc",
			keyring:   "testdata/GPG-PUBKEY.asc",
		},
	}

	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tt {
			t.Run(fmt.Sprintf("%s-%s=%d", shell, tc.name, tc.returnCode), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_gpg_verify %s %s %s", tc.target, tc.signature, tc.keyring))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()

				assert.Nil(t, err)
				assert.Empty(t, stdoutBuf.String())
				assert.Contains(t, stderrBuf.String(), tc.signature)
				assert.Contains(t, stderrBuf.String(), tc.keyring)
				assert.Contains(t, stderrBuf.String(), "VERIFIED")
				assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			})
		}
	}
}

// mismatch cases

func Test__libdl_verify_gpg_mismatch(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tt := []gpgTestCase{
		{
			name:      "binary-detached",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.mismatch.gpg",
		},
		{
			name:      "ascii-detached",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.mismatch.asc",
		},
	}

	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tt {
			t.Run(fmt.Sprintf("%s-%s=%d", shell, tc.name, tc.returnCode), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_gpg_verify %s %s", tc.target, tc.signature))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()
				tc.returnCode = 81

				assert.NotNil(t, err)
				assert.Empty(t, stdoutBuf.String())
				assert.Contains(t, stderrBuf.String(), tc.signature)
				assert.Contains(t, stderrBuf.String(), "FAILED")
				assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			})
		}
	}
}

func Test__libdl_verify_gpg_mismatch_custom_keyring(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tt := []gpgTestCase{
		{
			name:      "binary-detached-binary-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.mismatch.gpg",
			keyring:   "testdata/GPG-PUBKEY.gpg",
		},
		{
			name:      "ascii-detached-binary-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.mismatch.asc",
			keyring:   "testdata/GPG-PUBKEY.gpg",
		},
		{
			name:      "binary-detached-ascii-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.mismatch.gpg",
			keyring:   "testdata/GPG-PUBKEY.asc",
		},
		{
			name:      "ascii-detached-ascii-keyring",
			target:    "testdata/checksum.txt",
			signature: "testdata/checksum.txt.mismatch.asc",
			keyring:   "testdata/GPG-PUBKEY.asc",
		},
	}

	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tt {
			t.Run(fmt.Sprintf("%s-%s=%d", shell, tc.name, tc.returnCode), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_gpg_verify %s %s %s", tc.target, tc.signature, tc.keyring))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()
				tc.returnCode = 81

				assert.NotNil(t, err)
				assert.Empty(t, stdoutBuf.String())
				assert.Contains(t, stderrBuf.String(), tc.signature)
				assert.Contains(t, stderrBuf.String(), tc.keyring)
				assert.Contains(t, stderrBuf.String(), "FAILED")
				assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			})
		}
	}
}

func Test__libdl_verify_gpg_missing_files(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	tt := []gpgTestCase{
		{
			name:       "nonexistant-target",
			target:     "testdata/missing.txt",
			signature:  "testdata/checksum.txt.gpg",
			keyring:    "testdata/GPG-PUBKEY.gpg",
			returnCode: 41,
		},
		{
			name:       "nonexistant-signature",
			target:     "testdata/checksum.txt",
			signature:  "testdata/missing.txt.gpg",
			keyring:    "testdata/GPG-PUBKEY.gpg",
			returnCode: 42,
		},
		{
			name:       "nonexistant-keyring",
			target:     "testdata/checksum.txt",
			signature:  "testdata/checksum.txt.gpg",
			keyring:    "testdata/NO-SUCH-KEYRING.asc",
			returnCode: 43,
		},
		{
			name:       "empty-target",
			target:     `""`,
			signature:  "testdata/checksum.txt.gpg",
			keyring:    "testdata/GPG-PUBKEY.asc",
			returnCode: 12,
		},
		{
			name:       "empty-signature",
			target:     "testdata/checksum.txt",
			signature:  `""`,
			keyring:    "testdata/GPG-PUBKEY.asc",
			returnCode: 12,
		},
	}

	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tt {
			t.Run(fmt.Sprintf("%s-%s=%d", shell, tc.name, tc.returnCode), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_gpg_verify %s %s %s", tc.target, tc.signature, tc.keyring))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()

				assert.NotNil(t, err)
				assert.Empty(t, stdoutBuf.String())
				assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			})
		}
	}
}
