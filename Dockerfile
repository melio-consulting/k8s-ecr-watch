FROM python:3.9-alpine
LABEL description="An utility image that checks for changes to image tags in AWS ECR."

RUN apk upgrade --update

RUN apk add \
    bash \
    curl \
    groff \
    jq

RUN pip install --upgrade pip \
    awscli

ENV KUBECTL_VERSION 1.20.7

ADD https://storage.googleapis.com/kubernetes-release/release/v"$KUBECTL_VERSION"/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

WORKDIR /app

COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

ENV NAMESPACE ""
ENV DEPLOYMENT ""
ENV REGISTRY ""
ENV ASSUME_ROLE ""

CMD ["bash", "-c", "/app/run.sh"]
