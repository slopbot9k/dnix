/* Test-only: glibc's merge sort, plus a log line for every qsort call in
 * which two different elements compared equal (the only case in which the
 * sort algorithm can change a result). Inherited by every child process. */
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef int (*compare_fn)(const void *, const void *);
static unsigned long ties;

static const char *name(void) {
#ifdef __APPLE__
  return getprogname();
#else
  extern char *program_invocation_short_name;
  return program_invocation_short_name;
#endif
}

static void merge_sort(char *base, char *scratch, size_t count, size_t size,
                       compare_fn compare) {
  if (count < 2) return;
  size_t half = count / 2;
  merge_sort(base, scratch, half, size, compare);
  merge_sort(base + half * size, scratch, count - half, size, compare);
  char *left = base, *left_end = base + half * size;
  char *right = left_end, *right_end = base + count * size;
  char *out = scratch;
  while (left < left_end && right < right_end) {
    int c = compare(left, right);
    if (c == 0 && memcmp(left, right, size) != 0) ties++;
    if (c <= 0) {
      memcpy(out, left, size);
      left += size;
    } else {
      memcpy(out, right, size);
      right += size;
    }
    out += size;
  }
  memcpy(out, left, (size_t)(left_end - left));
  out += left_end - left;
  memcpy(base, scratch, (size_t)(out - scratch));
}

static void trace_qsort(void *base, size_t count, size_t size,
                        compare_fn compare) {
  if (count < 2 || size == 0) return;
  char *scratch = malloc(count * size);
  if (scratch == NULL) abort();
  ties = 0;
  merge_sort(base, scratch, count, size, compare);
  free(scratch);
  const char *log = getenv("DNIX_QSORT_TRACE");
  if (ties && log) {
    char line[256];
    int n = snprintf(line, sizeof line, "%s %d n=%zu size=%zu ties=%lu\n",
                     name(), (int)getpid(), count, size, ties);
    int fd = open(log, O_WRONLY | O_APPEND | O_CREAT, 0666);
    if (fd >= 0) {
      write(fd, line, (size_t)n);
      close(fd);
    }
  }
}

__attribute__((constructor)) static void hello(void) {
  if (getenv("DNIX_STABLE_QSORT_CHECK") != NULL) {
    static const char loaded[] = "dnix-stable-qsort\n";
    write(2, loaded, sizeof loaded - 1);
  }
  const char *log = getenv("DNIX_QSORT_TRACE");
  if (log) {
    char line[256];
    int n = snprintf(line, sizeof line, "%s %d loaded\n", name(), (int)getpid());
    int fd = open(log, O_WRONLY | O_APPEND | O_CREAT, 0666);
    if (fd >= 0) {
      write(fd, line, (size_t)n);
      close(fd);
    }
  }
}

#ifdef __APPLE__
__attribute__((used, section("__DATA,__interpose"))) static const struct {
  const void *replacement;
  const void *replacee;
} interpose_qsort = {(const void *)trace_qsort, (const void *)qsort};
#else
void qsort(void *base, size_t count, size_t size, compare_fn compare) {
  trace_qsort(base, count, size, compare);
}
#endif
