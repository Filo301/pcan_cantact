#include <sys/unistd.h>
int _write(int fd, const void *buf, size_t len) {
  (void)fd; (void)buf; return (int)len;
}
