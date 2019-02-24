FROM archlinux/base

RUN pacman --noconfirm -Syu 

RUN pacman --noconfirm -S \
    autoconf-archive \
    base-devel \
    gir-to-d \
    git \
    libnm \
    mlocate \
    python-gobject \
    python-mako \
    python-markdown \
    yelp-tools

WORKDIR /app

RUN git clone --progress https://gitlab.gnome.org/GNOME/gobject-introspection.git

WORKDIR /app/gobject-introspection

RUN ./autogen.sh --enable-doctool --prefix=/usr

RUN make -l 4

RUN make install

WORKDIR /app/docs

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/NM-1.0.gir

RUN yelp-build html .

WORKDIR /app

COPY ./patches patches

RUN ls -al patches

WORKDIR /usr/share/gir-1.0/

RUN ls -al

RUN patch < /app/patches/nm-no-doc-version.patch

WORKDIR /app

RUN girtod -i NM-1.0.gir -o d-lang

RUN ls -al d-lang/nm

WORKDIR /app/d-lang/nm

CMD ["python", "-m", "http.server"]
