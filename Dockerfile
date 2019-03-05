FROM archlinux/base


###############################################################################
# Install packages

RUN pacman --noconfirm -Syu \
    autoconf-archive \
    base-devel \
    gir-to-d \
    git \
#    gobject-introspection \
    libnm \
    libmm-glib \
    mlocate \
    patch \
    python-gobject \
    python-mako \
    python-markdown \
    rust \
    yelp-tools


###############################################################################
# Build gobject-introspection

WORKDIR /app

RUN git clone --progress https://gitlab.gnome.org/GNOME/gobject-introspection.git

WORKDIR /app/gobject-introspection

RUN ./autogen.sh --enable-doctool --prefix=/usr

RUN make -l 4

RUN make install


###############################################################################
# Build Rust Gir

WORKDIR /app/patches

COPY ./patches/gir gir

WORKDIR /app

RUN git clone --progress https://github.com/gtk-rs/gir.git

WORKDIR /app/gir

RUN patch -p0 < /app/patches/gir/source-position.patch
RUN patch -p0 < /app/patches/gir/in-addr.patch

RUN cargo build --release


###############################################################################
# Patch NM-1.0.gir

WORKDIR /app/patches

COPY ./patches/nm nm

WORKDIR /usr/share/gir-1.0/

RUN patch < /app/patches/nm/no-doc-version.patch
RUN patch < /app/patches/nm/in-addr.patch


###############################################################################
# Patch ModemManager-1.0.gir

WORKDIR /app/patches

COPY ./patches/mm mm

WORKDIR /usr/share/gir-1.0/

RUN patch < /app/patches/mm/no-type-name.patch


###############################################################################
# Python generation for NetworkManager

WORKDIR /app/docs/nm

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/NM-1.0.gir

RUN yelp-build html .


###############################################################################
# Python generation for ModemManager

WORKDIR /app/docs/mm

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/ModemManager-1.0.gir

RUN yelp-build html .


###############################################################################
# D-lang generation

WORKDIR /app/d-lang

RUN girtod -i NM-1.0.gir -o nm

RUN girtod -i ModemManager-1.0.gir -o mm


###############################################################################
# Rust generation for NetworkManager

WORKDIR /app

COPY ./libnm-rs libnm-rs

WORKDIR /app/libnm-rs

RUN ../gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_NM.sys.toml -o nm-sys

RUN ../gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_NM.toml


###############################################################################
# Rust generation for ModemManager

WORKDIR /app

COPY ./libmm-rs libmm-rs

WORKDIR /app/libmm-rs

RUN ../gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_ModemManager.sys.toml -o mm-sys

RUN ../gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_ModemManager.toml


###############################################################################
# Run web server

WORKDIR /app

COPY ./serve.py .

CMD ["python", "serve.py"]

