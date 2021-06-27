//go:build linux
// +build linux

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
	t.Parallel()

	_, dockerErr := exec.LookPath("docker")
	assert.Nil(t, dockerErr)

	assert.NoError(t, libtest.ImageBuild(t, testDockerImages))

	tests := []struct {
		shell   string
		command string
		code    int
	}{
		{shell: "bash", code: 0, command: "curl"},
		{shell: "bash", code: 1, command: "curl"},
		{shell: "bash", code: 0, command: "gpg"},
		{shell: "bash", code: 1, command: "gpg"},
		{shell: "bash", code: 0, command: "wget"},
		{shell: "bash", code: 1, command: "wget"},

		{shell: "sh", code: 0, command: "curl"},
		{shell: "sh", code: 1, command: "curl"},
		{shell: "sh", code: 0, command: "gpg"},
		{shell: "sh", code: 1, command: "gpg"},
		{shell: "sh", code: 0, command: "gpgv"},
		{shell: "sh", code: 1, command: "gpgv"},
		{shell: "sh", code: 0, command: "wget"},
		{shell: "sh", code: 1, command: "wget"},

		{shell: "zsh", code: 0, command: "curl"},
		{shell: "zsh", code: 1, command: "curl"},
		{shell: "zsh", code: 0, command: "gpgv"},
		{shell: "zsh", code: 1, command: "gpgv"},
		{shell: "zsh", code: 0, command: "gpg"},
		{shell: "zsh", code: 1, command: "gpg"},
		{shell: "zsh", code: 0, command: "wget"},
		{shell: "zsh", code: 1, command: "wget"},

		{shell: "ash", code: 0, command: "curl"},
		{shell: "ash", code: 1, command: "curl"},
		{shell: "ash", code: 0, command: "gpgv"},
		{shell: "ash", code: 1, command: "gpgv"},
		{shell: "ash", code: 0, command: "gpg"},
		{shell: "ash", code: 1, command: "gpg"},
		{shell: "ash", code: 0, command: "wget"},
		{shell: "ash", code: 1, command: "wget"},
	}
	for _, tc := range tests {
		t.Run(fmt.Sprintf("%s-%s-return-%d", tc.shell, tc.command, tc.code), func(t *testing.T) {
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
				tc.shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_%s", tc.command))
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
