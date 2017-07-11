FROM ubuntu:16.04
MAINTAINER Chad Sailer


# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       devscripts \
       locales \
       python-software-properties \
       software-properties-common \
       rsyslog systemd systemd-cron sudo wget openssh-client uuid-runtime
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf
#ADD etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf

# Install Ansible
RUN add-apt-repository -y ppa:ansible/ansible \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
     ansible 

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Ansible inventory file
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

RUN ansible-galaxy install\
    v0rts.java

RUN mkdir /tmp/ansible
WORKDIR /tmp/ansible
ADD java.yml /tmp/ansible/java.yml
RUN ansible-playbook -i localhost, java.yml

# Install Rundeck
RUN wget http://dl.bintray.com/rundeck/rundeck-deb/rundeck-2.8.3-1-GA.deb \
    && dpkg -i rundeck-2.8.3-1-GA.deb \
    && rm rundeck-*.deb 

# Clean up apt-get repo
RUN rm -rf /var/lib/apt/lists/* \
  && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
  && apt-get clean

# Run Rundeck
CMD ["/etc/init.d/rundeckd", "start"]

