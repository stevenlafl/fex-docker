# Multi-stage build to minimize final image size
FROM ubuntu:24.04 AS builder

COPY ./games/svends/sven5-26.tar.gz /tmp/

RUN mkdir -p /tmp/workspace \
    && cd /tmp/workspace \
    && tar xvf /tmp/sven5-26.tar.gz && rm -rf /tmp/sven5-26.tar.gz

FROM stevenlafl/fex:steamcmd

COPY --chown=fex:fex --from=builder /tmp/workspace ./Steam/steamapps/common

CMD ["sh", "-c", "cd '/home/fex/Steam/steamapps/common/Sven Co-op Dedicated Server' && FEX ./svends_run"]
