FROM docker.io/ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /tmp

# Install dependencies
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt \
 apt-get update \
 && apt-get install --no-install-recommends -y \
  curl \
  dnsutils \
  file \
  git \
  gpg \
  jq \
  lsb-release \
  make \
  python3 \
  python3-pip \
  unzip \
  vim \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install opentofu
ARG OPENTOFU_VERSION=1.9.1
RUN curl -Lso opentofu.zip "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/").zip" \
 && unzip -q opentofu.zip tofu \
 && install -o root -g root -m 0755 tofu /usr/local/bin/ \
 && rm opentofu.zip tofu \
 && tofu version

# Install terragrunt
ARG TERRAGRUNT_VERSION=0.81.0
RUN curl -Lso terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/")" \
 && install -o root -g root -m 0755 terragrunt /usr/local/bin/ \
 && rm terragrunt \
 && terragrunt -version

# Install yq
ARG YQ_VERSION=4.45.4
RUN curl -Lso yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/")" \
 && install -o root -g root -m 0755 yq /usr/local/bin/ \
 && rm yq \
 && yq --version

WORKDIR /app

# Copy infrastructure
COPY infrastructure/ ./

# Check tf code formatting
RUN tofu fmt -check -diff -recursive

# Cache terraform providers, and persist cache in the image
RUN --mount=type=cache,target=/var/tmp/terraform TF_PLUGIN_CACHE_DIR=/var/tmp/terraform ENV=cache make infra-init-cache \
 && cp -R /var/tmp/terraform /var/cache/terraform
ENV TF_PLUGIN_CACHE_DIR=/var/cache/terraform
ENV CHECKPOINT_DISABLE=true

# Set version
ARG P2P_VERSION
ENV P2P_VERSION=${P2P_VERSION}