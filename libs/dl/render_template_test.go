package dl

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/dotfiles/libs/libtest"
)

func Test__libdl_get_rendered_string(t *testing.T) {
	libtest.AssertShellsAvailable(t)

	// ARCH := libtest.UnameM()
	// OS := libtest.UnameS()

	tests := []struct {
		name   string
		url    string
		expect string
		code   int
	}{
		{
			name:   "no-template",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_amd64.tar.gz",
			expect: "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_amd64.tar.gz",
		},
		{
			name:   "with-goos",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_++GOOS++_amd64.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_%s_amd64.tar.gz", runtime.GOOS),
		},
		{
			name:   "with-goarch",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_++GOARCH++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_%s.tar.gz", runtime.GOARCH),
		},
		{
			name:   "with-goarch",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_++GOARCH++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_%s.tar.gz", runtime.GOARCH),
		},
	}
	for _, shell := range []string{"bash"} {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_render_template %s", tc.url))
				libtest.DebugPrintCmd(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()

				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				assert.Equal(t, tc.expect, stdoutBuf.String())
				assert.Empty(t, stderrBuf.String())

				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}
