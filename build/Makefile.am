all: default

default:

install:

# later we'll turn this into packaging the .deb
#GET OFF MY ASS
install-debian:
	$(INSTALL) -m 0755 deb/init.d/cif-router $(DESTDIR)/etc/init.d/cif-router
	$(INSTALL) -m 0755 deb/init.d/cif-smrt $(DESTDIR)/etc/init.d/cif-smrt
	$(INSTALL) -m 0660 deb/default/cif $(DESTDIR)/etc/default/cif
