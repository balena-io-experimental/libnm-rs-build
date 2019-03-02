FROM archlinux/base


###############################################################################
# Install packages

RUN pacman --noconfirm -Syu \
    autoconf-archive \
    base-devel \
    gir-to-d \
    git \
    libnm \
    mlocate \
    python-gobject \
    python-mako \
    python-markdown \
    rust \
    yelp-tools


###############################################################################
# Copy files

WORKDIR /app

COPY ./patches patches

COPY ./libnm-rs libnm-rs

###############################################################################
# Python generation

WORKDIR /app

RUN git clone --progress https://gitlab.gnome.org/GNOME/gobject-introspection.git

WORKDIR /app/gobject-introspection

RUN ./autogen.sh --enable-doctool --prefix=/usr

RUN make -l 4

RUN make install

WORKDIR /app/docs

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/NM-1.0.gir

RUN yelp-build html .


###############################################################################
# D-lang generation

WORKDIR /usr/share/gir-1.0/

RUN patch < /app/patches/nm-no-doc-version.patch

WORKDIR /app

RUN girtod -i NM-1.0.gir -o d-lang

###############################################################################
# Rust generation

WORKDIR /app

RUN git clone --progress https://github.com/gtk-rs/gir.git

WORKDIR /app/gir

RUN cargo build --release

WORKDIR /app/libnm-rs

RUN ../gir/target/release/gir -c Gir_NM.sys.toml -o nm-sys -d /usr/share/gir-1.0/

RUN ../gir/target/release/gir -c Gir_NM.toml

WORKDIR /app

###############################################################################
# Run web server

CMD ["python", "-m", "http.server"]
