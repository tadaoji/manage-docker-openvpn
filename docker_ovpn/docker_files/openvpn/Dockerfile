FROM alpine:latest

RUN apk --update --no-cache --no-progress add \
  openvpn \
  easy-rsa \
  tzdata \
  && \
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localhost && \
  rm -rf /var/cache/apk/*

COPY run.sh /
CMD [ "/run.sh" ]

