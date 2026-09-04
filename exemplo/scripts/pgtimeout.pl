#!/usr/bin/env perl
# Timeout com grupo de processo (macOS não tem `timeout`).
# Uso: perl scripts/pgtimeout.pl <segundos> <cmd...>
# Sai com 142 no timeout; senão propaga o exit code do comando.
use strict; use warnings;
my $t = shift @ARGV or die "uso: pgtimeout.pl <s> <cmd...>\n";
my $pid = fork;
die "fork: $!" unless defined $pid;
if (!$pid) { setpgrp(0, 0); exec @ARGV or die "exec: $!" }
$SIG{ALRM} = sub {
    kill 'TERM', -$pid; sleep 5; kill 'KILL', -$pid;
    waitpid $pid, 0;
    exit 142;
};
alarm $t;
waitpid $pid, 0;
my $st = $?;
exit(($st >> 8) || (($st & 127) ? 128 + ($st & 127) : 0));
