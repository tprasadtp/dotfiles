package dl

type hashTestTable struct {
	name           string
	shell          string
	hasherOverride string
	targetFile     string
	returnCode     int
	expectedHash   string
}
