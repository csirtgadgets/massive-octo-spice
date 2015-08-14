FROM ubuntu
MAINTAINER Aaron Eppert (aeppert@gmail.com)

# Update the repository sources list
RUN apt-get update

RUN apt-get -y install curl
RUN apt-get -y install wget
RUN apt-get -y install gettext
RUN apt-get -y install dnsutils
RUN curl -Ls https://raw.githubusercontent.com/csirtgadgets/massive-octo-spice/master/hacking/platforms/easybutton_curl.sh | sudo bash -
RUN sudo chown `whoami`:`whoami` ~/.cif.yml

ADD ./scripts/start.sh /start.sh
ADD ./scripts/foreground.sh /etc/apache2/foreground.sh
RUN chmod 755 /start.sh
RUN chmod 755 /etc/apache2/foreground.sh

EXPOSE 443
EXPOSE 5000
EXPOSE 9200

CMD ["/bin/bash", "/start.sh"]
