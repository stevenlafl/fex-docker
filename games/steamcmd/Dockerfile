# Multi-stage build to minimize final image size
FROM ubuntu:24.04 AS builder

COPY Steam.tar.gz steamcmd.tar.gz /tmp/
RUN mkdir -p /tmp/workspace \
    && cd /tmp/workspace \
    && tar xvf /tmp/Steam.tar.gz \
    && tar xvf /tmp/steamcmd.tar.gz \
    && rm -rf /tmp/Steam.tar.gz /tmp/steamcmd.tar.gz

FROM stevenlafl/fex:latest

COPY --chown=fex:fex --from=builder /tmp/workspace ./

CMD ["sh", "-c", "FEX ./steamcmd.sh"]
