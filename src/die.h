#ifndef __DIE_H__
#define __DIE_H__

#define die(fmt, ...)                                                   \
  do {                                                                  \
    fprintf(stderr, "%s:%d:%s(): " fmt "\n",                            \
            __FILE__, __LINE__, __func__,                               \
            ##__VA_ARGS__);                                             \
    exit(EXIT_FAILURE);                                                 \
  } while (0)

#endif /* __DIE_H__ */
