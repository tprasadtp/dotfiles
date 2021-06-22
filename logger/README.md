# logger

Simple bash logger.

- Supports leveled logging
- Supports colored logs
- Supports https://bixense.com/clicolors/ and https://no-color.org/ standards.
- Optionally log to stdderr instead of default stdout by setting `LOG_TO_STDERR=true`

## Levels

| Function | Level |
|---|---|
| `log_variable` | 0
| `log_debug` | 10
| `log_info` | 20
| `log_success` | 20
| `log_warning` | 30
| `log_notice` | 35
| `log_error` | 40

- `log_info` and `log_success` have same priority as they are usually related to one another,
Only difference between them is output color when colors are enabled.
- All functions above have `log_step*` equivalants which add a small indentation to logs as as shown in demo below.
(only effective if `LOG_FMT=pretty`)

## Settings

- `LOG_FMT` (String) Log format. Default is `pretty`. Set it to `full` to enable logs with timestamps. If terminal is non interactive or if colors are disabled `LOG_FMT` will revert to `full`
- `LOG_LVL` (integer) Log Level. Default is `20`. All levels below this value will not be logged.
- `LOG_TO_STDERR` (boolean) Log to sdterr instead of stdout (Default is false). If set to `true` logs will be written to stderr instead of stdout.

## Demo

- `LOG_FMT=pretty` (default)
  <pre><font color="#B8BB26"></font> <font color="#005FD7">./logger/demo.bash</font>
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

- `LOG_FMT="full"`
  <pre><font color="#B8BB26"></font> <font color="#00AFFF">LOG_FMT</font><font color="#00A6B2">=</font><font color="#00AFFF">full</font> <font color="#005FD7">./logger/demo.bash</font>
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

  <pre><font color="#005FD7">./logger/demo.bash</font> <font color="#009900">|</font> <font color="#005FD7">tee</font> <font color="#00AFFF"><u style="text-decoration-style:single">/dev/null</u></font>
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
- Tests require [faketime](https://github.com/wolfcw/libfaketime). On Ubuntu `faketime` pacakge is available from universe repos.

```bash
go test -v ./... -count=1
```

## Usage

See [`demo.bash`](./demo.bash).
