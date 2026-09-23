# =========================================================================
# Stage 1: Build the self-contained native Linux executable
# =========================================================================
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# =========================================================================
# Stage 2: Minimal scratch/distroless runtime (< 20MB image)
# =========================================================================
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/server /app/server

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]
