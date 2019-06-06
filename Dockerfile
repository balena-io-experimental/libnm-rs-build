FROM archlinux/base


###############################################################################
# Install packages

RUN pacman --noconfirm -Syu \
    gobject-introspection \
    libnm \
    libmm-glib \
    gawk \
    yelp-tools


###############################################################################
# Python generation for NetworkManager

WORKDIR /docs/nm

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/NM-1.0.gir

RUN yelp-build html .


###############################################################################
# Python generation for ModemManager

WORKDIR /docs/mm

RUN g-ir-doc-tool --language=Python -o . /usr/share/gir-1.0/ModemManager-1.0.gir

RUN yelp-build html .

###############################################################################
# Run web server

WORKDIR /app

COPY ./serve.py .

WORKDIR /docs

CMD ["python", "/app/serve.py"]

