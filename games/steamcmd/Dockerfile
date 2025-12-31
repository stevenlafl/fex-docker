FROM ubuntu:24.04 AS builder

COPY steamcmd.tar.gz /tmp/
RUN mkdir -p /tmp/workspace \
    && cd /tmp/workspace \
    && tar xvf /tmp/steamcmd.tar.gz

FROM stevenlafl/fex:latest

COPY --chown=fex:fex --from=builder /tmp/workspace ./

CMD ["FEX", "./linux32/steamcmd"]
