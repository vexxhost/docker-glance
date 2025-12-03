# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:a07e37dd04cd2482761e02cd5870b2b271aa334e62b199c2df3a6455ce3ef77f AS build
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
    https://github.com/storpool/storpool-openstack-integration/raw/master/drivers/os_brick/openstack/caracal/storpool.py \
    /var/lib/openstack/lib/python3.12/site-packages/os_brick/initiator/connectors/storpool.py

FROM ghcr.io/vexxhost/python-base:main@sha256:2e16855b7d95781de7396ac2cac3aef32ca5a83079db724e3f97d4e4be322c94
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
ADD --chmod=755 https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
