FROM debian:8

ENV HOME=/root
WORKDIR $HOME

RUN apt-get update && \
	apt-get -y upgrade

RUN apt install -y nasm doxygen m4 mercurial darcs wget rsync git patch unzip aspcud libgit2-dev

RUN wget https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh -O - | sh -s /usr/local/bin

ENV PATH="/root/.local/bin:${PATH}"

RUN wget -qO- https://get.haskellstack.org/ | sh

ENV OPAMROOT=$HOME/opam-coq.8.5.2
ENV OPAMYES="true"
ENV OPAMJOBS=2

RUN opam init -n --comp=4.01.0 -j 2

ENV CAML_LD_LIBRARY_PATH="/root/opam-coq.8.5.2/4.01.0/lib/stublibs"
ENV MANPATH="/root/opam-coq.8.5.2/4.01.0/man"
ENV PERL5LIB="/root/opam-coq.8.5.2/4.01.0/lib/perl5"
ENV OCAML_TOPLEVEL_PATH="/root/opam-coq.8.5.2/4.01.0/lib/toplevel"
ENV PATH="/root/opam-coq.8.5.2/4.01.0/bin:${PATH}"

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

WORKDIR $HOME/pipcore/
RUN make PARTITION=minimal partition