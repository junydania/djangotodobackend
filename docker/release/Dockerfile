FROM odania/todobackend-base:latest
MAINTAINER Osegbemoh Dania <o.dania@aol.com>

COPY target /wheelhouse

RUN . /appenv/bin/activate && \
    pip install --no-index -f /wheelhouse todobackend && \
    rm -rf /wheelhouse
