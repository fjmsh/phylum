FROM golang:alpine as builder
WORKDIR /src
COPY server/ .
RUN go build -o /bin/phylum cmd/phylum.go

FROM alpine
WORKDIR /app
COPY --from=builder /bin/phylum /app/phylum
ENTRYPOINT ["/app/phylum"]
CMD ["serve"]
