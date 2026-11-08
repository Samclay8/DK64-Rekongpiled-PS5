/* C library functions the payload SDK's libc does not provide, for a PS5 title. */
#include <stddef.h>
#include <stdint.h>
#include <time.h>

/* The C locale is the only one in a title: one byte per character. */
int ___mb_cur_max(void) { return 1; }

/* Advice only: ignoring it is always allowed. */
int posix_madvise(void *addr, size_t len, int advice) {
    (void)addr; (void)len; (void)advice;
    return 0;
}

/* Days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant's days_from_civil). */
static int64_t days_from_civil(int64_t y, unsigned m, unsigned d) {
    y -= m <= 2;
    const int64_t era = (y >= 0 ? y : y - 399) / 400;
    const unsigned yoe = (unsigned)(y - era * 400);
    const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + (int64_t)doe - 719468;
}

/* mktime for UTC: struct tm fields as given, out-of-range months folded into years. */
time_t timegm(struct tm *tm) {
    int64_t year = (int64_t)tm->tm_year + 1900;
    int64_t month = tm->tm_mon;
    year += month / 12;
    month %= 12;
    if (month < 0) {
        month += 12;
        year -= 1;
    }
    int64_t days = days_from_civil(year, (unsigned)month + 1, 1) + (tm->tm_mday - 1);
    return (time_t)(days * 86400 + (int64_t)tm->tm_hour * 3600 + (int64_t)tm->tm_min * 60 + tm->tm_sec);
}

/* DK64: curl and OpenSSL from PacBrew (RecompFrontend's online mod list) name these, and the
   system modules a title links against don't export them. Declared here without the system
   headers, whose prototypes for some of them the SDK leaves out. */
int pipe(int fds[2]);
int fcntl(int fd, int cmd, ...);
void abort(void);
int *__error(void);
#define SHIM_ENOSYS 78 /* ENOSYS on FreeBSD */
#define SHIM_F_GETFD 1
#define SHIM_F_SETFD 2
#define SHIM_F_GETFL 3
#define SHIM_F_SETFL 4
#define SHIM_FD_CLOEXEC 1
#define SHIM_O_NONBLOCK 0x0004
#define SHIM_O_CLOEXEC 0x00100000

/* curl's wake-up pipe: pipe() and the flags set after it. */
int pipe2(int fds[2], int flags) {
    if (pipe(fds) != 0) {
        return -1;
    }
    for (int i = 0; i < 2; i++) {
        if (flags & SHIM_O_NONBLOCK) {
            fcntl(fds[i], SHIM_F_SETFL, fcntl(fds[i], SHIM_F_GETFL) | SHIM_O_NONBLOCK);
        }
        if (flags & SHIM_O_CLOEXEC) {
            fcntl(fds[i], SHIM_F_SETFD, fcntl(fds[i], SHIM_F_GETFD) | SHIM_FD_CLOEXEC);
        }
    }
    return 0;
}

/* IPv6 zone names in URLs ("fe80::1%eth0"): no interface has a name to look up. */
unsigned int if_nametoindex(const char *name) {
    (void)name;
    return 0;
}

/* OpenSSL's datagram BIO (DTLS, QUIC), which curl's HTTPS never uses: not supported. */
int sendmmsg(int fd, void *msgs, unsigned int count, int flags) {
    (void)fd; (void)msgs; (void)count; (void)flags;
    *__error() = SHIM_ENOSYS;
    return -1;
}
int recvmmsg(int fd, void *msgs, unsigned int count, int flags, void *timeout) {
    (void)fd; (void)msgs; (void)count; (void)flags; (void)timeout;
    *__error() = SHIM_ENOSYS;
    return -1;
}

/* OpenSSL's ASYNC job fibres, only reached through ASYNC_start_job, which curl never calls. A wrapper
   around setjmp can't stand in for _setjmp (its frame is gone when it returns), so these stop the
   title loudly if that assumption is ever wrong. */
int _setjmp(void *env) {
    (void)env;
    abort();
    return 0;
}
void _longjmp(void *env, int value) {
    (void)env; (void)value;
    abort();
}
