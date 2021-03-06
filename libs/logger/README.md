# logger

Simple sh logger.

- Supports leveled logging
- Outputs to stderr by default, Optionally log to stdout instead of stderr by setting `LOG_TO_STDOUT=true`
- Supports colored logs
- Supports https://bixense.com/clicolors/ and https://no-color.org/ standards.
- Mostly POSIX compliant. Only non POSIX feature used is `local` keyword, but most shells
including dash and ash implement it anyway. See [this](https://github.com/koalaman/shellcheck/wiki/SC3043).
- Can be used with bash/ash/dash/sh or zsh.
- Avoids use of global variables for anything other than configuration.
- Avoids global state variables

## Dependencies

- Two external commands are used. `printf` and depending on the log format `date`. Both are usually provided by
`coreutils` package or on some systems like alpine by `busybox`.

## Levels

| Function | Level |
|---|---|
| `log_trace` | 0
| `log_debug` | 10
| `log_info` | 20
| `log_success` | 20
| `log_warning` | 30
| `log_notice` | 35
| `log_error` | 40

- `log_info` and `log_success` have same priority as they are usually related to one another,

## Settings

- `LOG_FMT` (String) Log format. Default is `pretty`. Set it to `short` to enable showing level names. Set to any other value to show with timestamps. If terminal is non interactive or if colors are disabled `LOG_FMT` will revert to logs with timestamps.
- `LOG_LVL` (integer) Log Level. Default is `20`. All levels below this value will not be logged.
- `LOG_TO_STDERR` (boolean) Log to sdterr instead of stdout (Default is false). If set to `true` logs will be written to stderr instead of stdout.

## Demo

- `LOG_FMT=pretty` (default)
  <pre><font color="#B8BB26"></font> <font color="#005FD7">./logger/demo.sh</font>
  • This is info level
  <font color="#5FFF5F">• This is ok level </font>
  <font color="#5FD7FF">• This is notice level </font>
  <font color="#FFAF00">• This is warning level </font>
  <font color="#FF005F">• This is error level </font>
    - This is info level
  <font color="#5FFF5F">  - This is ok level </font>
  <font color="#5FD7FF">  - This is notice level </font>
  <font color="#FFAF00">  - This is warning level </font>
  <font color="#FF005F">  - This is error level </font>
  </pre>`

- `LOG_FMT="long"`
  <pre><font color="#B8BB26"></font> <font color="#00AFFF">LOG_FMT</font><font color="#00A6B2">=</font><font color="#00AFFF">full</font> <font color="#005FD7">./logger/demo.sh</font>
  2021-06-22 16:12:09+02:00 [INFO  ] This is info level
  <font color="#5FFF5F">2021-06-22 16:12:09+02:00 [OK    ] This is ok level </font>
  <font color="#5FD7FF">2021-06-22 16:12:09+02:00 [NOTICE] This is notice level </font>
  <font color="#FFAF00">2021-06-22 16:12:09+02:00 [WARN  ] This is warning level </font>
  <font color="#FF005F">2021-06-22 16:12:09+02:00 [ERROR ] This is error level </font>
  2021-06-22 16:12:09+02:00 [INFO  ] This is info level
  <font color="#5FFF5F">2021-06-22 16:12:09+02:00 [OK    ] This is ok level </font>
  <font color="#5FD7FF">2021-06-22 16:12:09+02:00 [NOTICE] This is notice level </font>
  <font color="#FFAF00">2021-06-22 16:12:09+02:00 [WARN  ] This is warning level </font>
  <font color="#FF005F">2021-06-22 16:12:09+02:00 [ERROR ] This is error level </font>

  </pre>

- With colors disabled or in a non-interactive terminal

  <pre><font color="#005FD7">./logger/demo.sh</font> <font color="#009900">|</font> <font color="#005FD7">tee</font> <font color="#00AFFF"><u style="text-decoration-style:single">/dev/null</u></font>
  2021-06-22 16:16:03+02:00 [INFO  ] This is info level
  2021-06-22 16:16:03+02:00 [OK    ] This is ok level
  2021-06-22 16:16:03+02:00 [NOTICE] This is notice level
  2021-06-22 16:16:03+02:00 [WARN  ] This is warning level
  2021-06-22 16:16:03+02:00 [ERROR ] This is error level
  2021-06-22 16:16:03+02:00 [INFO  ] This is info level
  2021-06-22 16:16:03+02:00 [OK    ] This is ok level
  2021-06-22 16:16:03+02:00 [NOTICE] This is notice level
  2021-06-22 16:16:03+02:00 [WARN  ] This is warning level
  2021-06-22 16:16:03+02:00 [ERROR ] This is error level

  </pre>


## Tests

- Tests are written in go.
- Tests require [faketime](https://github.com/wolfcw/libfaketime).
  - On Ubuntu/Mint `faketime` package is available from universe repository.
  - ON Debian `faketime` package is available from repositories
  - On CentOS/Fedora/RHEL package `libfaketime` is available form EPEL repositories.
- Run Tests
  ```bash
  go test -v ./... -count=1
  ```

## Usage

See [`demo.bash`](./demo.bash).
