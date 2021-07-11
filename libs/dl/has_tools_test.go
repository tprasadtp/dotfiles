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

type hasToolsTestCase struct {
	name       string
	shell      string
	command    string
	testImage  string
	returnCode int
}

func hasToolsTestCases() []hasToolsTestCase {
	var testCases []hasToolsTestCase
	for _, shell := range libtest.SupportedShells() {
		for _, img := range []string{"all", "none"} {
			for _, command := range []string{"wget", "curl", "gpg", "gpgv"} {
				var name string
				var dockerTag string
				var rc int
				switch img {
				case "all":
					rc = 0
					dockerTag = "ghcr.io/tprasadtp/shlibs-testing-dl:all"
					name = fmt.Sprintf("%s-available-%s=%d", shell, command, rc)
				case "none":
					rc = 1
					dockerTag = "ghcr.io/tprasadtp/shlibs-testing-dl:none"
					name = fmt.Sprintf("%s-missing-%s=%d", shell, command, rc)
				}
				testCases = append(testCases,
					hasToolsTestCase{
						name:       name,
						shell:      shell,
						command:    command,
						testImage:  dockerTag,
						returnCode: rc,
					})
			}
		}
	}
	return testCases
}

func Test__libdl_has_tools(t *testing.T) {
	t.Parallel()
	libtest.AssertCommandAvailable(t, "docker")

	assert.NoError(t, libtest.ImageBuild(t, testDockerImages))
	for _, tc := range hasToolsTestCases() {
		t.Run(tc.name, func(t *testing.T) {
			wd, _ := os.Getwd()

			cmd := exec.Command("docker",
				"run",
				"--rm",
				"--volume", fmt.Sprintf("%s:/shlibs:ro", wd),
				"--workdir", "/shlibs",
				tc.testImage,
				tc.shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_command %s", tc.command))

			libtest.PrintCmdDebug(t, cmd)

			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf

			err := cmd.Run()
			assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			assert.Empty(t, stdoutBuf.String())
			assert.Empty(t, stderrBuf.String())

			if tc.returnCode == 0 {
				assert.Nil(t, err)
			} else {
				err := cmd.Run()
				assert.NotNil(t, err)
			}
		})
	}
}

func Test__libdl_has_tools_extended_validators(t *testing.T) {
	t.Parallel()
	libtest.AssertCommandAvailable(t, "docker")

	assert.NoError(t, libtest.ImageBuild(t, testDockerImages))
	for _, tc := range hasToolsTestCases() {
		t.Run(tc.name, func(t *testing.T) {
			wd, _ := os.Getwd()

			cmd := exec.Command("docker",
				"run",
				"--rm",
				"--volume", fmt.Sprintf("%s:/shlibs:ro", wd),
				"--workdir", "/shlibs",
				tc.testImage,
				tc.shell, "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_%s", tc.command))

			libtest.PrintCmdDebug(t, cmd)

			var stdoutBuf, stderrBuf bytes.Buffer
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf

			err := cmd.Run()
			assert.Equal(t, tc.returnCode, cmd.ProcessState.ExitCode())
			assert.Empty(t, stdoutBuf.String())
			assert.Empty(t, stderrBuf.String())

			if tc.returnCode == 0 {
				assert.Nil(t, err)
			} else {
				err := cmd.Run()
				assert.NotNil(t, err)
			}
		})
	}
}

func Test__libdl_has_tools_extended_alpine(t *testing.T) {
	t.Parallel()
	libtest.AssertCommandAvailable(t, "docker")
	for _, tc := range []string{"curl", "wget", "gpg", "gpgv"} {
		t.Run(tc, func(t *testing.T) {
			wd, _ := os.Getwd()

			cmd := exec.Command("docker",
				"run",
				"--rm",
				"--volume", fmt.Sprintf("%s:/shlibs:ro", wd),
				"--workdir", "/shlibs",
				"alpine:latest",
				"ash", "-c", fmt.Sprintf(". ./dl.sh && __libdl_has_%s", tc))

			libtest.PrintCmdDebug(t, cmd)

			var stdoutBuf, stderrBuf bytes.Buffer
			var returnCode int
			cmd.Stdout = &stdoutBuf
			cmd.Stderr = &stderrBuf

			switch tc {
			case "curl", "gpg", "gpgv":
				returnCode = 1
			case "wget":
				returnCode = 0
			default:
				returnCode = -1
			}

			err := cmd.Run()
			assert.Empty(t, stdoutBuf.String())
			assert.Empty(t, stderrBuf.String())
			assert.Equal(t, returnCode, cmd.ProcessState.ExitCode())

			if returnCode == 0 {
				assert.Nil(t, err)
			} else {
				err := cmd.Run()
				assert.NotNil(t, err)
			}
		})
	}
}
