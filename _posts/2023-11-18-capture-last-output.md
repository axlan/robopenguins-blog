---
title: Understanding Linux Pipes to Capture a Process's Last Words
author: jon
layout: post
categories:
  - Software
  - Work
image: 2023/pipes.webp
---

For a work tool, I wanted to capture the last output from a process if it crashed. I ended up doing a deep dive into Linux data pipes to accomplish this seemingly trivial task.

Many beginner programmers hit a steep learning curve when it comes to using the Linux command line. Typically, you just get enough of the basics to use it for your day to day tasks. Even then though you start to see the tip of the iceberg on the complexity of Bash. I'm far from an expert which may explain why I ended up with an [XY problem](https://en.wikipedia.org/wiki/XY_problem).

My goal was to run a process in the background that generated status output on `stdout`, and detailed diagnostics on `stderr`. Since this is a long running process, I didn't want `stderr` to clutter the output. I also didn't want it to take up a lot of memory or disk space writing by to a file. However, if the process crashed, I needed to get the last chunk of `stderr` from before the crash.

Since I was mostly interested in start up crashes, I initially thought the best way to do this would be to have the process start with writing both `stdout` and `stderr` to the terminal, before switching to only `stdout`.

To do this I researched three different approaches:

1. Run the process in `screen` and dump the scrollback buffer after a short while. This however wouldn't let me get `stdout`.
2. Use `strace` to "spy" on the process's writes to `stderr` for the duration needed, then disconnect. This is pretty messy since you need to parse the output of strace.
3. Use a FIFO named pipe and connect the processes `stderr` to it. I could cat it to the screen at the start, then switch to cat-ing it to `/dev/null`. 

This third idea seemed worth pursuing.

As I was researching this ideas, I needed to get a more precise idea of what happens when one process pipes it's output to a file or process.

My current understanding is that when a process reads or writes to a file (including `stdin`/`stdout`) it will block until that operation completes. `stdin`, `stdout`, and `stderr` aren't particularly special in this case, but they have a special connection to the terminal the application started in.

In the past I've been fairly confused by the nuance of running a task in the background vs. using `nohup` or `disown`. My current understanding is that this mostly comes down to disconnecting the
these file handles, and the `SIGHUP` signal to avoid blocking the process or signalling a shutdown.

The first two ideas I had don't really need to get into this nuance since they write to the outut normally.
The third approach uses a named pipe as a proxy to allow switching the output between the terminal and `/dev/null`.

A named pipe is basically just a memory buffer mapped to a file handle. It's typically just a few KB. By directing the process's output to one, I can then swap out what's reading from the other side:

To test this I wrote a simple test script:

```bash
COUNT=1

while true
do
  echo $COUNT
  echo "e: $COUNT" 1>&2
  COUNT=$((COUNT+1))
  sleep 1
done
```


```bash
# Create the FIFO.
mkfifo /tmp/testpipe
# Open the FIFO to start accepting data.
exec 3<> /tmp/testpipe

# Redirect the processes stderr to the FIFO
./test_script.sh 2> /tmp/testpipe &
# Store the process ID of test_script.sh for later.
PID=$!

# While sleeping the stdout of test_script.sh will print to the screen, while the stderr will be
# buffered in /tmp/testpipe.
sleep 5

# Dump the contents of /tmp/testpipe to the terminal.
timeout 1 cat /tmp/testpipe

# For the next 5 seconds redirect the data written to /tmp/testpipe to /dev/null
timeout 5 cat /tmp/testpipe > /dev/null

# Stop test_script.sh.
kill $PID

# Delete the FIFO
rm /tmp/testpipe
```

While this works fine, it requires a second process to always be reading the FIFO to avoid blocking test_script.sh.

In writing this I realized my [XY problem](https://en.wikipedia.org/wiki/XY_problem). Really, I just wanted to get the last output from the process stderr before it exits. The `tail` command does exactly this.

I don't know the exact rules that tail uses to determine the "end" of the file when it comes to piped stdin, but after some tweaking, it did work for my use case.

```bash
# This looks complicated, but it's just swapping stdout and stderr so stderr gets piped to tail
# instead of stdout. This wouldn't be needed if I wanted to buffer stdout instead.
./test_script.sh 3>&- 3>&1 1>&2 2>&3 | tail &
# When piping you can't use $! since it can get the ID of tail instead. Since the script just runs
# in bash, this is a way to get the test_script.sh process ID.
PID=$(pgrep --newest bash)

# While sleeping the scripts stdout is printed to the terminal, while stderr is buffered in tail.
# This will be limited to the number of lines tail is configured to output (10 by default).
sleep 5

# When test_script.sh is killed, tail will detect it reached the "end" and will output the last 10
# lines it got from stderr.
kill $PID
```

This can be simplified further by using a subshell:

```bash
./test_script.sh 2> >(tail) &
PID=$!

sleep 5

kill $PID
```

# Update

I actually revisited this bit of bash a bit later. The new complication was that I wanted to be able to handle the script being killed with `ctrl+c`.

This turned out to have a bunch of complications. The main one is that even if you add a `trap` to handle the interrupt for the script, the background processes will still receive the signal. I've documented the snippet below to try to cover all the weirdness.

```bash
echo "Starting Application."

# Catch SIGINT/SIGTERM so they don't completely kill the script.
# Despite expectations, the application will still see the signal.
forward_shutdown () {
    echo "Forwarding shutdown request to application..."
}

trap forward_shutdown SIGINT SIGTERM

# Use a FIFO to forward the console to tail process. This is to avoid coupling
# the processes where tail exiting would cause a SIGPIPE. We need to do this
# because, even when trapping the signal, the background processes (tail and the
# application) still also receive the signal.
CONSOLE_FIFO=$(mktemp -u)
mkfifo $CONSOLE_FIFO

# While running the application will print stderr to the console as normal, but
# send stdout to the FIFO.
./my_application > $CONSOLE_FIFO &
APPLICATION_PID=$!

# Catch the last bit of stdout output to print in the case of an exit caused by
# a failure.
EXIT_TEXT_FILE=$(mktemp -u)
tail -n 500 $CONSOLE_FIFO > $EXIT_TEXT_FILE &
TAIL_PID=$!

# This waits until either the application exits, or the script itself is
# interrupted by a signal.
wait $APPLICATION_PID
EXIT_CODE=$?

EXIT_TEXT=$(cat $EXIT_TEXT_FILE)
rm -f $EXIT_TEXT_FILE
rm -f $CONSOLE_FIFO

# If we receive a SIGINT (2) or SIGTERM (15) to shutdown the script assume the
# child process was killed. We could add an additional `wait` call to wait for
# the process to actually exit.
#
# We do _not_, however, want to do this on SIGSEGV or any other error signals.
#
# An extra complication is that the reported exit for commands is terminated by
# a signal is reported as SIGNAL_VAL+128:
# https://www.gnu.org/software/bash/manual/html_node/Exit-Status.html. 
if [ $EXIT_CODE -eq 130 ] || [ $EXIT_CODE -eq 143 ]; then
    echo "Application killed."
    exit 0
fi

echo "Application exited with code: $EXIT_CODE"

if [ "${EXIT_CODE}" != "0" ]; then
    CONSOLE_FILE="$CACHE_DIR/console.txt"
    printf "Last Application output:\n===============================================================\n$EXIT_TEXT\n"
    exit $EXIT_CODE
fi
```

This is pushing what should be attempted in a "simple script" pretty far. While this is pretty solid, it relies on a ton of bash arcana. This sort of functionality is better suited to being managed with things like systemd to control execution and logging.
