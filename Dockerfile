FROM microsoft/mssql-server-linux:latest

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="fishtenors/mssql-openshift" \
    vendor="fishtenors" \
    version="1.0" \
    release="1" \
    summary="MS SQL Server" \
    description="Microsoft SQL Server for Kubernetes/OpenShift" \
    ### Required labels above - recommended below
    url="https://www.microsoft.com/en-us/sql-server/" \
    run='docker run --name ${NAME} \
    -e ACCEPT_EULA=Y \
    -e MSSQL_SA_PASSWORD=yourStrong@Password \
    -p 1433:1433 \
    -d ${IMAGE}' \
    io.k8s.description="Microsoft SQL Server for Kubernetes/OpenShift" \
    io.k8s.display-name="MS SQL Server"


# For environment variables list, see https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-configure-environment-variables
# If you want to specify LCID, you may not set here. You should specify with running a docker. ``docker run -e "MSSQL_LCID=1041" <image>``
ARG SA_PASSWORD='StrongP@ssW0rd'
ARG TCP_PORT=1433
ARG PID=Developer
ENV ACCEPT_EULA=Y MSSQL_PID=$PID MSSQL_SA_PASSWORD=$SA_PASSWORD MSSQL_TCP_PORT=$TCP_PORT

# Create a config directory
RUN mkdir -p /usr/config
WORKDIR /usr/config

# Bundle config source
COPY entrypoint.sh /usr/config
COPY configure-db.sh /usr/config

# Grant permissions for to our scripts to be executable
RUN chmod +x /usr/config/entrypoint.sh
RUN chmod +x /usr/config/configure-db.sh

RUN mkdir -p /var/opt/mssql && \
    chmod -R g=u /var/opt/mssql /etc/passwd

### Containers should not run as root as a good practice
USER 10001

# Default SQL Server TCP/Port
EXPOSE 1433

ENTRYPOINT ["./entrypoint.sh"]

# Tail the setup logs to trap the process
CMD ["tail -f /dev/null"]

HEALTHCHECK --interval=15s CMD /opt/mssql-tools/bin/sqlcmd -U sa -P $SA_PASSWORD -Q "select 1" && grep -q "MSSQL CONFIG COMPLETE" ./config.log
