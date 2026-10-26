# smartpass-base-image

PHP 8.2 + Apache (mod_php) base image with PostgreSQL PDO, GD, Zip, Composer,
Xdebug and Google Chrome (for `beganovich/snappdf`).

## Security hardening

The image ships a hardened `php.ini` (`config/php/php.ini`) and an Apache
hardening config (`config/apache/hardening.conf`). Highlights:

| Area | Setting |
| --- | --- |
| Uploads | `upload_max_filesize = 40M`, `post_max_size = 40M`, `max_file_uploads = 10`, Apache `LimitRequestBody 41943040` |
| Upload progress | `session.upload_progress.enabled = Off` |
| Info disclosure | `expose_php = Off`, `display_errors = Off`, `log_errors = On`, `ServerTokens Prod`, `ServerSignature Off`, `X-Powered-By` stripped |
| Code execution | `allow_url_include = Off`, `enable_dl = Off`, `disable_functions = passthru,shell_exec,system,popen,pcntl_exec,show_source,highlight_file` (`exec`/`proc_open` kept for snappdf / Laravel Process / Composer) |
| Sessions | `use_strict_mode`, `use_only_cookies`, `cookie_httponly`, `cookie_samesite = Lax`, 48-char session ids |
| Resource limits | `max_execution_time = 60`, `max_input_time = 60`, `max_input_vars = 1000`, `memory_limit = 256M`, Apache `RequestReadTimeout` |
| Apache | `TraceEnable Off`, dotfiles (`.env`, `.git`, ...) and `*.env/ini/log/sql/sh/...` return 403, directory listings off, `X-Content-Type-Options: nosniff` |
| Xdebug | Installed but `xdebug.mode = "off"` |

`php-hardening-check` (installed in the image) verifies the PHP settings; it runs
at build time and in CI.

### Overriding a setting

`$PHP_INI_DIR/conf.d/*.ini` is parsed after `php.ini`, so a downstream image can
override any directive without replacing the whole file:

```Dockerfile
FROM allowski/php-image:latest
RUN printf 'upload_max_filesize = 64M\npost_max_size = 64M\n' > "$PHP_INI_DIR/conf.d/zz-app.ini"
```

Enable Xdebug for local development at run time (no rebuild needed):

```sh
docker run -e XDEBUG_MODE=debug,develop -e XDEBUG_CONFIG="client_host=host.docker.internal" ...
```

Once the app is served only over HTTPS, also set `session.cookie_secure = 1`
in a conf.d override.
