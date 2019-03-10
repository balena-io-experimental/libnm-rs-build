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
    python-pip \
    rust \
    yelp-tools


###############################################################################
# Install external Python dependencies

RUN pip install https://github.com/hay/xml2json/zipball/master


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

WORKDIR /build/docs/nm

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/NM-1.0.gir

RUN yelp-build html .


###############################################################################
# Python generation for ModemManager

WORKDIR /build/docs/mm

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/ModemManager-1.0.gir

RUN yelp-build html .


###############################################################################
# D-lang generation

WORKDIR /build/d-lang

RUN girtod -i NM-1.0.gir -o nm

RUN girtod -i ModemManager-1.0.gir -o mm


###############################################################################
# Generate JSON versions

WORKDIR /build/json

RUN xml2json -t xml2json --pretty --strip_text --strip_namespace --strip_newlines -o NM-1.0.json /usr/share/gir-1.0/NM-1.0.gir

RUN xml2json -t xml2json --pretty --strip_text --strip_namespace --strip_newlines -o ModemManager-1.0.json /usr/share/gir-1.0/ModemManager-1.0.gir


###############################################################################
# Generate TOML gir definitions

WORKDIR /build

COPY ./libnm-rs libnm-rs

COPY ./libmm-rs libmm-rs

WORKDIR /app

COPY ./generate.py .

RUN python generate.py


###############################################################################
# Rust generation for NetworkManager

WORKDIR /build/libnm-rs

RUN /app/gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_NM.sys.toml -o nm-sys

RUN /app/gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_NM.toml


###############################################################################
# Rust generation for ModemManager

WORKDIR /build/libmm-rs

RUN /app/gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_ModemManager.sys.toml -o mm-sys

RUN /app/gir/target/release/gir -d /usr/share/gir-1.0/ -c Gir_ModemManager.toml


###############################################################################
# Run web server

WORKDIR /app

COPY ./serve.py .

WORKDIR /build

CMD ["python", "/app/serve.py"]

