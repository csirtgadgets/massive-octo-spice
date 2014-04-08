all: default

default:

install:

# if someone wants to turn this into a PPA, feel free :)
install-debian:
	$(INSTALL) -m 0755 deb/init.d/cif-router $(DESTDIR)/etc/init.d/cif-router
	$(INSTALL) -m 0755 deb/init.d/cif-smrt $(DESTDIR)/etc/init.d/cif-smrt
	$(INSTALL) -m 0660 deb/default/cif $(DESTDIR)/etc/default/cif
	update-rc.d cif-router defaults 95 10
	update-rc.d cif-smrt defaults 95 10
