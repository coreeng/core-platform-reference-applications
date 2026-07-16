ARG OPENTOFU_VERSION=1.12.3
ARG TERRAGRUNT_VERSION=0.92.1
ARG JQ_VERSION=1.8.1

FROM docker.io/debian:trixie AS tooling

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /tmp

ARG OPENTOFU_VERSION
ARG TERRAGRUNT_VERSION
ARG JQ_VERSION

# Install dependencies
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt \
 apt-get update \
 && apt-get install --no-install-recommends -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  make \
  postgresql-client \
  vim-tiny \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /usr/share/doc/* \
 && rm -f /var/lib/dpkg/info/*.md5sums

# Install gcloud CLI
ARG GCLOUD_CLI_VERSION=576.0.0
VOLUME ["/root/.config/gcloud"]
RUN --mount=type=cache,target=/var/cache/apt \
 echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl -Ls https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
 && apt-get update \
 && apt-get install --no-install-recommends -y \
  google-cloud-cli=${GCLOUD_CLI_VERSION}-0 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && gcloud config set core/disable_usage_reporting true \
 && gcloud config set component_manager/disable_update_check true \
 && gcloud config set metrics/environment github_docker_image \
 && gcloud --version \
 && find /usr/lib/google-cloud-sdk -type d \( -name test -o -name tests -o -name testdata -o -name test_data -o -name __pycache__ \) -prune -exec rm -rf {} + \
 && find /usr/lib/google-cloud-sdk -type d \( -name docs -o -name doc \) -prune -exec rm -rf {} + \
 && find /usr/lib/google-cloud-sdk -type d -name dummyserver -prune -exec rm -rf {} + \
 && find /usr/lib/google-cloud-sdk -name '*.pyc' -delete \
 && rm -rf /usr/share/doc/* /root/.cache/pip \
 && rm -f /var/lib/dpkg/info/*.md5sums

# Install jq
RUN curl -Lsfo jq "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-$(dpkg --print-architecture)" \
 && install -o root -g root -m 0755 jq /usr/local/bin/jq \
 && rm jq \
 && jq --version

# Install cloud-sql-proxy
ARG CLOUD_SQL_PROXY_VERSION=2.23.0
RUN curl -Lsfo cloud-sql-proxy "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v${CLOUD_SQL_PROXY_VERSION}/cloud-sql-proxy.linux.$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/")" \
 && install -o root -g root -m 0755 cloud-sql-proxy /usr/local/bin/cloud-sql-proxy \
 && rm cloud-sql-proxy \
 && cloud-sql-proxy --version

# Install opentofu
RUN curl -Lsfo opentofu.tgz "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/").tar.gz" \
 && tar zxf opentofu.tgz tofu \
 && install -o root -g root -m 0755 tofu /usr/local/bin/ \
 && rm opentofu.tgz tofu \
 && tofu version

# Install terragrunt
RUN curl -Lsfo terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/")" \
 && install -o root -g root -m 0755 terragrunt /usr/local/bin/ \
 && rm terragrunt \
 && terragrunt -version

# Install yq
ARG YQ_VERSION=4.53.3
RUN curl -Lso yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(uname -m | sed -e "s/aarch64/arm64/" -e "s/x86_64/amd64/")" \
 && install -o root -g root -m 0755 yq /usr/local/bin/ \
 && rm yq \
 && yq --version

FROM tooling AS lint

WORKDIR /app

# Copy infrastructure
COPY infrastructure/ ./

# Check tf & tg formatting
RUN tofu fmt -check -diff -recursive && terragrunt hcl fmt --check

FROM lint

# Cache terraform providers, and persist cache in the image
RUN --mount=type=cache,target=/var/tmp/terraform \
 TF_PLUGIN_CACHE_DIR=/var/tmp/terraform \
 TF_PLUGIN_CACHE_DESTINATION=/var/cache/terraform \
 make infra-init-cache
ENV TF_PLUGIN_CACHE_DIR=/var/cache/terraform

ENV CHECKPOINT_DISABLE=true

# Set version
ARG P2P_VERSION
ENV P2P_VERSION=${P2P_VERSION}
