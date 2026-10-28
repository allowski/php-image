#!/usr/local/bin/php
<?php
/**
 * Verifies that the hardened php.ini is in effect. Run at build time by the
 * Dockerfile and in CI; exits non-zero on the first mismatch.
 */
declare(strict_types=1);

$bool = fn(string $k): bool => filter_var((string) ini_get($k), FILTER_VALIDATE_BOOLEAN);

// A php.ini directive the running PHP has deprecated or dropped shows up as a
// "PHP Startup" line when startup errors are displayed; session.sid_length did
// exactly that on 8.4, silently, until this check. shell_exec is disabled by
// the same php.ini, so the probe runs through proc_open (kept for snappdf).
function startupOutput(): string
{
    $proc = proc_open(
        [PHP_BINARY, '-d', 'display_startup_errors=1', '-d', 'error_reporting=E_ALL', '-r', 'echo 1;'],
        [1 => ['pipe', 'w'], 2 => ['pipe', 'w']],
        $pipes
    );
    if (!is_resource($proc)) {
        return 'proc_open failed';
    }
    $out = stream_get_contents($pipes[1]) . stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    proc_close($proc);
    return $out;
}
$startup = startupOutput();

$checks = [
    'PHP is 8.4 or newer'                    => PHP_VERSION_ID >= 80400,
    'php.ini raises no startup deprecation'  => !preg_match('/Deprecated|Warning/i', $startup),
    'expose_php is Off'                      => !$bool('expose_php'),
    'display_errors is Off'                  => !$bool('display_errors'),
    'display_startup_errors is Off'          => !$bool('display_startup_errors'),
    'log_errors is On'                       => $bool('log_errors'),
    'allow_url_include is Off'               => !$bool('allow_url_include'),
    'enable_dl is Off'                       => !$bool('enable_dl'),
    'upload_max_filesize is 40M'             => ini_get('upload_max_filesize') === '40M',
    'post_max_size is 40M'                   => ini_get('post_max_size') === '40M',
    'session.upload_progress.enabled is Off' => !$bool('session.upload_progress.enabled'),
    'session.cookie_httponly is On'          => $bool('session.cookie_httponly'),
    'session.use_strict_mode is On'          => $bool('session.use_strict_mode'),
    'session.use_only_cookies is On'         => $bool('session.use_only_cookies'),
    'zend.exception_ignore_args is On'       => $bool('zend.exception_ignore_args'),
    'system() is disabled'                   => !function_exists('system'),
    'shell_exec() is disabled'               => !function_exists('shell_exec'),
    'passthru() is disabled'                 => !function_exists('passthru'),
    'proc_open() is available (snappdf)'     => function_exists('proc_open'),
    'xdebug has no enabled features'         => !function_exists('xdebug_info') || xdebug_info('mode') === [],
];

$failed = false;
foreach ($checks as $label => $ok) {
    fwrite($ok ? STDOUT : STDERR, ($ok ? '  ok   ' : '  FAIL ') . $label . PHP_EOL);
    $failed = $failed || !$ok;
}
if (preg_match('/Deprecated|Warning/i', $startup)) {
    fwrite(STDERR, '  startup output was: ' . trim($startup) . PHP_EOL);
}

if ($failed) {
    fwrite(STDERR, "PHP hardening check FAILED\n");
    exit(1);
}
echo "PHP hardening OK\n";
