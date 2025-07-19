FROM ubuntu:latest

RUN apt-get update
RUN apt install ldc zlib1g-dev -y
# Install dependencies and DMD
RUN apt-get install -y curl wget git build-essential libssl-dev && \
    wget https://downloads.dlang.org/releases/2.x/2.111.0/dmd_2.111.0-0_amd64.deb && \
    dpkg -i dmd_2.111.0-0_amd64.deb && \
    rm dmd_2.111.0-0_amd64.deb && \
    apt-get clean

ARG BUILD_TYPE
ARG COMPILER=dmd

WORKDIR /app

COPY source/ /app/source
COPY dub.json /app/

RUN echo "Built with BUILD_TYPE=${BUILD_TYPE} and COMPILER=${COMPILER}" > /app/build_info.txt
RUN cat /app/build_info.txt
RUN dub build --build=${BUILD_TYPE} --compiler=${COMPILER}

# Create a non-root user and group
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Create home directory for appuser and set ownership
RUN mkdir -p /home/appuser && chown appuser:appuser /home/appuser

# Set HOME environment variable
ENV HOME=/home/appuser

# Change ownership of the app directory
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

CMD sh -c "cat /app/build_info.txt && ./rinha-de-backend-2025-d"
