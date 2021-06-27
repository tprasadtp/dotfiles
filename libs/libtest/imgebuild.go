package libtest

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"testing"
)

// TestingImageBuild builds docker image used for testing sh library library
func ImageBuild(t *testing.T, images []string) error {
	if _, err := exec.LookPath("docker"); err != nil {
		return errors.New("docker command not found in PATH")
	}
	forceRebuild, _ := strconv.ParseBool(os.Getenv("SHLIBS_TESTS_REBUILD_IMAGES"))

	for _, img := range images {
		inspectCmd := exec.Command("docker", "inspect", img)
		imgTag := strings.Split(img, ":")
		if err := inspectCmd.Run(); err != nil || forceRebuild {
			if len(imgTag) > 2 || len(imgTag) < 1 {
				return fmt.Errorf("image name format %s is invalid", img)
			}
			t.Logf("Building image: %s", img)
			buildCmd := exec.Command("docker",
				"build",
				"--target", imgTag[1],
				"--file", "testdata/Dockerfile",
				"--tag", img,
				"testdata/")
			if output, err := buildCmd.CombinedOutput(); err != nil {
				return fmt.Errorf("docker build failed for %s with output %s: %w", img, string(output), err)
			}
			t.Logf("%s built", img)
		}
	}
	return nil
}
