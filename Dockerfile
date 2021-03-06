# ===========================================
# infotechsoft/htcondor 
# SEE: http://research.cs.wisc.edu/htcondor
# ===========================================

FROM infotechsoft/java:11

ARG BUILD_DATE
ARG HTCONDOR_VERSION=8.9.7

LABEL name="infotechsoft/htcondor" \ 
	vendor="INFOTECH Soft, Inc." \
	version="${HTCONDOR_VERSION}" \
	build-date="${BUILD_DATE}"\
	maintainer="Thomas J. Taylor <thomas@infotechsoft.com>"
	
# HTCondor - default port for the condor_collector
ENV SHARED_PORT 9618
ARG SUBMIT_USER=submit

RUN yum -y -q update && \
    yum -y -q install curl && \
    rpm --import http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor && \
    curl -sS -o /etc/yum.repos.d/condor.repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo \
         -o /etc/yum.repos.d/condor-dev.repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-development-rhel7.repo && \
    yum -y -q install --enablerepo=centosplus condor-${HTCONDOR_VERSION} && \
    yum -y -q clean all && \
    useradd -m -g condor -u 1000 ${SUBMIT_USER}

# Configure HTCondor
RUN echo -e "DISCARD_SESSION_KEYRING_ON_STARTUP = False\n\
TRUST_UID_DOMAIN = True\n\
ALLOW_WRITE = *\n\
USE_SHARED_PORT = True\n\
SHARED_PORT_PORT = ${SHARED_PORT}\n" >> /etc/condor/condor_config.local

# Expose HTCondor shared port
EXPOSE ${SHARED_PORT}
# Expose volumes HTCondor logs and configuration
VOLUME ["/usr/local/condor/logs", "/etc/condor", "/home/${SUBMIT_USER}"]
WORKDIR /home/${SUBMIT_USER}

# Running condor_master directly from ENTRYPOINT isn't supported by HTCONDOR (pid=1) fails
#   Use '/bin/true' to allow condor_master to spawn under PID!=1
ENTRYPOINT /bin/true && /usr/sbin/condor_master -f -t