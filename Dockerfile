FROM phusion/baseimage:jammy-1.0.1

ENV DEBIAN_FRONTEND=noninteractive

# Download and register the Microsoft repository GPG keys
RUN apt-get update
RUN apt-get install -y wget apt-transport-https software-properties-common
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
RUN dpkg -i packages-microsoft-prod.deb

# Update and install misc packages
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install --no-install-recommends --no-install-suggests -y \
    powershell lib32gcc-s1 curl ca-certificates locales supervisor zip

# Install SteamCMD
WORKDIR /steam
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
  && tar xvf steamcmd_linux.tar.gz

# Install Wine
RUN wget -O - https://dl.winehq.org/wine-builds/winehq.key | apt-key add -  && \
    echo 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' |tee /etc/apt/sources.list.d/winehq.list && \
    apt-get update && apt-get --install-recommends -y install winehq-staging winbind  && \
    apt-get -y install winetricks

WORKDIR /opt/wine-staging/share/wine/mono
RUN wget -O - https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-x86.tar.xz | tar Jx -C /opt/wine-staging/share/wine/mono

WORKDIR /opt/wine-staging/share/wine/gecko
RUN wget -O /opt/wine-staging/share/wine/gecko/wine-gecko-2.47.1-x86.msi https://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.msi && wget -O /opt/wine-staging/share/wine/gecko/wine-gecko-2.47.2-x86_64.msi https://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.msi && \
    apt-get -y full-upgrade && apt-get clean

# Set up server folders
WORKDIR /app
RUN mkdir -p ./backups
RUN mkdir -p ./server
RUN mkdir -p ./logs

# Copy configs
COPY ./configs/supervisord.conf /etc

# Copy scripts
WORKDIR /scripts
COPY ./scripts/Entrypoint.ps1 .
COPY ./scripts/Start-Server.ps1 .
COPY ./scripts/Start-BackupService.ps1 .
COPY ./scripts/Start-UpdateService.ps1 .

# HEALTHCHECK CMD sv status ddns | grep run || exit 1
# RUN chmod 755 /etc/service/ddns/run

CMD pwsh /scripts/Entrypoint.ps1
