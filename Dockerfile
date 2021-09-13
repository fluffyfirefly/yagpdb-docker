FROM golang:stretch as builder

WORKDIR /appbuild/yagpdb
COPY go.mod go.sum ./
RUN go mod download

COPY . .
WORKDIR /appbuild/yagpdb/cmd/yagpdb
RUN CGO_ENABLED=0 GOOS=linux go build -v -ldflags "-X github.com/jonas747/yagpdb/common.VERSION=$(git describe --tags)"



FROM alpine:latest

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
	addgroup -g 1000 -S yagpdb; \
	adduser -u 1000 -S -D -H -s /bin/sh -G yagpdb yagpdb

# Dependencies: su-exec for step-down from root, ca-certificates for client TLS, tzdata for timezone support and ffmpeg for soundboard support
RUN apk --no-cache add \
	ca-certificates \
	ffmpeg \
	su-exec \
	tzdata

COPY --from=builder /appbuild/yagpdb/cmd/yagpdb/yagpdb /app/yagpdb

RUN set -eux; \
	mkdir -p /app/cert /app/soundboard; \
	chown yagpdb:yagpdb /app/cert /app/soundboard; \
	chmod 1777 /app /app/cert /app/soundboard
	
VOLUME ["/app/cert", "/app/soundboard"]
WORKDIR /app
ENV PATH=/app:$PATH

COPY --from=builder /appbuild/yagpdb/yagpdb_docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 80 443
CMD ["yagpdb", "-all", "-pa", "-exthttps=false", "-https=true"]
