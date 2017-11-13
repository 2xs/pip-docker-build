FROM debian:8

ENV HOME=/root
WORKDIR $HOME

RUN apt-get update && \
	apt-get -y upgrade

RUN apt install -y nasm doxygen m4 mercurial darcs wget rsync git patch unzip aspcud libgit2-dev

RUN wget https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh -O - | sh -s /usr/local/bin

ENV PATH="/root/.local/bin:${PATH}"

RUN wget -qO- https://get.haskellstack.org/ | sh

ENV OPAMROOT=$HOME/opam
ENV OPAM_VERSION="4.01.0"
ENV OPAM_PATH="${OPAMROOT}/${OPAM_VERSION}"
ENV OPAMYES="true"
ENV OPAMJOBS=2

RUN opam init -n --comp=${OPAM_VERSION} -j 2

ENV CAML_LD_LIBRARY_PATH="${OPAM_PATH}/lib/stublibs"
ENV MANPATH="${OPAM_PATH}/man"
ENV PERL5LIB="${OPAM_PATH}/lib/perl5"
ENV OCAML_TOPLEVEL_PATH="${OPAM_PATH}/lib/toplevel"
ENV PATH="${OPAM_PATH}/bin:${PATH}"

RUN opam repo add coq-released http://coq.inria.fr/opam/released
RUN opam install coq.8.5.2
RUN opam pin add coq 8.5.2

RUN git clone https://github.com/2xs/libpip -b feature/docker-build
RUN git clone https://github.com/2xs/pipcore

WORKDIR $HOME/libpip
RUN make

WORKDIR $HOME/pipcore/
RUN git submodule init && \
	git submodule update
RUN sed "s/LIBPIP=.*/LIBPIP=\/root\/libpip/g" src/partitions/x86/toolchain.mk.template > src/partitions/x86/toolchain.mk

WORKDIR $HOME/pipcore/tools/digger
RUN stack setup
RUN stack build

WORKDIR $HOME/pipcore/
RUN make PARTITION=minimal partition kernel ; make PARTITION=minimal partition kernel
