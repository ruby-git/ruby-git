FROM alpine:3.12

ARG GIT_VERSION

RUN apk add --no-cache curl curl-dev build-base expat-dev openssl-dev zlib-dev pcre2-dev gettext-dev

RUN curl -sL "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz" | tar -xz && \
    cd "git-${GIT_VERSION}" && \
    make prefix=/usr/local NO_REGEX=NeedsStartEnd NO_TCLTK=YesPlease LIBC_CONTAINS_LIBINTL= all && \
    make prefix=/usr/local NO_REGEX=NeedsStartEnd NO_TCLTK=YesPlease LIBC_CONTAINS_LIBINTL= install && \
    cd .. && rm -rf "git-${GIT_VERSION}"

ENTRYPOINT ["/bin/sh"]
