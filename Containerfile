# Bayzite — a macOS-style spin of Bazzite
#
# One Containerfile builds all four editions. The GitHub workflow passes:
#   BASE_IMAGE  ghcr.io/ublue-os/bazzite-gnome:stable         (GNOME, AMD/Intel)
#               ghcr.io/ublue-os/bazzite-gnome-nvidia-open:stable (GNOME, NVIDIA)
#               ghcr.io/ublue-os/bazzite:stable               (KDE,  AMD/Intel)
#               ghcr.io/ublue-os/bazzite-nvidia-open:stable   (KDE,  NVIDIA)
#   DESKTOP     gnome | kde

ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-gnome:stable

# Build scripts and files live in a throwaway stage so they are not copied
# into the final image; build.sh copies only what is needed.
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM ${BASE_IMAGE}

ARG DESKTOP=gnome

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    DESKTOP="${DESKTOP}" bash /ctx/build.sh

### Verify the final image is a valid bootable container
RUN bootc container lint
