//go:build extended
// +build extended

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

var testDockerImages = []string{"ghcr.io/tprasadtp/shlibs-testing-dl:none",
	"ghcr.io/tprasadtp/shlibs-testing-dl:all",
	"ghcr.io/tprasadtp/shlibs-testing-dl:wget-gpgv",
	"ghcr.io/tprasadtp/shlibs-testing-dl:wget-gpg",
	"ghcr.io/tprasadtp/shlibs-testing-dl:curl-gpgv",
	"ghcr.io/tprasadtp/shlibs-testing-dl:curl-gpg"}

func TestHasToolsUnifiedTest(t *testing.T) {

	_, dockerErr := exec.LookPath("docker")
	assert.Nil(t, dockerErr)

	assert.NoError(t, libtest.ImageBuild(t, testDockerImages))

	tests := []struct {
		command string
		code    int
	}{
		{code: 0, command: "curl"},
		{code: 1, command: "curl"},
		{code: 0, command: "gpg"},
		{code: 1, command: "gpg"},
		{code: 0, command: "wget"},
		{code: 1, command: "wget"},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s-return-%d", shell, tc.command, tc.code), func(t *testing.T) {
				var testImageTag string
				wd, _ := os.Getwd()

				if tc.code == 0 {
					testImageTag = "ghcr.io/tprasadtp/shlibs-testing-dl:all"
				} else {
					testImageTag = "ghcr.io/tprasadtp/shlibs-testing-dl:none"
				}
				cmd := exec.Command("docker", "run",
					"--rm",
					"--volume", fmt.Sprintf("%s:/shlibs:ro", wd),
					"--workdir", "/shlibs",
					testImageTag,
					shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_%s", tc.command))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				if tc.code == 0 {
					err := cmd.Run()
					assert.Nil(t, err)
					assert.Equal(t, 0, cmd.ProcessState.ExitCode())
				} else {
					err := cmd.Run()
					assert.NotNil(t, err)
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				}
				assert.Empty(t, stdoutBuf.String())
				assert.Empty(t, stderrBuf.String())
			})
		}
	}
}
