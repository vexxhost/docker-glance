# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:zed@sha256:6fe55f69f3a005e0f6590c274f4bf7d929aab0619ebde2597533e695d8cd7da9 AS build
RUN --mount=type=bind,from=glance,source=/,target=/src/glance,readwrite \
    --mount=type=bind,from=glance_store,source=/,target=/src/glance_store,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/glance \
        /src/glance_store[cinder] \
        storpool \
        storpool.spopenstack
EOF
ADD --chmod=644 \
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/os_brick/openstack/zed/storpool.py \
    /var/lib/openstack/lib/python3.10/site-packages/os_brick/initiator/connectors/storpool.py

FROM ghcr.io/vexxhost/python-base:zed@sha256:31398c3faed8eb0828d6b43e5d1f91538f562e92d71d2eaba5dc9f7c0fafc5e7
RUN \
    groupadd -g 42424 glance && \
    useradd -u 42424 -g 42424 -M -d /var/lib/glance -s /usr/sbin/nologin -c "Glance User" glance && \
    mkdir -p /etc/glance /var/log/glance /var/lib/glance /var/cache/glance && \
    chown -Rv glance:glance /etc/glance /var/log/glance /var/lib/glance /var/cache/glance
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    ceph-common dmidecode lsscsi nvme-cli python3-rados python3-rbd qemu-block-extra qemu-utils sysfsutils udev util-linux
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
ADD --chmod=755 https://dl.k8s.io/release/v1.29.3/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
