FROM archlinux/base

RUN pacman --noconfirm -Syu 

RUN pacman --noconfirm -S \
    autoconf-archive \
    base-devel \
    gir-to-d \
    git \
    libnm \
    python-gobject \
    python-mako \
    python-markdown \
    yelp-tools

WORKDIR /app

RUN git clone --progress https://gitlab.gnome.org/GNOME/gobject-introspection.git

WORKDIR /app/gobject-introspection

RUN ./autogen.sh --enable-doctool

RUN make -l 4

RUN make install

WORKDIR /app/docs

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/NM-1.0.gir

RUN yelp-build html .

#CMD ["girtod", "-i", "/usr/share/gir-1.0/NM-1.0.gir"]
#CMD ["python", "-c", "import gi; gi.require_version('NM', '1.0'); from gi.repository import NM"]

CMD ["python3", "-m", "http.server"]
