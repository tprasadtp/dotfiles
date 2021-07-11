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
			name:   "with-system-os",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_++UNAME_S++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_%s.tar.gz", libtest.UnameS()),
		},
		{
			name:   "with-system-arch",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_++UNAME_M++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_%s.tar.gz", libtest.UnameM()),
		},
		{
			name:   "with-all",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_++UNAME_S++_++UNAME_M++_++GOOS++_++GOARCH++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_%s_%s_%s_%s.tar.gz", libtest.UnameS(), libtest.UnameM(), runtime.GOOS, runtime.GOARCH),
		},
	}
	for _, shell := range []string{"bash"} {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_render_template %s", tc.url))
				libtest.PrintCmdDebug(t, cmd)

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
