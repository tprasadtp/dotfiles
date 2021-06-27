## Tests

- Tests are written in go and use docker to emulate some conditions of the filesystem.
- Tests require docker with buildkit enabled.
- Run Tests
  ```bash
  go test -v ./... -count=1
  ```
