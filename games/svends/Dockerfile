FROM ubuntu:24.04 AS builder

COPY svends.tar.gz /tmp/

RUN mkdir -p /tmp/workspace \
    && cd /tmp/workspace \
    && tar xvf /tmp/svends.tar.gz

FROM stevenlafl/fex:steamcmd

COPY --chown=fex:fex --from=builder /tmp/workspace ./Steam/steamapps/common

CMD ["sh", "-c", "cd '/home/fex/Steam/steamapps/common/Sven Co-op Dedicated Server' && FEX ./svends_run"]
